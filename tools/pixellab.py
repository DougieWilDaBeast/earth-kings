#!/usr/bin/env python3
"""Generate art through the PixelLab API, so nobody has to click through the website.

    python3 tools/pixellab.py balance
    python3 tools/pixellab.py dress sworn_blade                   the base body in the unit's outfit ([D55])
    python3 tools/pixellab.py character sworn_blade 32            -> downloads/pixellab/sworn_blade_32.zip
    python3 tools/pixellab.py animate <character_id> "a single overhead sword slash" --name attack
    python3 tools/pixellab.py portrait art/size_test/32/sworn_blade/idle/south.png --size 160

The key is read from the environment, never from a file in the repo: PIXELLAB_API_KEY, or
PIXELLAB. Every character and animation is downloaded as PixelLab's own export zip, the same
zip the website gives, so the importer (`.\\ek.ps1 sizetest import ...`, tools/size_test.gd)
puts it in place and keeps the prompt.

`character` takes its prompt from the unit's `art/units/<id>/metadata.json` unless --prompt
is given, so a unit regenerated at another size is described exactly as before ([19]).
Settings default to the ones the 64s were made with: low top-down, 8 directions, mannequin.

Standard library only.
"""

import argparse
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

API = "https://api.pixellab.ai/v2"
ROOT = Path(__file__).resolve().parent.parent
DOWNLOADS = ROOT / "downloads" / "pixellab"
## The founders' "Blank Male character" (2026-09-25): every humanoid is dressed onto it ([D55]).
BASE_CHARACTER = "2f5feedf-71de-424c-905c-e336b6d73fb9"
## Room for a sword and shield beside the base's 32 × 72; multiples of 4, no smaller than the base.
DRESS_CANVAS = {"width": 48, "height": 72}
POLL_SECONDS = 8
TIMEOUT_SECONDS = 20 * 60


def _key() -> str:
    key = os.environ.get("PIXELLAB_API_KEY") or os.environ.get("PIXELLAB")
    if not key:
        sys.exit("No PixelLab key: set PIXELLAB_API_KEY in the environment.")
    return key


def _call(method: str, path: str, body: dict | None = None, raw: bool = False):
    data = json.dumps(body).encode() if body is not None else None
    request = urllib.request.Request(API + path, data=data, method=method)
    request.add_header("Authorization", "Bearer " + _key())
    if data is not None:
        request.add_header("Content-Type", "application/json")
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                payload = response.read()
                return (response.status, payload) if raw else json.loads(payload)
        except urllib.error.HTTPError as error:
            if raw and error.code == 423:
                return 423, b""
            sys.exit("PixelLab %s %s: %s %s" % (method, path, error.code, error.read().decode()[:600]))
        except (urllib.error.URLError, ConnectionError, TimeoutError) as error:
            # A dropped connection is retried; a POST only if it never reached PixelLab.
            if attempt == 3 or (method == "POST" and not isinstance(error, urllib.error.URLError)):
                sys.exit("PixelLab %s %s: %s" % (method, path, error))
            time.sleep(2 ** (attempt + 1))


def _wait(job_id: str) -> dict:
    """Poll a background job until it finishes; return its last response."""
    started = time.time()
    while time.time() - started < TIMEOUT_SECONDS:
        job = _call("GET", "/background-jobs/" + job_id)
        if job["status"] == "completed":
            return job.get("last_response") or {}
        if job["status"] == "failed":
            sys.exit("PixelLab job failed: %s" % json.dumps(job.get("last_response"))[:600])
        time.sleep(POLL_SECONDS)
    sys.exit("PixelLab job %s still running after %d s" % (job_id, TIMEOUT_SECONDS))


def _download_zip(character_id: str, name: str, query: str = "") -> Path:
    """The character's export zip, once every animation on it has finished."""
    started = time.time()
    while time.time() - started < TIMEOUT_SECONDS:
        status, payload = _call("GET", "/characters/%s/zip%s" % (character_id, query), raw=True)
        if status == 200:
            DOWNLOADS.mkdir(parents=True, exist_ok=True)
            path = DOWNLOADS / (name + ".zip")
            path.write_bytes(payload)
            return path
        time.sleep(POLL_SECONDS)
    sys.exit("Character %s was still generating after %d s" % (character_id, TIMEOUT_SECONDS))


def _generations() -> float:
    balance = _call("GET", "/balance")
    return float((balance.get("subscription") or {}).get("generations", 0.0))


def _unit_prompt(unit: str) -> str:
    metadata = ROOT / "art" / "units" / unit / "metadata.json"
    if not metadata.exists():
        sys.exit("No %s: give the description with --prompt" % metadata.relative_to(ROOT))
    states = json.loads(metadata.read_text(encoding="utf-8"))["states"]
    # Older records keep the whole spreadsheet row, tab-separated; the prompt is its last cell.
    return states[0]["prompt"].split("\t")[-1].strip()


def _log(record: dict) -> None:
    """One line per generation in downloads/pixellab/log.jsonl: what was asked, what it cost."""
    DOWNLOADS.mkdir(parents=True, exist_ok=True)
    with open(DOWNLOADS / "log.jsonl", "a", encoding="utf-8") as log:
        log.write(json.dumps(record) + "\n")
    print(json.dumps(record, indent=1))


def character(args) -> None:
    prompt = args.prompt or _unit_prompt(args.unit)
    before = _generations()
    body = {
        "description": prompt,
        "image_size": {"width": args.size, "height": args.size},
        "view": args.view,
        "template_id": args.template,
        "mode": args.mode,
    }
    endpoint = "/create-character-with-%d-directions" % args.directions
    started = _call("POST", endpoint, body)
    _wait(started["background_job_id"])
    name = args.name or "%s_%d" % (args.unit, args.size)
    path = _download_zip(started["character_id"], name)
    _log({"kind": "character", "unit": args.unit, "size": args.size, "directions": args.directions,
          "view": args.view, "template": args.template, "mode": args.mode, "prompt": prompt,
          "character_id": started["character_id"], "zip": str(path.relative_to(ROOT)),
          "generations": before - _generations(), "date": time.strftime("%Y-%m-%d")})


def dress(args) -> None:
    """A unit as a state of the base body: same proportions, the unit's outfit."""
    outfit = args.outfit or "dress him as " + _unit_prompt(args.unit)
    before = _generations()
    started = _call("POST", "/create-character-state", {
        "character_id": args.base,
        "edit_description": outfit,
        "state_name": args.unit,
        "override_frame_size": DRESS_CANVAS,
    })
    _wait(started["background_job_id"])
    character_id = started["character_id"]
    path = _download_zip(character_id, args.unit + "_base", "?states=" + character_id)
    _log({"kind": "dress", "unit": args.unit, "base": args.base, "outfit": outfit,
          "character_id": character_id, "zip": str(path.relative_to(ROOT)),
          "generations": before - _generations(), "date": time.strftime("%Y-%m-%d")})


def animate(args) -> None:
    before = _generations()
    body = {"character_id": args.character_id, "animation_name": args.name,
            "directions": args.directions.split(",")}
    if args.template_animation:
        body["template_animation_id"] = args.template_animation
    else:
        body["action_description"] = args.action
        body["frame_count"] = args.frames
    if args.mode:
        body["mode"] = args.mode
    started = _call("POST", "/animate-character", body)
    for job_id in started.get("background_job_ids") or [started.get("background_job_id")]:
        if job_id:
            _wait(job_id)
    # Only this state: a dressed unit shares its export with the base and every other outfit.
    path = _download_zip(args.character_id, args.zip or "%s_%s" % (args.character_id[:8], args.name),
                         "?states=" + args.character_id)
    _log({"kind": "animation", "character_id": args.character_id, "name": args.name,
          "action": args.action, "template_animation": args.template_animation, "mode": args.mode,
          "frames_asked": args.frames, "directions": args.directions, "zip": str(path.relative_to(ROOT)),
          "generations": before - _generations(), "date": time.strftime("%Y-%m-%d")})


def portrait(args) -> None:
    before = _generations()
    image = base64.b64encode(Path(args.image).read_bytes()).decode()
    started = _call("POST", "/portrait-character-pro", {
        "direction": "character_to_portrait",
        "image": {"type": "base64", "base64": image},
        "view": args.view,
        "result_size": args.size,
    })
    result = _wait(started["background_job_id"])
    encoded = result["images"][0]["base64"].split(",")[-1]
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(base64.b64decode(encoded))
    _log({"kind": "portrait", "from": args.image, "size": args.size, "out": args.out,
          "generations": before - _generations(), "date": time.strftime("%Y-%m-%d")})


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)

    commands.add_parser("balance", help="generations left this month")

    c = commands.add_parser("character", help="a unit's body, every direction, as an export zip")
    c.add_argument("unit")
    c.add_argument("size", type=int)
    c.add_argument("--prompt", help="defaults to the unit's art/units/<id>/metadata.json")
    c.add_argument("--directions", type=int, choices=[4, 8], default=8)
    c.add_argument("--view", default="low top-down")
    c.add_argument("--template", default="mannequin")
    c.add_argument("--mode", choices=["standard", "pro"], default="standard")
    c.add_argument("--name", help="zip name, defaults to <unit>_<size>")

    d = commands.add_parser("dress", help="a unit dressed onto the base body, every direction")
    d.add_argument("unit")
    d.add_argument("--outfit", help='defaults to "dress him as" + the unit\'s prompt')
    d.add_argument("--base", default=BASE_CHARACTER)

    a = commands.add_parser("animate", help="an animation on a character made by `character`")
    a.add_argument("character_id")
    a.add_argument("action", nargs="?", default="", help="what the move is, in words")
    a.add_argument("--name", default="attack", help="the state it becomes: attack, walk, death ...")
    a.add_argument("--template-animation", help="a PixelLab template instead of words (1 generation a direction)")
    a.add_argument("--mode", help="v3 for words (the default), skeleton-v3 to pose a template steadily")
    a.add_argument("--frames", type=int, default=8)
    a.add_argument("--directions", default="south,east,north,west")
    a.add_argument("--zip", help="zip name")

    p = commands.add_parser("portrait", help="a bust portrait from a body sprite")
    p.add_argument("image")
    p.add_argument("--size", type=int, default=160)
    p.add_argument("--view", default="low top-down")
    p.add_argument("--out", default="art/size_test/portrait/sworn_blade.png")

    args = parser.parse_args()
    if args.command == "balance":
        print(json.dumps(_call("GET", "/balance"), indent=1))
    elif args.command == "character":
        character(args)
    elif args.command == "dress":
        dress(args)
    elif args.command == "animate":
        if not args.action and not args.template_animation:
            sys.exit("Say what the move is, or give --template-animation")
        animate(args)
    else:
        portrait(args)


if __name__ == "__main__":
    main()
