#!/usr/bin/env python3
"""Deterministic Flutter lifecycle; no model calls or shell interpolation."""
import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import time

HERE = Path(__file__).resolve().parent
PNG = b"\x89PNG\r\n\x1a\n"


class Blocked(RuntimeError):
    pass


def require(ok, message):
    if not ok:
        raise Blocked(message)


def run(root, *args, capture=False, timeout=600, log=None, env=None):
    if log:
        log.parent.mkdir(parents=True, exist_ok=True)
        with log.open("wb") as stream:
            result = subprocess.run(args, cwd=root, stdout=stream,
                                    stderr=subprocess.STDOUT, timeout=timeout, env=env)
        if result.returncode:
            raise Blocked(f"{args[0]} exit={result.returncode}; log={log}")
        return ""
    result = subprocess.run(args, cwd=root, capture_output=capture,
                            timeout=timeout, env=env)
    if result.returncode:
        detail = (result.stderr or b"").decode(errors="replace")[-1000:] if capture else ""
        raise Blocked(f"{args[0]} exit={result.returncode}: {detail}")
    return result.stdout if capture else b""


def git(root, *args):
    return run(root, "git", *args, capture=True, timeout=60)


def text(data):
    return data.decode("utf-8").strip()


def output(**data):
    print(json.dumps(data, ensure_ascii=False, sort_keys=True))


def read_json(path):
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"Expected JSON object: {path}")
    return value


def atomic_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8",
                                     dir=path.parent, delete=False) as f:
        tmp = Path(f.name)
        json.dump(value, f, indent=2, ensure_ascii=False)
        f.write("\n")
    try:
        tmp.replace(path)
    finally:
        tmp.unlink(missing_ok=True)


def config(root):
    c = read_json(root / ".flutter-harness/config.json")
    require(c.get("schema") == 2, "Install/sync Harness schema 2 first")
    require(c.get("profile") in ("mobile", "mobile-web"), "Invalid profile")
    base = c.get("integration_branch")
    require(isinstance(base, str) and base and not base.startswith("-"),
            "Invalid integration branch")
    git(root, "check-ref-format", "--branch", base)
    return c


def work(root):
    return root / ".flutter-harness/work"


def event(root, stage, **details):
    """Append only structured lifecycle facts, never prompts or command output."""
    path = work(root) / "lifecycle.jsonl"
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as stream:
        stream.write(json.dumps({"at": int(time.time() * 1000), "stage": stage, **details}) + "\n")


def paths(data):
    return [os.fsdecode(p) for p in data.split(b"\0") if p]


def fingerprint(root):
    """All tracked and nonignored files, including native/assets/configuration.
    Stable across staging/commit of the same working-tree contents."""
    names = sorted(set(paths(git(root, "ls-files", "-z", "--cached",
                                "--others", "--exclude-standard"))))
    h = hashlib.sha256()
    for name in names:
        path = root / name
        try:
            mode = path.lstat().st_mode
        except FileNotFoundError:
            continue
        require(not stat.S_ISDIR(mode), f"Submodules are outside v0 scope: {name}")
        h.update(os.fsencode(name) + b"\0")
        if stat.S_ISLNK(mode):
            h.update(b"link\0" + os.fsencode(os.readlink(path)))
        else:
            require(stat.S_ISREG(mode), f"Unsupported file: {name}")
            h.update(b"x" if mode & stat.S_IXUSR else b"-")
            with path.open("rb") as f:
                for chunk in iter(lambda: f.read(1024 * 1024), b""):
                    h.update(chunk)
        h.update(b"\0")
    return h.hexdigest()


def dirty(root):
    return sorted(set(paths(git(root, "diff", "--no-renames", "--name-only",
                                "-z", "HEAD", "--")) +
                      paths(git(root, "ls-files", "-z", "--others",
                                "--exclude-standard")) +
                      paths(git(root, "diff", "--cached", "--no-renames",
                                "--name-only", "-z", "HEAD", "--"))))


def branch(root, base):
    name = text(git(root, "symbolic-ref", "--short", "HEAD"))
    require(name not in (base, "main", "master", "app", "develop", ""),
            f"Expected feature branch, got {name}")
    return name


def begin(root, c, name):
    base = c["integration_branch"]
    require(not name.startswith("-"), "Invalid branch")
    git(root, "check-ref-format", "--branch", name)
    require(name not in (base, "main", "master", "app", "develop") and
            not name.startswith("-"), "Unsafe feature branch")
    require(not dirty(root), "Dirty checkout; preserve existing changes before begin")
    git(root, "fetch", "origin", base)
    require(text(git(root, "rev-parse", "FETCH_HEAD")) ==
            text(git(root, "rev-parse", "origin/" + base)),
            "origin integration reference is stale")
    current = text(git(root, "symbolic-ref", "--short", "HEAD"))
    if current != name:
        git(root, "switch", "-c", name, "origin/" + base)
        for filename in ("check.json","delivery.json","delivery-result.json","delivery-state.json","runtime.json","sessions.json","e2e-android.json","e2e-ios.json","e2e-web.json"):
            (work(root)/filename).unlink(missing_ok=True)
    require(text(git(root, "merge-base", "HEAD", "origin/" + base)) ==
            text(git(root, "rev-parse", "origin/" + base)),
            "Feature branch does not contain current integration base")
    event(root, "begin", branch=name, base=base)
    output(status="PASS", branch=name, base=base)


def doctor(root, c, operation):
    needed = {"check": ("git", "flutter", "dart", "python3"),
              "deliver": ("git", "gh"), "android": ("flutter", "adb"),
              "ios": ("flutter", "xcrun"), "web": ("flutter", "npx"),
              "e2e": ("flutter",)}[operation]
    tools = {name: shutil.which(name) for name in needed}
    missing = [name for name, location in tools.items() if not location]
    devices = None
    if operation in ("android", "ios", "web") and not missing:
        try:
            devices = json.loads(run(root, "flutter", "devices", "--machine",
                                     capture=True, timeout=60))
        except (Blocked, ValueError):
            missing.append("Flutter device discovery")
    if operation == "deliver" and not missing:
        try:
            run(root, "gh", "auth", "status", "--hostname", "github.com",
                capture=True, timeout=30)
        except Blocked:
            missing.append("github authentication")
    output(status="BLOCKED" if missing else "PASS", operation=operation,
           tools=tools, missing=missing, profile=c["profile"], devices=devices)
    require(not missing, "Missing required prerequisites")


def check(root, c):
    receipt = work(root) / "check.json"
    receipt.unlink(missing_ok=True)
    event(root, "check-start")
    require((root / ".flutter-harness/product.json").is_file(), "Missing product policy configuration")
    run(root, "flutter", "pub", "get", log=work(root) / "pub-get.log")
    run(root, "dart", "format", "lib", "test", log=work(root) / "format.log")
    before = fingerprint(root)
    # Unique artifact directory prevents collisions between runs/checkouts.
    artifact_dir = Path(tempfile.mkdtemp(prefix="standard-", dir=work(root)))
    environment = dict(os.environ, HARNESS_ARTIFACTS_DIR=str(artifact_dir))
    # Keep short runner stdout visible for the OpenCode quality hook.
    run(root, "bash", str(HERE / "check.sh"), ".", "standard", c["profile"], env=environment, timeout=2400)
    require(fingerprint(root) == before, "Check inputs changed during verification")
    reports = list(artifact_dir.glob("check-*.tsv"))
    require(len(reports) == 1, "Missing unique runner report")
    with reports[0].open() as f:
        checks = list(csv.DictReader(f, delimiter="\t"))
    require({r.get("check") for r in checks if r.get("status")=="PASS"} ==
            {"format","product","analyze","flutter-tests"}, "Incomplete standard runner evidence")
    atomic_json(receipt, {"digest": before, "status": "PASS", "checks":checks,
                          "report":str(reports[0]), "checked_at": int(time.time())})
    event(root, "check-pass", digest=before)
    output(status="PASS", digest=before, receipt=str(receipt))


def origin_repo(root):
    origin = text(git(root, "remote", "get-url", "origin"))
    match = re.fullmatch(r"(?:https://github\.com/|git@github\.com:|ssh://git@github\.com/)([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+?)(?:\.git)?", origin)
    require(match, "Expected a GitHub origin remote")
    require(text(git(root, "remote", "get-url", "--push", "origin")) == origin,
            "Push URL differs from origin")
    return match.group(1)


def pr_list(root, repo, name):
    data = json.loads(run(root, "gh", "pr", "list", "--repo", repo,
                          "--head", name, "--state", "open",
                          "--json", "number,baseRefName,headRefName,headRepositoryOwner,isCrossRepository,isDraft,headRefOid,state,url,title,body",
                          capture=True, timeout=60))
    require(isinstance(data, list), "Invalid GitHub PR response")
    own = [p for p in data if p.get("headRefName") == name and
           not p.get("isCrossRepository") and
           (p.get("headRepositoryOwner") or {}).get("login", "").lower() ==
           repo.split("/")[0].lower()]
    require(len(own) <= 1, "Multiple PRs for this branch")
    return own[0] if own else None


def validate_remote_pr(pr, repo, base, name, head):
    require(pr and pr.get("state") == "OPEN" and pr.get("baseRefName") == base and
            pr.get("headRefName") == name and pr.get("headRefOid") == head and
            not pr.get("isCrossRepository") and not pr.get("isDraft"),
            "PR missing, draft, stale, closed, cross-repo or targets the wrong branch")
    require(pr.get("url", "").lower().startswith("https://github.com/" + repo.lower() + "/pull/"),
            "Unexpected PR URL")
    return pr


def manifest_digest(manifest):
    return hashlib.sha256(json.dumps(manifest, sort_keys=True, separators=(",", ":"),
                                     ensure_ascii=False).encode()).hexdigest()


def completion(root, c):
    """Local evidence of an exact candidate previously verified against GitHub.
    No network call. Use verify for an explicit fresh remote read."""
    name = branch(root, c["integration_branch"])
    require(not dirty(root), "Uncommitted work remains")
    digest = fingerprint(root)
    head = text(git(root, "rev-parse", "HEAD"))
    receipt = read_json(work(root) / "check.json")
    require(receipt.get("status") == "PASS" and receipt.get("digest") == digest,
            "Missing/stale standard check receipt")
    path = work(root) / "delivery-result.json"
    require(path.is_file(), "Missing delivery-result.json; resume canonical deliver")
    result = read_json(path)
    manifest = read_json(work(root) / "delivery.json")
    require(all(result.get(k) == v for k, v in {
        "status": "PASS", "head": head, "digest": digest, "branch": name,
        "base": c["integration_branch"], "repo": origin_repo(root),
        "manifest_digest": manifest_digest(manifest), "checked_at": receipt.get("checked_at"),
    }.items()) and isinstance(result.get("delivered_at"), int),
            "Missing/stale delivery evidence; resume canonical deliver")
    require(result.get("pr", "").lower().startswith("https://github.com/" + result["repo"].lower() + "/pull/"),
            "Invalid delivery PR URL")
    return result


def verify(root, c):
    result = completion(root, c)
    pr = validate_remote_pr(pr_list(root, result["repo"], result["branch"]),
                            result["repo"], result["base"], result["branch"], result["head"])
    require(pr["url"] == result["pr"], "Remote PR differs from delivery receipt")
    output(status="PASS", pr=pr["url"], head=result["head"])
    return pr


def deliver(root, c):
    """Called only after the OpenCode policy gate and owner publication approval.
    The receipt is workflow evidence, not an adversarial security boundary."""
    name = branch(root, c["integration_branch"])
    receipt = read_json(work(root) / "check.json")
    digest = fingerprint(root)
    require(receipt.get("status") == "PASS" and receipt.get("digest") == digest,
            "Missing/stale standard check receipt; run check")
    manifest = read_json(work(root) / "delivery.json")
    required_e2e = manifest.get("required_e2e", [])
    require(isinstance(required_e2e, list) and all(p in ("android", "ios", "web") for p in required_e2e), "Invalid required_e2e")
    for platform in required_e2e:
        e = read_json(work(root) / ("e2e-" + platform + ".json"))
        require(e.get("status") == "PASS" and e.get("digest") == digest and e.get("platform") == platform,
                f"Missing/stale required {platform} E2E")
    for key in ("message", "title", "body"):
        require(isinstance(manifest.get(key), str) and manifest[key].strip(),
                f"Missing delivery {key}")
    files = manifest.get("files")
    require(isinstance(files, list) and all(isinstance(x, str) for x in files)
            and len(files) == len(set(files)), "Expected exact task file list")
    for path in files:
        require(path and not Path(path).is_absolute() and
                Path(path).as_posix() == path and ".." not in Path(path).parts and
                not path.startswith(("-", ".git/", ".flutter-harness/work/")),
                f"Unsafe delivery path: {path}")
    changed = dirty(root)
    require(not changed or set(changed) == set(files),
            "Dirty files differ from explicit task list; no files staged")
    require(not changed or not (set(files) & {".git"}), "Unsafe Git path")
    require(not any(p.startswith((".flutter-harness/work/", ".flutter-harness/previews/")) for p in files), "Local artifacts must not be published")
    repo = origin_repo(root)
    base = c["integration_branch"]
    # Refresh base before publishing; never merge/rebase implicitly.
    git(root, "fetch", "origin", base)
    require(text(git(root, "merge-base", "HEAD", "origin/" + base)) ==
            text(git(root, "rev-parse", "origin/" + base)),
            "Integration branch advanced; reconcile and recheck")
    require(fingerprint(root) == digest, "Candidate changed before publication")
    existing = pr_list(root, repo, name)
    require(not existing or existing.get("baseRefName") == base,
            "Existing PR targets another base")
    identity = {"branch": name, "base": base, "repo": repo, "digest": digest,
                "manifest_digest": manifest_digest(manifest)}
    def checkpoint(stage, **extra):
        atomic_json(work(root) / "delivery-state.json", {**identity, "stage": stage, **extra})
        event(root, stage, **identity, **extra)
    checkpoint("delivery-validated")
    if changed:
        git(root, "--literal-pathspecs", "add", "-A", "--", *files)
        staged = paths(git(root, "diff", "--cached", "--no-renames",
                           "--name-only", "-z", "HEAD", "--"))
        require(set(staged) == set(changed) and
                not git(root, "diff", "--name-only", "-z") and
                not git(root, "ls-files", "-z", "--others", "--exclude-standard") and
                fingerprint(root) == digest, "Index/working candidate mismatch")
        git(root, "commit", "-m", manifest["message"])
    require(not dirty(root) and fingerprint(root) == digest,
            "Commit does not match checked working candidate")
    require(git(root, "diff", "--name-only", "origin/" + base, "HEAD"),
            "No task change to publish")
    head = text(git(root, "rev-parse", "HEAD"))
    checkpoint("delivery-committed", head=head)
    body = work(root) / "pr-body.md"
    summary = ["", "", "## Harness evidence (generated)", f"- Candidate: {digest}", "- Standard check: PASS"]
    for platform in required_e2e:
        summary.append(f"- Required {platform} E2E: PASS")
    expected_body = manifest["body"].rstrip() + "\n".join(summary) + "\n"
    body.write_text(expected_body, encoding="utf-8")
    def matching(pr):
        return (pr and pr.get("headRefOid") == head and
                pr.get("title") == manifest["title"] and
                (pr.get("body") or "").rstrip() == expected_body.rstrip() and
                not pr.get("isDraft"))
    # Recover a completed remote operation even if the previous process died
    # before writing its local receipt. Never republish an identical PR.
    if not existing or existing.get("headRefOid") != head:
        git(root, "push", "-u", "origin", "HEAD:refs/heads/" + name)
    checkpoint("delivery-pushed", head=head)
    if not matching(existing):
        if existing:
            if (existing.get("title") != manifest["title"] or
                    (existing.get("body") or "").rstrip() != expected_body.rstrip()):
                run(root, "gh", "pr", "edit", str(existing["number"]), "--repo", repo,
                    "--title", manifest["title"], "--body-file", str(body))
            if existing.get("isDraft"):
                run(root, "gh", "pr", "ready", str(existing["number"]), "--repo", repo)
        else:
            run(root, "gh", "pr", "create", "--repo", repo, "--base", base,
                "--head", name, "--title", manifest["title"], "--body-file", str(body))
        existing = pr_list(root, repo, name)
    pr = validate_remote_pr(existing, repo, base, name, head)
    require(matching(pr), "Remote PR metadata differs from delivery manifest")
    checkpoint("delivery-remote-verified", head=head, pr=pr["url"])
    require(not dirty(root) and fingerprint(root) == digest and
            text(git(root, "rev-parse", "HEAD")) == head,
            "Candidate changed during delivery")
    result = {**identity, "status": "PASS", "head": head, "pr": pr["url"],
              "checked_at": receipt.get("checked_at"), "delivered_at": int(time.time())}
    atomic_json(work(root) / "delivery-result.json", result)
    checkpoint("delivery-complete", head=head, pr=pr["url"])
    output(**result)


def scaffold(root, name, layers):
    require(re.fullmatch(r"[a-z][a-z0-9_]*", name), "Use snake_case feature name")
    require(layers, "Select needed layers")
    for layer in layers:
        target = root / "lib/features" / name / layer
        require(not any(p.is_symlink() for p in (target, *target.parents) if p != root and root in p.parents), "Symlink in scaffold path")
        target.mkdir(parents=True, exist_ok=True)
        suffix = {"view_models": "view_model", "screens": "screen"}.get(layer)
        if suffix:
            file = target / (name + "_" + suffix + ".dart")
            if not file.exists():
                cls = "".join(part.capitalize() for part in name.split("_"))
                template = root / ".flutter-harness/templates/product/scaffold" / (suffix + ".dart.template")
                file.write_text(template.read_text().replace("@CLASS@", cls), encoding="utf-8")
    output(status="PASS", feature=name, layers=layers)


def launch(root, c, platform, device):
    require(platform != "web" or c["profile"] == "mobile-web", "Web disabled")
    digest = fingerprint(root)
    receipt = work(root) / "runtime.json"
    previous = read_json(receipt) if receipt.exists() else {}
    if platform == "web":
        # Reuse a healthy server only for identical source; no speculative rebuild.
        action = "status" if previous.get("digest") == digest and previous.get("platform") == "web" else "start"
        try:
            result = text(run(root, sys.executable, str(HERE / "web-preview.py"),
                              action, capture=True))
        except Blocked:
            if action != "status":
                raise
            result = text(run(root, sys.executable, str(HERE / "web-preview.py"),
                              "start", capture=True))
        match = re.search(r"READY Web URL: (http://127\.0\.0\.1:\d+/)", result)
        require(match, "Web preview missing readiness URL")
        device = match.group(1)
    else:
        require(device and not device.startswith("-"), "Explicit emulator/simulator ID required")
        if platform == "android":
            require(text(run(root,"adb","-s",device,"shell","getprop","ro.kernel.qemu",capture=True)) == "1", "Use an Android emulator, not a physical device")
        else:
            run(root,"xcrun","simctl","getenv",device,"HOME",capture=True)
        run(root, "flutter", "run", "--no-resident", "-d", device,
            log=work(root) / "launch.log", timeout=900)
    require(fingerprint(root) == digest, "Runtime source changed during launch")
    atomic_json(receipt, {"digest": digest, "platform": platform, "device": device})
    output(status="READY", platform=platform, target=device, digest=digest)


def capture(root, platform, label, theme, viewport):
    require(re.fullmatch(r"[a-zA-Z0-9_-]+", label), "Invalid capture label")
    current = read_json(work(root) / "runtime.json")
    digest = fingerprint(root)
    require(current.get("digest") == digest and current.get("platform") == platform,
            "Launch this candidate/platform before capture")
    device = current["device"]
    directory = root / ".flutter-harness/previews" / digest
    directory.mkdir(parents=True, exist_ok=True)
    image = directory / (label + "-" + platform + "-" + theme + ".png")
    image.unlink(missing_ok=True)
    if platform == "android":
        # Explicit target, not an arbitrary attached device. Theme label is
        # requested metadata; the reviewer must inspect the actual image.
        run(root, "adb", "-s", device, "shell", "cmd", "uimode", "night",
            "yes" if theme == "dark" else "no")
        time.sleep(1)
        image.write_bytes(run(root, "adb", "-s", device, "exec-out", "screencap",
                              "-p", capture=True))
    elif platform == "ios":
        run(root, "xcrun", "simctl", "ui", device, "appearance", theme)
        time.sleep(1)
        run(root, "xcrun", "simctl", "io", device, "screenshot", str(image))
    else:
        require(re.fullmatch(r"\d+,\d+", viewport), "Viewport must be width,height")
        run(root, "npx", "--no-install", "playwright", "screenshot",
            "--viewport-size=" + viewport, "--color-scheme=" + theme, "--wait-for-timeout=1500",
            device, str(image))
    data = image.read_bytes()
    require(data.startswith(PNG) and len(data) > 24 and fingerprint(root) == digest,
            "Invalid or stale capture")
    atomic_json(image.with_suffix(".json"), {"digest": digest, "platform": platform,
                "target": device, "theme": theme, "viewport": viewport if platform == "web" else None,
                "sha256": hashlib.sha256(data).hexdigest(), "path": str(image)})
    output(status="CAPTURED", path=str(image), digest=digest)


def visual_evidence(root):
    digest = fingerprint(root)
    folder = root / ".flutter-harness/previews" / digest
    valid = []
    for metadata in sorted(folder.glob("*.json")):
        try:
            item = read_json(metadata)
            image = metadata.with_suffix(".png")
            data = image.read_bytes()
            if (item.get("digest") == digest and item.get("platform") in ("android","ios","web")
                and item.get("theme") in ("light","dark")
                and data.startswith(PNG) and hashlib.sha256(data).hexdigest() == item.get("sha256")):
                valid.append(item)
        except (OSError, ValueError, Blocked):
            continue
    groups = {(x["platform"], x.get("target"), x.get("viewport")) for x in valid}
    require(any({x["theme"] for x in valid if (x["platform"], x.get("target"), x.get("viewport")) == key}
                == {"light","dark"} for key in groups),
            "Current candidate needs light/dark captures from one representative target")
    output(status="PASS", digest=digest, captures=valid)


def e2e(root, platform, scenario, device):
    path = Path(scenario)
    require(not path.is_absolute() and ".." not in path.parts and
            (root / path).is_file() and not (root / path).is_symlink(),
            "Expected a project-local scenario file")
    digest = fingerprint(root)
    runtime = read_json(work(root) / "runtime.json")
    require(runtime.get("digest") == digest and runtime.get("platform") == platform,
            "Launch the current candidate before E2E")
    environment = dict(os.environ)
    if platform == "web":
        environment["HARNESS_WEB_URL"] = runtime["device"]
        require(path.parts[0] in ("e2e", "playwright", "tests"), "Use a committed Playwright scenario")
        args = ("npx", "--no-install", "playwright", "test", scenario)
    else:
        require(device and not device.startswith("-") and path.parts[0] == "maestro",
                "Maestro scenario and explicit device required")
        require(device == runtime["device"], "E2E device differs from launched target")
        args = ("bash", str(HERE / "maestro.sh"), "--device", device, "test", scenario)
    log = work(root) / ("e2e-" + platform + ".log")
    receipt = log.with_suffix(".json")
    receipt.unlink(missing_ok=True)
    run(root, *args, log=log, timeout=600, env=environment)
    require(fingerprint(root) == digest, "E2E candidate changed")
    atomic_json(receipt, {"status": "PASS", "digest": digest, "scenario": scenario,
                          "platform": platform, "device": device, "log": str(log)})
    output(status="PASS", receipt=str(receipt))


def usage(root, sessions, *, emit=True):
    with tempfile.TemporaryDirectory() as tmp:
        exports = []
        for i, session in enumerate(sessions):
            path = Path(tmp) / f"{i}.json"
            path.write_bytes(run(root, "opencode", "session", "export", session,
                                 "--sanitize", capture=True, timeout=120))
            exports.append(str(path))
        summary = json.loads(run(root, sys.executable, str(HERE / "session-usage.py"), "--json", *exports, capture=True))
        if emit:
            print(json.dumps(summary, indent=2))
        return summary


def diagnostics(root, sessions):
    """One safe, compact report; sanitized exports are temporary."""
    summary = usage(root, sessions, emit=False)
    data = {"usage": summary, "artifacts": {}}
    for name in ("check.json", "delivery-state.json", "delivery-result.json", "sessions.json"):
        path = work(root) / name
        if path.is_file():
            data["artifacts"][name] = read_json(path)
    path = work(root) / "lifecycle.jsonl"
    events = []
    if path.is_file():
        for line in path.read_text(encoding="utf-8").splitlines():
            item = json.loads(line)
            if item.get("session") in sessions or any(
                    start <= item.get("at", 0) <= end
                    for start, end in summary["session_windows"]):
                events.append(item)
    data["events"] = events
    target = work(root) / "diagnostics.json"
    atomic_json(target, data)
    output(status="PASS", report=str(target))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", default=".", type=Path)
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("doctor")
    p.add_argument("operation", choices=("check","deliver","android","ios","web","e2e"))
    p = sub.add_parser("begin")
    p.add_argument("branch")
    for cmd in ("check","ci","deliver","verify","completion","status","fingerprint","stop-preview","adopt","visual-evidence"):
        sub.add_parser(cmd)
    p = sub.add_parser("scaffold")
    p.add_argument("name")
    p.add_argument("layers", nargs="+", choices=("models","repositories","services","view_models","screens","widgets","use_cases"))
    p = sub.add_parser("launch")
    p.add_argument("platform", choices=("android","ios","web"))
    p.add_argument("--device")
    p = sub.add_parser("capture")
    p.add_argument("platform", choices=("android","ios","web"))
    p.add_argument("label")
    p.add_argument("theme", choices=("light","dark"))
    p.add_argument("--viewport", default="390,844")
    p = sub.add_parser("e2e")
    p.add_argument("platform", choices=("android","ios","web"))
    p.add_argument("scenario")
    p.add_argument("--device")
    for cmd in ("usage", "diagnostics"):
        p = sub.add_parser(cmd)
        p.add_argument("sessions", nargs="*")
    a = parser.parse_args()
    root = a.project.resolve()
    try:
        require((root / "pubspec.yaml").is_file(), "Expected Flutter project")
        if a.command == "fingerprint":
            print(fingerprint(root))
            return 0
        c = config(root)
        if a.command == "doctor":
            doctor(root, c, a.operation)
        elif a.command == "begin":
            begin(root, c, a.branch)
        elif a.command == "check":
            check(root, c)
        elif a.command == "ci":
            run(root, sys.executable, str(HERE / "validate-opencode.py"), "opencode.jsonc", c["profile"])
            require((root / ".flutter-harness/product.json").is_file(), "Missing product policy configuration")
            run(root, "flutter", "pub", "get", log=work(root)/"pub-get.log")
            run(root, "bash", str(HERE/"check.sh"), ".", "standard", c["profile"])
            require(not git(root,"diff","--name-only","HEAD","--","pubspec.lock"), "Dependency lock changed in CI")
        elif a.command == "deliver":
            deliver(root, c)
        elif a.command == "verify":
            verify(root, c)
        elif a.command == "completion":
            output(**completion(root, c))
        elif a.command == "status":
            receipt = work(root) / "check.json"
            digest = fingerprint(root)
            output(branch=text(git(root,"branch","--show-current")),
                   base=c["integration_branch"], changed=dirty(root), digest=digest,
                   checked=receipt.exists() and read_json(receipt).get("digest")==digest)
        elif a.command == "scaffold":
            scaffold(root, a.name, a.layers)
        elif a.command == "adopt":
            run(root, sys.executable, str(HERE / "init-product.py"), ".")
        elif a.command == "launch":
            launch(root, c, a.platform, a.device)
        elif a.command == "capture":
            capture(root, a.platform, a.label, a.theme, a.viewport)
        elif a.command == "visual-evidence":
            visual_evidence(root)
        elif a.command == "stop-preview":
            run(root, sys.executable, str(HERE / "web-preview.py"), "stop")
        elif a.command == "e2e":
            e2e(root, a.platform, a.scenario, a.device)
        elif a.command in ("usage", "diagnostics"):
            sessions = a.sessions or read_json(work(root)/"sessions.json")["sessions"]
            require(sessions, "No recorded sessions")
            if a.command == "diagnostics":
                diagnostics(root, sessions)
            else:
                usage(root, sessions)
        return 0
    except (Blocked, OSError, ValueError, KeyError, subprocess.TimeoutExpired) as exc:
        if a.command in ("check", "deliver"):
            try:
                event(root, a.command + "-blocked", error_type=type(exc).__name__)
            except OSError:
                pass
        print(f"BLOCKED: {exc}", file=sys.stderr)
        return 3


if __name__ == "__main__":
    sys.exit(main())
