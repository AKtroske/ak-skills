#!/usr/bin/env python3
"""Show, inspect, and clear the local macOS Sticky checklist."""

import argparse
import json
import os
import pathlib
import re
import subprocess
import sys
import tempfile
import time
from urllib.parse import urlparse


ROOT = pathlib.Path(__file__).resolve().parent.parent
STATE_DIR = pathlib.Path.home() / ".local" / "state" / "agent-sticky"
CACHE_DIR = pathlib.Path.home() / ".cache" / "agent-sticky"
BINARY = CACHE_DIR / "sticky-panel"
SOURCE = ROOT / "scripts" / "StickyPanel.swift"


def note_file(note_id="default"):
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,39}", note_id):
        raise ValueError("note ID must use lowercase letters, digits, or hyphens (up to 40 characters)")
    return STATE_DIR / ("note.json" if note_id == "default" else f"note-{note_id}.json")


def write_note(note, path=None):
    path = path or note_file()
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    STATE_DIR.chmod(0o700)
    fd, tmp = tempfile.mkstemp(prefix="note-", suffix=".json", dir=STATE_DIR)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            json.dump(note, stream, ensure_ascii=False, indent=2)
            stream.write("\n")
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)


def read_note(path=None):
    path = path or note_file()
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return None


def ensure_binary():
    if sys.platform != "darwin":
        raise RuntimeError("The floating window helper currently requires macOS")
    if not BINARY.exists() or SOURCE.stat().st_mtime > BINARY.stat().st_mtime:
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        tmp = CACHE_DIR / "sticky-panel.build"
        try:
            subprocess.run(["swiftc", "-framework", "AppKit", str(SOURCE), "-o", str(tmp)], check=True)
            os.replace(tmp, BINARY)
        finally:
            tmp.unlink(missing_ok=True)


def running(path):
    try:
        pattern = "^" + re.escape(str(BINARY)) + " " + re.escape(str(path)) + r"( |$)"
        result = subprocess.run(["pgrep", "-f", pattern], capture_output=True, text=True)
        return result.returncode == 0
    except FileNotFoundError:
        return False


def validate_note(payload):
    if not isinstance(payload, dict):
        raise ValueError("checklist JSON must be an object")
    title = payload.get("title")
    steps = payload.get("steps")
    if not isinstance(title, str) or not title.strip():
        raise ValueError("checklist needs a title")
    if not isinstance(steps, list) or not 1 <= len(steps) <= 20:
        raise ValueError("checklist needs 1 to 20 steps")
    clean_steps = []
    for number, step in enumerate(steps, 1):
        if isinstance(step, str):
            step = {"text": step}
        if not isinstance(step, dict) or not isinstance(step.get("text"), str) or not step["text"].strip():
            raise ValueError(f"step {number} needs text")
        clean = {"text": step["text"].strip(), "done": bool(step.get("done", False))}
        for field in ("detail", "url", "link_label"):
            value = step.get(field)
            if value is not None:
                if not isinstance(value, str):
                    raise ValueError(f"step {number} {field} must be text")
                if value.strip():
                    clean[field] = value.strip()
        if "url" in clean:
            parsed = urlparse(clean["url"])
            web_link = parsed.scheme in ("https", "http") and bool(parsed.netloc)
            local_file = parsed.scheme == "file" and parsed.path.startswith("/")
            if not web_link and not local_file:
                raise ValueError(f"step {number} needs an http(s) or file URL")
        clean_steps.append(clean)
    return {"title": title.strip(), "steps": clean_steps, "visible": True}


def visible_note_count():
    count = 0
    for path in STATE_DIR.glob("*.json"):
        try:
            if read_note(path).get("visible"):
                count += 1
        except (ValueError, AttributeError):
            continue
    return count


def start_window(path):
    if running(path):
        return
    slot = min(max(visible_note_count() - 1, 0), 5)
    with open(os.devnull, "wb") as devnull:
        process = subprocess.Popen([str(BINARY), str(path), str(slot)], stdin=devnull, stdout=devnull, stderr=devnull, start_new_session=True)
    for _ in range(40):
        if running(path):
            return
        if process.poll() is not None:
            raise RuntimeError("floating window exited during startup")
        time.sleep(0.05)
    raise RuntimeError("floating window did not start")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    show = commands.add_parser("show", help="open or replace the floating checklist")
    show.add_argument("--title")
    show.add_argument("--step", action="append", dest="steps")
    show.add_argument("--json", metavar="FILE", help="structured checklist JSON file, or - for stdin")
    show.add_argument("--id", default="default", help="stable ID for an independent note (default: default)")
    reopen = commands.add_parser("reopen", help="restore a dismissed checklist with its checked items")
    reopen.add_argument("--id", default="default")
    status = commands.add_parser("status", help="print one checklist and checkbox state as JSON")
    status.add_argument("--id", default="default")
    clear = commands.add_parser("clear", help="delete one checklist")
    clear.add_argument("--id", default="default")
    commands.add_parser("list", help="list saved checklists and their progress")
    args = parser.parse_args()

    if args.command == "list":
        notes = []
        for path in sorted(STATE_DIR.glob("*.json")):
            note_id = "default" if path.name == "note.json" else path.stem.removeprefix("note-")
            note = read_note(path)
            if isinstance(note, dict):
                steps = note.get("steps", [])
                notes.append({"id": note_id, "title": note.get("title"), "visible": note.get("visible"), "done": sum(bool(s.get("done")) for s in steps), "total": len(steps)})
        print(json.dumps(notes, ensure_ascii=False, indent=2))
        return

    path = note_file(args.id)
    if args.command == "status":
        print(json.dumps(read_note(path), ensure_ascii=False, indent=2))
        return
    if args.command == "clear":
        note = read_note(path)
        if note is not None:
            path.unlink(missing_ok=True)
            for _ in range(40):
                if not running(path):
                    break
                time.sleep(0.05)
        return

    if args.command == "reopen":
        note = read_note(path)
        if note is None:
            raise RuntimeError(f"there is no saved checklist named {args.id!r} to reopen")
        ensure_binary()
        note["visible"] = True
        write_note(note, path)
        start_window(path)
        print("Sticky checklist reopened.")
        return

    if args.json:
        if args.title or args.steps:
            parser.error("--json cannot be combined with --title or --step")
        source = sys.stdin if args.json == "-" else open(args.json, encoding="utf-8")
        try:
            payload = json.load(source)
        finally:
            if source is not sys.stdin:
                source.close()
    else:
        if not args.title or not args.steps:
            parser.error("provide --title and at least one --step, or --json")
        payload = {"title": args.title, "steps": args.steps}
    note = validate_note(payload)
    ensure_binary()
    write_note(note, path)
    start_window(path)
    print("Sticky checklist shown.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, subprocess.CalledProcessError, RuntimeError, ValueError, json.JSONDecodeError) as error:
        print(f"sticky: {error}", file=sys.stderr)
        sys.exit(1)
