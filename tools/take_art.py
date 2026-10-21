#!/usr/bin/env python3
"""Move finished art from DROP-ZONE/ into art/, checked against what the game expects of it.

    python3 tools/take_art.py check            every request in data/art_slots.json: dropped, in place, or still to make
    python3 tools/take_art.py check A53        one request, file by file
    python3 tools/take_art.py take A53         check each dropped file's size and move it to where the game reads it
    python3 tools/take_art.py take A53 --dry   say what would move, move nothing

The requests, the files each must hold, their sizes and where each lands are in
data/art_slots.json (docs/24, D344). `dougie` drops a request's files in DROP-ZONE/<id>/ as
PixelLab gives them: loose PNGs, or PixelLab's export zip, which is unpacked first. A file is
matched by its name; a folder of eight facings (`rotations`) is matched by the folder's name
or, for one alone, by the facings themselves. A file the wrong size is not moved and is said.

After a take, open the project in Godot (or run `godot --headless --import`) so the new
pictures are imported, and move the request's row to Done in docs/24 with the date.

Standard library only.
"""

import argparse
import json
import shutil
import struct
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SLOTS = ROOT / "data" / "art_slots.json"
DROP = ROOT / "DROP-ZONE"


def png_size(path):
    """[width, height] of a PNG, read off its header, or None for anything else."""
    with open(path, "rb") as f:
        head = f.read(24)
    if len(head) < 24 or head[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    return list(struct.unpack(">II", head[16:24]))


def wanted(request):
    """Each file a request asks for: (name to look for, where it lands, size, facings or None)."""
    out = []
    for entry in request["files"]:
        for each in entry.get("each", [None]):
            fill = (lambda text: text.replace("{each}", each)) if each else (lambda text: text)
            out.append((fill(entry["name"]), fill(entry["to"]), entry.get("size"), entry.get("rotations")))
    return out


def dropped(request_id, unpack_to):
    """Every file under DROP-ZONE/<id>/, zips unpacked into [unpack_to]: name -> path."""
    found = {"_all": []}
    folder = DROP / request_id
    if not folder.is_dir():
        return found
    for path in sorted(folder.rglob("*")):
        if path.suffix.lower() == ".zip":
            with zipfile.ZipFile(path) as z:
                target = Path(unpack_to) / path.stem
                for member in z.namelist():
                    resolved = (target / member).resolve()
                    if not str(resolved).startswith(str(target.resolve())):
                        continue
                    z.extract(member, target)
            for inner in sorted(target.rglob("*.png")):
                found.setdefault(inner.name, inner)
                found["_all"].append(inner)
        elif path.suffix.lower() == ".png":
            found.setdefault(path.name, path)
            found["_all"].append(path)
    return found


def facings_in(found, name, facings):
    """The eight facings of [name]: from a folder of that name, or loose when there is one set."""
    own = {p.stem: p for p in found["_all"] if p.parent.name == name and p.stem in facings}
    if own:
        return own
    loose = [p for p in found["_all"] if p.stem in facings]
    if len(loose) == len({p.stem for p in loose}):
        return {p.stem: p for p in loose}
    return {}


def check(request_id, request, found, take=False, dry=False):
    lines = []
    moved = 0
    missing = 0
    for name, to, size, facings in wanted(request):
        target = ROOT / to
        if facings:
            got = facings_in(found, name, facings)
            have = all((target / (f + ".png")).exists() for f in facings)
            if len(got) < len(facings):
                missing += 1
                state = "stand-in or earlier art in place" if have else "to make"
                lines.append(f"  {to}/  {state}  ({len(got)} of {len(facings)} facings dropped)")
                continue
            sources = [(got[f], target / (f + ".png")) for f in facings]
        else:
            source = found.get(name)
            if source is None:
                missing += 1
                lines.append(f"  {to}  {'stand-in or earlier art in place' if target.exists() else 'to make'}")
                continue
            sources = [(source, target)]
        wrong = [s for s, _ in sources if size and png_size(s) != size]
        if wrong:
            missing += 1
            lines.append(f"  {to}  dropped, but {wrong[0].name} is {png_size(wrong[0])}, not {size}: not moved")
            continue
        if take and not dry:
            for source, dest in sources:
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(source, dest)
        moved += 1
        lines.append(f"  {to}  dropped{', moved' if take and not dry else ''}{' (would move)' if dry else ''}")
    head = f"{request_id}  {request['what']}: {len(wanted(request)) - missing} of {len(wanted(request))} dropped"
    return head, lines, moved


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("action", choices=["check", "take"])
    parser.add_argument("request", nargs="?")
    parser.add_argument("--dry", action="store_true")
    args = parser.parse_args()
    requests = json.loads(SLOTS.read_text(encoding="utf-8"))["requests"]
    if args.request and args.request not in requests:
        sys.exit(f"no request {args.request} in {SLOTS.relative_to(ROOT)}")
    if args.action == "take" and not args.request:
        sys.exit("take one request at a time: take_art.py take A53")
    with tempfile.TemporaryDirectory() as unpacked:
        for request_id, request in requests.items():
            if args.request and request_id != args.request:
                continue
            found = dropped(request_id, unpacked)
            head, lines, moved = check(request_id, request, found, args.action == "take", args.dry)
            print(head)
            if args.request:
                print("\n".join(lines))
                print(f"  shows: {request['shows']}")
            if args.action == "take" and moved and not args.dry:
                print(f"\n{moved} moved. Import them in Godot, then move {request_id} to Done in docs/24.")


if __name__ == "__main__":
    main()
