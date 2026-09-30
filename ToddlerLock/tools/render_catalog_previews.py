#!/usr/bin/env python3
"""Render labelled contact sheets for reviewing the added pictures."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
entries = json.loads((ROOT / 'catalog/pictures.json').read_text())
font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 18)
for category, prefix, folder in [('animals', 'animal-', 'Animals'),
                                 ('transport', 'transport-', 'Transport'),
                                 ('home', 'home-', 'Household')]:
    items = [entry for entry in entries
             if entry['status'] == 'added' and entry['asset'].startswith(prefix)]
    width, height = 240, 245
    page = Image.new('RGB', (5 * width, ((len(items) + 4) // 5) * height), '#faf2e0')
    draw = ImageDraw.Draw(page)
    for index, entry in enumerate(items):
        x, y = index % 5 * width, index // 5 * height
        with Image.open(ROOT / 'ToddlerLock/Resources/Pictures' / folder / (entry['asset'] + '.png')) as img:
            thumb = img.resize((210, 210), Image.Resampling.LANCZOS)
            page.paste(thumb, (x + 15, y + 1), thumb)
        draw.text((x + width / 2, y + 224), entry['name'], font=font, fill='#443b32', anchor='mm')
    page.save(ROOT / 'catalog' / (category + '-added.jpg'), quality=92)
    print(category, len(items))
