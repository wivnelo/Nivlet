"""Encode the captured UI frames as compact, looping README GIFs (requires Pillow)."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parent.parent
output = root / 'docs/assets/demos'
output.mkdir(parents=True, exist_ok=True)
for language in ('en', 'zh'):
    paths = sorted((root / 'build/readme-demo' / language).glob('*.png'))
    if len(paths) != 128:
        raise SystemExit(f'{language}: expected 128 frames, found {len(paths)}')
    frames = [Image.open(path).convert('RGB') for path in paths]
    samples = [frames[i].resize((320, 267)) for i in (0, 24, 32, 56, 64, 88, 96, 120)]
    sheet = Image.new('RGB', (1280, 534))
    for i, sample in enumerate(samples):
        sheet.paste(sample, ((i % 4) * 320, (i // 4) * 267))
    sheet.save(root / 'build/readme-demo' / f'preview-{language}.jpg')
    palette = sheet.quantize(colors=128, method=Image.Quantize.MEDIANCUT)
    frames = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
    target = output / f'overview-{language}.gif'
    # GIF delays use 10 ms units: alternate 120/130 ms for a true 8 fps.
    frames[0].save(target, save_all=True, append_images=frames[1:],
                   duration=[120, 130] * 64, loop=0, optimize=True, disposal=1)
    with Image.open(target) as check:
        duration = 0
        for i in range(check.n_frames):
            check.seek(i)
            duration += check.info['duration']
        assert duration == 16000, duration
        assert check.size == (960, 800)
        assert check.info['loop'] == 0
        print(f'{target.relative_to(root)}: {check.n_frames} frames, {duration / 1000:g}s, {target.stat().st_size / 1024 / 1024:.2f} MiB')
