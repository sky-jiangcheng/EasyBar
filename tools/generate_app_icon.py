#!/usr/bin/env python3
"""Generate the AppIcon asset set from the slider-glass artwork.

The source is a photograph of a frosted-glass panel with two slider rails on a
white background. We crop the panel to a square and bake a macOS rounded
rectangle into the alpha channel, producing full-bleed 1024px canvases.

Geometry
--------
* crop box (left, top, right, bottom) = (158, 300, 734, 876) -> 576x576
  Measured from the panel's own edges (gradient centroid, sub-pixel accuracy).
* corner radius = 0.2257 * side -- the panel's own radius (130/576), so the mask
  lands exactly on the existing glass edge instead of clipping it. On the 1024
  master this is 231px, close to Apple's 185px/1024 grid but rounder, matching
  the macOS 26 "Tahoe" grid.
* The canvas is full-bleed (the artwork reaches all four edges), which is what
  the macOS 26/27 icon grid expects. The same baked squircle is what macOS
  12-15 renders, so one asset set serves both system generations.

Rendering notes
---------------
Every size is resampled straight from the source crop (never up from a smaller
PNG), and the mask is drawn at 4x and box-filtered down, so the 16px corners
stay clean. The dark appearance currently reuses the light artwork: the source
is a light glass panel and no separate dark master exists yet.

Usage
-----
    python3 tools/generate_app_icon.py [SOURCE_IMAGE]
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw

CROP = (158, 300, 734, 876)
RADIUS_RATIO = 0.2257
SUPERSAMPLE = 4

# filename -> pixel size, matching Contents.json exactly.
SIZES = {
    "icon_16x16.png": 16,
    "icon_16x16@2x.png": 32,
    "icon_32x32.png": 32,
    "icon_32x32@2x.png": 64,
    "icon_128x128.png": 128,
    "icon_128x128@2x.png": 256,
    "icon_256x256.png": 256,
    "icon_256x256@2x.png": 512,
    "icon_512x512.png": 512,
    "icon_512x512@2x.png": 1024,
}

ROOT = Path(__file__).resolve().parent.parent
APPSET = ROOT / "Sources/StatusBar/Resources/Assets.xcassets/AppIcon.appiconset"
DEFAULT_SOURCE = ROOT / ".uploads/52d6ce84-0837-4b8c-bd0b-c4b7ab158780_image_187667517090030.png"


def squircle_mask(size: int) -> Image.Image:
    """Anti-aliased rounded-rectangle alpha mask for a `size` x `size` icon."""
    radius = max(1, round(RADIUS_RATIO * size))
    big = size * SUPERSAMPLE
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, big - 1, big - 1), radius=radius * SUPERSAMPLE, fill=255
    )
    return mask.resize((size, size), Image.LANCZOS)


def render(source: Image.Image, size: int) -> Image.Image:
    icon = source.crop(CROP).resize((size, size), Image.LANCZOS).convert("RGBA")
    icon.putalpha(squircle_mask(size))
    return icon


def main() -> None:
    source_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_SOURCE
    if not source_path.is_file():
        raise SystemExit(f"source image not found: {source_path}")

    source = Image.open(source_path).convert("RGB")
    dark_dir = APPSET / "dark"
    dark_dir.mkdir(parents=True, exist_ok=True)

    for name, size in SIZES.items():
        icon = render(source, size)
        icon.save(APPSET / name)
        icon.save(dark_dir / name)
        print(f"  {name} ({size}px)")

    print(f"AppIcon set written to {APPSET}")


if __name__ == "__main__":
    main()
