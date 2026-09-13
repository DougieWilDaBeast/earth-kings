#!/usr/bin/env python3
"""Turn the recordings in DROP-ZONE/ into voice-note transcripts.

    pip install faster-whisper
    python3 tools/transcribe_voice_notes.py --respondent doug-md

Writes one markdown file per recording into docs/worldbuilding/voice-notes/,
with the front matter the ingest loop expects (see that folder's README).

Two things this does on purpose:

* It seeds the model with the world's own proper nouns, so "the Codex" does not
  come back as "the codecs" and "delvers" does not become "delvas".
* It marks passages the model was unsure of as [unclear] instead of passing them
  off as something somebody said. The answer ledger's rule is that a quote is
  never edited, which only means anything if the quote is really what was said —
  a confident-looking transcription error is worse than a flagged one.

Needs no ffmpeg: faster-whisper decodes through PyAV. It does need to reach
huggingface.co once to fetch the model, which some networks block.
"""
import argparse
import os
import re
import sys
import time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DROP_ZONE = os.path.join(REPO, "DROP-ZONE")
OUT_DIR = os.path.join(REPO, "docs", "worldbuilding", "voice-notes")
AUDIO = (".m4a", ".mp3", ".wav", ".ogg", ".aac", ".flac")

PROMPT = (
    "This is a worldbuilding interview about Earth Kings, a tactical RPG. "
    "Terms used: the gates, gate ranks, the Tower, the Spire, the Codex, delvers, "
    "doctrine, hearths, tempers, permadeath, the Heart Empire, the Bamboo Court, "
    "the Freeholds, the Dusk, the Ooze, the Tide, the Ember Wilds, the Titans, "
    "charms, graces, the step clock, wards, keeps, libraries, villages, huts."
)

# Below these the model was guessing rather than hearing.
LOGPROB_FLOOR = -1.0
NO_SPEECH_CEILING = 0.6


def stamp(seconds):
    return "%02d:%02d" % (int(seconds) // 60, int(seconds) % 60)


def slug(name):
    """'Part 1 (b) - Land, scale and edges.m4a' -> 'part-1-b-land-scale-and-edges'."""
    base = os.path.splitext(name)[0].lower()
    base = base.replace("world charter interview", "")
    base = re.sub(r"[^a-z0-9]+", "-", base).strip("-")
    return re.sub(r"-+", "-", base)[:60]


def transcribe(model, path, respondent, recorded, model_name):
    started = time.time()
    segments, info = model.transcribe(
        path,
        language="en",
        initial_prompt=PROMPT,
        vad_filter=True,
        vad_parameters={"min_silence_duration_ms": 700},
        beam_size=5,
        condition_on_previous_text=True,
    )

    lines, unclear, words = [], 0, 0
    for seg in segments:
        text = seg.text.strip()
        if not text:
            continue
        words += len(text.split())
        shaky = seg.avg_logprob < LOGPROB_FLOOR or seg.no_speech_prob > NO_SPEECH_CEILING
        unclear += 1 if shaky else 0
        lines.append("[%s]%s %s" % (stamp(seg.start), " [unclear]" if shaky else "", text))

    name = os.path.basename(path)
    out_name = "%s-%s-%s.md" % (recorded, respondent, slug(name))
    header = (
        "---\n"
        "respondent: %s\n"
        "recorded: %s\n"
        "source: DROP-ZONE/%s\n"
        "transcribed: faster-whisper %s — machine transcription, unverified\n"
        "---\n\n"
        "# %s\n\n"
        "> Machine transcription of a %s recording, kept as spoken. Passages the model was\n"
        "> unsure of are marked `[unclear]` — check those against the audio before quoting them\n"
        "> as canon. Timestamps are offsets into the recording.\n\n"
    ) % (respondent, recorded, name, model_name, os.path.splitext(name)[0], stamp(info.duration))

    with open(os.path.join(OUT_DIR, out_name), "w") as f:
        f.write(header + "\n\n".join(lines) + "\n")

    took = max(time.time() - started, 0.001)
    print("  %-52s %5d words  %2d unclear  %.1fx realtime"
          % (out_name[:52], words, unclear, info.duration / took))
    return words


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--respondent", required=True,
                    help="id from docs/worldbuilding/respondents.md, e.g. doug-md")
    ap.add_argument("--recorded", default=time.strftime("%Y-%m-%d"),
                    help="date the note was recorded (YYYY-MM-DD)")
    ap.add_argument("--model", default="medium",
                    help="tiny | base | small | medium | large-v3 (default: medium)")
    ap.add_argument("--only", default="", help="substring filter on the filename")
    args = ap.parse_args()

    try:
        from faster_whisper import WhisperModel
    except ImportError:
        sys.exit("faster-whisper is not installed.  pip install faster-whisper")

    if not os.path.isdir(DROP_ZONE):
        sys.exit("no DROP-ZONE/ to read")
    files = sorted(f for f in os.listdir(DROP_ZONE)
                   if f.lower().endswith(AUDIO) and args.only in f)
    if not files:
        sys.exit("nothing to transcribe in DROP-ZONE/")

    os.makedirs(OUT_DIR, exist_ok=True)
    print("loading %s (first run downloads the model)..." % args.model)
    model = WhisperModel(args.model, device="cpu", compute_type="int8",
                         cpu_threads=os.cpu_count() or 4)

    total = 0
    for name in files:
        total += transcribe(model, os.path.join(DROP_ZONE, name),
                            args.respondent, args.recorded, args.model)
    print("\n  %d words from %d recording(s)" % (total, len(files)))
    print("  now run:  godot --headless --path . res://tools/question_report.tscn")


if __name__ == "__main__":
    main()
