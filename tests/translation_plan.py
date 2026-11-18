import os
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory() as work:
    binary = Path(work) / 'translation-plan'
    main = Path(work) / 'main.swift'
    main.write_text((root / 'tests/translation_plan.swift').read_text())
    cache = Path(work) / 'module-cache'
    environment = dict(os.environ, CLANG_MODULE_CACHE_PATH=str(cache), SWIFT_MODULECACHE_PATH=str(cache))
    subprocess.run(['xcrun', 'swiftc', '-swift-version', '5', '-module-cache-path', str(cache),
                    str(root / 'Native/capture/TranslationPlan.swift'), str(main),
                    '-o', str(binary)], check=True, env=environment)
    result = subprocess.run([str(binary)], capture_output=True, text=True)
    print(result.stdout.strip())
    assert result.returncode == 0, result.stdout + result.stderr
