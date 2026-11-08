#!/usr/bin/env python3
"""Boot reveal for the fastfetch sheet: green rain, then a decode wipe.

Reads the ANSI text on stdin and plays one short animation (about 1 s) over
the block. It is a one-shot: nothing runs after it ends, so an idle shell costs
nothing. Frames follow the clock, so a slow terminal skips frames instead of
stretching the boot. Output that is not a terminal is passed through unchanged.
"""
import os
import random
import re
import shutil
import sys
import time

FPS = 30
TOTAL = 30  # frames, 1.0 s
RAIN_CHARS = "0123456789abcdef:;<>=+*#"
NOISE_CHARS = "▓▒░#%&@$=+01"
HEAD, BODY, TAIL = "97", "38;2;57;255;20", "38;2;20;120;10"
NOISE = "38;2;0;240;255"

TOKEN = re.compile(r"\x1b\[([0-9;]*)m|\x1b\[(\d*)C|\x1b\[[0-9;?]*[A-Za-z]|\x1b\][^\x07]*\x07|(.)", re.S)


def parse(line):
    """Split one ANSI line into (style, char) cells."""
    cells, style = [], ""
    for sgr, fwd, ch in TOKEN.findall(line):
        if ch:
            cells.append((style, ch))
        elif fwd:
            cells.extend((style, " ") for _ in range(int(fwd)))
        elif sgr in ("", "0"):
            style = ""
        elif sgr:
            style += f"\x1b[{sgr}m"
    return cells


def row_text(cells):
    out, last = [], None
    for style, ch in cells:
        if style != last:
            out.append("\x1b[0m" + style)
            last = style
        out.append(ch)
    return "".join(out) + "\x1b[0m"


def build(lines, rng):
    grid = [parse(l) for l in lines]
    width = min(max((len(r) for r in grid), default=0), shutil.get_terminal_size().columns - 1)
    grid = [(r + [("", " ")] * width)[:width] for r in grid]
    height = len(grid)
    drops = []
    for _ in range(width):
        active = rng.random() < 0.75
        drops.append((rng.uniform(-height * 0.7, 0), rng.uniform(1.3, 2.3), rng.randint(5, 9), active))
    lock = [[9 + r * 0.5 + rng.uniform(0, 5) for _ in range(width)] for r in range(height)]
    return grid, width, height, drops, lock


def frame(i, grid, width, height, drops, lock, rng):
    rows = []
    for r in range(height):
        out, last = [], None
        for c in range(width):
            style, ch = grid[r][c]
            t = lock[r][c]
            if i >= t + 3:
                s, g = style, ch
            elif i >= t:
                s, g = f"\x1b[{NOISE}m", rng.choice(NOISE_CHARS)
            else:
                start, speed, trail, active = drops[c]
                d = start + speed * i - r
                if active and 0 <= d < trail:
                    col = HEAD if d < 1 else BODY if d < trail * 0.5 else TAIL
                    s, g = f"\x1b[{col}m", rng.choice(RAIN_CHARS)
                else:
                    s, g = "", " "
            if s != last:
                out.append("\x1b[0m" + s)
                last = s
            out.append(g)
        rows.append("".join(out) + "\x1b[0m")
    return rows


def main():
    lines = sys.stdin.read().split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    if not lines:
        return
    out = sys.__stdout__
    if not out.isatty() or os.environ.get("NOANIM"):
        out.write("\n".join(lines) + "\n")
        return
    rng = random.Random()
    grid, width, height, drops, lock = build(lines, rng)
    out.write("\x1b[?25l" + "\n" * height + f"\x1b[{height}A")
    try:
        start, shown = time.monotonic(), -1
        while True:
            i = int((time.monotonic() - start) * FPS)
            if i >= TOTAL:
                break
            if i != shown:
                shown = i
                out.write("\r" + "\n".join(frame(i, grid, width, height, drops, lock, rng)) + f"\n\x1b[{height}A")
                out.flush()
            time.sleep(1 / (FPS * 2))
    except (KeyboardInterrupt, BrokenPipeError):
        pass
    finally:
        out.write("\r" + "\x1b[K\n".join(lines) + "\x1b[K\n\x1b[?25h")
        out.flush()


if __name__ == "__main__":
    main()
