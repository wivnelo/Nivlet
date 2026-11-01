"""Compare the published popup default with the real in-memory export adapter."""
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parent.parent
probe = r'''
dofile('tests/runtime.lua')
local value=desktopToolkit.configuration.export(true).modules.popupShortcut
assert(type(value)=='table' and type(value.key)=='string' and type(value.mods)=='table')
print('POPUP_DEFAULT_KEY='..value.key)
print('POPUP_DEFAULT_MODS='..table.concat(value.mods,','))
'''
result = subprocess.run(['lua', '-e', probe], cwd=root, text=True,
                        capture_output=True)
assert result.returncode == 0, result.stderr
values = {}
for line in result.stdout.splitlines():
    if line.startswith('POPUP_DEFAULT_'):
        key, value = line.split('=', 1)
        assert key not in values
        values[key] = value
exported = {'key': values['POPUP_DEFAULT_KEY'],
            'mods': values['POPUP_DEFAULT_MODS'].split(',')}
example = json.loads((root / 'examples/configuration.json').read_text())
assert example['modules']['popupShortcut'] == exported
assert exported == {'key': 'V', 'mods': ['cmd', 'shift']}
print('Configuration example matches the enabled Command-Shift-V export default')
