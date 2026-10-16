#!/usr/bin/env python3
"""The proposed prices in four coins (D90, for doug-md to check).

    python3 tools/economy/proposed_prices.py            -> docs/26-coins-and-prices.md

Every amount is in copper: 100 copper a silver, 100 silver a gold, 100 gold a
platinum (D166; first proposed with bronze as the smallest coin, D89). Nothing
here is in data/ yet: once the prices are checked they are written into the
data files and the game shows them in coins.
Standard library only.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
S, G, P = 100, 10_000, 1_000_000


def coins(copper: int) -> str:
    out = []
    for name, size in (("p", P), ("g", G), ("s", S), ("c", 1)):
        if copper >= size or (name == "c" and not out):
            out.append("%d%s" % (copper // size, name))
            copper %= size
    return " ".join(out)


# (id, new price in copper, why) — the old price is read from data/equipment.json.
ITEMS = {
    "Food and herbs": [
        ("apple", 8, "everyday food is pocket change"),
        ("bread", 20, ""),
        ("ale_flask", 30, ""),
        ("cheese", 40, "keeps for a month"),
        ("herbs", 1 * S + 50, "the cheapest real medicine"),
    ],
    "Draughts": [
        ("red_draught", 20 * S, "the common one: a fight's loot buys about one"),
        ("blue_draught", 45 * S, ""),
        ("green_draught", 80 * S, ""),
        ("amber_draught", 1 * G + 60 * S, "the first thing that costs gold"),
    ],
    "Blades": [
        ("iron_blade", 20 * S, ""),
        ("steel_blade", 55 * S, ""),
        ("silver_blade", 1 * G, ""),
        ("thorn_blade", 1 * G + 40 * S, ""),
        ("ember_blade", 1 * G + 70 * S, ""),
        ("rune_blade", 2 * G, ""),
        ("gilt_blade", 2 * G + 50 * S, ""),
        ("storm_blade", 3 * G, "the best blade a shop sells"),
    ],
    "Bows": [
        ("hunting_bow", 28 * S, ""),
        ("horn_bow", 75 * S, ""),
        ("yew_longbow", 1 * G + 80 * S, ""),
    ],
    "Staffs": [
        ("orrery_staff", 40 * S, ""),
        ("lantern_staff", 70 * S, ""),
        ("skull_staff", 1 * G + 20 * S, ""),
        ("frost_staff", 1 * G + 60 * S, ""),
        ("comet_staff", 2 * G + 80 * S, ""),
    ],
    "Armour": [
        ("padded_coat", 18 * S, ""),
        ("owl_helm", 40 * S, ""),
        ("bark_harness", 50 * S, ""),
        ("scale_shirt", 60 * S, ""),
        ("feather_mail", 1 * G, ""),
        ("filigree_plate", 1 * G + 40 * S, ""),
        ("halo_robe", 1 * G + 90 * S, ""),
        ("gilded_plate", 2 * G + 40 * S, "the best armour a shop sells"),
    ],
}

# (what, where it lives, old, new in copper, note)
OTHER = {
    "Home": [
        ("A rope cot", "world_rules.home.beds", 200, 50 * S, ""),
        ("A feather bed", "world_rules.home.beds", 550, 1 * G + 50 * S, ""),
        ("An eiderdown bed", "world_rules.home.beds", 1300, 4 * G, ""),
        ("A canopied bed", "world_rules.home.beds", 2800, 9 * G, "the dearest thing in the game; platinum is left for property later"),
    ],
    "Services": [
        ("Hire a companion", "world_rules.recruit.cost_base", 70, 20 * S, "plus the line below for each level"),
        ("… for each level", "world_rules.recruit.cost_per_level", 35, 10 * S, ""),
        ("Ransom a captive", "world_rules.captive.ransom_base", 120, 30 * S, "plus the line below for each level"),
        ("… for each level", "world_rules.captive.ransom_per_level", 25, 6 * S, ""),
        ("A Guild map", "guild.map.price", 50, 12 * S, ""),
        ("A grimoire", "grimoires.price_base", 90, 25 * S, "plus up to the line below"),
        ("… up to", "grimoires.price_spread", 70, 20 * S, ""),
        ("A round for the room", "dialogue/the_innkeeper", 40, 10 * S, ""),
        ("A drink at the inn", "dialogue/the_innkeeper", 20, 2 * S, "the line already says \"Two silver\""),
        ("A carriage, one leg", "new (agenda item 60)", None, 6 * S, "proposed; nothing to ride yet"),
    ],
    "What you earn": [
        ("Starting purse", "GameState.DEFAULT_GOLD", 250, 60 * S, "three iron blades, or a blade, a coat and some herbs"),
        ("Loot from a fight", "world_rules.loot.gold_base", 40, 10 * S, "plus up to the line below"),
        ("… up to", "world_rules.loot.gold_spread", 60, 15 * S, ""),
        ("Each Tower floor", "world_rules.tower.gold_per_floor", 60, 15 * S, ""),
        ("Defending a town", "world_rules.town.defence_reward", 160, 40 * S, ""),
        ("Guild contract", "guild.contract.gold_base", 60, 15 * S, "plus the line below for each rank"),
        ("… for each rank", "guild.contract.gold_per_rank", 90, 25 * S, ""),
        ("A muster won", "guild.muster.gold", 240, 60 * S, ""),
        ("An errand", "errands.reward_base", 40, 10 * S, "plus the line below for each tile away"),
        ("… for each tile away", "errands.reward_per_distance", 3, 75, ""),
        ("A cull, for each head", "errands.cull_reward_per_head", 30, 8 * S, ""),
        ("A bounty", "errands.bounty_reward", 130, 35 * S, ""),
        ("A purse found on the road", "roadside.purse_base", 55, 14 * S, "plus the line below for each level"),
        ("… for each level", "roadside.purse_per_level", 22, 5 * S + 50, ""),
        ("A delivery", "roadside.delivery_base", 90, 22 * S + 50, "plus the line below for each level"),
        ("… for each level", "roadside.delivery_per_level", 30, 7 * S + 50, ""),
        ("A trade route, each rest", "roadside.route_pay", 18, 4 * S + 50, ""),
        ("A debt repaid (thread)", "threads.the_debt", 60, 15 * S, ""),
        ("Chests", "data/areas/*.json", None, None, "each chest's gold × 25 copper, rounded to 5 silver: today 45–460, so 11s–1g 15s"),
    ],
    "Asked for in conversation": [
        ("The shore idiot", "dialogue/shore_idiot", 5, 1 * S, ""),
        ("The well child", "dialogue/well_child", 10, 2 * S + 50, ""),
        ("The pine sellsword", "dialogue/pine_sellsword", 15, 4 * S, ""),
        ("The fen fowler", "dialogue/fen_fowler", 20, 5 * S, ""),
        ("The fen wizard", "dialogue/fen_wizard", 25, 6 * S, ""),
        ("The keep watchman", "dialogue/keep_watchman", 30, 8 * S, ""),
        ("The village steward", "dialogue/village_steward", 60, 15 * S, ""),
        ("The chief", "dialogue/the_chief", 100, 25 * S, ""),
    ],
}


def rows() -> dict:
    equipment = json.loads((ROOT / "data" / "equipment.json").read_text(encoding="utf-8"))
    out = {}
    for group, items in ITEMS.items():
        out[group] = []
        for item_id, new, why in items:
            piece = equipment[item_id]
            stats = ", ".join("%s %s" % (k.replace("defense", "defence").replace("mends", "mends"), piece[k])
                              for k in ("attack", "defense", "mends") if k in piece)
            out[group].append({"name": piece["display_name"], "stats": stats, "old": piece["price"],
                               "new": new, "coins": coins(new), "why": why})
    for group, items in OTHER.items():
        out[group] = [{"name": n, "where": w, "old": o, "new": b,
                       "coins": coins(b) if b is not None else "", "why": why} for n, w, o, b, why in items]
    return out


def markdown(table: dict) -> str:
    lines = [
        "# 26 — Coins and prices",
        "",
        "**Proposed 2026-10-12, not in the game yet.** `doug-md` asked for four coins — copper, silver,",
        "gold and platinum, a hundred of each to the next — and for every price to be set again from",
        "scratch, for him to check ([D89](06-decisions.md), [D90](06-decisions.md)). The smallest coin",
        "was first written bronze; he made it copper on 2026-10-16 ([D166](06-decisions.md)). Every number",
        "below is **Inferred** until he has checked it. Generated by `tools/economy/proposed_prices.py`;",
        "change it there. `c` is copper, `s` silver, `g` gold, `p` platinum.",
        "",
        "**How the prices were set.** Prices and earnings move together. Most things are about 25 copper",
        "for each old gold, so a fight still pays for about one Red Draught. Food is far cheaper, because",
        "an apple should cost copper. The best gear costs gold, and nothing costs platinum yet: that is",
        "left for property and other things built later.",
        "",
    ]
    for group, items in table.items():
        lines += ["## " + group, ""]
        if "stats" in items[0]:
            lines += ["| Item | Does | Was (gold) | Now | Note |", "| --- | --- | ---: | ---: | --- |"]
            for r in items:
                lines.append("| %s | %s | %d | %s | %s |" % (r["name"], r["stats"], r["old"], r["coins"], r["why"]))
        else:
            lines += ["| What | Was (gold) | Now | Note |", "| --- | ---: | ---: | --- |"]
            for r in items:
                lines.append("| %s | %s | %s | %s |" % (r["name"], "" if r["old"] is None else r["old"],
                                                        r["coins"] or "—", r["why"]))
        lines.append("")
    return "\n".join(lines)


if __name__ == "__main__":
    table = rows()
    (ROOT / "docs" / "26-coins-and-prices.md").write_text(markdown(table), encoding="utf-8")
    (Path(__file__).parent / "proposed_prices.json").write_text(json.dumps(table, indent=1), encoding="utf-8")
    print("wrote docs/26-coins-and-prices.md")
