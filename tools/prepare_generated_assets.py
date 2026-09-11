"""Prepare runtime WebP assets, preserving PNG masters and native alpha."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
NAMES = ['moon_library', 'ocean_without_end', 'red_forest', 'empty_city',
         'glass_staircase', 'last_train', 'sky_islands', 'door_under_water']

for name in NAMES:
    source = ROOT / 'assets/dreams' / (name + '.png')
    if not source.exists():
        continue
    with Image.open(source) as image:
        image = image.convert('RGB')
        image.thumbnail((1600, 1200), Image.Resampling.LANCZOS)
        image.save(source.with_suffix('.webp'), 'WEBP', quality=92, method=6)
        print(f'{name}.webp: {image.size}')

background = ROOT / 'assets/backgrounds/cosmic_background.png'
if background.exists():
    with Image.open(background) as image:
        image = image.convert('RGB')
        image.thumbnail((1440, 3120), Image.Resampling.LANCZOS)
        image.save(background.with_suffix('.webp'), 'WEBP', quality=92, method=6)
        print(f'cosmic_background.webp: {image.size}')

with Image.open(ROOT / 'assets/backgrounds/nebula_foreground.png') as source:
    if 'A' not in source.getbands() or source.getchannel('A').getextrema()[0] == 255:
        raise ValueError('Nebula must have real transparency; no automatic chroma-key fallback.')
    rgba = source.convert('RGBA')
    rgba.thumbnail((1600, 1100), Image.Resampling.LANCZOS)
    rgba.save(ROOT / 'assets/backgrounds/nebula_foreground.webp', 'WEBP', quality=92, method=6)
    preview = Image.new('RGBA', rgba.size, (7, 11, 30, 255))
    preview.alpha_composite(rgba)
    preview.convert('RGB').save(ROOT / 'docs/generation/nebula_preview.jpg', quality=90)
    print(f'nebula_foreground.webp: {rgba.size}, native alpha preserved')
