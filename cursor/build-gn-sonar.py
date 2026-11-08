#!/usr/bin/env python3
"""Build the GN-Sonar cursor theme: a GN green dot and ring with a sonar ping, as an animated
Xcursor that replaces only the default arrow. Every other cursor is inherited from Bibata.

usage: build-gn-sonar.py <output dir>   (for example ~/.local/share/icons/GN-Sonar)
"""
import math
import os
import struct
import sys

from PIL import Image, ImageDraw

GREEN = (46, 230, 168)
DARK = (7, 11, 20)
FRAMES = 15
DELAY_MS = 80          # 15 x 80 ms = one ping every 1.2 s
SIZES = (24, 48)
SS = 4                 # supersampling for smooth edges


def frame(size, t):
    s = size * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = s / 2
    w = max(1, round(1.4 * SS * size / 24))

    def ring(r, color, alpha, width):
        d.ellipse((c - r, c - r, c + r, c + r), outline=color + (int(alpha),), width=width)

    # Sonar ping: grows from the inner ring to the edge and fades out.
    ease = 1 - (1 - t) ** 2
    r_ping = s * (0.26 + 0.22 * ease)
    ring(r_ping, GREEN, 200 * (1 - t), w)
    # Inner ring with a dark halo so it reads on light backgrounds.
    ring(s * 0.26, DARK, 150, w + 2 * SS)
    ring(s * 0.26, GREEN, 235, w)
    # Center dot (the hotspot).
    r_dot = s * 0.075
    d.ellipse((c - r_dot - SS, c - r_dot - SS, c + r_dot + SS, c + r_dot + SS), fill=DARK + (170,))
    d.ellipse((c - r_dot, c - r_dot, c + r_dot, c + r_dot), fill=GREEN + (255,))
    return img.resize((size, size), Image.LANCZOS)


def argb_premultiplied(img):
    out = bytearray()
    raw = img.tobytes()
    for i in range(0, len(raw), 4):
        r, g, b, a = raw[i:i + 4]
        out += struct.pack("<I", (a << 24) | ((r * a // 255) << 16) | ((g * a // 255) << 8) | (b * a // 255))
    return bytes(out)


def xcursor(images):
    """images: list of (nominal size, PIL image, delay ms). Returns Xcursor file bytes."""
    header, toc_entry, chunk_header = 16, 12, 36
    pos = header + toc_entry * len(images)
    toc, chunks = b"", b""
    for nominal, img, delay in images:
        w, h = img.size
        toc += struct.pack("<III", 0xFFFD0002, nominal, pos)
        chunk = struct.pack("<IIIIIIIII", chunk_header, 0xFFFD0002, nominal, 1, w, h, w // 2, h // 2, delay)
        chunk += argb_premultiplied(img)
        chunks += chunk
        pos += len(chunk)
    return b"Xcur" + struct.pack("<III", header, 0x10000, len(images)) + toc + chunks


def main():
    out = os.path.expanduser(sys.argv[1])
    cursors = os.path.join(out, "cursors")
    os.makedirs(cursors, exist_ok=True)
    images = [(size, frame(size, i / FRAMES), DELAY_MS) for size in SIZES for i in range(FRAMES)]
    with open(os.path.join(cursors, "left_ptr"), "wb") as f:
        f.write(xcursor(images))
    for alias in ("default", "arrow", "top_left_arrow", "left_arrow"):
        link = os.path.join(cursors, alias)
        if os.path.lexists(link):
            os.remove(link)
        os.symlink("left_ptr", link)
    with open(os.path.join(out, "index.theme"), "w") as f:
        f.write("[Icon Theme]\nName=GN-Sonar\nComment=GN green sonar ring; other cursors from Bibata\nInherits=Bibata-Modern-Ice\n")
    print("built", out)


if __name__ == "__main__":
    main()
