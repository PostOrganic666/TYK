#!/usr/bin/env python3
"""Import November alphabet illustrations and render all six examples per letter.

Run with a Python environment containing Pillow. Original imagegen outputs and
their exact prompts remain in catalog/alphabet-expansion-2026-11/.
"""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
EXPANSION = ROOT / 'catalog/alphabet-expansion-2026-11'


def main():
    manifest = json.loads((EXPANSION / 'generation.json').read_text())
    assets_path = ROOT / 'catalog/alphabet-assets.json'
    assets = {item['asset']: item for item in json.loads(assets_path.read_text())}
    for item in manifest['items']:
        source = EXPANSION / 'originals' / (item['asset'] + '.png')
        with Image.open(source) as image:
            image = image.convert('RGBA')
            assert image.getchannel('A').getextrema()[0] == 0, source
            bbox = image.getchannel('A').point(lambda a: 255 if a >= 16 else 0).getbbox()
            assert bbox, source
            image = image.crop(bbox)
            scale = 440 / max(image.size)
            image = image.resize((round(image.width * scale), round(image.height * scale)),
                                 Image.Resampling.LANCZOS)
            sprite = Image.new('RGBA', (512, 512))
            sprite.alpha_composite(image, ((512 - image.width) // 2, (512 - image.height) // 2))
            destination = ROOT / 'ToddlerLock/Resources/Alphabet' / (item['asset'] + '.png')
            sprite.save(destination, optimize=True)
        item['sourceFile'] = 'originals/' + source.name
        item['sourceSha256'] = hashlib.sha256(source.read_bytes()).hexdigest()
        item['file'] = str(destination.relative_to(ROOT / 'ToddlerLock'))
        assets[item['asset']] = {key: item[key] for key in ('name', 'asset', 'prompt')}
    assets_path.write_text(json.dumps(list(assets.values()), ensure_ascii=False, indent=2) + '\n')
    (EXPANSION / 'generation.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')

    # Review pages include reused illustrations too, so caption/subject mismatches
    # can be checked alongside the newly generated pictures.
    files = {p.stem: p for p in (ROOT / 'ToddlerLock/Resources').rglob('*.png')}
    cards = json.loads((ROOT / 'catalog/alphabet.json').read_text())
    font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 17)
    letter_font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 34)
    for page_number, offset in enumerate(range(0, len(cards), 11), 1):
        page = Image.new('RGB', (1380, 11 * 205), '#faf2e0')
        draw = ImageDraw.Draw(page)
        for row, card in enumerate(cards[offset:offset + 11]):
            y = row * 205
            draw.text((35, y + 85), card['glyph'], font=letter_font, fill='#ad6446', anchor='mm')
            for column, picture in enumerate(card['pictures']):
                x = 65 + column * 218
                with Image.open(files[picture['assetName']]) as image:
                    image = image.convert('RGBA').resize((174, 174), Image.Resampling.LANCZOS)
                    page.paste(image, (x + 22, y), image)
                draw.text((x + 109, y + 185), picture['name'], font=font, fill='#443b32', anchor='mm')
        page.save(EXPANSION / f'preview-{page_number}.jpg', quality=93)
    print(f"Imported {len(manifest['items'])} illustrations; rendered 198 examples on three review pages")


if __name__ == '__main__':
    main()
