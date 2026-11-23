#!/usr/bin/env python3
"""Refuse a full PASS when local platform evidence is missing or incomplete.

Run: python3 .flutter-harness/bin/verify-e2e.py .flutter-harness/verification.json --profile mobile-web
A complete report is NOT proof of executions; inspect tool calls for independent evidence.
"""
import argparse
import json
from pathlib import Path
import sys

STATUSES = {"PASS", "FAIL", "BLOCKED", "SKIPPED"}


def verify(report, profile):
    problems = []
    platforms = ("android", "ios") + (("web",) if profile == "mobile-web" else ())
    if not isinstance(report, dict):
        return ["report must be a JSON object"]
    for name in platforms:
        row = report.get(name)
        if not isinstance(row, dict):
            problems.append(f"{name}: MISSING platform outcome")
            continue
        status = row.get("status")
        if status not in STATUSES:
            problems.append(f"{name}: invalid status {status!r}")
            continue
        if status == "PASS":
            for key in ("target", "tool", "assertions", "evidence"):
                if not isinstance(row.get(key), str) or not row[key].strip():
                    problems.append(f"{name}: PASS missing {key}")
            expected = "playwright" if name == "web" else "maestro"
            if str(row.get("tool", "")).lower() != expected:
                problems.append(f"{name}: PASS requires tool={expected}")
        else:
            if not isinstance(row.get("reason"), str) or not row["reason"].strip():
                problems.append(f"{name}: {status} missing reason")
            problems.append(f"{name}: {status} (not verified)")
    return problems


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", type=Path)
    parser.add_argument("--profile", choices=("mobile", "mobile-web"), default="mobile-web")
    args = parser.parse_args(argv)
    try:
        report = json.loads(args.report.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        print(f"INCOMPLETE E2E report: {exc}")
        return 3
    problems = verify(report, args.profile)
    if problems:
        for problem in problems:
            print("INCOMPLETE E2E: " + problem)
        print("Use DRAFT PR with limitations; never claim verification DONE")
        return 3
    print("PASS E2E evidence report: Android/iOS" + ("/Web" if args.profile == "mobile-web" else ""))
    print("NOTE: report data are claims; review linked tool calls for actual proof")
    return 0


if __name__ == "__main__":
    sys.exit(main())
