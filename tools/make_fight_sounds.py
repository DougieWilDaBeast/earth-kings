#!/usr/bin/env python3
"""Make the fight's sounds from nothing but arithmetic ([D76]).

    python3 tools/make_fight_sounds.py            # writes every sound into audio/sfx/
    python3 tools/make_fight_sounds.py hit block  # only these

Nothing is sampled or borrowed: each sound is sine waves, filtered noise and
a plucked string (Karplus-Strong), shaped by an envelope. The dice are seeded,
so running it again gives the same files. What each sound is cued by, and how
loud, lives in data/sfx.json; this only makes the noises.

Standard library only. Mono, 16-bit, 44.1 kHz WAV.
"""

import math
import random
import struct
import sys
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "audio" / "sfx"


# --- building blocks ------------------------------------------------------------


def silence(seconds):
    return [0.0] * int(RATE * seconds)


def mix(*tracks):
    length = max(len(t) for t in tracks)
    out = [0.0] * length
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    return out


def delay(track, seconds):
    return silence(seconds) + track


def envelope(n, attack, decay_rate, hold=0.0):
    """Rise over `attack` seconds, hold, then fall away exponentially."""
    env = []
    for i in range(n):
        t = i / RATE
        if t < attack:
            env.append(t / attack if attack > 0 else 1.0)
        elif t < attack + hold:
            env.append(1.0)
        else:
            env.append(math.exp(-(t - attack - hold) * decay_rate))
    return env


def tone(seconds, freq_from, freq_to=None, attack=0.005, decay=6.0, harmonics=((1, 1.0),), vibrato=0.0):
    """A sine (with optional overtones) gliding from one pitch to another."""
    freq_to = freq_from if freq_to is None else freq_to
    n = int(RATE * seconds)
    env = envelope(n, attack, decay)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = freq_from * (freq_to / freq_from) ** (t / seconds)
        if vibrato:
            f *= 1.0 + vibrato * math.sin(2 * math.pi * 7.0 * t)
        phase += 2 * math.pi * f / RATE
        v = sum(a * math.sin(phase * h) for h, a in harmonics)
        out.append(v * env[i])
    return out


def noise(seconds, rng, attack=0.002, decay=20.0, bright_from=0.9, bright_to=0.9):
    """White noise through a one-pole filter whose brightness sweeps over time:
    near 1.0 is bright and hissing, near 0.0 dull and thumping."""
    n = int(RATE * seconds)
    env = envelope(n, attack, decay)
    out = []
    last = 0.0
    for i in range(n):
        k = bright_from + (bright_to - bright_from) * i / max(1, n - 1)
        last = last + k * (rng.uniform(-1, 1) - last)
        out.append(last * env[i])
    return out


def pluck(seconds, freq, rng, damping=0.996):
    """A plucked string (Karplus-Strong): a burst of noise fed round a loop."""
    period = max(2, int(RATE / freq))
    ring = [rng.uniform(-1, 1) for _ in range(period)]
    out = []
    for i in range(int(RATE * seconds)):
        v = ring[i % period]
        nxt = ring[(i + 1) % period]
        ring[i % period] = damping * 0.5 * (v + nxt)
        out.append(v)
    return out


def scale(track, gain):
    return [v * gain for v in track]


def write(name, track, peak=0.85, fade=0.03):
    # Every sound ends in a short fade: one cut off mid-wave clicks.
    tail = min(len(track), int(RATE * fade))
    track = list(track)
    for i in range(tail):
        track[len(track) - tail + i] *= 1.0 - (i + 1) / tail
    top = max(1e-9, max(abs(v) for v in track))
    data = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v / top * peak)) * 32767)) for v in track)
    path = OUT / ("%s.wav" % name)
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data)
    print("wrote %s (%.2f s)" % (path.relative_to(OUT.parent.parent), len(track) / RATE))


# --- the sounds -------------------------------------------------------------------


def swing(rng):
    # Air parted by a blade: noise that starts bright and dulls as it passes.
    return noise(0.2, rng, attack=0.06, decay=18.0, bright_from=0.55, bright_to=0.12)


def hit(rng):
    # A blow landing: a low thump that drops in pitch, and a short slap on top.
    body = tone(0.16, 120, 48, attack=0.002, decay=22.0, harmonics=((1, 1.0), (2, 0.3)))
    slap = scale(noise(0.05, rng, decay=70.0, bright_from=0.6, bright_to=0.3), 0.6)
    return mix(body, slap)


def crit(rng):
    # A blow that tells: the thump, heavier, with a bright crack over it.
    body = tone(0.26, 140, 40, attack=0.001, decay=14.0, harmonics=((1, 1.0), (2, 0.4), (3, 0.15)))
    crack = scale(noise(0.08, rng, decay=45.0, bright_from=0.95, bright_to=0.7), 0.9)
    return mix(body, crack)


def block(rng):
    # Steel on a shield: inharmonic partials ringing out, and the click of contact.
    ring = mix(*[
        scale(tone(0.42, f, f, attack=0.001, decay=d), a)
        for f, d, a in ((523, 9.0, 1.0), (1247, 11.0, 0.6), (2113, 14.0, 0.4), (3387, 18.0, 0.25))
    ])
    click = scale(noise(0.02, rng, decay=200.0, bright_from=1.0, bright_to=1.0), 0.8)
    return mix(ring, click)


def shoot(rng):
    # A bowstring let go: a plucked low string, and the arrow hissing off.
    string = pluck(0.35, 165, rng, damping=0.992)
    env = envelope(len(string), 0.001, 9.0)
    string = [v * e for v, e in zip(string, env)]
    hiss = scale(noise(0.18, rng, attack=0.01, decay=20.0, bright_from=0.9, bright_to=0.5), 0.35)
    return mix(string, delay(hiss, 0.02))


def charge(rng):
    # Power gathering: a shimmering tone rising, with a breath of air under it.
    rise = tone(0.7, 220, 660, attack=0.25, decay=3.0, harmonics=((1, 1.0), (2, 0.3), (3.01, 0.15)), vibrato=0.02)
    air = scale(noise(0.7, rng, attack=0.3, decay=4.0, bright_from=0.3, bright_to=0.8), 0.25)
    return mix(rise, air)


def spell(rng):
    # Power let go: a falling bright tone and a burst of sparkle.
    fall = tone(0.45, 900, 260, attack=0.002, decay=8.0, harmonics=((1, 1.0), (1.5, 0.35), (2.02, 0.2)))
    burst = scale(noise(0.3, rng, decay=12.0, bright_from=0.95, bright_to=0.4), 0.55)
    return mix(fall, burst)


def heal(rng):
    # Mending: a soft rising chime, E – G# – B, each note warming in.
    out = silence(0.0)
    for i, f in enumerate((659.25, 830.61, 987.77)):
        out = mix(out, delay(tone(0.6, f, attack=0.03, decay=5.0, harmonics=((1, 1.0), (2, 0.12))), 0.08 * i))
    return out


def stun(rng):
    # Seeing stars: a high wobbling ping, round and round.
    return tone(0.5, 1250, 1050, attack=0.003, decay=6.0, harmonics=((1, 1.0), (2.7, 0.2)), vibrato=0.06)


def drink(rng):
    # A draught going down: a few quick gulps and bubbles.
    out = silence(0.45)
    t = 0.0
    while t < 0.36:
        f = rng.uniform(260, 520)
        blip = tone(0.07, f, f * 1.6, attack=0.004, decay=40.0)
        out = mix(out, delay(blip, t))
        t += rng.uniform(0.05, 0.09)
    return out


def fall(rng):
    # One of yours goes down: a low tone sinking, and the ground taking them.
    sink = tone(0.75, 220, 98, attack=0.01, decay=4.0, harmonics=((1, 1.0), (2, 0.25)))
    thud = delay(tone(0.2, 70, 40, attack=0.002, decay=18.0), 0.22)
    return mix(sink, thud)


def death(rng):
    # A foe falls: a heavy thump and the dust after it.
    thud = tone(0.3, 90, 38, attack=0.002, decay=12.0, harmonics=((1, 1.0), (2, 0.2)))
    dust = scale(noise(0.35, rng, attack=0.01, decay=10.0, bright_from=0.25, bright_to=0.1), 0.6)
    return mix(thud, dust)


def victory(rng):
    # The field is yours: a short brass-ish call, C – E – G – C.
    brass = ((1, 1.0), (2, 0.5), (3, 0.3), (4, 0.15), (5, 0.08))
    notes = ((0.0, 523.25, 0.18), (0.14, 659.25, 0.18), (0.28, 783.99, 0.18), (0.44, 1046.5, 0.9))
    out = silence(1.4)
    for at, f, length in notes:
        out = mix(out, delay(tone(length + 0.3, f, attack=0.02, decay=3.5 if length > 0.5 else 9.0, harmonics=brass), at))
    return out


def defeat(rng):
    # The field is lost: a slow fall through a minor chord, G – E♭ – C.
    soft = ((1, 1.0), (2, 0.25), (3, 0.08))
    out = silence(1.6)
    for i, f in enumerate((392.0, 311.13, 261.63)):
        out = mix(out, delay(tone(0.9, f, f * 0.98, attack=0.05, decay=2.6, harmonics=soft), 0.32 * i))
    return out


SOUNDS = {
    "swing": swing, "hit": hit, "crit": crit, "block": block, "shoot": shoot,
    "charge": charge, "spell": spell, "heal": heal, "stun": stun, "drink": drink,
    "fall": fall, "death": death, "victory": victory, "defeat": defeat,
}


def main(names):
    OUT.mkdir(parents=True, exist_ok=True)
    for name in names or SOUNDS:
        if name not in SOUNDS:
            sys.exit("no sound called %r; there are: %s" % (name, " ".join(SOUNDS)))
        # Each sound its own dice, so remaking one never changes another.
        write(name, SOUNDS[name](random.Random("earth-kings/%s" % name)))


if __name__ == "__main__":
    main(sys.argv[1:])
