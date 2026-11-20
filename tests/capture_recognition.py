import os
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parent.parent
SAMPLE = '''import AppKit
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1200, pixelsHigh: 300, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSColor.white.setFill(); NSRect(x: 0, y: 0, width: 1200, height: 300).fill()
("截图识别 Screenshot OCR 2026" as NSString).draw(at: NSPoint(x: 40, y: 140), withAttributes: [.font: NSFont.systemFont(ofSize: 48), .foregroundColor: NSColor.black])
NSGraphicsContext.restoreGraphicsState()
FileHandle.standardOutput.write(rep.representation(using: .png, properties: [:])!)
'''

with tempfile.TemporaryDirectory() as work:
    work = Path(work)
    cache = work / 'module-cache'
    environment = dict(os.environ, CLANG_MODULE_CACHE_PATH=str(cache), SWIFT_MODULECACHE_PATH=str(cache))
    helper = work / 'capture-helper'
    subprocess.run(['xcrun', 'swiftc', '-swift-version', '5', '-module-cache-path', str(cache),
                    '-Xlinker', '-weak_framework', '-Xlinker', 'Translation',
                    '-Xlinker', '-weak_framework', '-Xlinker', '_Translation_SwiftUI',
                    *map(str, sorted((root / 'Native/capture').glob('*.swift'))), '-o', str(helper)],
                   check=True, env=environment)
    (work / 'sample.swift').write_text(SAMPLE)
    subprocess.run(['xcrun', 'swiftc', '-module-cache-path', str(cache), str(work / 'sample.swift'),
                    '-o', str(work / 'sample')], check=True, env=environment)
    png = subprocess.run([str(work / 'sample')], capture_output=True, check=True).stdout

    for interface in ['zh-Hans', 'en']:
        result = subprocess.run([str(helper), '--recognize', interface], input=png, capture_output=True, timeout=180)
        text = result.stdout.decode()
        assert result.returncode == 0, (interface, result.returncode, result.stderr)
        assert '截图识别' in text and 'Screenshot OCR' in text, (interface, text)

    bad = subprocess.run([str(helper), '--recognize', 'zh-Hans'], input=b'not an image', capture_output=True, timeout=60)
    assert bad.returncode == 1 and bad.stdout == b'', bad

print('capture recognition: fresh-process OCR reads Chinese and English, rejects non-images')
