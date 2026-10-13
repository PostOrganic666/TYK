#!/usr/bin/env python3
"""Check catalogue, runtime names, PNGs, and Xcode resource registration."""
from pathlib import Path
import argparse
import json
import re
from collections import Counter
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'ToddlerLock'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--collection', nargs='+', choices=['animals', 'transport', 'household', 'food'],
                        help='Check selected collections; by default check the full catalogue')
    args = parser.parse_args()
    entries = json.loads((ROOT / 'catalog/pictures.json').read_text())
    runtime = re.findall(r'\.init\(name: "([^"]+)", assetName: "([^"]+)"\)',
                         (SOURCE / 'Modes/PictureMode.swift').read_text())
    expected = [(entry['name'], entry['asset']) for entry in entries]
    assert Counter(runtime) == Counter(expected), 'Runtime and catalogue differ'
    assert len({entry['asset'] for entry in entries}) == len(entries), 'Duplicate assets'
    assert len({entry['name'] for entry in entries}) == len(entries), 'Duplicate names'
    prefixes = {'animals': 'animal-', 'transport': 'transport-', 'household': 'home-', 'food': 'food-'}
    selected = tuple(prefixes[key] for key in args.collection) if args.collection else tuple(prefixes.values())
    entries = [entry for entry in entries if entry['asset'].startswith(selected)]
    files = {path.stem: path for path in (SOURCE / 'Resources/Pictures').rglob('*.png')}
    files = {asset: path for asset, path in files.items() if asset.startswith(selected)}
    assert set(files) == {entry['asset'] for entry in entries}, 'Missing or orphan PNGs'
    project = (ROOT / 'ToddlerLock.xcodeproj/project.pbxproj').read_text()
    for entry in entries:
        path = files[entry['asset']]
        assert str(path.relative_to(SOURCE)) in project, f'Not registered: {path}'
        with Image.open(path) as img:
            assert img.mode == 'RGBA' and img.size == (512, 512), f'Invalid format: {path}'
            alpha = img.getchannel('A')
            minimum, maximum = alpha.getextrema()
            assert minimum == 0 and maximum >= 240, f'Invalid alpha: {path}'
            bbox = alpha.point(lambda value: 255 if value >= 16 else 0).getbbox()
            assert bbox and min(bbox[:2]) >= 30 and max(bbox[2:]) <= 482, f'Clipped: {path}'
    counts = Counter(entry['group'] for entry in entries)
    expected_counts = {'animals': 140, 'transport': 50, 'Кухня': 40,
                       'Ванная': 29, 'Прихожая': 27, 'Комната': 34, 'food': 50}
    group_collection = {'Кухня': 'household', 'Ванная': 'household',
                        'Прихожая': 'household', 'Комната': 'household'}
    if args.collection:
        expected_counts = {group: count for group, count in expected_counts.items()
                           if group_collection.get(group, group) in args.collection}
    assert counts == expected_counts, counts
    print(f'OK: {len(entries)} unique named transparent PNGs, runtime and Xcode resources agree')
    print(dict(counts))


if __name__ == '__main__':
    main()
