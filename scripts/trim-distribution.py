#!/usr/bin/env python3
"""Remove only embedded framework compile-time interfaces before release signing.

Runtime libraries, resources, notices, signatures and source checkouts are never
selected. All paths are preflighted before removal; unexpected content fails
closed so a dependency upgrade cannot silently widen the removal scope.
"""
import argparse
import json
import os
from pathlib import Path
import plistlib
import shutil
import stat

FRAMEWORKS = {
    'LuaSkin.framework': ('A', ('Headers', 'Modules')),
    'Sparkle.framework': ('B', ('Headers', 'PrivateHeaders', 'Modules')),
}


def trim(app):
    app = Path(os.path.abspath(app))
    if app.suffix != '.app' or app.is_symlink() or not app.is_dir():
        raise ValueError('Expected a real app bundle')
    if (app / 'Contents').is_symlink() or (app / 'Contents/Frameworks').is_symlink():
        raise ValueError('Unexpected bundle directory symlink')
    info = app / 'Contents/Info.plist'
    if info.is_symlink() or plistlib.loads(info.read_bytes()).get('CFBundleIdentifier') != 'dev.local.DesktopToolkit':
        raise ValueError('Expected the Nivlet app bundle')
    planned = []
    removed_bytes = 0
    for framework, (version, names) in FRAMEWORKS.items():
        base = app / 'Contents/Frameworks' / framework
        for name in names:
            directory = base / 'Versions' / version / name
            for parent in (base.parent, base, base / 'Versions', base / 'Versions' / version, directory):
                if parent.is_symlink():
                    raise ValueError('Unexpected directory symlink: ' + str(parent.relative_to(app)))
            if directory.exists():
                if not directory.is_dir():
                    raise ValueError('Expected compile-time directory: ' + str(directory.relative_to(app)))
                for entry in directory.rglob('*'):
                    mode = entry.lstat().st_mode
                    if stat.S_ISDIR(mode):
                        continue
                    expected = entry.suffix == '.h' if name.endswith('Headers') else entry.suffix == '.modulemap'
                    if not stat.S_ISREG(mode) or not expected:
                        raise ValueError('Unexpected compile-time content: ' + str(entry.relative_to(app)))
                    removed_bytes += entry.stat().st_size
                planned.append(directory)
            link = base / name
            if link.is_symlink():
                if os.readlink(link) != 'Versions/Current/' + name:
                    raise ValueError('Unexpected interface symlink: ' + str(link.relative_to(app)))
                planned.append(link)
            elif link.exists():
                raise ValueError('Expected interface symlink: ' + str(link.relative_to(app)))
    for path in planned:
        if path.is_symlink():
            path.unlink()
        else:
            shutil.rmtree(path)
    return {'removedPaths': [str(path.relative_to(app)) for path in planned],
            'removedRegularFileBytes': removed_bytes}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    args = parser.parse_args()
    print(json.dumps(trim(args.app), ensure_ascii=False))


if __name__ == '__main__':
    main()
