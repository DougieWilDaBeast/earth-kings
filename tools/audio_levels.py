#!/usr/bin/env python3
"""How loud, how long and how bright each sound is, so the fight's sounds and the
in-house music can be weighed against each other and against Ewan's tracks.

    python3 tools/audio_levels.py                 # every .wav in audio/sfx/ and audio/music/
    python3 tools/audio_levels.py audio/sfx/hit.wav

For each file: its length, its peak and RMS level in dBFS (0 is the loudest a
16-bit sample can be), and how much of its energy is over 200 Hz. A phone's or
a laptop's speaker plays little under that, so a fight sound with most of its
energy below it is felt on headphones and lost on a phone. The make_* tools
print the same line for each file they write.

Standard library only. Reads 16-bit PCM WAV, mono or stereo (stereo is averaged).
"""

import math
import struct
import sys
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TAU = 2.0 * math.pi


def levels(path):
    """{seconds, peak_db, rms_db, above_200} for a 16-bit WAV; above_200 is the share
    of its energy over 200 Hz (a phone's or a laptop's speaker plays little under that)."""
    with wave.open(str(path), "rb") as f:
        channels = f.getnchannels()
        rate = f.getframerate()
        width = f.getsampwidth()
        frames = f.getnframes()
        raw = f.readframes(frames)
    seconds = frames / float(rate)
    if width != 2 or frames == 0:
        return {"seconds": seconds, "peak_db": float("nan"), "rms_db": float("nan"), "above_200": float("nan")}
    data = struct.unpack("<%dh" % (len(raw) // 2), raw)
    rc = 1.0 / (TAU * 200.0)
    a = rc / (rc + 1.0 / rate)
    peak = 0.0
    total = 0.0
    high = 0.0
    last_x = 0.0
    last_y = 0.0
    for i in range(0, len(data) - channels + 1, channels):
        v = data[i] if channels == 1 else sum(data[i:i + channels]) / channels
        if abs(v) > peak:
            peak = abs(v)
        total += v * v
        last_y = a * (last_y + v - last_x)
        last_x = v
        high += last_y * last_y

    def db(x):
        return 20.0 * math.log10(x / 32768.0) if x > 0 else -120.0

    return {
        "seconds": seconds, "peak_db": db(peak), "rms_db": db(math.sqrt(total / frames)),
        "above_200": high / total if total > 0 else 0.0,
    }


def line(path):
    m = levels(path)
    try:
        name = Path(path).resolve().relative_to(ROOT)
    except ValueError:
        name = path
    return "%-34s %6.2f s  peak %6.1f dB  rms %6.1f dB  over 200 Hz %3.0f%%" % (
        name, m["seconds"], m["peak_db"], m["rms_db"], 100.0 * m["above_200"])


def main(paths):
    if not paths:
        paths = sorted((ROOT / "audio" / "sfx").glob("*.wav")) + sorted((ROOT / "audio" / "music").glob("*.wav"))
    for path in paths:
        print(line(path))


if __name__ == "__main__":
    main(sys.argv[1:])
