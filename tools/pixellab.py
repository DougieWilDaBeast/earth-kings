#!/usr/bin/env python3
"""Generate art through the PixelLab API, so nobody has to click through the website.

    python3 tools/pixellab.py balance
    python3 tools/pixellab.py dress sworn_blade                   the base body in the unit's outfit ([D55], [D57])
    python3 tools/pixellab.py character ogre 96 --model v3        a big unit, on its own body ([D57])
    python3 tools/pixellab.py image art/ui/status/stun.png "three yellow stars circling" --size 32
    python3 tools/pixellab.py effect art/effects/slash "a white sword slash arc" "the arc sweeps and fades"
    python3 tools/pixellab.py unpack downloads/pixellab/sworn_blade_base.zip art/tier1/sworn_blade
    python3 tools/pixellab.py character sworn_blade 32            -> downloads/pixellab/sworn_blade_32.zip
    python3 tools/pixellab.py animate <character_id> "a single overhead sword slash" --name attack
    python3 tools/pixellab.py portrait art/size_test/32/sworn_blade/idle/south.png --size 160
    python3 tools/pixellab.py vfx DROP-ZONE/A54/fall "a sword falling out of the sky in fire" --artist pro
    python3 tools/pixellab.py object DROP-ZONE/A52/blade "a plain iron sword" --size 36 36 --directions 8
    python3 tools/pixellab.py building DROP-ZONE/A51/kit "the Tower's old grey-blue stone" \
        --walls "grey-blue stone block walls" --floor "worn grey-blue flagstones"

The key is read from the environment, never from a file in the repo: PIXELLAB_API_KEY, or
PIXELLAB. Every character and animation is downloaded as PixelLab's own export zip, the same
zip the website gives, so the importer (`.\\ek.ps1 sizetest import ...`, tools/size_test.gd)
puts it in place and keeps the prompt.

`vfx`, `object` and `building` (PixelLab's newer tools, October 2026; docs/24) keep whatever the
job gives back in the folder named, with its result.json; `--palette muted` holds a picture
to the game's colours in data/palettes.json.

`character` takes its prompt from the unit's `art/units/<id>/metadata.json` unless --prompt
is given, so a unit regenerated at another size is described exactly as before ([19]).
Settings default to the ones the 64s were made with: low top-down, 8 directions, mannequin.

Standard library only.
"""

import argparse
import base64
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
import zipfile
from pathlib import Path

API = "https://api.pixellab.ai/v2"
ROOT = Path(__file__).resolve().parent.parent
DOWNLOADS = ROOT / "downloads" / "pixellab"
## The founders' "Blank Male character" (2026-09-25): every humanoid is dressed onto it ([D55]).
BASE_CHARACTER = "2f5feedf-71de-424c-905c-e336b6d73fb9"
## Room for a sword and shield beside the base's 32 × 72; multiples of 4, no smaller than the base.
DRESS_CANVAS = {"width": 48, "height": 72}
## The look every dressed unit asks for ([D57]): the base body's proportions and friendly face,
## finished like the heroic 64s on disk. One sentence, so every unit is asked the same way.
BLEND_STYLE = ("Keep his proportions, head size and face exactly. Finish him like detailed heroic "
               "pixel art: a dark outline, three tones of shading on every surface, worn highlights "
               "on metal and leather, a muted earthy palette.")
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
    busy = 0
    attempt = 0
    while True:
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                payload = response.read()
                return (response.status, payload) if raw else json.loads(payload)
        except urllib.error.HTTPError as error:
            if raw and error.code == 423:
                return 423, b""
            if error.code == 429 and busy < 120:
                # Every job slot is taken: wait for one to free up rather than fail.
                busy += 1
                time.sleep(30)
                continue
            sys.exit("PixelLab %s %s: %s %s" % (method, path, error.code, error.read().decode()[:600]))
        except (urllib.error.URLError, ConnectionError, TimeoutError) as error:
            # A dropped connection is retried; a POST only if it never reached PixelLab.
            if attempt == 3 or (method == "POST" and not isinstance(error, urllib.error.URLError)):
                sys.exit("PixelLab %s %s: %s" % (method, path, error))
            attempt += 1
            time.sleep(2 ** attempt)


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
    record = json.loads(metadata.read_text(encoding="utf-8"))
    # Imported packs keep the prompt at the top and the states as bare names.
    first = record["states"][0]
    prompt = first["prompt"] if isinstance(first, dict) else record["prompt"]
    # Older records keep the whole spreadsheet row, tab-separated; the prompt is its last cell.
    return prompt.split("\t")[-1].strip()


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
    if args.model == "v3":
        # The newer model: a detailed south view drawn first, then turned. Any size 32-256.
        body = {"description": prompt, "image_size": {"width": args.size, "height": args.size},
                "view": args.view, "template_id": args.template, "detail": "highly detailed"}
        endpoint = "/create-character-v3"
    started = _call("POST", endpoint, body)
    _wait(started["background_job_id"])
    name = args.name or "%s_%d" % (args.unit, args.size)
    path = _download_zip(started["character_id"], name)
    _log({"kind": "character", "unit": args.unit, "size": args.size, "directions": args.directions,
          "view": args.view, "template": args.template, "mode": args.mode, "model": args.model, "prompt": prompt,
          "character_id": started["character_id"], "zip": str(path.relative_to(ROOT)),
          "generations": before - _generations(), "date": time.strftime("%Y-%m-%d")})


def dress(args) -> None:
    """A unit as a state of the base body: same proportions, the unit's outfit."""
    outfit = args.outfit or "dress him as " + _unit_prompt(args.unit)
    if args.style:
        outfit += ". " + args.style
    before = _generations()
    started = _call("POST", "/create-character-state", {
        "character_id": args.base,
        "edit_description": outfit,
        "state_name": args.unit,
        "override_frame_size": {"width": args.canvas[0], "height": args.canvas[1]},
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


def _pixen(description: str, size: int, view: str | None = None) -> bytes:
    body = {"description": description, "image_size": {"width": size, "height": size},
            "no_background": True, "outline": "single color black outline"}
    if view:
        body["view"] = view
    result = _call("POST", "/create-image-pixen", body)
    return base64.b64decode(result["image"]["base64"].split(",")[-1])


def image(args) -> None:
    """One still with a clear background: an icon, a mark, a frame."""
    before = _generations()
    out = ROOT / args.out
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(_pixen(args.description, args.size, args.view))
    _log({"kind": "image", "out": args.out, "size": args.size, "prompt": args.description,
          "generations": before - _generations(), "date": time.strftime("%Y-%m-%d")})


def effect(args) -> None:
    """A still drawn from words, then set moving: <dest>/frame_000.png, frame_001.png ..."""
    before = _generations()
    # --still starts from a picture already made (a good one picked from several tries).
    picture = Path(args.still).read_bytes() if args.still else _pixen(args.description, args.size, args.view)
    still = base64.b64encode(picture).decode()
    started = _call("POST", "/animate-with-text-v3", {
        "first_frame": {"type": "base64", "base64": still},
        "action": args.motion, "frame_count": args.frames, "no_background": True})
    result = _wait(started["background_job_id"])
    dest = ROOT / args.dest
    dest.mkdir(parents=True, exist_ok=True)
    for index, frame in enumerate(result.get("images") or []):
        (dest / ("frame_%03d.png" % index)).write_bytes(base64.b64decode(frame["base64"].split(",")[-1]))
    _log({"kind": "effect", "out": args.dest, "size": args.size, "prompt": args.description,
          "motion": args.motion, "frames": len(result.get("images") or []),
          "generations": before - _generations(), "date": time.strftime("%Y-%m-%d")})


## The game's palette for --palette: the muted, earthy colours every picture is held to ([D40]).
PALETTES = ROOT / "data" / "palettes.json"


def _fetch(url: str) -> bytes:
    """A file a job points at: a link of PixelLab's own (sent with the key) or a plain download link."""
    if url.startswith("/"):
        url = API.rsplit("/v2", 1)[0] + url
    # PixelLab's file host turns away Python's own user agent.
    request = urllib.request.Request(url, headers={"User-Agent": "earth-kings-tools"})
    if url.startswith(API.rsplit("/v2", 1)[0]):
        request.add_header("Authorization", "Bearer " + _key())
    with urllib.request.urlopen(request, timeout=300) as response:
        return response.read()


def _keep(result, dest: Path) -> list[str]:
    """Everything a finished job gave back, into [dest]: its pictures (base64 or links) and result.json."""
    dest.mkdir(parents=True, exist_ok=True)
    kept: list[str] = []

    def walk(value, name: str) -> object:
        if isinstance(value, dict):
            if isinstance(value.get("base64"), str):
                path = dest / ("%s_%03d.png" % (name, len(kept)))
                path.write_bytes(base64.b64decode(value["base64"].split(",")[-1]))
                kept.append(path.name)
                return {"saved": path.name}
            return {key: walk(inner, key) for key, inner in value.items()}
        if isinstance(value, list):
            return [walk(inner, name) for inner in value]
        if isinstance(value, str) and re.match(r"https?://\S+\.(png|gif|zip|json)(\?|$)", value):
            path = dest / Path(value.split("?")[0]).name
            path.write_bytes(_fetch(value))
            kept.append(path.name)
        return value

    record = walk(result, "image")
    (dest / "result.json").write_text(json.dumps(record, indent=1), encoding="utf-8")
    return kept


def _palette(name: str | None) -> dict | None:
    if not name:
        return None
    palettes = json.loads(PALETTES.read_text(encoding="utf-8"))
    if name not in palettes:
        sys.exit("No palette %s in %s" % (name, PALETTES.relative_to(ROOT)))
    return {"colors": palettes[name]["colors"], "name": name}


def vfx(args) -> None:
    """An animated effect from words by PixelLab's effects artist, around a sprite if given."""
    before = _generations()
    body = {"description": args.description, "artist": args.artist, "game_pack": True}
    if args.sprite:
        body["sprite"] = {"type": "base64", "base64": base64.b64encode(Path(args.sprite).read_bytes()).decode()}
        body["sprite_frames"] = args.sprite_frames
    if args.effect_id:
        body["effect_id"] = args.effect_id
    started = _call("POST", "/vfx", body)
    if "quoted_generations" in started:
        print("quoted: %s generations" % started["quoted_generations"])
    result = _wait(started["background_job_id"])
    kept = _keep(result, ROOT / args.dest)
    _log({"kind": "vfx", "out": args.dest, "artist": args.artist, "prompt": args.description,
          "effect_id": result.get("effect_id"), "files": kept,
          "generations": before - _generations(), "date": time.strftime("%Y-%m-%d")})
    print("%s: %s" % (args.dest, ", ".join(kept)))


def pro_object(args) -> None:
    """A thing (a prop, a weapon) by Pro Flash: one facing, or all eight, held to a palette if asked."""
    before = _generations()
    body = {"description": args.description, "name": Path(args.dest).name, "view": args.view,
            "n_directions": args.directions,
            "image_size": {"width": args.size[0], "height": args.size[1]}}
    palette = _palette(args.palette)
    if palette:
        body["target_palette"] = palette
    started = _call("POST", "/create-object-pro-flash", body)
    result = _wait(started["background_job_id"])
    object_id = started.get("object_id") or result.get("object_id")
    dest = ROOT / args.dest
    kept = _keep(result, dest)
    if object_id:
        # Each facing as <facing>.png, the folder take_art.py looks for (art/items/bone_sword's shape).
        made = _call("GET", "/objects/" + object_id)
        for facing, url in (made.get("rotation_urls") or {}).items():
            (dest / (facing + ".png")).write_bytes(_fetch(url))
            kept.append(facing + ".png")
    _log({"kind": "object", "out": args.dest, "size": args.size, "directions": args.directions,
          "palette": args.palette, "prompt": args.description, "object_id": object_id, "files": kept,
          "generations": before - _generations(), "date": time.strftime("%Y-%m-%d")})
    print("%s: %s" % (args.dest, ", ".join(kept)))


def building(args) -> None:
    """A construction kit by Tiles Pro: floor, walls that join, doorways, a pillar and a stair."""
    before = _generations()
    body = {"description": args.description, "tile_type": "square_topdown", "tile_size": args.size,
            "tile_view": args.view, "tile_feature": "building",
            "building_wall_description": args.walls, "building_floor_description": args.floor,
            "building_wall_tiles": args.wall_tiles}
    palette = _palette(args.palette)
    if palette:
        body["target_palette"] = palette
    started = _call("POST", "/create-tiles-pro", body)
    job = started.get("background_job_id")
    result = _wait(job) if job else {}
    tile_id = started.get("tile_id") or started.get("id")
    if tile_id:
        result = {"job": result, "tiles": _call("GET", "/tiles-pro/" + tile_id)}
    dest = ROOT / args.dest
    kept = _keep(result, dest)
    # tile_<n>.png named for the piece it is (floor, wall_N, pillar, stairs_s_low ...).
    for index, piece in enumerate((result.get("job") or {}).get("config_names") or []):
        tile = dest / ("tile_%d.png" % index)
        if tile.exists():
            tile.replace(dest / (piece + ".png"))
    _log({"kind": "building", "out": args.dest, "size": args.size, "prompt": args.description,
          "walls": args.walls, "floor": args.floor, "files": kept,
          "generations": before - _generations(), "date": time.strftime("%Y-%m-%d")})
    print("%s: %d files" % (args.dest, len(kept)))


## What PixelLab calls a template animation, as the state the game calls it.
STATE_NAMES = {"walking": "walk", "taking_a_punch": "hit", "falling_backward": "death", "attack_words": "attack"}
DIRECTIONS = ("south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west")


def unpack(args) -> None:
    """An export zip into the art layout: <dest>/idle/<facing>.png, <dest>/<state>/<facing>/frame_000.png."""
    dest = ROOT / args.dest
    placed = {}
    with zipfile.ZipFile(ROOT / args.zip) as export:
        for entry in export.namelist():
            parts = entry.split("/")
            if not entry.endswith(".png"):
                continue
            if parts[-2] == "rotations" and parts[-1][:-4] in DIRECTIONS:
                target = dest / "idle" / parts[-1]
            elif len(parts) >= 4 and parts[-4] == "animations" and parts[-2] in DIRECTIONS:
                # Facings added later come back in a folder of their own: attack-9c934341.
                name = re.sub(r"-[0-9a-f]{8}$", "", parts[-3])
                state = STATE_NAMES.get(name, name)
                target = dest / state / parts[-2] / parts[-1]
            else:
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(export.read(entry))
            state = target.relative_to(dest).parts[0]
            placed[state] = placed.get(state, 0) + 1
        manifest = json.loads(export.read("metadata.json")) if "metadata.json" in export.namelist() else {}
    # Every folder keeps how it was made ([19]): this character's lines from the log, then PixelLab's manifest.
    ids = {state["character"]["id"] for state in manifest.get("states", [])}
    log = DOWNLOADS / "log.jsonl"
    made = [json.loads(line) for line in log.read_text(encoding="utf-8").splitlines()] if log.exists() else []
    record = {
        "id": dest.name,
        "view": "low top-down",
        "generations": [entry for entry in made if entry.get("character_id") in ids],
        "pixellab": manifest,
    }
    (dest / "metadata.json").write_text(json.dumps(record, indent=1, ensure_ascii=False), encoding="utf-8")
    for state, count in sorted(placed.items()):
        print("%-8s %d images" % (state, count))


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
    c.add_argument("--model", choices=["template", "v3"], default="template",
                   help="v3 draws a detailed body at any size 32-256 (about 3 generations at 96)")

    d = commands.add_parser("dress", help="a unit dressed onto the base body, every direction")
    d.add_argument("unit")
    d.add_argument("--outfit", help='defaults to "dress him as" + the unit\'s prompt')
    d.add_argument("--base", default=BASE_CHARACTER)
    d.add_argument("--style", default=BLEND_STYLE, help='the finish asked for; --style "" for the plain base look')
    d.add_argument("--canvas", type=int, nargs=2, default=[DRESS_CANVAS["width"], DRESS_CANVAS["height"]],
                   metavar=("W", "H"), help="bigger for big units; multiples of 4")

    a = commands.add_parser("animate", help="an animation on a character made by `character`")
    a.add_argument("character_id")
    a.add_argument("action", nargs="?", default="", help="what the move is, in words")
    a.add_argument("--name", default="attack", help="the state it becomes: attack, walk, death ...")
    a.add_argument("--template-animation", help="a PixelLab template instead of words (1 generation a direction)")
    a.add_argument("--mode", help="v3 for words (the default); pixminimax, 1 generation a facing at 64 up to 8 "
                                  "frames (frames a multiple of 4); skeleton-v3 to pose a template steadily")
    a.add_argument("--frames", type=int, default=8)
    a.add_argument("--directions", default="south,east,north,west")
    a.add_argument("--zip", help="zip name")

    u = commands.add_parser("unpack", help="an export zip into art/<...>/<state>/<facing>/")
    u.add_argument("zip")
    u.add_argument("dest")

    p = commands.add_parser("portrait", help="a bust portrait from a body sprite")
    p.add_argument("image")
    p.add_argument("--size", type=int, default=160)
    p.add_argument("--view", default="low top-down")
    p.add_argument("--out", default="art/size_test/portrait/sworn_blade.png")

    i = commands.add_parser("image", help="one still with a clear background, from words")
    i.add_argument("out")
    i.add_argument("description")
    i.add_argument("--size", type=int, default=32, help="16-512, a multiple of 4")
    i.add_argument("--view", help="side, low top-down or high top-down")

    e = commands.add_parser("effect", help="an animated effect: a still from words, then set moving")
    e.add_argument("dest")
    e.add_argument("description", help="the effect's first frame")
    e.add_argument("motion", help="how it moves")
    e.add_argument("--size", type=int, default=64)
    e.add_argument("--frames", type=int, default=8, help="4-16, even")
    e.add_argument("--view")
    e.add_argument("--still", help="start from this picture instead of drawing one from the description")

    v = commands.add_parser("vfx", help="an animated effect by PixelLab's effects artist (lite 1 generation, pro 6)")
    v.add_argument("dest", help="folder for the GIF, the strip and its JSON, e.g. DROP-ZONE/A54/fall")
    v.add_argument("description")
    v.add_argument("--artist", choices=["lite", "pro"], default="lite")
    v.add_argument("--sprite", help="a PNG or GIF to make the effect around")
    v.add_argument("--sprite-frames", type=int, default=1, help="frames in the sprite's PNG strip")
    v.add_argument("--effect-id", help="change an effect made before")

    o = commands.add_parser("object", help="a thing by Pro Flash, one facing or eight (about 5 + 1 at 64)")
    o.add_argument("dest", help="folder for its facings, e.g. DROP-ZONE/A52/blade")
    o.add_argument("description")
    o.add_argument("--size", type=int, nargs=2, default=[64, 64], metavar=("W", "H"), help="16-256, steps of 4")
    o.add_argument("--directions", type=int, choices=[1, 8], default=1)
    o.add_argument("--view", default="low top-down", choices=["low top-down", "high top-down", "side"])
    o.add_argument("--palette", help="a palette in data/palettes.json, e.g. muted")

    b = commands.add_parser("building", help="a building kit by Tiles Pro: floor, walls, doorways, pillar, stair")
    b.add_argument("dest")
    b.add_argument("description")
    b.add_argument("--walls", required=True, help="the wall material")
    b.add_argument("--floor", required=True, help="the floor material")
    b.add_argument("--size", type=int, default=64, help="tile size, 16-96 for a kit")
    b.add_argument("--wall-tiles", type=int, default=2, help="wall height in tiles, 1-3")
    b.add_argument("--view", default="low top-down", choices=["top-down", "high top-down", "low top-down"])
    b.add_argument("--palette")

    args = parser.parse_args()
    if args.command == "balance":
        print(json.dumps(_call("GET", "/balance"), indent=1))
    elif args.command == "character":
        character(args)
    elif args.command == "unpack":
        unpack(args)
    elif args.command == "dress":
        dress(args)
    elif args.command == "animate":
        if not args.action and not args.template_animation:
            sys.exit("Say what the move is, or give --template-animation")
        animate(args)
    elif args.command == "image":
        image(args)
    elif args.command == "effect":
        effect(args)
    elif args.command == "vfx":
        vfx(args)
    elif args.command == "object":
        pro_object(args)
    elif args.command == "building":
        building(args)
    else:
        portrait(args)


if __name__ == "__main__":
    main()
