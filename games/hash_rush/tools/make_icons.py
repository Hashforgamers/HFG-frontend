"""Draws the cartoon launcher icons for Hash Rush and Road Rumble (flat shapes,
thick dark outlines, rounded purple frame — the style of the Arrow Escape,
Wordly and Snakes & Ladders icons).

    python3 games/hash_rush/tools/make_icons.py        # run from the repo root

Drawn at 4x and downsampled, so edges are smooth. Needs Pillow.
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

S = 4  # supersampling
N = 512 * S
INK = (21, 16, 58)
OUT = sys.argv[1] if len(sys.argv) > 1 else "assets/mini_game_icons"
FONT = "/System/Library/Fonts/Supplemental/Arial Black.ttf"


def px(v):
    return int(round(v * S))


def font(size):
    try:
        return ImageFont.truetype(FONT, px(size))
    except OSError:
        return ImageFont.load_default()


def frame(top, bottom):
    """Rounded dark frame with a vertical-gradient panel inside. Returns (image, draw)."""
    img = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    grad = Image.new("RGBA", (N, N))
    gd = ImageDraw.Draw(grad)
    for y in range(N):
        t = y / N
        gd.line([(0, y), (N, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, N - 1, N - 1], radius=px(104), fill=INK)
    mask = Image.new("L", (N, N), 0)
    ImageDraw.Draw(mask).rounded_rectangle([px(16), px(16), N - px(16), N - px(22)], radius=px(88), fill=255)
    img.paste(grad, (0, 0), mask)
    return img, ImageDraw.Draw(img), mask


def ink_shape(d, kind, box, fill, w=9, **kw):
    """A filled shape with the house outline."""
    getattr(d, kind)([px(v) for v in box], fill=fill, outline=INK, width=px(w), **kw)


def poly(d, pts, fill, w=9):
    pts = [(px(x), px(y)) for x, y in pts]
    d.polygon(pts, fill=fill)
    d.line(pts + [pts[0], pts[1]], fill=INK, width=px(w), joint="curve")


def text(d, xy, s, size, fill, stroke=8, anchor="mm"):
    d.text((px(xy[0]), px(xy[1])), s, font=font(size), fill=fill, anchor=anchor, stroke_width=px(stroke), stroke_fill=INK)


def rays(img, mask, cx, cy, color, n=14):
    """Sunburst behind the subject."""
    layer = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for i in range(n):
        a0 = 2 * math.pi * i / n
        a1 = a0 + math.pi / n
        d.polygon([(px(cx), px(cy)), (px(cx + 700 * math.cos(a0)), px(cy + 700 * math.sin(a0))),
                   (px(cx + 700 * math.cos(a1)), px(cy + 700 * math.sin(a1)))], fill=color)
    img.paste(layer, (0, 0), Image.composite(layer.split()[3], Image.new("L", (N, N), 0), mask))


def robot(d, cx, cy, k, body, dark, visor):
    """Hash Rush unit: big round helmet, glowing visor, stubby body."""
    def b(x0, y0, x1, y1):
        return [cx + x0 * k, cy + y0 * k, cx + x1 * k, cy + y1 * k]
    w = max(5, 9 * k)
    ink_shape(d, "rounded_rectangle", b(-52, 62, -14, 112), dark, w, radius=px(12 * k))      # legs
    ink_shape(d, "rounded_rectangle", b(14, 62, 52, 112), dark, w, radius=px(12 * k))
    ink_shape(d, "rounded_rectangle", b(-96, 22, -62, 84), body, w, radius=px(16 * k))       # arms
    ink_shape(d, "rounded_rectangle", b(62, 22, 96, 84), body, w, radius=px(16 * k))
    ink_shape(d, "rounded_rectangle", b(-66, 10, 66, 92), body, w, radius=px(26 * k))        # torso
    ink_shape(d, "rounded_rectangle", b(-24, 40, 24, 62), visor, max(4, 6 * k), radius=px(8 * k))
    d.line([px(cx + 34 * k), px(cy - 96 * k), px(cx + 50 * k), px(cy - 150 * k)], fill=INK, width=px(w))  # antenna
    ink_shape(d, "ellipse", b(36, -172, 66, -142), visor, max(4, 6 * k))
    ink_shape(d, "ellipse", b(-122, -44, -84, 6), dark, w)                                   # ear pucks
    ink_shape(d, "ellipse", b(84, -44, 122, 6), dark, w)
    ink_shape(d, "ellipse", b(-104, -118, 104, 62), body, w)                                 # helmet
    d.chord([px(v) for v in b(-84, -104, 60, 30)], 190, 300, fill=tuple(min(255, c + 60) for c in body))  # shine
    ink_shape(d, "rounded_rectangle", b(-78, -40, 78, 20), visor, w, radius=px(30 * k))      # visor
    d.rounded_rectangle([px(v) for v in b(-58, -28, -8, -12)], radius=px(8 * k), fill=(255, 255, 255))


def hash_rush():
    img, d, mask = frame((70, 52, 196), (36, 26, 120))
    rays(img, mask, 256, 300, (255, 255, 255, 26))
    d = ImageDraw.Draw(img)
    # a multiplier gate behind the squad
    ink_shape(d, "rounded_rectangle", (300, 70, 470, 250), (48, 214, 122), 9, radius=px(18))
    d.rounded_rectangle([px(316), px(86), px(454), px(150)], radius=px(10), fill=(122, 240, 170))
    text(d, (385, 162), "×2", 86, (255, 255, 255))
    # the army: two small units behind, the hero in front
    robot(d, 120, 260, 0.62, (43, 123, 255), (22, 60, 160), (79, 240, 255))
    robot(d, 396, 318, 0.62, (43, 123, 255), (22, 60, 160), (79, 240, 255))
    robot(d, 248, 300, 1.12, (43, 123, 255), (22, 60, 160), (79, 240, 255))
    return img


def road_rumble():
    img, d, mask = frame((255, 176, 46), (240, 84, 40))
    rays(img, mask, 256, 250, (255, 255, 255, 40))
    d = ImageDraw.Draw(img)
    # road rushing towards the viewer
    road = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    rd = ImageDraw.Draw(road)
    rd.polygon([(px(196), px(250)), (px(316), px(250)), (px(560), px(520)), (px(-48), px(520))], fill=(58, 54, 84))
    for y0, y1, w in ((262, 284, 5), (304, 340, 8), (370, 430, 13), (462, 520, 20)):
        rd.polygon([(px(256 - w * 0.6), px(y0)), (px(256 + w * 0.6), px(y0)), (px(256 + w), px(y1)), (px(256 - w), px(y1))], fill=(255, 226, 92))
    # road edges go on the clipped layer too, so they stop at the frame
    rd.line([px(196), px(250), px(-48), px(520)], fill=INK, width=px(9))
    rd.line([px(316), px(250), px(560), px(520)], fill=INK, width=px(9))
    img.paste(road, (0, 0), Image.composite(road.split()[3], Image.new("L", (N, N), 0), mask))
    d = ImageDraw.Draw(img)
    # speed lines
    for x, y, l in ((70, 130, 70), (48, 190, 46), (400, 96, 60), (430, 170, 40)):
        d.line([px(x), px(y), px(x + l), px(y)], fill=(255, 255, 255), width=px(9))
    # bike and rider, seen from behind
    ink_shape(d, "rounded_rectangle", (226, 318, 286, 452), (30, 28, 46), 9, radius=px(26))          # rear tyre
    d.rounded_rectangle([px(244), px(338), px(268), px(432)], radius=px(10), fill=(74, 70, 100))
    poly(d, [(170, 300), (342, 300), (322, 372), (190, 372)], (226, 48, 60))                         # tail fairing
    ink_shape(d, "rounded_rectangle", (226, 318, 286, 348), (255, 214, 64), 7, radius=px(8))         # tail light
    ink_shape(d, "rounded_rectangle", (118, 232, 196, 258), (40, 36, 60), 8, radius=px(12))          # handlebars
    ink_shape(d, "rounded_rectangle", (316, 232, 394, 258), (40, 36, 60), 8, radius=px(12))
    poly(d, [(176, 200), (336, 200), (318, 322), (194, 322)], (43, 123, 255))                        # rider's back
    poly(d, [(176, 204), (212, 204), (170, 262), (132, 252)], (43, 123, 255))                        # arms
    poly(d, [(336, 204), (300, 204), (342, 262), (380, 252)], (43, 123, 255))
    text(d, (256, 262), "7", 70, (255, 255, 255), stroke=7)
    ink_shape(d, "ellipse", (188, 92, 324, 222), (255, 214, 64), 9)                                  # helmet
    d.chord([px(200), px(100), px(300), px(190)], 190, 290, fill=(255, 240, 160))
    ink_shape(d, "rounded_rectangle", (236, 96, 276, 216), (226, 48, 60), 7, radius=px(10))          # stripe
    # comic punch burst
    cx, cy = 404, 356
    pts = []
    for i in range(20):
        r = 86 if i % 2 == 0 else 54
        a = 2 * math.pi * i / 20 - 0.2
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    poly(d, pts, (255, 236, 92), 9)
    text(d, (cx, cy + 2), "POW", 44, (226, 48, 60), stroke=6)
    return img


def finish(img, name):
    # soft bottom lip so the icon reads as a raised tile, like its neighbours
    out = img.resize((512, 512), Image.LANCZOS)
    path = os.path.join(OUT, name)
    out.save(path, optimize=True)
    print(path, os.path.getsize(path) // 1024, "KB")


if __name__ == "__main__":
    finish(hash_rush(), "hash_rush.png")
    finish(road_rumble(), "road_rumble.png")
    _ = ImageFilter  # (kept available for tweaks)
