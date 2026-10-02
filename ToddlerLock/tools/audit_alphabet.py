#!/usr/bin/env python3
"""Audit all alphabet examples, source ordering, assets and offline recordings."""
from pathlib import Path
import json
from PIL import Image
from generate_speech import validate_alphabet

root = Path(__file__).resolve().parents[1]
validate_alphabet(root, require_resources=True)
assets = json.loads((root / 'catalog/alphabet-assets.json').read_text())
assert len(assets) == 36 and len({item['asset'] for item in assets}) == 36
files = list((root / 'ToddlerLock/Resources/Alphabet').glob('*.png'))
assert {path.stem for path in files} == {item['asset'] for item in assets}
for path in files:
    with Image.open(path) as image:
        assert image.mode == 'RGBA' and image.size == (512, 512), path
        alpha = image.getchannel('A')
        minimum, maximum = alpha.getextrema()
        assert minimum == 0 and maximum >= 240, path
        bbox = alpha.point(lambda value: 255 if value >= 16 else 0).getbbox()
        assert bbox and min(bbox[:2]) >= 30 and max(bbox[2:]) <= 482, path
index = json.loads((root / 'ToddlerLock/Resources/Speech/speech-index.json').read_text())
for card in json.loads((root / 'catalog/alphabet.json').read_text()):
    for picture in card['pictures']:
        assert picture['name'] in index, picture
print('OK: 33 letters, 99 examples, 36 new transparent images, all words have Kore recordings')
