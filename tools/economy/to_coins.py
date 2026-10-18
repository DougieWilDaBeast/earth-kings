#!/usr/bin/env python3
"""Write the four coins into the game's data (D253): every amount of money becomes copper.

    python3 tools/economy/to_coins.py           rewrite data/ (run once; it refuses to run twice)

The prices `doug-md` asked for are docs/26 (tools/economy/proposed_prices.py, D89, D90, D177):
those it names are taken as they are. Everything it does not name (prices set since, a chest, a
bribe, a price somebody asks in conversation) is about 25 copper for each old gold, as docs/26
says, rounded to a tidy amount: a chest's to 5 silver. A few are set by hand below (`BY_HAND`),
where the round number reads better or the thing is food. Multipliers, chances and dials are left
alone. Standard library only.
"""
from __future__ import annotations

import glob
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))
from proposed_prices import ITEMS, OTHER, S, G  # noqa: E402

RATE = 25
DONE_MARK = "_coins"


def tidy(old: float, chest: bool = False) -> int:
    if old == 0:
        return 0
    sign = -1 if old < 0 else 1
    c = abs(old) * RATE
    if chest:
        step = 5 * S
    elif c >= G:
        step = 10 * S
    elif c >= 10 * S:
        step = S
    elif c >= S:
        step = 50
    else:
        step = 5
    return sign * max(step, int(c / step + 0.5) * step)


# docs/26's own numbers, by where they live.
NAMED = {
    ("world_rules", "recruit", "cost_base"): 20 * S,
    ("world_rules", "recruit", "cost_per_level"): 10 * S,
    ("world_rules", "captive", "ransom_base"): 30 * S,
    ("world_rules", "captive", "ransom_per_level"): 6 * S,
    ("world_rules", "loot", "gold_base"): 10 * S,
    ("world_rules", "loot", "gold_spread"): 15 * S,
    ("world_rules", "tower", "gold_per_floor"): 15 * S,
    ("world_rules", "town", "defence_reward"): 40 * S,
    ("guild", "map", "price"): 12 * S,
    ("guild", "contract", "gold_base"): 15 * S,
    ("guild", "contract", "gold_per_rank"): 25 * S,
    ("guild", "muster", "gold"): 60 * S,
    ("grimoires", "price_base"): 25 * S,
    ("grimoires", "price_spread"): 20 * S,
    ("errands", "reward_base"): 10 * S,
    ("errands", "reward_per_distance"): 75,
    ("errands", "cull_reward_per_head"): 8 * S,
    ("errands", "bounty_reward"): 35 * S,
    ("roadside", "rules", "purse_base"): 14 * S,
    ("roadside", "rules", "purse_per_level"): 5 * S + 50,
    ("roadside", "rules", "route_pay"): 4 * S + 50,
    ("roadside", "rules", "delivery_base"): 22 * S + 50,
    ("roadside", "rules", "delivery_per_level"): 7 * S + 50,
}
BEDS = {200: 50 * S, 550: 1 * G + 50 * S, 1300: 4 * G, 2800: 9 * G}
DIALOGUE = {"shore_idiot": 1 * S, "well_child": 2 * S + 50, "pine_sellsword": 4 * S, "fen_fowler": 5 * S,
            "fen_wizard": 6 * S, "keep_watchman": 8 * S, "village_steward": 15 * S, "the_chief": 25 * S}
INNKEEPER = {20: 2 * S, 40: 10 * S}
# Set by hand: food docs/26 leaves out, and prices since that read better round.
BY_HAND_ITEMS = {"meat_pie": 50, "honey_cake": 15}
# (area, the `q` of the ask, old cost) -> copper
BY_HAND_ASKS = {
    "Let us keep room two for good (250 gold).": 60 * S,
    "We keep a room at the Flagon now. The narrow house (900 gold)?": 2 * G + 25 * S,
    "Build a smithy at the crater (300 gold).": 75 * S,
    "Build an infirmary at the crater (300 gold).": 75 * S,
    "Put a wall round the crater (500 gold).": 1 * G + 25 * S,
}
# A bribe, by what is said with it -> copper.
BY_HAND_BRIBES = {
    "Ten gold for a minute of your time?": 3 * S,
    "Add three gold to the pile.": 1 * S,
    "Ten gold says you've heard of him.": 3 * S,
}
# Words that say an amount, rewritten with it.
SAID = [
    ("Ten gold for a minute of your time?", "Three silver for a minute of your time?"),
    ("Add three gold to the pile.", "Add a silver to the pile."),
    ("Ten gold says you've heard of him.", "Three silver says you've heard of him."),
    ("Toss it a coin. (2 gold)", "Toss it a coin. (50 copper)"),
    ("A hundred gold, and", "Twenty-five silver, and"),
    ("Forty for the room. Forty!", "Ten silver for the room. Ten silver!"),
    ("(250 gold)", "(60 silver)"), ("Two hundred and fifty", "Sixty silver"),
    ("(900 gold)", "(2 gold 25 silver)"), ("Nine hundred.", "Two gold and twenty-five silver."),
    ("(300 gold)", "(75 silver)"), ("(500 gold)", "(1 gold 25 silver)"),
    ("A room for the night. Forty?", "A room for the night. Ten silver?"),
    ("Forty, and it's yours", "Ten silver, and it's yours"),
    ("Forty it is.", "Ten silver it is."), ("Forty for the room", "Ten silver for the room"),
    ("I've had my forty.", "I've had my ten silver."),
]

NUMBER = re.compile(r"-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?")


def number_spans(text: str) -> list[tuple[int, int]]:
    """Where every number in a JSON text stands, in the order a parser meets them."""
    spans = []
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == '"':
            i += 1
            while text[i] != '"':
                i += 2 if text[i] == "\\" else 1
            i += 1
        elif ch == "-" or ch.isdigit():
            m = NUMBER.match(text, i)
            spans.append((m.start(), m.end()))
            i = m.end()
        else:
            i += 1
    return spans


def numbers(o) -> list:
    if isinstance(o, dict):
        return [n for v in o.values() for n in numbers(v)]
    if isinstance(o, list):
        return [n for v in o for n in numbers(v)]
    if isinstance(o, (int, float)) and not isinstance(o, bool):
        return [o]
    return []


def rewrite_numbers(text: str, data) -> str:
    """[param text] with only the numbers changed to [param data]'s, so the file keeps its layout."""
    spans = number_spans(text)
    now = numbers(data)
    was = numbers(json.loads(text))
    assert len(spans) == len(now) == len(was), "number count differs"
    out = text
    for (a, b), old, new in reversed(list(zip(spans, was, now))):
        if old != new:
            out = out[:a] + str(new) + out[b:]
    return out


changed: list[str] = []


def put(where: str, old, new) -> None:
    if old != new:
        changed.append("%-60s %8s -> %s" % (where, old, new))


def convert_world_rules(d: dict) -> None:
    for (f, *path), new in NAMED.items():
        if f != "world_rules":
            continue
        node = d
        for k in path[:-1]:
            node = node[k]
        put("world_rules." + ".".join(path), node[path[-1]], new)
        node[path[-1]] = new
    for bed in d["home"]["beds"]:
        new = BEDS.get(bed["cost"], tidy(bed["cost"]))
        put("world_rules.home.beds." + bed["id"], bed["cost"], new)
        bed["cost"] = new
    for path in (("town", "purse_base"), ("town", "purse_per_rank"), ("renown", "remembered", "cold", "bribe"),
                 ("life", "road_watch", "purse_base"), ("life", "road_watch", "purse_per_level")):
        node = d
        for k in path[:-1]:
            node = node.get(k, {})
        if path[-1] in node:
            new = tidy(node[path[-1]])
            put("world_rules." + ".".join(path), node[path[-1]], new)
            node[path[-1]] = new


def convert_named(name: str, d: dict) -> None:
    for (f, *path), new in NAMED.items():
        if f != name:
            continue
        node = d
        for k in path[:-1]:
            node = node[k]
        put(name + "." + ".".join(path), node[path[-1]], new)
        node[path[-1]] = new


def walk_money(o, where: str, keys: tuple, rule) -> None:
    if isinstance(o, dict):
        for k, v in list(o.items()):
            if k in keys and isinstance(v, (int, float)) and not isinstance(v, bool):
                new = rule(o, k, v, where)
                put(where + "." + k, v, new)
                o[k] = new
            else:
                walk_money(v, where + "." + k, keys, rule)
    elif isinstance(o, list):
        for v in o:
            walk_money(v, where, keys, rule)


def area_rule(node: dict, key: str, old, where: str) -> int:
    if key == "bribe" and str(node.get("bribe_q", "")) in BY_HAND_BRIBES:
        return BY_HAND_BRIBES[str(node["bribe_q"])]
    if key == "cost" and str(node.get("q", "")) in BY_HAND_ASKS:
        return BY_HAND_ASKS[str(node["q"])]
    if ".chests" in where or (key == "gold" and ".talk" not in where):
        return tidy(old, chest=True)
    return tidy(old)


def main() -> None:
    rules_path = ROOT / "data" / "world_rules.json"
    if DONE_MARK in rules_path.read_text(encoding="utf-8"):
        sys.exit("to_coins: data/ is already in coins")
    files: dict[Path, object] = {}

    def load(path: Path):
        files[path] = json.loads(path.read_text(encoding="utf-8"))
        return files[path]

    rules = load(rules_path)
    convert_world_rules(rules)
    rules_mark = "D253: every amount of money in data/ is copper (100 a silver, 100 silver a gold, 100 gold a platinum); see src/chronicle/coins.gd and docs/26."
    for name in ("guild", "grimoires", "errands", "roadside"):
        convert_named(name, load(ROOT / "data" / ("%s.json" % name)))
    coliseum = load(ROOT / "data" / "coliseum.json")
    put("coliseum.rules.purse_per_round", coliseum["rules"]["purse_per_round"], 15 * S)
    coliseum["rules"]["purse_per_round"] = 15 * S
    threads = load(ROOT / "data" / "threads.json")
    walk_money(threads, "threads", ("gold",), lambda n, k, v, w: 15 * S if v == 60 else tidy(v))
    backgrounds = load(ROOT / "data" / "lore" / "backgrounds.json")
    for key, bg in backgrounds.items():
        gift = bg.get("gift", {}) if isinstance(bg, dict) else {}
        gift = gift if isinstance(gift, dict) else {}
        if gift.get("kind") == "gold":
            put("backgrounds.%s.gift" % key, gift["value"], tidy(gift["value"]))
            gift["value"] = tidy(gift["value"])

    equipment = load(ROOT / "data" / "equipment.json")
    listed = {item: new for group in ITEMS.values() for item, new, _ in group}
    for item_id, piece in equipment.items():
        if isinstance(piece, dict) and "price" in piece:
            new = listed.get(item_id, BY_HAND_ITEMS.get(item_id, tidy(piece["price"])))
            put("equipment." + item_id, piece["price"], new)
            piece["price"] = new

    for path in sorted(glob.glob(str(ROOT / "data" / "dialogue" / "*.json"))):
        p = Path(path)
        name = p.stem
        d = load(p)
        if name == "the_innkeeper":
            rule = lambda n, k, v, w: (-1 if v < 0 else 1) * INNKEEPER.get(abs(v), tidy(abs(v)))
        elif name in DIALOGUE:
            rule = lambda n, k, v, w, name=name: (-1 if v < 0 else 1) * DIALOGUE[name]
        else:
            rule = lambda n, k, v, w: tidy(v)
        walk_money(d, "dialogue/" + name, ("gold", "requires_gold"), rule)

    for path in sorted(glob.glob(str(ROOT / "data" / "areas" / "*.json"))):
        p = Path(path)
        walk_money(load(p), "areas/" + p.stem, ("gold", "cost", "price", "reward", "bribe"), area_rule)

    for path, data in files.items():
        text = path.read_text(encoding="utf-8")
        out = rewrite_numbers(text, data)
        if path == rules_path:
            out = out.replace("{\n", "{\n\t\"%s\": %s,\n" % (DONE_MARK, json.dumps(rules_mark)), 1)
        for old, new in SAID:
            out = out.replace(old, new)
        if out != text:
            path.write_text(out, encoding="utf-8")
    print("\n".join(changed))
    print("to_coins: %d amounts in %d files" % (len(changed), len(files)))


if __name__ == "__main__":
    main()
