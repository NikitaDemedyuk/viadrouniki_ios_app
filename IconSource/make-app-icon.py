#!/usr/bin/env python3
"""Regenerate the three AppIcon appearance PNGs from viadrouniki_icon.svg.

The source art is a white rounded rect behind a black glyph. iOS applies its own
squircle mask and appearance treatment, so the rect is dropped here and each
appearance gets its own background. The glyph is scaled to 75% about the canvas
centre: at 100% it spans 82% of the canvas height and reads as cramped inside
the mask. Tinted is greyscale — iOS maps its luminance into the user's tint.

Requires Pillow and macOS's qlmanage:

    pip3 install pillow

qlmanage is the SVG rasteriser here because it ships with macOS and this repo has no
other build tooling. It only renders a square canvas faithfully — it crops rather than
fits anything else — which is why every variant below is emitted at 1024x1024.

Usage:  python3 IconSource/make-app-icon.py

Every path is resolved relative to this file, not the working directory, so it runs
correctly from anywhere in the repo.
"""
import re, subprocess, tempfile
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
DEST = ROOT / "viadrouniki_ios_app/Assets.xcassets/AppIcon.appiconset"
GLYPH_CENTRE = (4996.5, 5004.0)          # measured from the path's bounding box
SCALE = 0.75
VARIANTS = {                              # name: (background, glyph)
    "light":  ("#FFFFFF", "#000000"),
    "dark":   ("#1C1C1E", "#FFFFFF"),
    "tinted": ("#000000", "#FFFFFF"),
}

d = re.search(r'\sd="([^"]+)"', (ROOT / "IconSource/viadrouniki_icon.svg").read_text()).group(1)
cx, cy = GLYPH_CENTRE

with tempfile.TemporaryDirectory() as tmp:
    tmp = Path(tmp)
    for name, (bg, fg) in VARIANTS.items():
        (tmp / f"{name}.svg").write_text(
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10000 10000" width="1024" height="1024">'
            f'<rect width="10000" height="10000" fill="{bg}"/>'
            f'<g transform="translate(5000 5000) scale({SCALE}) translate({-cx} {-cy})">'
            f'<path fill="{fg}" fill-rule="nonzero" d="{d}"/></g></svg>')
        subprocess.run(["qlmanage", "-t", "-s", "1024", "-o", str(tmp), str(tmp / f"{name}.svg")],
                       check=True, capture_output=True)

        im = Image.open(tmp / f"{name}.svg.png")
        if im.size != (1024, 1024):
            im = im.resize((1024, 1024), Image.LANCZOS)
        if im.mode in ("RGBA", "LA", "P"):
            im = im.convert("RGBA")
            flat = Image.new("RGB", im.size, tuple(int(bg[i:i+2], 16) for i in (1, 3, 5)))
            flat.paste(im, mask=im.split()[-1])   # App Store rejects alpha in the app icon
            im = flat
        im.convert("RGB").save(DEST / f"AppIcon-{name}.png", "PNG", optimize=True)
        print(f"AppIcon-{name}.png")
