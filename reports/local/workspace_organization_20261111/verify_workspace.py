"""Read-only checks of preserved files, Git history, archives, and entry links."""
import ast
from concurrent.futures import ThreadPoolExecutor
import gzip
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
import tarfile
from urllib.parse import unquote
import zipfile

ROOT = Path(__file__).resolve().parents[3]
RAW = ROOT / "work/workspace_organization_20261111"
REPORT = Path(__file__).resolve().parent
before = json.loads((RAW / "before_files.json").read_text(encoding="utf-8"))
plan = json.loads((REPORT / "migration_plan.json").read_text(encoding="utf-8"))
git_before = json.loads((RAW / "before_git.json").read_text(encoding="utf-8"))
edited = {".gitignore", "README.md", "GOAL.md", "STATUS.md", "WORKLOG.md", "docs/NEXT_STEPS.md",
          "experiments/ic_eda_20261111_backend/LAB_RUNBOOK.md",
          "experiments/ic_eda_20261110/REPORT.md", "experiments/ic_eda_20261110/scripts/verify_results.py",
          "scripts/h0_vm_smoke.sh"}


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def relocated(name):
    for move in plan["moves"]:
        if name == move["source"] or name.startswith(move["source"] + "/"):
            return move["target"] + name[len(move["source"]):]
    return name


def check_file(row):
    target = ROOT / relocated(row["path"])
    assert target.is_file(), target
    actual = digest(target)
    if row["path"] in edited:
        return {"original": row["path"], "current": target.relative_to(ROOT).as_posix(),
                "before_sha256": row["sha256"], "after_sha256": actual}
    assert actual == row["sha256"], target
    assert target.stat().st_size == row["bytes"], target
    return None


with ThreadPoolExecutor(max_workers=4) as pool:
    changed = [result for result in pool.map(check_file, before) if result]


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args], text=True).strip()


refs = dict(line.split(" ", 1)[::-1] for line in git("show-ref").splitlines())
branch = git("symbolic-ref", "HEAD")
for line in git_before["refs"].splitlines():
    old_hash, ref = line.split(" ", 1)
    if ref == branch:
        subprocess.run(["git", "-C", str(ROOT), "merge-base", "--is-ancestor", old_hash, refs[ref]], check=True)
    else:
        assert refs[ref] == old_hash, ref
for label, commit in git_before["commits"].items():
    assert git("rev-parse", label) == commit, label
    if label not in ("main", "origin/main"):
        subprocess.run(["git", "-C", str(ROOT), "merge-base", "--is-ancestor", commit, "HEAD"], check=True)
current_worktrees = git("worktree", "list", "--porcelain").replace(git("rev-parse", "HEAD"), git_before["head"])
current_worktree_state = [line for line in current_worktrees.splitlines() if not line.startswith("worktree ")]
original_worktree_state = [line for line in git_before["worktrees"].strip().splitlines() if not line.startswith("worktree ")]
assert current_worktree_state == original_worktree_state
assert Path(git("rev-parse", "--show-toplevel")).resolve() == ROOT
current_status = set(git("status", "--porcelain=v1", "-uall").splitlines())
untracked = [line for line in git_before["status"].splitlines() if line.startswith("?? ")]
assert all(line in current_status for line in untracked), "Original untracked status changed"
assert (ROOT / "scripts/h0_vm_smoke.sh").read_bytes() == subprocess.check_output(
    ["git", "-C", str(ROOT), "show", "main:scripts/h0_vm_smoke.sh"])
subprocess.run(["git", "-C", str(ROOT), "diff", "--exit-code", "main", "--", "rtl", "student_release",
                "model", "scripts", "synth", "constraints", "tb"], check=True)

archives = []
archive_paths = sorted((ROOT / "experiments").rglob("*.tar.gz"))
archive_paths += [ROOT / "deliverables/2026-11-11_backend_lab/LAB_INPUTS.tar.gz", RAW / "safety_originals.tar.gz"]
for path in archive_paths:
    # Reading through EOF checks the gzip CRC, including its trailer.
    with gzip.open(path, "rb") as stream:
        while stream.read(1024 * 1024):
            pass
    with tarfile.open(path) as archive:
        count = 0
        for member in archive:
            if member.isfile():
                with archive.extractfile(member) as stream:
                    hashlib.file_digest(stream, "sha256")
                count += 1
    archives.append({"path": path.relative_to(ROOT).as_posix(), "files": count, "sha256": digest(path)})

manifests = [ROOT / "experiments/ic_eda_20261110/night_opt/evidence" / name
             for name in ("netlist_archive.json", "module_archive.json")]
manifests.append(ROOT / "experiments/ic_eda_20261111_backend/evidence/artifacts.json")
members_verified = 0
for listing in manifests:
    data = json.loads(listing.read_text())
    archive_path = listing.parent / data["archive"]
    assert digest(archive_path) == data["sha256"], archive_path
    with tarfile.open(archive_path) as archive:
        for row in data["files"]:
            member = archive.getmember(row["path"])
            assert member.size == row["bytes"], row["path"]
            with archive.extractfile(member) as stream:
                assert hashlib.file_digest(stream, "sha256").hexdigest() == row["sha256"], row["path"]
            local = listing.parent / row["path"]
            assert digest(local) == row["sha256"], local
            members_verified += 1

bundle = ROOT / "deliverables/2026-11-11_backend_lab/LAB_INPUTS.tar.gz"
assert digest(bundle) == (bundle.parent / (bundle.name + ".sha256")).read_text().split()[0]
assert digest(bundle) == digest(ROOT / "experiments/ic_eda_20261111_backend/evidence/LAB_INPUTS.tar.gz")
before_by_path = {row["path"]: row for row in before}
bundle_files = 0
with tarfile.open(bundle) as archive:
    for member in archive:
        path = PurePosixPath(member.name)
        assert not path.is_absolute() and ".." not in path.parts, member.name
        if member.isfile():
            with archive.extractfile(member) as stream:
                assert hashlib.file_digest(stream, "sha256").hexdigest() == before_by_path[path.as_posix()]["sha256"], member.name
            bundle_files += 1

docx = ROOT / "archive/reference/2026-10_course_plan/plan.docx"
with zipfile.ZipFile(docx) as archive:
    assert archive.testzip() is None

documents = [ROOT / name for name in ("README.md", "GOAL.md", "STATUS.md", "docs/NEXT_STEPS.md",
             "experiments/README.md", "experiments/active/README.md", "experiments/archive/README.md",
             "experiments/ic_eda_20261110/README.md", "experiments/ic_eda_20261110/REPORT.md",
             "experiments/ic_eda_20261111_backend/LAB_RUNBOOK.md", "archive/README.md",
             "deliverables/README.md", "deliverables/2026-11-11_backend_lab/README.md",
             "experiments/archive/2026-11-10_prn_environment/README.md",
             "experiments/archive/2026-11-10_prn_environment/REPORT.md")]
documents += [REPORT / "README.md", ROOT.parents[1] / "README.md"]
links_checked = 0
for document in documents:
    for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", document.read_text(encoding="utf-8")):
        if re.match(r"https?://|#", target):
            continue
        relative = unquote(target.split("#", 1)[0].strip("<>"))
        assert (document.parent / relative).exists(), (document, target)
        links_checked += 1

for directory in (ROOT / "experiments/ic_eda_20261111_backend/scripts", ROOT / "experiments/ic_eda_20261111_backend/lab"):
    for script in directory.glob("*.py"):
        ast.parse(script.read_text(encoding="utf-8"), filename=str(script))
ast.parse((ROOT / "experiments/archive/2026-11-10_prn_environment/scripts/verify_results.py").read_text(encoding="utf-8"))

result = {"original_files_checked": len(before), "byte_identical_files": len(before) - len(changed),
          "intentional_text_edits": changed, "lost_files": 0,
          "original_untracked_files_preserved": len(untracked), "git_refs_and_history": "PASS",
          "main": git("rev-parse", "main"), "technical_result_commit": git_before["head"],
          "archive_count": len(archives), "archives": archives,
          "manifest_members_and_local_originals_verified": members_verified,
          "lab_bundle_files_matching_before_inventory": bundle_files,
          "markdown_links_checked": links_checked, "python_ast": "PASS", "docx_zip_integrity": "PASS",
          "native_dc_reload_this_task": "NOT_RUN", "synthesis_input_and_cache_paths": "UNCHANGED"}
(REPORT / "verification.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps({key: value for key, value in result.items() if key not in ("intentional_text_edits", "archives")}, ensure_ascii=False, indent=2))
