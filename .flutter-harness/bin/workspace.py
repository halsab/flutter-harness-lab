#!/usr/bin/env python3
"""Owner-side worktrees and ordered, non-publishing integration checks."""
import argparse
from contextlib import contextmanager, ExitStack
import fcntl
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
sys.dont_write_bytecode=True
import harness as h

LIMIT=3

def common(root):
    return Path(h.text(h.git(root,"rev-parse","--path-format=absolute","--git-common-dir"))).resolve()

def registry(root):
    return common(root)/"flutter-harness"

@contextmanager
def lock(path):
    path.parent.mkdir(parents=True,exist_ok=True)
    with path.open("a") as stream:
        try:
            fcntl.flock(stream,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:
            raise h.Blocked("Workspace operation already active: "+path.name)
        yield

def entries(root):
    path=registry(root)/"workspaces.json"
    return h.read_json(path) if path.is_file() else {}

def save(root,data):
    h.atomic_json(registry(root)/"workspaces.json",data)

def task_path(root,name):
    h.require(re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}",name),"Use a simple unique task name")
    return root.parent/(root.name+".worktrees")/name

def create(root,c,name,only=None):
    path=task_path(root,name)
    h.require(name not in (c["integration_branch"],"main","master","app","develop"),"Unsafe task branch")
    with lock(registry(root)/"manager.lock"):
        data=entries(root)
        h.require(name not in data and not path.exists(),"Task already exists; use workspace run")
        h.require(len(data)<LIMIT,"Three workspaces allocated; clean a merged workspace")
        base=h.fetch_base(root,c["integration_branch"])
        h.installed_revision(root,c,base_ref=base)
        unavailable=[]
        for platform,device in h.runtime_targets(root,c,only):
            try:
                with h.target_lock("slot",platform):
                    if h.slot_owner(platform):
                        unavailable.append(platform+": occupied")
                        continue
                    try:
                        h.probe_runtime(root,platform,device)
                    except (h.Blocked,OSError,ValueError,subprocess.TimeoutExpired):
                        unavailable.append(platform+": unavailable")
                        continue
                    path.parent.mkdir(parents=True,exist_ok=True)
                    h.git(root,"worktree","add","-b",name,str(path),base)
                    lease={"root":str(path.resolve()),"branch":name,"platform":platform,"device":device,
                           "common":str(common(root)),"revision":c["revision"]}
                    # Retain work on interruption. Never steal or auto-delete a lease.
                    h.atomic_json(h.work(path)/"workspace.json",lease)
                    h.atomic_json(h.slot_path(platform),lease)
                    data[name]=lease
                    save(root,data)
                    h.output(status="READY",**lease)
                    return lease
            except h.Blocked as exc:
                if "Runtime target busy" not in str(exc):
                    raise
                unavailable.append(platform+": busy")
        raise h.Blocked("No available eligible runtime slot: "+("; ".join(unavailable) or "no device"))

def lookup(root,name):
    task_path(root,name)
    data=entries(root)
    h.require(name in data,"Unknown managed workspace: "+name)
    lease=data[name]
    path=Path(lease["root"])
    h.require(path==task_path(root,name).resolve() and common(path)==common(root)
              and h.workspace_assignment(path)==lease,"Workspace identity mismatch")
    return path,lease

def session_lock(root,name):
    return registry(root)/("session-"+name+".lock")

def start(root,name):
    path,lease=lookup(root,name)
    with lock(session_lock(root,name)):
        h.require(h.slot_owner(lease["platform"])==lease,"Workspace reservation missing")
        h.require(h.text(h.git(path,"branch","--show-current"))==name,"Assigned branch changed")
        h.installed_revision(path,h.config(path),lease["revision"])
        return subprocess.call(["opencode"],cwd=path,env=dict(os.environ,HARNESS_WORKSPACE_ROOT=str(path)))

def pr_state(root,repo,number):
    return json.loads(h.run(root,"gh","pr","view",str(number),"--repo",repo,
              "--json","number,state,headRefOid,headRefName,baseRefName,isCrossRepository,isDraft,url",
              capture=True,timeout=60))

def verify_pr(root,repo,base,item,state):
    current=pr_state(root,repo,item["number"])
    h.require(current.get("state")==state and current.get("headRefOid")==item["head"]
              and current.get("headRefName")==item["branch"] and current.get("baseRefName")==base
              and current.get("isCrossRepository") is False and current.get("isDraft") is False,
              "PR state/head changed: "+item["branch"])
    return current

def delivered(root,name,repo,base):
    path,_=lookup(root,name)
    result=h.completion(path,h.config(path))
    h.require(result["repo"]==repo and result["base"]==base,"Delivery repository/base mismatch")
    match=re.fullmatch(r"https://github.com/"+re.escape(repo)+r"/pull/(\d+)",result["pr"],re.I)
    h.require(match,"Invalid PR identity")
    item={"branch":name,"head":result["head"],"number":int(match.group(1)),"url":result["pr"]}
    verify_pr(root,repo,base,item,"OPEN")
    return item

def tree(root,ref="HEAD"):
    return h.text(h.git(root,"rev-parse",ref+"^{tree}"))

def integration_check(root,c,names):
    h.require(1<=len(names)<=LIMIT and len(set(names))==len(names),"Specify one to three distinct tasks in merge order")
    with lock(registry(root)/"manager.lock"),ExitStack() as stack:
        for name in sorted(names):
            task_path(root,name)
            stack.enter_context(lock(session_lock(root,name)))
        return integration_locked(root,c,names)

def integration_locked(root,c,names):
    base=c["integration_branch"]
    repo=h.origin_repo(root)
    base_head=h.fetch_base(root,base)
    h.installed_revision(root,c,base_ref=base_head)
    folder=registry(root)
    report=folder/"integration.json"
    report.unlink(missing_ok=True)
    items=[delivered(root,n,repo,base) for n in names]
    result={"status":"RUNNING","repo":repo,"base":base,"base_head":base_head,
            "base_tree":tree(root,base_head),"items":items,"checked":0}
    h.atomic_json(report,result)
    logdir=Path(tempfile.mkdtemp(prefix="integration-",dir=folder))
    result["logs"]=str(logdir)
    with tempfile.TemporaryDirectory(prefix="harness-integration-") as tmp:
        candidate=Path(tmp)/"candidate"
        h.git(root,"worktree","add","--detach",str(candidate),base_head)
        try:
            for index,item in enumerate(items):
                log=logdir/(str(index+1)+"-"+item["branch"]+".log")
                result["current"]=item["branch"]
                h.atomic_json(report,result)
                with log.open("wb") as stream:
                    merged=subprocess.run(["git","-c","user.name=Harness Integration","-c",
                          "user.email=harness@example.invalid","merge","--no-ff","--no-edit",item["head"]],
                          cwd=candidate,stdout=stream,stderr=subprocess.STDOUT,timeout=60)
                    h.require(merged.returncode==0,"Integration conflict at "+item["branch"]+"; see "+str(log))
                    checked=subprocess.run([sys.executable,str(candidate/".flutter-harness/bin/harness.py"),"ci"],
                                           cwd=candidate,stdout=stream,stderr=subprocess.STDOUT,timeout=600)
                    h.require(checked.returncode==0,"Combined verification failed at "+item["branch"]+"; see "+str(log))
                h.require(not h.dirty(candidate),"Combined verification changed tracked/nonignored files")
                item["combined_tree"]=tree(candidate)
                result["checked"]=index+1
                h.atomic_json(report,result)
            h.require(h.fetch_base(root,base)==base_head,"Integration base advanced during verification")
            for item in items:
                verify_pr(root,repo,base,item,"OPEN")
            result["status"]="PASS"
        except BaseException:
            result["status"]="BLOCKED"
            raise
        finally:
            h.atomic_json(report,result)
            # Force-remove only our disposable checkout, never a task workspace.
            h.git(root,"worktree","remove","--force",str(candidate))
    h.output(**result)
    return result

def next_pr(root,c):
    report=h.read_json(registry(root)/"integration.json")
    h.require(report.get("status")=="PASS" and report.get("base")==c["integration_branch"]
              and report.get("repo")==h.origin_repo(root),"No valid integration batch; run verify-batch")
    expected=report["base_tree"]
    remaining=[]
    for item in report["items"]:
        current=pr_state(root,report["repo"],item["number"])
        if current.get("state")=="MERGED" and not remaining:
            verify_pr(root,report["repo"],report["base"],item,"MERGED")
            expected=item["combined_tree"]
        else:
            verify_pr(root,report["repo"],report["base"],item,"OPEN")
            remaining.append(item)
    actual=h.fetch_base(root,report["base"])
    h.require(tree(root,actual)==expected,"Base tree differs from verified merge prefix; revalidate remaining batch")
    if not remaining:
        h.output(status="COMPLETE")
        return None
    item=remaining[0]
    h.output(status="READY_FOR_OWNER",**item,merge_command=["gh","pr","merge",str(item["number"]),"--squash","--match-head-commit",item["head"]])
    return item

def clean(root,c,name):
    with lock(registry(root)/"manager.lock"),lock(session_lock(root,name)):
        path,lease=lookup(root,name)
        h.require(not h.dirty(path),"Workspace has uncommitted work; preserve it")
        repo=h.origin_repo(root)
        result=h.completion(path,h.config(path))
        match=re.fullmatch(r"https://github.com/"+re.escape(repo)+r"/pull/(\d+)",result["pr"],re.I)
        h.require(match,"Invalid PR identity")
        item={"number":int(match.group(1)),"head":result["head"],"branch":name}
        verify_pr(root,repo,c["integration_branch"],item,"MERGED")
        platform=lease["platform"]
        with h.target_lock("slot",platform):
            h.require(h.slot_owner(platform)==lease,"Reservation changed; refusing cleanup")
            if platform=="web":
                h.run(path,sys.executable,str(path/".flutter-harness/bin/web-preview.py"),"stop")
            h.git(root,"worktree","remove",str(path))
            h.slot_path(platform).unlink()
            data=entries(root)
            del data[name]
            save(root,data)
        h.output(status="CLEANED",branch=name)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    sub=p.add_subparsers(dest="cmd",required=True)
    a=sub.add_parser("create")
    a.add_argument("name")
    a.add_argument("--only",choices=("ios","android","web"))
    for cmd in ("run","clean"):
        a=sub.add_parser(cmd)
        a.add_argument("name")
    sub.add_parser("list")
    a=sub.add_parser("verify-batch")
    a.add_argument("names",nargs="+")
    sub.add_parser("next")
    a=p.parse_args()
    try:
        root=Path(h.text(h.git(Path.cwd(),"rev-parse","--show-toplevel"))).resolve()
        h.require((root/".git").is_dir(),"Run workspace manager from primary project checkout")
        c=h.config(root)
        h.installed_revision(root,c)
        if a.cmd=="create": create(root,c,a.name,a.only)
        elif a.cmd=="run": return start(root,a.name)
        elif a.cmd=="list": h.output(workspaces=entries(root))
        elif a.cmd=="verify-batch": integration_check(root,c,a.names)
        elif a.cmd=="next": next_pr(root,c)
        elif a.cmd=="clean": clean(root,c,a.name)
        return 0
    except (h.Blocked,OSError,ValueError,KeyError,subprocess.TimeoutExpired) as exc:
        print("BLOCKED: "+str(exc),file=sys.stderr)
        return 3

if __name__=="__main__":
    sys.exit(main())
