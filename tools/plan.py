#!/usr/bin/env python3
"""The pipeline's bookkeeping on GitHub (docs/32), run by the workflows in
.github/workflows/plan-*.yml so nobody has to keep it in order by hand.

    python3 tools/plan.py sync                 # labels and milestones match .github/plan.json
    python3 tools/plan.py check-pr             # a pull request closes an issue, and its D numbers are new
    python3 tools/plan.py check-decisions BASE # only the D-number half, against a base commit
    python3 tools/plan.py sort                 # form answers become labels; unsorted issues get "needs sort"
    python3 tools/plan.py status               # rewrite the status issue: what waits on whom, milestones
    python3 tools/plan.py delete-branches FILE # delete the branches named in FILE (one a line)

Everything but check-decisions talks to the GitHub API with GITHUB_TOKEN for
GITHUB_REPOSITORY, as a workflow gives them. check-pr reads the pull request
from GITHUB_EVENT_PATH.

Standard library only.
"""

import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PLAN = ROOT / ".github" / "plan.json"
DECISIONS = "docs/06-decisions.md"
STATUS_TITLE = "Status: what is in flight"
# A pull request closes an issue, or says why it has none (docs/32, the loop).
LINKED = re.compile(r"\b(close[sd]?|fix(e[sd])?|resolve[sd]?|refs?)\s+#\d+", re.I)
EXEMPT = re.compile(r"\b(docs-only|no issue:)", re.I)
DECISION_ROW = re.compile(r"^\| D(\d+) \|", re.M)
# An issue form's answers, as GitHub writes them into the body: "### Label\n\nAnswer".
FORM_ANSWER = re.compile(r"^### (.+?)\s*\n+(?!###)(.+?)\s*$", re.M)
# Which form questions become labels: {value} is the whole answer, {first} its first word.
FORM_LABELS = {"Kind": "kind: {value}", "How bad": "{first}"}
BOARD_URL = "https://github.com/DougieWilDaBeast/earth-kings/projects"


def api(method, path, body=None):
    """One call to the GitHub REST API; returns the parsed JSON, or None for 204."""
    url = path if path.startswith("https://") else "https://api.github.com" + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", "Bearer " + os.environ["GITHUB_TOKEN"])
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("X-GitHub-Api-Version", "2022-11-28")
    with urllib.request.urlopen(req) as res:
        raw = res.read()
    return json.loads(raw) if raw else None


def every(path):
    """Every item of a paged list."""
    items, page = [], 1
    sep = "&" if "?" in path else "?"
    while True:
        batch = api("GET", f"{path}{sep}per_page=100&page={page}")
        items += batch
        if len(batch) < 100:
            return items
        page += 1


def repo():
    return "/repos/" + os.environ["GITHUB_REPOSITORY"]


def sync():
    plan = json.loads(PLAN.read_text())
    have = {l["name"]: l for l in every(repo() + "/labels")}
    for label in plan["labels"]:
        old = have.get(label["name"])
        if old is None:
            api("POST", repo() + "/labels", label)
            print("label made:", label["name"])
        elif old["color"] != label["color"] or (old["description"] or "") != label["description"]:
            api("PATCH", repo() + "/labels/" + urllib.parse.quote(label["name"]), label)
            print("label changed:", label["name"])
    milestones = {m["title"]: m for m in every(repo() + "/milestones?state=all")}
    for m in plan["milestones"]:
        old = milestones.get(m["title"])
        if old is None:
            api("POST", repo() + "/milestones", m)
            print("milestone made:", m["title"])
        elif old["state"] != m["state"] or (old["description"] or "") != m["description"]:
            api("PATCH", f"{repo()}/milestones/{old['number']}", m)
            print("milestone changed:", m["title"])
    print("labels and milestones match .github/plan.json")


def decision_numbers(text):
    return [int(n) for n in DECISION_ROW.findall(text)]


def check_decisions(base):
    """No D number is used twice (the D165 clash of 2026-10-16). One below main's highest
    is allowed, since an open PR may have held it while a later one merged first."""
    old = subprocess.run(["git", "show", f"{base}:{DECISIONS}"], cwd=ROOT,
                         capture_output=True, text=True, check=True).stdout
    before = decision_numbers(old)
    after = decision_numbers((ROOT / DECISIONS).read_text())
    problems = []
    for n in sorted({n for n in after if after.count(n) > 1}):
        problems.append(f"D{n} is in {DECISIONS} more than once")
    added = sorted(set(after) - set(before))
    top = max(before, default=0)
    for n in added:
        if n <= top:
            print(f"note: D{n} is below main's highest, D{top}; fine if it was held by this PR")
    for line in problems:
        print("PROBLEM:", line)
    if not problems:
        print(f"decisions: {len(added)} new, none used twice" if added else "decisions: none new")
    return problems


def check_pr():
    event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text())
    pr = event["pull_request"]
    problems = []
    body = pr.get("body") or ""
    if not LINKED.search(body) and not EXEMPT.search(body):
        problems.append('the description names no issue: add "Closes #n", or "docs-only", or '
                        '"No issue: <why>" (docs/32, the loop)')
    for line in problems:
        print("PROBLEM:", line)
    problems += check_decisions(pr["base"]["sha"])
    sys.exit(1 if problems else 0)


def open_issues():
    return [i for i in every(repo() + "/issues?state=open") if "pull_request" not in i]


def names(issue):
    return {l["name"] for l in issue["labels"]}


def form_labels(issue, known):
    """Labels the issue form's answers ask for ("How bad: S1 crash..." is "S1 crash or stuck")."""
    wanted = set()
    for question, answer in FORM_ANSWER.findall(issue.get("body") or ""):
        pattern = FORM_LABELS.get(question)
        if not pattern or answer == "_No response_":
            continue
        name = pattern.format(value=answer, first=answer.split()[0])
        match = [k for k in known if k == name or k.startswith(name + " ")]
        if match:
            wanted.add(match[0])
    return wanted


def sort():
    known = [l["name"] for l in json.loads(PLAN.read_text())["labels"]]
    for issue in open_issues():
        labels = names(issue)
        if "status" in labels:
            continue
        add = form_labels(issue, known) - labels
        if add:
            api("POST", f"{repo()}/issues/{issue['number']}/labels", {"labels": sorted(add)})
            print("labelled from form:", issue["number"], sorted(add))
            labels |= add
        unsorted = not any(n.startswith("kind: ") for n in labels) or issue["milestone"] is None
        if unsorted and "needs sort" not in labels:
            api("POST", f"{repo()}/issues/{issue['number']}/labels", {"labels": ["needs sort"]})
            print("needs sort:", issue["number"], issue["title"])
        elif not unsorted and "needs sort" in labels:
            api("DELETE", f"{repo()}/issues/{issue['number']}/labels/needs%20sort")
            print("sorted:", issue["number"], issue["title"])


def line(issue):
    return f"- #{issue['number']} {issue['title']}"


def status():
    issues = [i for i in open_issues() if "status" not in names(i)]
    parts = ["_Kept up to date by `tools/plan.py status` on every merge to main and once a day; "
             "do not edit by hand. How the work moves: docs/32._", "",
             f"**Board:** {BOARD_URL}", ""]
    # A section per "waits on" label in plan.json, so a new person needs no code change.
    people = [l["name"][len("waits on "):] for l in json.loads(PLAN.read_text())["labels"]
              if l["name"].startswith("waits on ")]
    for who in people:
        waiting = [i for i in issues if f"waits on {who}" in names(i)]
        parts.append(f"## Waiting on {who} ({len(waiting)})")
        parts += [line(i) for i in waiting] or ["Nothing."]
        parts.append("")
    blocking = [i for i in issues if "S1 crash or stuck" in names(i)]
    if blocking:
        parts.append(f"## S1, no itch push until these close ({len(blocking)})")
        parts += [line(i) for i in blocking] + [""]
    parts.append("## Milestones")
    for m in every(repo() + "/milestones?state=open&sort=due_on"):
        done, left = m["closed_issues"], m["open_issues"]
        parts.append(f"- **{m['title']}**: {done} done, {left} open. {m['description'] or ''}")
    unsorted = [i for i in issues if "needs sort" in names(i)]
    parts += ["", f"## Needs sort ({len(unsorted)})"] + ([line(i) for i in unsorted] or ["Nothing."])
    body = "\n".join(parts) + "\n"
    found = [i for i in every(repo() + "/issues?state=open&labels=status")]
    if found:
        api("PATCH", f"{repo()}/issues/{found[0]['number']}", {"body": body})
        print("status issue updated:", found[0]["number"])
    else:
        made = api("POST", repo() + "/issues", {"title": STATUS_TITLE, "body": body, "labels": ["status"]})
        print("status issue made:", made["number"])


def delete_branches(listing):
    for name in Path(listing).read_text().split():
        try:
            api("DELETE", f"{repo()}/git/refs/heads/{urllib.parse.quote(name, safe='/')}")
            print("deleted:", name)
        except urllib.error.HTTPError as err:
            # 422 is GitHub's answer for a branch that is already gone.
            print("not deleted:", name, err.code)


def main(args):
    if not args:
        sys.exit(__doc__)
    command = args[0]
    if command == "sync":
        sync()
    elif command == "check-pr":
        check_pr()
    elif command == "check-decisions":
        sys.exit(1 if check_decisions(args[1] if len(args) > 1 else "origin/main") else 0)
    elif command == "sort":
        sort()
    elif command == "status":
        status()
    elif command == "delete-branches":
        delete_branches(args[1])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
