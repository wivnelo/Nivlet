#!/usr/bin/env python3
"""Sign Developer ID releases, notarize and staple apps/DMGs, then checksum."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
MAGIC = {bytes.fromhex(value) for value in (
    'cafebabe', 'bebafeca', 'cafebabf', 'bfbafeca',
    'cffaedfe', 'feedfacf', 'cefaedfe', 'feedface',
)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for flag, env in [('identity', 'SIGN_IDENTITY'), ('team-id', 'TEAM_ID'),
                      ('notary-profile', 'NOTARY_PROFILE'), ('build-dir', 'RELEASE_DIR'),
                      ('build', 'BUILD_NUMBER')]:
        parser.add_argument('--' + flag, default=os.environ.get('NIVLET_' + env),
                            help='or NIVLET_' + env)
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('archs', nargs='*', choices=['arm64', 'x86_64'])
    args = parser.parse_args()
    for flag in ['identity', 'team_id', 'notary_profile', 'build_dir', 'build']:
        if not getattr(args, flag) or not getattr(args, flag).strip():
            parser.error('Missing required --' + flag.replace('_', '-') + ' (or its NIVLET environment variable)')
    if not args.build.isdecimal():
        parser.error('--build must be a numeric build number')
    archs = args.archs or ['arm64', 'x86_64']
    if len(set(archs)) != len(archs):
        parser.error('Duplicate architectures')
    version = (ROOT / 'VERSION').read_text().strip()
    release = Path(args.build_dir).resolve()
    dist = release / 'dist'
    entitlements = ROOT / 'Native/Nivlet.entitlements'

    def run(*command, **kwargs):
        command = list(map(str, command))
        print('+ ' + shlex.join(command), flush=True)
        if not args.dry_run:
            return subprocess.run(command, check=True, **kwargs)

    def sign(path, ent=False, runtime=True):
        command = ['codesign', '--force', '--sign', args.identity, '--timestamp']
        if runtime:
            command += ['--options', 'runtime']
        if ent:
            command += ['--entitlements', entitlements]
        run(*command, path)
        result = run('codesign', '-dv', '--verbose=4', path, capture_output=True, text=True)
        if result and ('TeamIdentifier=' + args.team_id) not in result.stderr.splitlines():
            raise ValueError('Signing TeamIdentifier mismatch: ' + str(path))
        if args.dry_run:
            print('  require TeamIdentifier=' + args.team_id)

    def notarize(path, tag):
        report = release / ('notary-' + tag + '.json')
        log_path = release / ('notary-' + tag + '-log.json')
        command = ['xcrun', 'notarytool', 'submit', path, '--keychain-profile',
                   args.notary_profile, '--wait', '--output-format', 'json']
        # A failed submission still needs its response and diagnostic log saved.
        print('+ ' + shlex.join(list(map(str, command))), flush=True)
        print('  save response to ' + str(report) + '; require Accepted')
        if args.dry_run:
            run('xcrun', 'notarytool', 'log', '<submission-id-on-failure>',
                '--keychain-profile', args.notary_profile, log_path)
            return
        result = subprocess.run(list(map(str, command)), capture_output=True, text=True)
        report.write_text(result.stdout)
        if result.stderr:
            print(result.stderr, file=sys.stderr)
        try:
            data = json.loads(result.stdout)
        except json.JSONDecodeError:
            data = {}
        if result.returncode or data.get('status') != 'Accepted':
            if data.get('id'):
                run('xcrun', 'notarytool', 'log', data['id'], '--keychain-profile',
                    args.notary_profile, log_path)
            raise ValueError('Notarization not Accepted for ' + tag)

    # Check every output before making any changes, including diagnostics and staging.
    for arch in archs:
        work = release / arch
        base = f'Nivlet-{version}-build{args.build}-{arch}'
        outputs = [work / 'Nivlet.app', work / 'dmg-stage', work / (base + '-notary.zip')]
        outputs += [dist / (base + suffix) for suffix in ['.zip', '.dmg', '.sha256']]
        outputs += [release / f'notary-{kind}-{arch}{suffix}'
                    for kind in ['app', 'dmg'] for suffix in ['.json', '-log.json']]
        for path in outputs:
            if path.exists() or path.is_symlink():
                raise ValueError('Refusing overwrite: ' + str(path))
        source = work / 'DerivedData/Build/Products/Release/Nivlet.app'
        if not args.dry_run and not source.is_dir():
            raise ValueError('Missing built app: ' + str(source))
    if not args.dry_run:
        dist.mkdir(parents=True, exist_ok=True)
    print(f'Version {version}, build {args.build}; release directory: {release}')
    for arch in archs:
        work = release / arch
        source = work / 'DerivedData/Build/Products/Release/Nivlet.app'
        app = work / 'Nivlet.app'
        base = f'Nivlet-{version}-build{args.build}-{arch}'
        run('ditto', source, app)
        scan = source if args.dry_run else app
        binaries, bundles = [], []
        for path in scan.rglob('*'):
            if path.is_symlink():
                continue
            if path.is_file():
                with path.open('rb') as stream:
                    if stream.read(4) in MAGIC:
                        binaries.append(path)
            elif path.suffix in {'.framework', '.app', '.xpc', '.bundle'}:
                if path.suffix != '.bundle' or (path / 'Contents/MacOS').is_dir():
                    bundles.append(path)
        if args.dry_run and not source.exists():
            print('  discover all nested Mach-O files, then code bundles; each deepest-first')
            binaries = [scan / 'Contents/MacOS/Nivlet']
        for paths in [binaries, bundles]:
            for path in sorted(paths, key=lambda p: (-len(p.parts), str(p))):
                target = app / path.relative_to(scan)
                sign(target, target == app / 'Contents/MacOS/Nivlet')
        sign(app, True)
        run('codesign', '--verify', '--deep', '--strict', app)
        notary_zip = work / (base + '-notary.zip')
        run('ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', app, notary_zip)
        notarize(notary_zip, 'app-' + arch)
        run('xcrun', 'stapler', 'staple', app)
        run('xcrun', 'stapler', 'validate', app)
        run('spctl', '-a', '-vvv', '-t', 'exec', app)
        archive, dmg = dist / (base + '.zip'), dist / (base + '.dmg')
        run('ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', app, archive)
        run(sys.executable, ROOT / 'scripts/check-privacy.py', '--zip', archive)
        stage = work / 'dmg-stage'
        print('+ mkdir ' + shlex.quote(str(stage)))
        if not args.dry_run:
            stage.mkdir()
        run('ditto', app, stage / 'Nivlet.app')
        print('+ ln -s /Applications ' + shlex.quote(str(stage / 'Applications')))
        if not args.dry_run:
            (stage / 'Applications').symlink_to('/Applications')
        run('hdiutil', 'create', '-quiet', '-volname', 'Nivlet ' + version,
            '-srcfolder', stage, '-format', 'UDZO', dmg)
        sign(dmg, runtime=False)
        notarize(dmg, 'dmg-' + arch)
        run('xcrun', 'stapler', 'staple', dmg)
        run('xcrun', 'stapler', 'validate', dmg)
        run('spctl', '-a', '-vvv', '-t', 'open', '--context', 'context:primary-signature', dmg)
        checksum = dist / (base + '.sha256')
        print('+ SHA-256 ' + str(archive) + ' ' + str(dmg) + ' -> ' + str(checksum))
        if not args.dry_run:
            with checksum.open('x') as output:
                for path in [archive, dmg]:
                    digest = hashlib.sha256()
                    with path.open('rb') as stream:
                        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
                            digest.update(chunk)
                    output.write(f'{digest.hexdigest()}  {path.name}\n')


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))
