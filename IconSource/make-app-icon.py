#!/usr/bin/env python3
"""Regenerate the AppIcon appearance PNGs and splash-logo SVGs from viadrouniki_icon.svg.

The source art is a white rounded rect behind a black glyph. iOS applies its own
squircle mask and appearance treatment, so the rect is dropped here and each
appearance gets its own background. The glyph is scaled to 75% of its natural
size about the canvas centre: at 100% it spans 82% of the canvas height and
reads as cramped inside the mask. Tinted is greyscale — iOS maps its luminance
into the user's tint.

The glyph's centre is measured by rendering it once, not hardcoded. That matters
because the documented workflow is "change the SVG and regenerate": a stale
hardcoded centre would emit an off-centre icon in all three appearances with no
error and a green build, visible only by looking at the icon.

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
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parent.parent
DEST = ROOT / "viadrouniki_ios_app/Assets.xcassets/AppIcon.appiconset"
VIEWBOX = 10000                           # the source SVG's user-unit canvas
SIZE = 1024                               # emitted PNG edge, and the App Store's icon size
PROBE_SIZE = 2048                         # oversampled so the measured centre lands sub-pixel
PROBE_SCALE = 0.5                         # headroom: measuring is a render, and a render clips
SCALE = 0.75
VARIANTS = {                              # name: (background, glyph)
    "light":  ("#FFFFFF", "#000000"),
    "dark":   ("#1C1C1E", "#FFFFFF"),
    "tinted": ("#000000", "#FFFFFF"),
}
SPLASH_DEST = ROOT / "viadrouniki_ios_app/Assets.xcassets/splashLogo.imageset"
SPLASH_CANVAS = 320                       # points; the imageset's intrinsic size
SPLASH_SCALE = 0.67                       # glyph fills ~55% of the canvas, centred
SPLASH_VARIANTS = {"light": "#000000", "dark": "#FFFFFF"}  # glyph colour only — no background


def about_centre(scale):
    """SVG transform scaling by `scale` about the canvas centre."""
    half = VIEWBOX // 2
    return f'translate({half} {half}) scale({scale}) translate({-half} {-half})'


def render(bg, body, size=SIZE):
    """Rasterise `body` over a full-bleed `bg` and return it flattened to RGB."""
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        src = tmp / "icon.svg"
        src.write_text(
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {VIEWBOX} {VIEWBOX}" '
            f'width="{size}" height="{size}">'
            f'<rect width="{VIEWBOX}" height="{VIEWBOX}" fill="{bg}"/>{body}</svg>')
        result = subprocess.run(["qlmanage", "-t", "-s", str(size), "-o", str(tmp), str(src)],
                                capture_output=True, text=True)
        out = tmp / "icon.svg.png"
        # qlmanage exits 0 even when it writes no thumbnail, so the file is the real check —
        # and its diagnostics reach the user only if we relay them ourselves.
        if not out.exists():
            raise SystemExit(f"qlmanage wrote no thumbnail (exit {result.returncode})\n"
                             f"{result.stdout}{result.stderr}".rstrip())
        im = Image.open(out)
        im.load()                         # Image.open is lazy; read before the temp dir goes
    if im.size != (size, size):
        im = im.resize((size, size), Image.LANCZOS)
    if im.mode in ("RGBA", "LA", "P"):
        im = im.convert("RGBA")
        flat = Image.new("RGB", im.size, tuple(int(bg[i:i+2], 16) for i in (1, 3, 5)))
        flat.paste(im, mask=im.split()[-1])   # App Store rejects alpha in the app icon
        im = flat
    return im.convert("RGB")


def glyph_centre(path_d):
    """Measure the glyph's centre in SVG user units by rendering it shrunk and un-shrinking."""
    probe = render("#FFFFFF",
                   f'<g transform="{about_centre(PROBE_SCALE)}">'
                   f'<path fill="#000000" fill-rule="nonzero" d="{path_d}"/></g>',
                   PROBE_SIZE)
    box = ImageOps.invert(probe.convert("L")).getbbox()
    if box is None:
        raise SystemExit("the path rendered nothing — check the d= attribute in the SVG")
    x0, y0, x1, y1 = box
    # A clipped bbox measures short and silently mis-centres the icon, so refuse to guess.
    if x0 == 0 or y0 == 0 or x1 == PROBE_SIZE or y1 == PROBE_SIZE:
        raise SystemExit(f"the glyph overflows the {VIEWBOX}-unit viewBox even at "
                         f"{PROBE_SCALE:g}x — its centre cannot be measured. Fit the path "
                         f"inside the viewBox in viadrouniki_icon.svg.")
    half = VIEWBOX / 2
    return tuple(half + ((lo + hi) / 2 * VIEWBOX / PROBE_SIZE - half) / PROBE_SCALE
                 for lo, hi in ((x0, x1), (y0, y1)))


svg = (ROOT / "IconSource/viadrouniki_icon.svg").read_text()
paths = re.findall(r'\sd="([^"]+)"', svg)
# Rendering only the first of several paths would fail silently, so make it a hard stop.
if len(paths) != 1:
    raise SystemExit(f"expected exactly one path in viadrouniki_icon.svg, found {len(paths)}")
glyph = paths[0]
cx, cy = glyph_centre(glyph)

for name, (bg, fg) in VARIANTS.items():
    im = render(bg, f'<g transform="translate({VIEWBOX // 2} {VIEWBOX // 2}) scale({SCALE}) '
                    f'translate({-cx} {-cy})">'
                    f'<path fill="{fg}" fill-rule="nonzero" d="{glyph}"/></g>')
    im.save(DEST / f"AppIcon-{name}.png", "PNG", optimize=True)
    print(f"AppIcon-{name}.png")

for name, fg in SPLASH_VARIANTS.items():
    svg_out = (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {VIEWBOX} {VIEWBOX}" '
        f'width="{SPLASH_CANVAS}" height="{SPLASH_CANVAS}">'
        f'<g transform="translate({VIEWBOX // 2} {VIEWBOX // 2}) scale({SPLASH_SCALE}) '
        f'translate({-cx} {-cy})">'
        f'<path fill="{fg}" fill-rule="nonzero" d="{glyph}"/></g></svg>'
    )
    out_path = SPLASH_DEST / f"splashLogo-{name}.svg"
    out_path.write_text(svg_out)
    print(f"splashLogo-{name}.svg")
