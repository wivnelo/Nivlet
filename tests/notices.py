"""Check that suffix-named upstream notices reach generated distribution text."""
from pathlib import Path
import subprocess, sys, tempfile
root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory() as directory:
    output = Path(directory) / 'notices.md'
    subprocess.run([sys.executable, str(root / 'scripts/collect-notices.py'), str(output)], check=True)
    text = output.read_text()
    for relative in ['extensions/network/ping/LICENSE.SimplePing', 'extensions/httpserver/LICENSE.timeout3', 'Pods/SocketRocket/LICENSE-examples']:
        assert '## ' + relative in text, relative
        assert (root / 'vendor/hammerspoon' / relative).read_text() in text, relative
    assert '## Lua 5.4.7' in text
print('Suffix-named licenses and exact upstream notice text: passed')
