"""Collect vendored license texts into the app without copying source or user data."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parent.parent
upstream = root / 'vendor/hammerspoon'
ack = upstream / 'Pods/Target Support Files/Pods-Hammerspoon/Pods-Hammerspoon-acknowledgements.markdown'
if not ack.is_file():
    raise SystemExit('Missing dependency acknowledgements; install pinned Runtime dependencies first')
parts = [(root / 'THIRD-PARTY-NOTICES.md').read_text(), ack.read_text()]
parts.append('## Nivlet updater: Sparkle 2.10.0\n\n' + (root / 'vendor/sparkle-2.10.0/LICENSE').read_text())
licenses = sorted(path for path in upstream.rglob('*') if path.is_file() and (path.name.lower() in {'license', 'copying', 'copyright'} or path.name.lower().startswith(('license.', 'license-', 'copying.', 'copying-', 'copyright.', 'copyright-'))) and '.git' not in path.parts and 'Headers' not in path.parts)
for path in licenses:
    if not path.is_symlink():
        parts.append('## ' + path.relative_to(upstream).as_posix() + '\n\n' + path.read_text(errors='replace'))
# Lua embeds its copyright/license in the README.
lua_readme = upstream / 'LuaSkin/lua-5.4.7/README'
if not lua_readme.is_file():
    raise SystemExit('Missing Lua license README')
parts.append('## Lua 5.4.7\n\n' + lua_readme.read_text())
Path(sys.argv[1]).write_text('\n\n'.join(parts))
print('Collected dependency acknowledgements and', len(licenses), 'license files')
