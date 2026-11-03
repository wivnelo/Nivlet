"""Runtime trim stays fail-closed and never removes a module Toolkit references."""
from pathlib import Path
import importlib.util
import plistlib
import re
import tempfile

root = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('trim_runtime', root / 'scripts/trim-runtime.py')
trim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(trim)

removed = {name[3:-6] for name in trim.LIBRARIES} | {name.removesuffix('.lua') for name in trim.EXTENSIONS}
removed |= {name.replace('_', '') for name in removed}
used = set()
for path in list((root / 'Toolkit').rglob('*.lua')) + [root / 'Toolkit/settings.html']:
    source = re.sub(r'--[^\n]*', '', path.read_text(errors='replace'))
    used |= {match.replace('.', '_') for match in re.findall(r'\bhs\.([A-Za-z_][\w.]*)', source)}
    used |= {match.split('.')[0] for match in re.findall(r'\bhs\.([A-Za-z_][\w.]*)', source)}
conflicts = sorted(used & removed)
assert not conflicts, 'Toolkit references removed runtime modules: ' + ', '.join(conflicts)
for required in ('network', 'network_configuration', 'window', 'window_filter', 'spaces', 'spaces_watcher', 'plist', 'redshift',
                 'webview', 'pasteboard', 'axuielement', 'doc'):
    assert required not in removed, required + ' must stay bundled'

with tempfile.TemporaryDirectory(prefix='nivlet-trim-test-') as directory:
    app = Path(directory) / 'Nivlet.app'
    (app / 'Contents').mkdir(parents=True)
    (app / 'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier': 'dev.local.DesktopToolkit'}))
    for path in trim.planned_paths(app) + trim.emptied_paths(app):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.mkdir() if path.suffix == '' and path.parent.name == 'hs' and path.name != 'hs' else path.write_bytes(b'x')
    kept = app / 'Contents/Frameworks/hs/libwindow.dylib'
    kept.write_bytes(b'kept')
    missing = trim.planned_paths(app)[0]
    missing.unlink()
    try:
        trim.trim(app)
    except ValueError as error:
        assert 'missing' in str(error)
    else:
        raise AssertionError('Missing runtime path must stop the trim')
    assert all(path.exists() for path in trim.planned_paths(app)[1:]), 'Refused trim must not remove anything'
    missing.write_bytes(b'x')
    result = trim.trim(app)
    assert result['removedPaths'] == len(trim.planned_paths(app))
    assert not any(path.exists() for path in trim.planned_paths(app)) and kept.read_bytes() == b'kept'
    assert all(path.read_bytes() == b'[]\n' for path in trim.emptied_paths(app)), 'API docs must stay as empty JSON'
print('Runtime trim keeps Toolkit modules, refuses missing paths without partial removal, removes only listed paths and keeps empty API docs')
