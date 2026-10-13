#!/usr/bin/env python3
"""Normalize food cutouts to the existing 512px card format and render a review sheet."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]


def main():
    entries = json.loads((ROOT / 'catalog/food/items.json').read_text())
    destination = ROOT / 'ToddlerLock/Resources/Pictures/Food'
    destination.mkdir(parents=True, exist_ok=True)
    for entry in entries:
        source = ROOT / 'catalog/food/originals' / (entry['asset'] + '.png')
        with Image.open(source) as image:
            image = image.convert('RGBA')
            assert image.getchannel('A').getextrema()[0] == 0, source
            box = image.getchannel('A').getbbox()
            assert box, source
            image = image.crop(box)
            scale = 440 / max(image.size)
            image = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
            sprite = Image.new('RGBA', (512, 512))
            sprite.alpha_composite(image, ((512-image.width)//2, (512-image.height)//2))
            sprite.save(destination / (entry['asset'] + '.png'), optimize=True)
    sheet = Image.new('RGB', (1200, 2450), '#faf2e0')
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 18)
    for index, entry in enumerate(entries):
        x, y = index % 5 * 240, index // 5 * 245
        with Image.open(destination / (entry['asset'] + '.png')) as image:
            image = image.resize((210, 210), Image.Resampling.LANCZOS)
            sheet.paste(image, (x+15, y+1), image)
        draw.text((x+120, y+224), entry['name'], font=font, fill='#443b32', anchor='mm')
    sheet.save(ROOT / 'catalog/food-added.jpg', quality=93)
    print(f'Imported {len(entries)} food sprites and created food-added.jpg')


if __name__ == '__main__':
    main()
