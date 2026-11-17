#!/usr/bin/env python3
"""A pair of captures of the same view, Enemy Within's and the port's, put side by side with hints of where they differ.

    ~/.cache/lwx2-compare/bin/python tools/compare/pair.py logs/compare/ew/base.png logs/compare/x2/base.png logs/compare/pairs/base

writes <out>.png (EW left, the port right, a grid of the most different cells drawn on both) and <out>.txt (the cells
ranked, each with what differs: brightness, colour, detail, structure). Two games never match pixel for pixel, so
the cells are compared by their statistics, not their pixels: a cell grey and flat in the port where EW's is coloured
and detailed, or lit where EW's is black, ranks high. Captures of other sizes are scaled to 1600 x 900.
Needs numpy, Pillow and scikit-image (the venv ~/.cache/lwx2-compare).
"""
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from skimage.color import rgb2gray, rgb2hsv
from skimage.filters import sobel
from skimage.metrics import structural_similarity

W, H = 1600, 900
COLS, ROWS = 16, 9  # 100 px cells
TOP = 12


def load(path):
    im = Image.open(path).convert('RGB')
    if im.size != (W, H):
        im = im.resize((W, H), Image.LANCZOS)
    return im


def stats(a):
    """Per cell: brightness, saturation, edge density, mean colour."""
    g = rgb2gray(a)
    hsv = rgb2hsv(a)
    e = sobel(g)
    out = {}
    for r in range(ROWS):
        for c in range(COLS):
            sl = (slice(r * 100, (r + 1) * 100), slice(c * 100, (c + 1) * 100))
            out[(r, c)] = dict(
                lum=float(g[sl].mean()),
                sat=float((hsv[sl][..., 1] * hsv[sl][..., 2]).mean()),
                edge=float(e[sl].mean()),
                rgb=a[sl].reshape(-1, 3).mean(0),
            )
    return out, g


def describe(e, p):
    """What differs in one cell, in words, strongest first."""
    parts = []
    dl = p['lum'] - e['lum']
    if abs(dl) > 0.06:
        parts.append((abs(dl), f"{'brighter' if dl > 0 else 'darker'} in the port ({e['lum']:.2f} -> {p['lum']:.2f})"))
    ds = p['sat'] - e['sat']
    if abs(ds) > 0.04:
        parts.append((abs(ds) * 1.5, f"{'more' if ds > 0 else 'less'} colour in the port ({e['sat']:.2f} -> {p['sat']:.2f})"))
    de = p['edge'] - e['edge']
    if abs(de) > 0.012:
        parts.append((abs(de) * 6, f"{'more' if de > 0 else 'less'} detail in the port ({e['edge']:.3f} -> {p['edge']:.3f})"))
    hue = np.abs(p['rgb'] - e['rgb']).max() / 255
    if hue > 0.12:
        er, eg, eb = (int(x) for x in e['rgb'])
        pr, pg, pb = (int(x) for x in p['rgb'])
        parts.append((hue * 0.5, f"mean colour #{er:02x}{eg:02x}{eb:02x} -> #{pr:02x}{pg:02x}{pb:02x}"))
    parts.sort(reverse=True)
    return [t for _, t in parts]


def where(r, c):
    v = ['top', 'upper', 'middle', 'lower', 'bottom'][min(4, r * 5 // ROWS)]
    h = ['left', 'left-centre', 'centre', 'right-centre', 'right'][min(4, c * 5 // COLS)]
    return f"{v} {h}"


def main(ew_path, x2_path, out):
    ew, x2 = load(ew_path), load(x2_path)
    a, b = np.asarray(ew) / 255.0, np.asarray(x2) / 255.0
    se, ge = stats(a)
    sp, gp = stats(b)
    _, ssim = structural_similarity(ge, gp, data_range=1.0, full=True)
    cells = []
    for k in se:
        r, c = k
        sl = (slice(r * 100, (r + 1) * 100), slice(c * 100, (c + 1) * 100))
        s = float(ssim[sl].mean())
        e, p = se[k], sp[k]
        score = (abs(p['lum'] - e['lum']) + 1.5 * abs(p['sat'] - e['sat']) + 6 * abs(p['edge'] - e['edge'])
                 + 0.5 * float(np.abs(p['rgb'] - e['rgb']).max() / 255) + 0.5 * (1 - s))
        cells.append((score, r, c, s, describe(e, p)))
    cells.sort(reverse=True)
    top = cells[:TOP]

    # Whole-image summary.
    lines = [f"view: {out.rsplit('/', 1)[-1]}", f"EW: {ew_path}", f"port: {x2_path}",
             f"whole image: brightness EW {ge.mean():.2f} port {gp.mean():.2f}; colour EW "
             f"{np.mean([v['sat'] for v in se.values()]):.2f} port {np.mean([v['sat'] for v in sp.values()]):.2f}; "
             f"detail EW {np.mean([v['edge'] for v in se.values()]):.3f} port {np.mean([v['edge'] for v in sp.values()]):.3f}; "
             f"structural similarity {float(ssim.mean()):.2f}",
             f"cells of 100 px, {COLS} x {ROWS}, (column, row) from the top left; the {TOP} most different:"]
    for i, (score, r, c, s, words) in enumerate(top, 1):
        lines.append(f"{i:2}. cell ({c},{r}) {where(r, c)}, x {c * 100}-{c * 100 + 100} y {r * 100}-{r * 100 + 100}: "
                     f"score {score:.2f}, structure {s:.2f}; " + ('; '.join(words) or 'structure only'))
    with open(out + '.txt', 'w') as f:
        f.write('\n'.join(lines) + '\n')

    # Side by side, the top cells outlined and numbered on both.
    sheet = Image.new('RGB', (W * 2 + 16, H + 40), (20, 20, 20))
    sheet.paste(ew, (0, 40))
    sheet.paste(x2, (W + 16, 40))
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype('DejaVuSans-Bold.ttf', 22)
    except OSError:
        font = ImageFont.load_default()
    d.text((10, 8), 'ENEMY WITHIN', fill=(255, 210, 80), font=font)
    d.text((W + 26, 8), 'PORT (XCOM 2)', fill=(120, 220, 255), font=font)
    for i, (score, r, c, s, words) in enumerate(top, 1):
        for ox in (0, W + 16):
            x, y = ox + c * 100, 40 + r * 100
            d.rectangle([x, y, x + 99, y + 99], outline=(255, 60, 60), width=3)
            d.text((x + 5, y + 3), str(i), fill=(255, 60, 60), font=font)
    sheet.save(out + '.png')
    print(out + '.png', out + '.txt')


if __name__ == '__main__':
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
