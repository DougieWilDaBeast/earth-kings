#!/usr/bin/env python3
"""A small model's fight plans, written offline as a table (D298, docs/investigation/12).

    llama-server -m embeddinggemma-2-Q8_0.gguf --embeddings --port 8099 &
    python3 tools/plan_table.py make                     embed every situation and plan, write the table
    python3 tools/plan_table.py compare 60               party clashes with the rules brain, then with the
                                                         table driving the company's side: a results table

The fight brain (src/skirmish/skirmish_brain.gd) sees a fighter's situation in five words: how it fights
(close, ranged, mender), its health, a foe at its elbow or not, a friend under half health or not, and a
foe winding up or not. There are 72 of them, so a model never has to run in the game: `make` writes each
situation and each plan as a sentence, embeds them with EmbeddingGemma 2 (a GGUF file served by llama.cpp),
and keeps the plan nearest each situation in `data/skirmish.json` -> `tactics.plan_table.moves`. The game
looks it up only when `plan_table.side` names a side; it is empty, so play is unchanged. `compare` runs
tools/party_war.py's draws twice, each fought both ways round, without the table and with it on the
company's side, and prints both.

`make` needs llama.cpp's `llama-server` built from a version that knows the model (its architecture,
`gemma-embedding2`, landed in October 2026; llama-cpp-python 0.3.36 does not have it yet) and the model file
(huggingface.co/ggml-org/embeddinggemma-2-GGUF). It runs on the maker's machine and nothing of it ships.
The tool itself is standard library only.
"""

import argparse
import datetime
import itertools
import json
import math
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "data", "skirmish.json")
SCENE = "res://src/party_war/party_war.tscn"

KINDS = {
    "close": "a fighter who hits up close with a sword, an axe or fists",
    "ranged": "a fighter who shoots or casts from a few paces away",
    "mender": "a healer who keeps the others on their feet",
}
HEALTH = {
    "healthy": "is unhurt or barely scratched",
    "wounded": "is wounded, about half their health gone",
    "failing": "is badly hurt and close to falling",
}
NEAR = {"near": "an enemy is right next to them", "clear": "no enemy is within reach of them"}
FRIENDS = {"friend_hurt": "a friend nearby is badly wounded", "friends_fine": "their friends are holding up"}
WINDUP = {"windup": "an enemy is winding up a big blow", "calm": "nobody is winding up anything big"}
PLANS = {
    "dodge": "Step out of the way of a big blow an enemy is winding up, before it lands.",
    "kite": "Step back from an enemy who is too close, and keep them in range of your bow or spell.",
    "flank": "Circle round to the side or the back of the enemy in front of you, where your blows land harder.",
    "guard": "Step in beside a wounded friend and take on whoever is hitting them.",
    "hang_back": "Keep out of reach behind your friends, and heal or shoot from the back.",
    "break": "You are badly hurt: get clear of the fighting for a few seconds and catch your breath.",
    "strike": "Stand your ground and keep hitting the enemy in front of you.",
}


def situations() -> dict:
    out = {}
    for kind, health, near, friends, windup in itertools.product(KINDS, HEALTH, NEAR, FRIENDS, WINDUP):
        key = "/".join([kind, health, near, friends, windup])
        out[key] = "In a fight, %s %s; %s, %s, and %s. What should they do?" % (
            KINDS[kind], HEALTH[health], NEAR[near], FRIENDS[friends], WINDUP[windup])
    return out


def cosine(a: list, b: list) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    return dot / (math.sqrt(sum(x * x for x in a)) * math.sqrt(sum(y * y for y in b)))


def embed(server: str, texts: list) -> list:
    """Vectors for [texts] from llama.cpp's `llama-server --embeddings` (its OpenAI-shaped endpoint)."""
    import urllib.request
    body = json.dumps({"input": texts, "model": "embeddinggemma-2"}).encode("utf-8")
    request = urllib.request.Request(server.rstrip("/") + "/v1/embeddings", data=body,
                                     headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=600) as answer:
        data = json.loads(answer.read().decode("utf-8"))["data"]
    return [row["embedding"] for row in sorted(data, key=lambda r: r["index"])]


# EmbeddingGemma's prompts: asymmetric search (a query for the situation, a document for each plan),
# or symmetric classification (both as the same kind of text).
PROMPTS = {
    "search": ("task: search result | query: ", "title: none | text: "),
    "classification": ("task: classification | query: ", "task: classification | query: "),
}


def make(server: str, model_name: str, prompt: str = "search") -> None:
    import time

    asked = situations()
    # One at a time, so the time a call takes is the time the game would wait for one.
    query, document = PROMPTS[prompt]
    started = time.time()
    plan_vectors = {p: embed(server, [document + text])[0] for p, text in PLANS.items()}
    moves, margins = {}, []
    for key, text in asked.items():
        vector = embed(server, [query + text])[0]
        ranked = sorted(((cosine(vector, v), p) for p, v in plan_vectors.items()), reverse=True)
        moves[key] = ranked[0][1]
        margins.append(ranked[0][0] - ranked[1][0])
    took = time.time() - started
    table = {
        "_comment": "D298, docs/investigation/12: the plan EmbeddingGemma 2 put nearest each situation the "
                    "brain can be in (SkirmishBrain.situation), written offline by tools/plan_table.py. Used "
                    "only when side names one (party, foes, all); empty, play is unchanged.",
        "side": "",
        "model": model_name,
        "prompt": prompt,
        "made": datetime.date.today().isoformat(),
        "moves": dict(sorted(moves.items())),
    }
    write_table(table)
    counts = {}
    for move in moves.values():
        counts[move] = counts.get(move, 0) + 1
    print("%d situations and %d plans embedded in %.1f s (%.0f ms each)" % (
        len(asked), len(PLANS), took, 1000.0 * took / (len(asked) + len(PLANS))))
    print("picked: " + ", ".join("%s %d" % (m, c) for m, c in sorted(counts.items(), key=lambda x: -x[1])))
    print("margin between the first and second plan: mean %.3f, least %.3f" % (
        sum(margins) / len(margins), min(margins)))


def write_table(table: dict) -> None:
    """Put `table` in as `tactics.plan_table`, leaving the rest of the file exactly as it was."""
    text = open(DATA, encoding="utf-8").read()
    block = json.dumps(table, indent="\t", ensure_ascii=False).replace("\n", "\n\t\t")
    at = text.find('\t\t"plan_table": ')
    if at >= 0:
        start = text.index("{", at)
        _, length = json.JSONDecoder().raw_decode(text[start:])
        end = start + length
        text = text[:start] + block + text[end:]
    else:
        head = text.index('"tactics": {') + len('"tactics": {')
        text = text[:head] + '\n\t\t"plan_table": ' + block + "," + text[head:]
    json.loads(text)
    open(DATA, "w", encoding="utf-8").write(text)
    print("wrote", os.path.relpath(DATA, ROOT))


def godot() -> str:
    found = os.environ.get("EK_GODOT") or shutil.which("godot")
    if not found:
        sys.exit("Godot 4.7 was not found. Put it on the PATH or set EK_GODOT=/path/to/godot.")
    return found


def clashes(count: int, seed: int, extra: list) -> list:
    out = subprocess.run([godot(), "--headless", "--path", ROOT, SCENE, "--",
                          "--table=%d" % count, "--seed=%d" % seed] + extra,
                         capture_output=True, text=True).stdout
    rows = []
    for line in out.splitlines():
        if line.startswith("clash: "):
            rows.append(dict(p.partition("=")[::2] for p in line[len("clash: "):].split(" | ")))
    return rows


def summary(rows: list) -> dict:
    won = sum(1 for r in rows if r["winner"] == "left")
    seconds = [float(r["seconds"]) for r in rows]
    health = [float(r["left_health"]) for r in rows]
    return {"fights": len(rows), "company_won": won, "share": won / max(1, len(rows)),
            "seconds": sum(seconds) / max(1, len(seconds)), "health_left": sum(health) / max(1, len(health))}


def compare(count: int, seed: int) -> None:
    before = clashes(count, seed, [])
    after = clashes(count, seed, ["--plan-table=party"])
    print("| Brain on the company's side | Fights | Company won | Mean seconds | Company's health left |")
    print("| --- | --- | --- | --- | --- |")
    for name, rows in (("rules only", before), ("the model's table", after)):
        s = summary(rows)
        print("| %s | %d | %d (%.0f%%) | %.1f | %.2f |" % (name, s["fights"], s["company_won"], 100 * s["share"],
                                                      s["seconds"], s["health_left"]))
    turned = sum(1 for a, b in zip(before, after) if a["winner"] != b["winner"])
    print("%d of %d fights changed winner" % (turned, min(len(before), len(after))))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("what", choices=["make", "compare"])
    parser.add_argument("count", nargs="?", type=int, default=60)
    parser.add_argument("--server", default="http://127.0.0.1:8099")
    parser.add_argument("--prompt", choices=sorted(PROMPTS), default="search")
    parser.add_argument("--model-name", default="embeddinggemma-2-Q8_0.gguf")
    parser.add_argument("--seed", type=int, default=7)
    args = parser.parse_args()
    if args.what == "make":
        make(args.server, args.model_name, args.prompt)
    else:
        compare(args.count, args.seed)


if __name__ == "__main__":
    main()
