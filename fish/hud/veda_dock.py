#!/usr/bin/env python3
"""VEDA LOG dock: a sonar of recent shell commands, drawn in a Ghostty split.

Reads the shared log written by the fish HUD ("epoch|rc|took|command" per line) and the running
command markers in $XDG_RUNTIME_DIR/veda-active/<pid>. Redraws about 8 times a second; the sweep
turns once every 4 seconds. NOANIM=1 draws one still frame per log change instead.
Usage: veda_dock.py LOGFILE
"""
import math
import os
import shutil
import signal
import sys
import time
import zlib

LOG = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/.local/state/veda/log")
ACTIVE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "veda-active")
STILL = os.environ.get("NOANIM") == "1"
FPS = 8
TURN = 4.0  # seconds per sweep

ESC = "\x1b["
RESET = ESC + "0m"


def fg(n):
    return f"{ESC}38;5;{n}m"


DIM, MUTE, TEXT = fg(23), fg(244), fg(253)
GREEN, CYAN, RED, YELLOW, ORANGE = fg(48), fg(51), fg(204), fg(221), fg(215)

# Command categories: (label, color, first words that belong to it).
CATS = [
    ("GIT", fg(215), {"git", "gh", "lazygit"}),
    ("PKG", fg(213), {"yay", "pacman", "npm", "pnpm", "bun", "pip", "cargo", "mise", "spu", "upgrade", "update"}),
    ("EDIT", fg(117), {"nvim", "vim", "vi", "nano", "code"}),
    ("FILE", fg(80), {"ls", "ll", "la", "cd", "cp", "mv", "rm", "mkdir", "cat", "find", "fd", "rg", "grep", "tree"}),
    ("NET", fg(111), {"curl", "wget", "ssh", "ping", "nmcli", "scp", "rsync"}),
    ("SYS", fg(221), {"sudo", "systemctl", "journalctl", "hyprctl", "qs", "kill", "pkill"}),
]


def category(cmd):
    word = cmd.split()[0] if cmd.split() else ""
    for i, (_, _, words) in enumerate(CATS):
        if word in words:
            return i
    return None


def read_log():
    try:
        with open(LOG, encoding="utf-8", errors="replace") as f:
            rows = [l.rstrip("\n").split("|", 3) for l in f if l.count("|") >= 3]
    except OSError:
        return []
    out = []
    for r in rows:
        try:
            out.append((int(r[0]), int(r[1]), r[2], r[3]))
        except ValueError:
            continue
    return out


def read_active():
    found = []
    try:
        names = os.listdir(ACTIVE)
    except OSError:
        return found
    for name in names:
        if not name.isdigit() or not os.path.exists(f"/proc/{name}"):
            continue
        try:
            with open(os.path.join(ACTIVE, name), encoding="utf-8", errors="replace") as f:
                cmd = f.read().strip()
        except OSError:
            continue
        if cmd:
            found.append(cmd)
    return found


def short(text, n):
    return text if len(text) <= n else text[: max(1, n - 1)] + "…"


def radar(rows, cols, angle, blips):
    """Braille radar. Returns `rows` strings of `cols` cells with colors, plus label overlays."""
    w, h = cols * 2, rows * 4
    cx, cy = (w - 1) / 2, (h - 1) / 2
    rad = min(cx, cy * 1.0)
    dots = {}  # (x, y) -> color

    def put(x, y, color):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < w and 0 <= y < h:
            dots[(x, y)] = color

    for frac in (1.0, 0.66, 0.33):
        r = rad * frac
        steps = max(24, int(r * 3))
        for i in range(steps):
            if i % 2:
                continue
            t = 2 * math.pi * i / steps
            put(cx + r * math.cos(t), cy + r * math.sin(t), DIM)
    for i in range(int(-rad), int(rad) + 1, 3):
        put(cx + i, cy, DIM)
        put(cx, cy + i, DIM)

    # Sweep with a fading trail.
    for k, color in ((0, GREEN), (6, fg(35)), (12, fg(29)), (18, fg(23))):
        a = math.radians(angle - k)
        for i in range(1, int(rad)):
            put(cx + i * math.cos(a), cy + i * math.sin(a), color)

    labels = []
    for b in blips:
        a = math.radians(b["angle"])
        bx, by = cx + b["r"] * rad * math.cos(a), cy + b["r"] * rad * math.sin(a)
        behind = (angle - b["angle"]) % 360  # degrees since the sweep passed
        lit = b["running"] or b["failed"] or behind < 200
        color = YELLOW if b["running"] else RED if b["failed"] else (b["color"] if lit else DIM)
        for dx in (0, 1):
            for dy in (0, 1):
                put(bx + dx, by + dy, color)
        if lit:
            labels.append((int(by) // 4, int(bx) // 2 + 2, color, b["label"]))

    bits = ((0, 0, 0x01), (0, 1, 0x02), (0, 2, 0x04), (1, 0, 0x08), (1, 1, 0x10), (1, 2, 0x20), (0, 3, 0x40), (1, 3, 0x80))
    grid = []
    for row in range(rows):
        line = []
        for col in range(cols):
            mask, color = 0, DIM
            for dx, dy, bit in bits:
                c = dots.get((col * 2 + dx, row * 4 + dy))
                if c:
                    mask |= bit
                    if c != DIM:
                        color = c
            line.append((chr(0x2800 + mask) if mask else " ", color))
        grid.append(line)
    # Labels never overwrite each other: a clash moves the label one row down, else it is skipped.
    taken = set()
    for r, c, color, text in labels:
        for row in (r, r + 1, r - 1):
            cells = {(row, c + i) for i in range(len(text)) if 0 <= c + i < cols}
            if 0 <= row < rows and cells and not (cells & taken):
                taken |= cells
                for i, ch in enumerate(text):
                    if 0 <= c + i < cols:
                        grid[row][c + i] = (ch, color)
                break
    return ["".join(color + ch for ch, color in line) + RESET for line in grid]


def activity(log, width, now):
    """One row of braille dots: commands per 30 s, newest on the right."""
    buckets = [0] * width
    for ts, _, _, _ in log:
        age = (now - ts) // 30
        if 0 <= age < width:
            buckets[width - 1 - age] += 1
    levels = (0x40, 0x04, 0x02, 0x01)  # bottom dot up to top dot (left column)
    out = []
    for i, n in enumerate(buckets):
        lvl = min(3, n)
        mark = chr(0x2800 + levels[lvl])
        if i == width - 1:
            mark = chr(0x2800 + 0x47)  # the "now" head
        out.append(mark)
    return ORANGE + "".join(out) + RESET


def frame(angle, log, active, cols, lines):
    now = int(time.time())
    midnight = int(time.mktime(time.localtime(now)[:3] + (0, 0, 0, 0, 0, -1)))
    today = [e for e in log if e[0] >= midnight]
    faults = [e for e in today if e[1] not in (0, 130)]
    last = log[-1] if log else None
    high = last is not None and last[1] not in (0, 130)
    head_color = RED if high else CYAN

    w = max(30, min(cols, 100))
    out = []
    title = f"╭─ VEDA LOG "
    tail = f" ● ENGAGED {time.strftime('%H:%M:%S')} ─╮"
    out.append(f"{head_color}{title}{'─' * max(1, w - len(title) - len(tail))}{tail}{RESET}")
    threat = f"HIGH · {last[1]}" if high else "NOMINAL"
    def box(text):
        """Pads a body line to the frame width and closes it with the right edge."""
        return text + " " * max(0, w - 1 - visible_len(text)) + f"{head_color}│{RESET}"

    out.append(box(f"{MUTE}│{RESET} Threat {head_color}{threat:<14}{RESET}{MUTE}Sorties{RESET} {len(today)} today · {len(faults)} faults"))

    rows = max(5, lines - 6)
    left_w, right_w = 13, 7
    cols_radar = max(10, min(w - left_w - right_w - 2, rows * 2 + 2))
    recent = list(reversed(log[-6:]))
    blips = []
    for i, (ts, rc, took, cmd) in enumerate(recent):
        cat = category(cmd)
        blips.append({
            "angle": zlib.crc32(cmd.encode()) % 360,
            "r": 0.3 + 0.12 * i,
            "color": CATS[cat][1] if cat is not None else GREEN,
            "failed": rc not in (0, 130),
            "running": False,
            "label": short(cmd, 14),
        })
    for j, cmd in enumerate(active[:3]):
        blips.append({"angle": zlib.crc32(cmd.encode()) % 360, "r": 0.2, "color": YELLOW,
                      "failed": False, "running": True, "label": short(cmd, 14)})
    sonar = radar(rows, cols_radar, angle, blips)

    fault = next((e for e in reversed(log) if e[1] not in (0, 130)), None)
    stats = [
        (f"{MUTE}BEARING{RESET}", f"{GREEN}{int(angle) % 360:03d}°{RESET}"),
        (f"{MUTE}CONTACTS{RESET}", f"{GREEN}{len(today):02d}{RESET}"),
        (f"{MUTE}ACTIVE{RESET}", f"{YELLOW if active else GREEN}{len(active):02d}{RESET}"),
        (f"{MUTE}LOCK{RESET}", f"{ORANGE}{short(active[0] if active else (last[3] if last else '—'), 11)}{RESET}"),
        (f"{MUTE}TRACKING{RESET}", f"{RED}{short(fault[3], 11) if fault else '—'}{RESET}"),
    ]
    left = []
    for name, value in stats:
        left += [name, value, ""]
    counts = [0] * len(CATS)
    for e in today:
        c = category(e[3])
        if c is not None:
            counts[c] += 1
    right = []
    for (label, color, _), n in zip(CATS, counts):
        right += [f"{color}⠿{RESET} {(label if n else MUTE + label + RESET):<4}", ""]

    for i in range(rows):
        l = left[i] if i < len(left) else ""
        r = right[i] if i < len(right) else ""
        pad = left_w + (len(l) - visible_len(l))
        out.append(box(f"{MUTE}│{RESET} {l:<{pad}}{sonar[i]} {r}"))

    out.append(box(f"{MUTE}│{RESET} " + activity(log, max(10, w - 4), now)))
    out.append(f"{head_color}╰{'─' * (w - 2)}╯{RESET}")
    return out


def visible_len(s):
    n, i = 0, 0
    while i < len(s):
        if s[i] == "\x1b":
            j = s.find("m", i)
            i = j + 1 if j != -1 else len(s)
        else:
            n += 1
            i += 1
    return n


def main():
    def leave(*_):
        sys.stdout.write(ESC + "?25h" + RESET + "\n")
        sys.stdout.flush()
        sys.exit(0)

    signal.signal(signal.SIGINT, leave)
    signal.signal(signal.SIGTERM, leave)
    sys.stdout.write(ESC + "?25l")
    start = time.monotonic()
    log, log_mtime, last_still = [], None, None
    while True:
        try:
            mtime = os.path.getmtime(LOG)
        except OSError:
            mtime = None
        if mtime != log_mtime:
            log_mtime, log = mtime, read_log()
        active = read_active()
        size = shutil.get_terminal_size((80, 20))
        if STILL:
            key = (log_mtime, tuple(active), size)
            if key != last_still:
                last_still = key
                lines = frame(45, log, active, size.columns, size.lines)
                sys.stdout.write(ESC + "H" + ESC + "2J" + "\n".join(lines))
                sys.stdout.flush()
            time.sleep(1)
            continue
        angle = ((time.monotonic() - start) / TURN * 360) % 360
        lines = frame(angle, log, active, size.columns, size.lines)
        sys.stdout.write(ESC + "H" + "\n".join(l + ESC + "K" for l in lines) + ESC + "J")
        sys.stdout.flush()
        time.sleep(1 / FPS)


if __name__ == "__main__":
    main()
