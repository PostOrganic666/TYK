#!/usr/bin/env python3
"""Normalize November cards, retain source provenance and render review pages.

Use --partial while image generation is in progress. The normal run requires
all selected images and writes two review pages for each collection,
plus a before/after sheet for targeted animal redraws.
"""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
EXPANSION = ROOT / 'catalog/expansion-2026-11'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--partial', action='store_true')
    args = parser.parse_args()
    base_items = json.loads((EXPANSION / 'items.json').read_text())
    base_assets = {i['asset'] for i in base_items}
    revision_path = EXPANSION / 'revisions.json'
    revisions = json.loads(revision_path.read_text()) if revision_path.exists() else []
    revision_by_asset = {i['asset']: i for i in revisions}
    items = [revision_by_asset.get(i['asset'], i) for i in base_items]
    items += [i for i in revisions if i['asset'] not in base_assets]
    def original_path(item):
        return EXPANSION / item.get('sourceFile', 'originals/' + item['asset'] + '.png')
    missing = [i['asset'] for i in items if not original_path(i).is_file()]
    if missing and not args.partial:
        raise SystemExit('Missing originals: ' + ', '.join(missing))
    available = []
    for item in items:
        source = original_path(item)
        if not source.is_file():
            continue
        folder = 'Animals' if item['group'] == 'animals' else 'Household'
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
            destination = ROOT / 'ToddlerLock/Resources/Pictures' / folder / (item['asset'] + '.png')
            sprite.save(destination, optimize=True)
        item['sourceFile'] = str(source.relative_to(EXPANSION))
        item['sourceSha256'] = hashlib.sha256(source.read_bytes()).hexdigest()
        if item.get('originalFile'):
            item['originalSha256'] = hashlib.sha256((EXPANSION / item['originalFile']).read_bytes()).hexdigest()
        item['file'] = str(destination.relative_to(ROOT / 'ToddlerLock'))
        item['sha256'] = hashlib.sha256(destination.read_bytes()).hexdigest()
        available.append(item)

    font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 17)
    for category in ['animals', 'household']:
        selected = [i for i in available if i['asset'] in base_assets
                    and (i['group'] == 'animals') == (category == 'animals')]
        for page_number, offset in enumerate(range(0, len(selected), 20), 1):
            page_items = selected[offset:offset + 20]
            page = Image.new('RGB', (1200, 245 * ((len(page_items) + 4) // 5)), '#faf2e0')
            draw = ImageDraw.Draw(page)
            for index, item in enumerate(page_items):
                x, y = index % 5 * 240, index // 5 * 245
                with Image.open(ROOT / 'ToddlerLock' / item['file']) as image:
                    image = image.resize((210, 210), Image.Resampling.LANCZOS)
                    page.paste(image, (x + 15, y + 1), image)
                draw.text((x + 120, y + 224), item['name'], font=font, fill='#443b32', anchor='mm')
            page.save(EXPANSION / f'{category}-preview-{page_number}.jpg', quality=93)
    refined = [i for i in available if i['asset'] in revision_by_asset]
    if refined:
        page = Image.new('RGB', (1200, 265 * ((len(refined) + 1) // 2)), '#faf2e0')
        draw = ImageDraw.Draw(page)
        for index, item in enumerate(refined):
            x, y = index % 2 * 600, index // 2 * 265
            for column, path in enumerate([EXPANSION / item['originalFile'], ROOT / 'ToddlerLock' / item['file']]):
                with Image.open(path) as image:
                    image = image.convert('RGBA')
                    bbox = image.getchannel('A').point(lambda a: 255 if a >= 16 else 0).getbbox()
                    image = image.crop(bbox)
                    image.thumbnail((260, 210), Image.Resampling.LANCZOS)
                    page.paste(image, (x + column * 300 + (300 - image.width) // 2,
                                      y + 10 + (210 - image.height) // 2), image)
                label = 'было' if column == 0 else 'стало'
                draw.text((x + column * 300 + 150, y + 240), item['name'] + ' · ' + label,
                          font=font, fill='#443b32', anchor='mm')
        page.save(EXPANSION / 'animal-revisions-before-after.jpg', quality=93)
    (EXPANSION / 'generation.json').write_text(json.dumps(
        {'generator': 'built-in image_gen', 'newCardCount': 80,
         'revisedExistingCardCount': len([i for i in revisions if i['asset'] not in base_assets]),
         'items': available}, ensure_ascii=False, indent=2) + '\n')
    print(f'Imported {len(available)}/{len(items)} illustrations; {len(refined)} refined; rendered review pages')


if __name__ == '__main__':
    main()
