#!/usr/bin/env python3
"""Remove Hammerspoon extensions and the IPC tool that Nivlet cannot reach; empty the API docs.

Run before signing. Only the listed paths are removed; every one must exist, and no
remaining Mach-O may link a removed dylib. The core passes docs.json's path to Lua at
launch, so the API docs become empty JSON arrays instead of being deleted. Unlisted
modules are always kept, so a
runtime update cannot silently widen the removal. tests/runtime_trim.py checks that
Toolkit never references a removed module.
"""
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys

LIBRARIES = (
    'libaudiodevice.dylib', 'libaudiodevicewatcher.dylib', 'libbase64.dylib',
    'libbattery.dylib', 'libbatterywatcher.dylib', 'libbonjour.dylib',
    'libbonjourservice.dylib', 'libbrightness.dylib', 'libcamera.dylib',
    'libdistributednotifications.dylib', 'libhid.dylib', 'libhints.dylib',
    'libhttpserver.dylib', 'libipc.dylib', 'liblocation.dylib', 'liblsqlite3.dylib',
    'libmarkdown.dylib', 'libmidi.dylib', 'libmilight.dylib', 'libnoises.dylib',
    'libnotify.dylib', 'libpathwatcher.dylib', 'librazer.dylib',
    'libserial.dylib', 'libshortcuts.dylib', 'libsocket.dylib', 'libsocketudp.dylib',
    'libspeech.dylib', 'libspeechlistener.dylib',
    'libstreamdeck.dylib', 'libusb.dylib', 'libusbwatcher.dylib', 'libwifi.dylib',
    'libwifiwatcher.dylib',
)
EXTENSIONS = (
    'appfinder.lua', 'audiodevice.lua', 'base64.lua', 'battery.lua', 'bonjour.lua',
    'brightness.lua', 'camera.lua', 'cgilua_compatibility_functions.lua', 'deezer.lua',
    'distributednotifications.lua', 'doc_builder.lua', 'expose.lua', 'grid.lua', 'hid.lua',
    'hints.lua', 'hsdocs', 'httpserver.lua', 'httpserver_hsminweb.lua', 'ipc.lua',
    'itunes.lua', 'javascript.lua', 'layout.lua', 'location.lua', 'location_geocoder.lua',
    'messages.lua', 'midi.lua', 'milight.lua', 'mjomatic.lua', 'noises.lua', 'notify.lua',
    'pathwatcher.lua', 'razer.lua', 'serial.lua', 'shortcuts.lua',
    'socket.lua', 'speech.lua', 'spoons.lua', 'spotify.lua', 'sqlite3.lua',
    'streamdeck.lua', 'tabs.lua', 'tangent.lua', 'usb.lua', 'vox.lua', 'wifi.lua',
)
EMPTIED = ('docs.json', 'lua.json')
TOOLS = ('hs',)


def planned_paths(app):
    contents = app / 'Contents'
    return ([contents / 'Frameworks/hs' / name for name in LIBRARIES + TOOLS]
            + [contents / 'Resources/extensions/hs' / name for name in EXTENSIONS])


def emptied_paths(app):
    return [app / 'Contents/Resources' / name for name in EMPTIED]


def size(path):
    if path.is_dir():
        return sum(item.stat().st_size for item in path.rglob('*') if item.is_file() and not item.is_symlink())
    return path.stat().st_size


def trim(app):
    app = Path(os.path.abspath(app))
    info = app / 'Contents/Info.plist'
    if app.suffix != '.app' or app.is_symlink() or not info.is_file():
        raise ValueError('Expected a real app bundle')
    if plistlib.loads(info.read_bytes()).get('CFBundleIdentifier') != 'dev.local.DesktopToolkit':
        raise ValueError('Expected the Nivlet app bundle')
    planned = planned_paths(app)
    emptied = emptied_paths(app)
    missing = [str(path.relative_to(app)) for path in planned + emptied if not path.exists() or path.is_symlink()]
    if missing:
        raise ValueError('Expected runtime paths are missing: ' + ', '.join(missing))
    removed = {path.name for path in planned if path.suffix == '.dylib'}
    removed_bytes = sum(size(path) for path in planned) + sum(size(path) - 3 for path in emptied)
    for path in planned:
        shutil.rmtree(path) if path.is_dir() else path.unlink()
    for path in emptied:
        path.write_bytes(b'[]\n')
    for path in app.rglob('*'):
        if path.is_symlink() or not path.is_file() or path.suffix not in {'.dylib', ''}:
            continue
        with path.open('rb') as stream:
            if stream.read(4) not in {bytes.fromhex('cffaedfe'), bytes.fromhex('cafebabe')}:
                continue
        linked = subprocess.run(['otool', '-L', str(path)], capture_output=True, text=True, check=True).stdout
        broken = sorted(name for name in removed if '/' + name + ' ' in linked)
        if broken:
            raise ValueError(str(path.relative_to(app)) + ' links removed ' + ', '.join(broken))
    return {'removedPaths': len(planned), 'emptiedPaths': len(emptied), 'removedBytes': removed_bytes}


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit('usage: trim-runtime.py <Nivlet.app>')
    print(json.dumps(trim(sys.argv[1])))
