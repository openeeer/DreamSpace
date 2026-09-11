"""Import the six expected PNGs, validate them, and retain replaced sources."""
import hashlib
import io
import json
from pathlib import Path
import shutil
import sys
import zipfile
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DESTINATIONS = {
    'moon_library.png': 'dreams',
    'cosmic_background.png': 'backgrounds',
    'ocean_without_end.png': 'dreams',
    'red_forest.png': 'dreams',
    'empty_city.png': 'dreams',
    'nebula_foreground.png': 'backgrounds',
}


def main(archive):
    prepared = []
    with zipfile.ZipFile(archive) as bundle:
        for name, directory in DESTINATIONS.items():
            matches = [entry for entry in bundle.infolist()
                       if Path(entry.filename.replace('\\', '/')).name == name]
            if len(matches) != 1:
                raise ValueError(f'Expected exactly one {name}')
            data = bundle.read(matches[0])
            with Image.open(io.BytesIO(data)) as image:
                if image.format != 'PNG':
                    raise ValueError(f'{name}: expected PNG')
                image.load()
                alpha = image.getchannel('A').getextrema() if 'A' in image.getbands() else None
                if name == 'nebula_foreground.png' and (alpha is None or alpha[0] == 255):
                    raise ValueError('The supplied nebula has no effective transparency')
                metadata = {'file': f'assets/{directory}/{name}', 'width': image.width,
                            'height': image.height, 'mode': image.mode, 'alpha_range': alpha,
                            'sha256': hashlib.sha256(data).hexdigest(), 'source': 'user archive'}
            prepared.append((ROOT / 'assets' / directory / name, data, metadata))
    for target, data, metadata in prepared:
        if target.exists() and target.read_bytes() != data:
            backup = ROOT / 'docs/generation/superseded' / target.name
            backup.parent.mkdir(parents=True, exist_ok=True)
            if not backup.exists():
                shutil.copy2(target, backup)
        target.write_bytes(data)
        print(json.dumps(metadata, ensure_ascii=False))
    (ROOT / 'docs/generation/user_assets.json').write_text(
        json.dumps([item[2] for item in prepared], ensure_ascii=False, indent=2), encoding='utf-8')


if __name__ == '__main__':
    main(sys.argv[1])
