#!/usr/bin/env python3
"""Make the First Hour's stand-in music from nothing but arithmetic ([D185]).

    python3 tools/make_music.py                       # writes every theme into audio/music/
    python3 tools/make_music.py tower_floors crater   # only these

The creatives' meeting (C7) asked Ewan for six cues (docs/28, "Music the hour
still needs"). Until his arrive, these hold their places, made the way
tools/make_fight_sounds.py makes the fight's sounds ([D76]): additive tones, a
plucked string (Karplus-Strong), filtered noise and a small room reverb.
Nothing is sampled or borrowed, and nothing here is any part of the fan covers
([D100]). The dice are seeded, so running it again gives the same files. Which
place hears which theme lives in data/music.json; this only makes the music.

Every theme loops: a note still ringing at the end is folded back over the
start, and the noise beds are cross-faded into themselves, so the seam does
not click. All of it is in D minor and borrows the memory theme's first four
notes (A, D, C, A), the motif the brief asks the other cues to share.

  memory_theme   one piano, a short phrase that stops dead, then a held note
  world_ending   the memory phrase, slower, broken off on its fourth note
  tower_floors   slow and low: a held organ chord, a hall's footfall, the motif on a bell
  stormreach     busy: lute, hand drum, a reed tune, the motif in the bass under it
  crater         near silence: wind, a fire ticking, the phrase once, far off

Standard library only. Mono, 16-bit WAV, 22.05 kHz (16 kHz for the two quietest).
"""

import math
import random
import struct
import sys
import wave
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from audio_levels import line  # noqa: E402

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "audio" / "music"
TAU = 2.0 * math.pi


def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


# --- the bed a theme is laid in ---------------------------------------------------


class Loop:
    """A theme `seconds` long. Notes are added at a time; whatever rings past the
    end is folded back over the start, so the loop's seam is seamless."""

    def __init__(self, seconds):
        self.n = int(RATE * seconds)
        self.buf = [0.0] * self.n

    def add(self, at, track, gain=1.0):
        start = int(at * RATE)
        n = self.n
        buf = self.buf
        for i, v in enumerate(track):
            buf[(start + i) % n] += v * gain

    def bed(self, track, gain=1.0):
        """A layer exactly the loop's length (a noise bed), laid under everything."""
        for i in range(self.n):
            self.buf[i] += track[i] * gain


def envelope(n, attack, release, hold_until=None):
    """Rise over `attack` seconds, hold, then fall over the last `release` seconds."""
    a = max(1, int(attack * RATE))
    r = max(1, int(release * RATE))
    out = [1.0] * n
    for i in range(min(a, n)):
        out[i] = i / a
    for i in range(min(r, n)):
        out[n - 1 - i] *= i / r
    return out


# --- the instruments --------------------------------------------------------------


def piano(freq, seconds, vel=1.0, damp=0.06, decay=1.0):
    """A soft felt piano: slightly stretched overtones, each dying faster than the
    one under it, then the damper. `seconds` is how long the key is held."""
    ring = seconds + damp
    n = int(RATE * ring)
    held = int(RATE * seconds)
    out = [0.0] * n
    stretch = 0.0004
    for k in range(1, 8):
        f = freq * k * math.sqrt(1.0 + stretch * k * k)
        if f > RATE * 0.45:
            break
        amp = vel / (k ** 1.35) * (1.0 if k > 1 else 1.2)
        rate = (0.55 + 0.45 * k) * (freq / 440.0) ** 0.4 * decay
        w = TAU * f / RATE
        for i in range(n):
            t = i / RATE
            e = amp * math.exp(-rate * t)
            if i >= held:
                e *= math.exp(-(i - held) / (RATE * damp) * 4.0)
            out[i] += e * math.sin(w * i)
    attack = int(0.004 * RATE)
    for i in range(min(attack, n)):
        out[i] *= i / attack
    return out


def organ(freq, seconds, attack=1.5, release=2.0, vel=1.0, warmth=((1, 1.0), (2, 0.35), (3, 0.12), (4, 0.06))):
    """A held reed-organ chord tone, slow in and slow out, two voices a hair apart."""
    n = int(RATE * (seconds + release))
    env = envelope(n, attack, release)
    out = [0.0] * n
    for detune in (0.9985, 1.0015):
        for k, a in warmth:
            w = TAU * freq * k * detune / RATE
            for i in range(n):
                out[i] += vel * 0.5 * a * env[i] * math.sin(w * i)
    return out


def bell(freq, seconds, vel=1.0):
    """A bronze bell: inharmonic partials, the low ones ringing longest."""
    n = int(RATE * seconds)
    out = [0.0] * n
    for ratio, amp, rate in ((0.5, 0.45, 0.6), (1.0, 1.0, 0.9), (1.19, 0.35, 1.6), (1.5, 0.3, 1.4),
                             (2.0, 0.4, 1.9), (2.74, 0.2, 3.0), (3.76, 0.1, 4.5)):
        w = TAU * freq * ratio / RATE
        for i in range(n):
            out[i] += vel * amp * math.exp(-rate * i / RATE) * math.sin(w * i)
    for i in range(min(40, n)):
        out[i] *= i / 40.0
    return out


def pluck(freq, seconds, rng, vel=1.0, damping=0.994, bright=0.5):
    """A lute string (Karplus-Strong): a burst of noise fed round a loop."""
    period = max(2, int(RATE / freq))
    ring = [rng.uniform(-1, 1) for _ in range(period)]
    # A duller burst for a duller string.
    for _ in range(int((1.0 - bright) * 4)):
        ring = [0.5 * (ring[i] + ring[i - 1]) for i in range(period)]
    # No offset in the burst, or a hundred plucks pile up into a lean.
    mean = sum(ring) / period
    ring = [v - mean for v in ring]
    n = int(RATE * seconds)
    out = [0.0] * n
    for i in range(n):
        j = i % period
        v = ring[j]
        ring[j] = damping * 0.5 * (v + ring[(j + 1) % period])
        out[i] = v * vel
    tail = min(n, int(0.03 * RATE))
    for i in range(tail):
        out[n - 1 - i] *= i / tail
    return out


def reed(freq, seconds, vel=1.0, vibrato=0.012):
    """A wooden pipe: a sine and its odd overtones, a little breath, a slow vibrato."""
    n = int(RATE * seconds)
    env = envelope(n, 0.05, 0.12)
    out = [0.0] * n
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = freq * (1.0 + vibrato * min(1.0, t * 2.5) * math.sin(TAU * 5.2 * t))
        phase += TAU * f / RATE
        out[i] = vel * env[i] * (math.sin(phase) + 0.22 * math.sin(3 * phase) + 0.08 * math.sin(5 * phase))
    return out


def drum(low, seconds, rng, vel=1.0):
    """A hand drum: a low skin's thump (`low`) or a rim's tek (not `low`)."""
    n = int(RATE * seconds)
    out = [0.0] * n
    if low:
        phase = 0.0
        for i in range(n):
            t = i / RATE
            f = 70.0 + 70.0 * math.exp(-t * 30.0)
            phase += TAU * f / RATE
            out[i] = vel * math.exp(-t * 14.0) * (math.sin(phase) + 0.4 * math.sin(2.1 * phase))
    last = 0.0
    k = 0.25 if low else 0.8
    rate = 60.0 if low else 45.0
    for i in range(n):
        last += k * (rng.uniform(-1, 1) - last)
        out[i] += vel * (0.3 if low else 0.7) * last * math.exp(-i / RATE * rate)
    return out


def wind_bed(seconds, rng, brightness, swell_periods, gain=1.0):
    """Wind: noise through a one-pole filter whose brightness and loudness breathe
    on slow cycles that each divide the loop, cross-faded into itself."""
    n = int(RATE * seconds)
    extra = int(RATE * 1.5)
    raw = [0.0] * (n + extra)
    lo = 0.0
    lo2 = 0.0
    for i in range(n + extra):
        t = i / RATE
        swell = 0.55
        for p, a, off in swell_periods:
            swell += a * math.sin(TAU * t / p + off)
        swell = max(0.05, swell)
        k = brightness * (0.6 + 0.5 * swell)
        lo += k * (rng.uniform(-1, 1) - lo)
        lo2 += k * (lo - lo2)
        raw[i] = lo2 * swell * gain
    return cross_fade(raw, n, extra)


def cross_fade(raw, n, extra):
    out = raw[:n]
    for i in range(extra):
        x = i / extra
        out[i] = raw[n + i] * math.cos(x * math.pi / 2) + raw[i] * math.sin(x * math.pi / 2)
    return out


# --- the room ---------------------------------------------------------------------


def reverb(track, wet=0.3, size=1.0, damp=0.35):
    """A small Schroeder room: four damped combs, two all-passes. Run over the loop
    twice and the second pass kept, so the tail at the seam is the loop's own."""
    n = len(track)
    two = track + track
    combs = [int(d * size * RATE / 44100) for d in (1557, 1617, 1491, 1422)]
    feedback = min(0.86, 0.76 + 0.05 * size)
    total = [0.0] * (2 * n)
    for d in combs:
        line_ = [0.0] * d
        idx = 0
        store = 0.0
        for i in range(2 * n):
            out = line_[idx]
            store = out * (1.0 - damp) + store * damp
            line_[idx] = two[i] + store * feedback
            idx = (idx + 1) % d
            total[i] += out * 0.25
    for d in (int(556 * RATE / 44100), int(225 * RATE / 44100)):
        line_ = [0.0] * d
        idx = 0
        for i in range(2 * n):
            buffered = line_[idx]
            v = total[i]
            total[i] = -v + buffered
            line_[idx] = v + buffered * 0.5
            idx = (idx + 1) % d
    return [track[i] * (1.0 - wet) + total[n + i] * wet for i in range(n)]


def lowpass(track, k):
    """One pole: near 1.0 leaves it be, near 0.0 dulls it as if through a wall."""
    out = [0.0] * len(track)
    last = 0.0
    for i, v in enumerate(track):
        last += k * (v - last)
        out[i] = last
    return out


# --- the phrase every cue borrows from --------------------------------------------

# (beat, midi, beats held, velocity). A, D, C, A is the motif; the phrase goes on
# down to F, climbs back, and is cut off on the B flat as it reaches for the top.
PHRASE = [
    (0.0, 69, 1.0, 0.9), (1.0, 74, 1.0, 1.0), (2.0, 72, 0.5, 0.8), (2.5, 69, 0.5, 0.75),
    (3.0, 65, 1.0, 0.8), (4.0, 67, 0.75, 0.75), (4.75, 69, 1.25, 0.85), (6.0, 70, 0.3, 0.9),
]
MOTIF = [69, 74, 72, 69]


def play_phrase(loop, at, beat, notes, gain=1.0, octave=0, decay=1.0, cut=None):
    """The phrase's notes into `loop` from `at` seconds, `beat` seconds a beat. A
    note at or past `cut` beats is struck and stopped dead there."""
    for when, midi, held, vel in notes:
        if cut is not None and when > cut:
            break
        seconds = held * beat
        if cut is not None and when + held > cut:
            seconds = max(0.08, (cut - when) * beat)
            loop.add(at + when * beat, piano(hz(midi + 12 * octave), seconds, vel, damp=0.02, decay=decay), gain)
            continue
        loop.add(at + when * beat, piano(hz(midi + 12 * octave), seconds * 1.15, vel, decay=decay), gain)


# --- the themes ------------------------------------------------------------------


def memory_theme(rng):
    # One piano. The phrase over a low D, then B flat, stopped dead on "White.";
    # a breath of silence; one held D, left to ring out.
    loop = Loop(30.0)
    beat = 0.8
    play_phrase(loop, 1.0, beat, PHRASE, cut=6.15)
    loop.add(1.0, piano(hz(50), 3.0 * beat, 0.45, damp=0.3), 1.0)        # D3 under the motif
    loop.add(1.0 + 3.0 * beat, piano(hz(46), 3.0 * beat, 0.4, damp=0.02), 1.0)  # B flat 2, cut with the rest
    held = 1.0 + 6.15 * beat + 1.9
    loop.add(held, piano(hz(62), 15.0, 0.85, damp=1.5, decay=0.35), 1.0)  # the held D4
    loop.add(held, piano(hz(50), 15.0, 0.3, damp=1.5, decay=0.35), 1.0)   # its octave, barely
    loop.buf = reverb(loop.buf, wet=0.22, size=1.15)
    return loop.buf, -20.0


def world_ending(rng):
    # The same piano, slower and further off, the phrase broken off on its fourth
    # note; then only a low D and A, a long way down, and quiet.
    loop = Loop(24.0)
    beat = 1.05
    play_phrase(loop, 1.5, beat, PHRASE, cut=2.62, decay=0.8)
    loop.add(1.5, piano(hz(50), 2.6 * beat, 0.4, damp=0.02), 1.0)
    low = 1.5 + 2.62 * beat + 3.2
    loop.add(low, piano(hz(38), 11.0, 0.55, damp=2.0, decay=0.3), 1.0)
    loop.add(low + 0.35, piano(hz(45), 10.5, 0.35, damp=2.0, decay=0.3), 1.0)
    loop.buf = reverb(loop.buf, wet=0.38, size=1.35, damp=0.5)
    return loop.buf, -22.0


def tower_floors(rng):
    # Slow, lower than the road: 60 a minute, eight bars. A reed-organ chord held
    # under it (D minor, B flat, C), a soft footfall in the hall on each
    # bar, a low string on the root, and the motif on a bronze bell, twice.
    beat = 1.0
    bar = 4 * beat
    loop = Loop(8 * bar)
    chords = [(0, 4, [50, 53, 57]), (4, 2, [46, 50, 53]), (6, 2, [48, 52, 55])]
    for start, bars, notes in chords:
        for midi in notes:
            loop.add(start * bar, organ(hz(midi), bars * bar - 0.6, attack=1.6, release=1.8, vel=0.32), 1.0)
        loop.add(start * bar, organ(hz(notes[0] - 12), bars * bar - 0.6, attack=1.0, release=1.8, vel=0.45,
                                    warmth=((1, 1.0), (2, 0.5), (3, 0.2))), 1.0)
    roots = [38, 38, 38, 38, 34, 34, 36, 36]
    for i, root in enumerate(roots):
        loop.add(i * bar, drum(True, 1.2, rng, vel=0.55), 0.6)
        loop.add(i * bar + 2 * beat, pluck(hz(root + 12), 3.0, rng, vel=0.5, damping=0.998, bright=0.2), 0.7)
    # The motif, a note every two beats, then answered lower.
    for i, midi in enumerate(MOTIF):
        loop.add(i * 2 * beat + 0.5, bell(hz(midi - 12), 5.0, vel=0.5), 0.8)
    for i, midi in enumerate([69, 74, 72, 65]):
        loop.add(4 * bar + i * 2 * beat + 0.5, bell(hz(midi - 12), 5.0, vel=0.42), 0.8)
    loop.buf = reverb(loop.buf, wet=0.35, size=1.4, damp=0.45)
    return loop.buf, -20.0


def stormreach(rng):
    # The great city: busy, 120 a minute, sixteen bars. A lute picking eighths
    # through D minor, C, B flat and A minor; a hand drum and a shaker; a reed
    # tune over the second and fourth eight bars; and under it all the Tower's
    # motif, A D C A, in the bass, the whole way through.
    beat = 0.5
    bar = 4 * beat
    loop = Loop(16 * bar)
    chords = [[62, 65, 69, 74], [60, 64, 67, 72], [58, 62, 65, 70], [57, 60, 64, 69]]
    order = [0, 3, 1, 2, 3, 2, 1, 0]
    for b in range(16):
        notes = chords[(b // 2) % 4]
        t0 = b * bar
        for e in range(8):
            midi = notes[order[e]]
            vel = 0.7 if e % 2 == 0 else 0.5
            loop.add(t0 + e * beat / 2, pluck(hz(midi), 0.9, rng, vel=vel, damping=0.993, bright=0.7), 0.55)
        # Doum on the one and the and of two; tek on the off-beats.
        for e, low, vel in ((0, True, 1.0), (3, True, 0.7), (4, True, 0.85), (2, False, 0.6), (5, False, 0.5),
                            (6, False, 0.65), (7, False, 0.4 + 0.3 * (b % 2))):
            loop.add(t0 + e * beat / 2, drum(low, 0.35, rng, vel=vel), 0.5)
        for e in range(8):
            loop.add(t0 + e * beat / 2 + 0.01, drum(False, 0.06, rng, vel=0.25), 0.4)
    # The motif in the bass, a note every bar's half.
    for b in range(16):
        for half in range(2):
            midi = MOTIF[(b * 2 + half) % 4] - 24
            loop.add(b * bar + half * 2 * beat, pluck(hz(midi), 1.1, rng, vel=0.9, damping=0.997, bright=0.3), 0.8)
            loop.add(b * bar + half * 2 * beat, organ(hz(midi), 0.8, attack=0.02, release=0.2, vel=0.25,
                                                       warmth=((1, 1.0), (2, 0.3))), 1.0)
    tune = [
        (0, 74, 1), (1, 76, 0.5), (1.5, 77, 0.5), (2, 76, 1), (3, 74, 1),
        (4, 72, 1.5), (5.5, 74, 0.5), (6, 72, 1), (7, 70, 1),
        (8, 69, 1), (9, 70, 0.5), (9.5, 72, 0.5), (10, 74, 1), (11, 77, 1),
        (12, 76, 1.5), (13.5, 74, 0.5), (14, 73, 1), (15, 74, 1),
    ]
    for start_bar in (4, 12):
        for when, midi, held in tune:
            loop.add(start_bar * bar + when * beat, reed(hz(midi), held * beat * 0.95, vel=0.5), 0.6)
    loop.buf = reverb(loop.buf, wet=0.18, size=0.9)
    return loop.buf, -18.0


def crater(rng):
    # Near silence: wind over the rim, a fire ticking, a low roar of heat; and
    # once in the loop, a long way off, the memory phrase.
    seconds = 30.0
    loop = Loop(seconds)
    loop.bed(wind_bed(seconds, rng, 0.05, ((30.0, 0.3, 0.0), (10.0, 0.2, 1.3), (6.0, 0.12, 2.1))), 1.0)
    loop.bed(wind_bed(seconds, rng, 0.012, ((15.0, 0.25, 0.7), (7.5, 0.1, 0.2))), 1.6)
    # The fire: sparse ticks and the odd pop.
    t = rng.uniform(0.2, 0.5)
    while t < seconds - 0.2:
        loop.add(t, drum(False, 0.03 + rng.uniform(0, 0.03), rng, vel=rng.uniform(0.08, 0.35)), 0.5)
        t += rng.expovariate(5.0)
    far = Loop(seconds)
    play_phrase(far, 11.0, 0.85, PHRASE[:7], gain=0.22)
    far.buf = lowpass(reverb(far.buf, wet=0.6, size=1.5, damp=0.6), 0.22)
    loop.bed(far.buf, 1.0)
    return loop.buf, -28.0


# Each theme and the rate it is written at. The two quietest, with nothing much
# above 8 kHz in them, are written at 16 kHz to keep the build small.
THEMES = {
    "memory_theme": (memory_theme, 22050), "world_ending": (world_ending, 16000),
    "tower_floors": (tower_floors, 22050), "stormreach": (stormreach, 22050), "crater": (crater, 16000),
}


def write(name, track, rms_db):
    """To `rms_db` loud on average, never past -1 dB at the peak."""
    rms = math.sqrt(sum(v * v for v in track) / max(1, len(track)))
    top = max(1e-9, max(abs(v) for v in track))
    gain = (10.0 ** (rms_db / 20.0)) / max(1e-9, rms)
    gain = min(gain, (10.0 ** (-1.0 / 20.0)) / top)
    data = struct.pack("<%dh" % len(track), *(int(max(-1.0, min(1.0, v * gain)) * 32767) for v in track))
    path = OUT / ("%s.wav" % name)
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data)
    print("wrote " + line(path))


def main(names):
    global RATE
    OUT.mkdir(parents=True, exist_ok=True)
    for name in names or THEMES:
        if name not in THEMES:
            sys.exit("no theme called %r; there are: %s" % (name, " ".join(THEMES)))
        # Each theme its own dice, so remaking one never changes another.
        make, RATE = THEMES[name]
        track, rms_db = make(random.Random("earth-kings/music/%s" % name))
        write(name, track, rms_db)


if __name__ == "__main__":
    main(sys.argv[1:])
