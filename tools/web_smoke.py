#!/usr/bin/env python3
"""Export the Web build, serve it, and play it in headless Chromium.

    python3 tools/web_smoke.py                 # export, then play
    python3 tools/web_smoke.py --no-export     # play what is already in builds/web

Standard library only; the browser half is tools/web_smoke.js, which needs Node
and the `playwright` npm package (a global install is found through
`npm root -g`) with a Chromium it can launch (set PLAYWRIGHT_BROWSERS_PATH if
the browsers are not in Playwright's default cache).

Godot is $EK_GODOT if set, else `godot` on the PATH, and needs the 4.7.2
web_nothreads export templates. Screenshots land in builds/web_smoke/.
Exits 1 when the export or the browser run finds a problem: a console error,
a page error, a failed request, a screen that never came, or a save that never
reached IndexedDB. See docs/10-manual-tests.md, "The browser build".
"""

import argparse
import functools
import http.server
import json
import os
import shutil
import subprocess
import sys
import threading
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WEB = ROOT / "builds" / "web"
SHOTS = ROOT / "builds" / "web_smoke"


def export(godot: str) -> bool:
    WEB.mkdir(parents=True, exist_ok=True)
    (ROOT / "builds" / ".gdignore").touch()
    if not (ROOT / ".godot" / "imported").is_dir():
        subprocess.run([godot, "--headless", "--path", str(ROOT), "--import"],
                       capture_output=True, text=True)
    out = subprocess.run(
        [godot, "--headless", "--path", str(ROOT), "--export-release", "Web", "builds/web/index.html"],
        capture_output=True, text=True)
    errors = [line for line in (out.stdout + out.stderr).splitlines() if "ERROR" in line]
    if out.returncode != 0 or errors or not (WEB / "index.pck").exists():
        print(f"export failed (exit {out.returncode})")
        print("\n".join(errors[:20]))
        return False
    return True


class _Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def node_env() -> dict:
    env = dict(os.environ)
    npm = shutil.which("npm")
    if npm:
        root = subprocess.run([npm, "root", "-g"], capture_output=True, text=True).stdout.strip()
        if root:
            env["NODE_PATH"] = os.pathsep.join(p for p in (env.get("NODE_PATH", ""), root) if p)
    return env


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--no-export", action="store_true", help="play the build already in builds/web")
    args = parser.parse_args()

    if not args.no_export and not export(os.environ.get("EK_GODOT", "godot")):
        return 1
    if not (WEB / "index.html").exists():
        print("no builds/web/index.html; run without --no-export")
        return 1
    if not shutil.which("node"):
        print("node was not found; the browser half needs Node and the playwright package")
        return 1

    sizes = {name: (WEB / name).stat().st_size for name in ("index.pck", "index.wasm", "index.js")}
    server = http.server.ThreadingHTTPServer(
        ("127.0.0.1", 0), functools.partial(_Quiet, directory=str(WEB)))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    url = f"http://127.0.0.1:{server.server_address[1]}/index.html"

    SHOTS.mkdir(parents=True, exist_ok=True)
    run = subprocess.run(["node", str(ROOT / "tools" / "web_smoke.js"), url, str(SHOTS)],
                         capture_output=True, text=True, env=node_env())
    server.shutdown()

    last = (run.stdout.strip().splitlines() or ["{}"])[-1]
    try:
        result = json.loads(last)
    except json.JSONDecodeError:
        print(run.stdout, run.stderr, sep="\n")
        return 1
    mb = {k: round(v / 1_000_000, 1) for k, v in sizes.items()}
    print(f"web build: pck {mb['index.pck']} MB, wasm {mb['index.wasm']} MB, js {mb['index.js']} MB")
    print(f"boot {result.get('boot_s')} s to the title card, {result.get('world_s')} s from picking a life to the world")
    print(f"saved to IndexedDB: {result.get('saved')}; screenshots in {SHOTS.relative_to(ROOT)}/")
    for problem in result.get("problems", []):
        print(f"  PROBLEM {problem}")
    if run.returncode != 0:
        print("web smoke: FAIL")
        return 1
    print("web smoke: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
