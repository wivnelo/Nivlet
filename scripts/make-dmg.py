#!/usr/bin/env python3
"""Build the Nivlet install DMG with the designed Finder window, then verify it.

dmgbuild writes the window layout without scripting Finder. Install it once with
  python3 -m venv build/dmg-venv && build/dmg-venv/bin/pip install -r scripts/requirements-dmg.txt
or point NIVLET_DMGBUILD at another dmgbuild executable.
"""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / 'assets/dmg'
DEFAULT_DMGBUILD = ROOT / 'build/dmg-venv/bin/dmgbuild'
INSTALL_HINT = ('python3 -m venv build/dmg-venv && '
                'build/dmg-venv/bin/pip install -r scripts/requirements-dmg.txt')


def find_dmgbuild(explicit=None):
    path = Path(explicit or os.environ.get('NIVLET_DMGBUILD') or DEFAULT_DMGBUILD)
    if not (path.is_file() and os.access(path, os.X_OK)):
        raise SystemExit(f'dmgbuild not found at {path}; install it with: {INSTALL_HINT}')
    return path


def verify(dmg, appname):
    """Mount read-only and check the layout files and the app signature inside."""
    with tempfile.TemporaryDirectory(prefix='nivlet-dmg-') as mount:
        subprocess.run(['hdiutil', 'attach', '-nobrowse', '-readonly', '-noautoopen',
                        '-mountpoint', mount, str(dmg)], check=True, stdout=subprocess.DEVNULL)
        try:
            volume = Path(mount)
            for name in ('.DS_Store', '.background.tiff', appname):
                if not (volume / name).exists():
                    raise SystemExit(f'DMG is missing {name}')
            if os.readlink(volume / 'Applications') != '/Applications':
                raise SystemExit('DMG Applications link does not point to /Applications')
            subprocess.run(['codesign', '--verify', '--deep', '--strict', str(volume / appname)], check=True)
        finally:
            subprocess.run(['hdiutil', 'detach', mount, '-quiet'], check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('app', type=Path)
    parser.add_argument('dmg', type=Path)
    parser.add_argument('--volname', required=True)
    parser.add_argument('--dmgbuild')
    args = parser.parse_args()
    dmgbuild = find_dmgbuild(args.dmgbuild)
    app, dmg = args.app.resolve(), args.dmg.resolve()
    if not app.is_dir():
        raise SystemExit(f'App not found: {app}')
    if dmg.exists():
        raise SystemExit(f'Refusing overwrite: {dmg}')
    subprocess.run([str(dmgbuild), '-s', str(ASSETS / 'dmg-settings.py'),
                    '-D', f'app={app}', '-D', f'background={ASSETS / "background.tiff"}',
                    args.volname, str(dmg)], check=True, stdout=subprocess.DEVNULL)
    verify(dmg, app.name)
    print(f'DMG ready: {dmg}')


if __name__ == '__main__':
    main()
