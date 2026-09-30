#!/usr/bin/env python3
"""Extract isolated sprites from a transparent imagegen sheet (default: 3x2).

The subjects are detected as connected alpha components instead of being cut at
the mathematical cell boundaries. This matters because a paw, tail, or shadow
can cross a nominal grid line even when the subjects do not overlap.
"""

from __future__ import annotations

import argparse
from array import array
from collections import deque
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


ALPHA_THRESHOLD = 16
OUTPUT_SIZE = 512
SAFE_SIZE = 440


@dataclass
class Component:
    label: int
    count: int
    left: int
    top: int
    right: int
    bottom: int
    x_sum: int
    y_sum: int

    @property
    def center(self) -> tuple[float, float]:
        return self.x_sum / self.count, self.y_sum / self.count


def connected_components(alpha: Image.Image) -> tuple[array, list[Component]]:
    width, height = alpha.size
    pixels = alpha.tobytes()
    labels = array("I", [0]) * (width * height)
    components: list[Component] = []
    next_label = 1

    for start, value in enumerate(pixels):
        if value < ALPHA_THRESHOLD or labels[start]:
            continue

        queue = deque([start])
        labels[start] = next_label
        count = x_sum = y_sum = 0
        left = right = start % width
        top = bottom = start // width

        while queue:
            index = queue.popleft()
            x = index % width
            y = index // width
            count += 1
            x_sum += x
            y_sum += y
            left = min(left, x)
            right = max(right, x)
            top = min(top, y)
            bottom = max(bottom, y)

            for neighbor in (
                index - width if y else -1,
                index + width if y + 1 < height else -1,
                index - 1 if x else -1,
                index + 1 if x + 1 < width else -1,
            ):
                if neighbor >= 0 and not labels[neighbor] and pixels[neighbor] >= ALPHA_THRESHOLD:
                    labels[neighbor] = next_label
                    queue.append(neighbor)

        components.append(
            Component(next_label, count, left, top, right + 1, bottom + 1, x_sum, y_sum)
        )
        next_label += 1

    return labels, components


def ordered_subjects(components: list[Component], columns: int = 3, rows: int = 2) -> list[Component]:
    count = columns * rows
    sizeable = [component for component in components if component.count >= 500]
    if len(sizeable) < count:
        raise SystemExit(f"Expected {count} sizeable alpha components, found {len(sizeable)}")

    subjects = sorted(sizeable, key=lambda component: component.count, reverse=True)[:count]
    subjects.sort(key=lambda component: component.center[1])
    return [subject for row in range(rows)
            for subject in sorted(subjects[row * columns:(row + 1) * columns],
                                  key=lambda component: component.center[0])]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("names", nargs="+")
    parser.add_argument("--columns", type=int, default=3)
    parser.add_argument("--rows", type=int, default=2)
    args = parser.parse_args()
    if args.columns < 1 or args.rows < 1 or len(args.names) != args.columns * args.rows:
        parser.error("Provide one name per cell and positive grid dimensions")

    sheet = Image.open(args.source).convert("RGBA")
    alpha = sheet.getchannel("A")
    labels, components = connected_components(alpha)
    subjects = ordered_subjects(components, args.columns, args.rows)
    width, _ = sheet.size
    sheet_pixels = sheet.load()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    for name, subject in zip(args.names, subjects):
        # Include tiny detached details (for example whiskers) in the same
        # generous neighborhood, while excluding every other main subject.
        center_x, center_y = subject.center
        assigned_labels = {subject.label}
        for component in components:
            if component.count >= 500 or component.count < 3:
                continue
            x, y = component.center
            if abs(x - center_x) <= 290 and abs(y - center_y) <= 260:
                closest = min(
                    subjects,
                    key=lambda candidate: (candidate.center[0] - x) ** 2 + (candidate.center[1] - y) ** 2,
                )
                if closest.label == subject.label:
                    assigned_labels.add(component.label)

        member_components = [component for component in components if component.label in assigned_labels]
        left = min(component.left for component in member_components)
        top = min(component.top for component in member_components)
        right = max(component.right for component in member_components)
        bottom = max(component.bottom for component in member_components)

        isolated = Image.new("RGBA", (right - left, bottom - top))
        isolated_pixels = isolated.load()
        for y in range(top, bottom):
            row_offset = y * width
            for x in range(left, right):
                if labels[row_offset + x] in assigned_labels:
                    isolated_pixels[x - left, y - top] = sheet_pixels[x, y]

        scale = min(1.0, SAFE_SIZE / max(isolated.size))
        if scale < 1.0:
            isolated = isolated.resize(
                (round(isolated.width * scale), round(isolated.height * scale)),
                Image.Resampling.LANCZOS,
            )

        cell = Image.new("RGBA", (OUTPUT_SIZE, OUTPUT_SIZE))
        position = ((OUTPUT_SIZE - isolated.width) // 2, (OUTPUT_SIZE - isolated.height) // 2)
        cell.alpha_composite(isolated, position)
        output = args.output_dir / f"{name}.png"
        cell.save(output, optimize=True)
        print(f"{output} ({subject.count:,} px; source bbox {right-left}x{bottom-top})")


if __name__ == "__main__":
    main()
