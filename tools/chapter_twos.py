#!/usr/bin/env python3
"""Put the sixteen chapter twos into data/memories.json (D254, the Second Hour).

    python3 tools/chapter_twos.py /mnt/project-files/story/chapter-two

The drafts (D182; **Inferred**, the founders' to rewrite) live in the project's shared files, one
markdown file a lead: its ten boxes under "## The memory" become the scene, its "Journal line" the
journal, its README row the keepsake's name. Where each keepsake lies is tools/build_tower_floors.py's
`KEEPSAKES`. A lead's chapter two already in memories.json is written again, so the tool can be run
after a draft changes; the writers' pass (D274) edited the chapter twos in memories.json
after, so bring the drafts in line before running it again. Standard library only.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from build_tower_floors import KEEPSAKES  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
MEMORIES = ROOT / "data" / "memories.json"
NUMBERS = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]


def unquote(text: str) -> str:
    text = text.strip()
    return text[1:-1] if len(text) > 1 and text[0] == '"' and text[-1] == '"' else text


def plain(text: str) -> str:
    return re.sub(r"\*\*(.+?)\*\*", r"\1", text).strip()


def box_lines(box: str) -> list[dict]:
    """One numbered box as lines: a speaker's words (quoted), and any telling after them."""
    m = re.match(r"\*\*(.+?):\*\*\s*(.*)$", box)
    if not m:
        return [{"speaker": "", "text": plain(box)}]
    speaker, rest = m.group(1), m.group(2).strip()
    if rest.startswith('"'):
        end = rest.find('"', 1)
        said, after = rest[1:end], rest[end + 1:].strip()
        out = [{"speaker": speaker, "text": said}]
        if after:
            out.append({"speaker": "", "text": plain(after)})
        return out
    return [{"speaker": speaker, "text": plain(rest)}]


def keepsake_names(readme: str) -> dict[str, str]:
    names = {}
    for row in readme.splitlines():
        cells = [c.strip() for c in row.strip().strip("|").split("|")]
        if len(cells) > 3 and cells[0].lower() in KEEPSAKES:
            names[cells[0].lower()] = cells[2].replace("_", "")
    return names


def chapter_two(lead: str, text: str, keepsake: str) -> dict:
    title = re.match(r"# Chapter two: (.+?) \(", text).group(1)
    memory = text.split("## The memory", 1)[1].split("\n## ", 1)[0]
    boxes = re.findall(r"^\d+\.\s+(.+)$", memory, re.M)
    scene = [line for box in boxes for line in box_lines(box)]
    journal = unquote(re.search(r"\*\*Journal line:\*\*\s*(.+)$", memory, re.M).group(1))
    floor, cell = KEEPSAKES[lead]
    return {
        "id": "%s_2" % lead,
        "chapter": 2,
        "title": "Chapter two: %s" % title,
        "object": keepsake,
        "area": "tower_floor_%d" % floor,
        "cell": list(cell),
        "art": "coin_pile",
        "scene": scene,
        "journal": journal,
    }


def main() -> None:
    folder = Path(sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/story/chapter-two")
    names = keepsake_names((folder / "README.md").read_text(encoding="utf-8"))
    data = json.loads(MEMORIES.read_text(encoding="utf-8"))
    for lead in KEEPSAKES:
        text = (folder / ("%s-chapter-two.md" % lead)).read_text(encoding="utf-8")
        entry = chapter_two(lead, text, names[lead])
        kept = [m for m in data.get(lead, []) if int(m.get("chapter", 1)) != 2]
        data[lead] = kept + [entry]
        print("%-8s floor %-2s %-28s %2d lines" % (lead, KEEPSAKES[lead][0], entry["title"][13:], len(entry["scene"])))
    MEMORIES.write_text(json.dumps(data, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
