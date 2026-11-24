#!/usr/bin/env python3
"""Validate a local task graph and suggest compatible ready slices (stdlib only).

This checks declarations, not actual edits, child completion or acceptance.
The build agent is responsible for executing and checking the proposed work.
"""
import argparse
import json
import re
import sys
from pathlib import Path, PurePosixPath

LIMIT = 2
STATES = {"pending", "running", "done", "failed"}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def nonempty(value):
    return isinstance(value, str) and bool(value.strip())


def strings(value, label):
    require(isinstance(value, list) and all(nonempty(x) for x in value),
            f"{label}: expected a list of nonempty strings")
    require(len(value) == len(set(value)), f"{label}: duplicate value")
    return value


def canonical(path):
    p = PurePosixPath(path)
    require(not p.is_absolute() and p.parts and
            p.as_posix() == path and not any(part in {".", ".."} for part in p.parts)
            and not any(c in path for c in "\\*?[]:\x00\n\r")
            and p.parts[0].casefold() != ".git",
            f"expected a concrete project-relative file path: {path!r}")
    # Conservative on case-insensitive checkouts; does not resolve symlinks.
    return tuple(part.casefold() for part in p.parts)


def overlaps(a, b):
    return a[:len(b)] == b or b[:len(a)] == a


def conflict(left, right):
    lw = [canonical(p) for p in left["writes"]]
    rw = [canonical(p) for p in right["writes"]]
    lr = [canonical(p) for p in left["reads"]]
    rr = [canonical(p) for p in right["reads"]]
    return any(overlaps(a, b) for a in lw for b in rw + rr) or any(
        overlaps(a, b) for a in lr for b in rw)


def validate(plan):
    require(isinstance(plan, dict) and type(plan.get("schema")) is int
            and plan["schema"] == 1 and nonempty(plan.get("goal")),
            "expected schema 1 and a nonempty goal")
    tasks = plan.get("tasks")
    require(isinstance(tasks, list) and bool(tasks), "expected nonempty tasks")
    by_id = {}
    for t in tasks:
        require(isinstance(t, dict), "task must be an object")
        key = t.get("id")
        require(isinstance(key, str) and bool(re.fullmatch(r"[a-zA-Z0-9_-]+", key)),
                "task id must contain only letters, digits, hyphen or underscore")
        require(key not in by_id, f"duplicate task id: {key}")
        require(nonempty(t.get("goal")), f"{key}: missing goal")
        for name in ("depends_on", "reads", "writes", "acceptance"):
            strings(t.get(name), f"{key}.{name}")
        require(bool(t["acceptance"]), f"{key}: missing acceptance")
        for path in t["reads"] + t["writes"]:
            canonical(path)
        require(isinstance(t.get("status"), str) and t["status"] in STATES,
                f"{key}: invalid status")
        if t["status"] == "done":
            require(nonempty(t.get("evidence")), f"{key}: done without evidence")
        by_id[key] = t
    for t in tasks:
        for dep in t["depends_on"]:
            require(dep in by_id, f"{t['id']}: unknown dependency {dep}")
            if t["status"] in {"running", "done"}:
                require(by_id[dep]["status"] == "done",
                        f"{t['id']}: dependency {dep} is not done")
    # Topological traversal catches cycles, including self-dependencies.
    visited = set()
    while len(visited) < len(tasks):
        next_ids = {t["id"] for t in tasks if t["id"] not in visited
                    and set(t["depends_on"]) <= visited}
        require(bool(next_ids), "dependency cycle")
        visited.update(next_ids)
    running = [t for t in tasks if t["status"] == "running"]
    require(len(running) <= LIMIT, f"at most {LIMIT} running slices")
    for i, left in enumerate(running):
        for right in running[i+1:]:
            require(not conflict(left, right),
                    f"running slices conflict: {left['id']} / {right['id']}")
    return tasks


def ready(plan):
    tasks = validate(plan)
    running = [t for t in tasks if t["status"] == "running"]
    done = {t["id"] for t in tasks if t["status"] == "done"}
    selected = []
    for t in tasks:
        if len(running) + len(selected) >= LIMIT:
            break
        if (t["status"] == "pending" and set(t["depends_on"]) <= done
                and not any(conflict(t, x) for x in running + selected)):
            selected.append(t)
    return [t["id"] for t in selected]


def complete(plan):
    tasks = validate(plan)
    remaining = [t["id"] for t in tasks if t["status"] != "done"]
    require(not remaining, "unfinished slices: " + ", ".join(remaining))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("check", "ready", "complete"))
    parser.add_argument("manifest", type=Path)
    args = parser.parse_args()
    try:
        plan = json.loads(args.manifest.read_text(encoding="utf-8"))
        if args.command == "ready":
            print(json.dumps(ready(plan)))
        elif args.command == "complete":
            complete(plan)
            print("PASS declared plan complete (verify real acceptance separately)")
        else:
            validate(plan)
            print("PASS declared plan")
    except (OSError, ValueError) as error:
        print(f"FAIL task plan: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
