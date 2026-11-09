#!/usr/bin/env python3
"""Generate the shell's event sounds (original, synthesized). Run: python3 make.py
Drop your own <name>.ogg/.wav into ~/.local/share/dap-shell/sounds/ to override any of them."""
import math, os, struct, wave

RATE = 44100
HERE = os.path.dirname(os.path.abspath(__file__))


def tone(f0, f1, ms, amp=0.35, attack=6, release=60, harmonics=(1.0,)):
    """Sine sweep from f0 to f1 Hz with a short attack and an exponential tail."""
    n = int(RATE * ms / 1000)
    out, phase = [], 0.0
    for i in range(n):
        t = i / n
        phase += 2 * math.pi * (f0 + (f1 - f0) * t) / RATE
        s = sum(h * math.sin(phase * (k + 1)) for k, h in enumerate(harmonics)) / sum(harmonics)
        env = min(1.0, i / (RATE * attack / 1000)) * math.exp(-t * release / 20)
        out.append(s * env * amp)
    return out


def silence(ms):
    return [0.0] * int(RATE * ms / 1000)


def mix(*parts):
    n = max(len(p) for p in parts)
    return [sum(p[i] for p in parts if i < len(p)) for i in range(n)]


def write(name, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    gain = min(1.0, 0.9 / peak)
    with wave.open(os.path.join(HERE, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * gain * 32767)) for s in samples))


GN = (1.0, 0.35, 0.15)  # a little upper harmonic content, like a drive hum

# Link up: two rising chirps. Link down: one long fall.
write("link-up", tone(620, 940, 90, harmonics=GN) + silence(25) + tone(940, 1400, 120, harmonics=GN))
write("link-down", tone(1100, 420, 260, release=30, harmonics=GN))
# Drive docked: low thump, then a rising shimmer. Released: the reverse.
write("dock", mix(tone(95, 60, 140, amp=0.6, release=90), silence(60) + tone(700, 1500, 180, amp=0.25, harmonics=GN)))
write("release", mix(tone(1500, 700, 160, amp=0.25, harmonics=GN), silence(90) + tone(80, 55, 120, amp=0.5, release=90)))
# Charger in: GN drive spin-up. Out: spin-down.
write("charge", tone(110, 330, 520, amp=0.4, attack=40, release=12, harmonics=(1.0, 0.5, 0.3, 0.15)))
write("discharge", tone(330, 110, 380, amp=0.35, attack=10, release=18, harmonics=(1.0, 0.5, 0.3, 0.15)))
# Volume tick: very short and quiet, it can fire many times a second.
write("tick", tone(1800, 1800, 18, amp=0.12, attack=1, release=200))
