"""Fetch public commit-pinned fixtures into ignored .local; never execute them.

Existing fixtures must have the exact origin, commit and clean tracked/untracked
contents. No reset, clean, overwrite, live-mod installation or deletion occurs.
--check verifies existing fixtures without a network request.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def git(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-c", "core.autocrlf=false", "-c", "core.longpaths=true", *args],
                                   cwd=root, text=True, encoding="utf-8").strip()


def validate_lock(lock: dict, inventory: dict) -> list[dict]:
    entries = lock["dependencies"]
    expected = {(item["folder"], item["mod_id"]) for item in inventory["dependency_sources"]}
    if len(entries) != len(expected) or {(item["folder"], item["mod_id"]) for item in entries} != expected:
        raise ValueError("Lock and selected dependency inventory differ")
    for item in entries:
        if (not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9 _-]*", item["folder"])
                or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]*", item["mod_id"])
                or not re.fullmatch(r"https://github.com/B47ANCE/[A-Za-z0-9_-]+\.git", item["url"])
                or not re.fullmatch(r"[0-9a-f]{40}", item["commit"])):
            raise ValueError("Invalid dependency lock identity, path, origin or full commit SHA")
    if len({item["folder"].lower() for item in entries}) != len(entries):
        raise ValueError("Case-colliding dependency folders")
    return entries


def prepare(root: Path, check_only: bool = False) -> list[dict]:
    entries = validate_lock(json.loads((root / "tests/dependencies.lock.json").read_text()),
                            json.loads((root / "SOURCE_INVENTORY.json").read_text()))
    destination = root / ".local/ci-dependencies"
    if destination.is_symlink() or destination.resolve() != root.resolve() / ".local/ci-dependencies":
        raise ValueError("Fixture root must stay inside this checkout")
    results = []
    for entry in entries:
        target = destination / entry["folder"]
        if target.is_symlink() or target.resolve() != destination.resolve() / entry["folder"]:
            raise ValueError("Fixture path escaped the fixture root")
        if not target.exists():
            if check_only:
                raise ValueError("Missing locked fixture: " + entry["folder"])
            destination.mkdir(parents=True, exist_ok=True)
            subprocess.run(["git", "clone", "--no-checkout", "--filter=blob:none", entry["url"], str(target)], check=True)
            git(target, "fetch", "--depth=1", "origin", entry["commit"])
            git(target, "checkout", "--detach", entry["commit"])
        if git(target, "remote", "get-url", "origin") != entry["url"]:
            raise ValueError("Fixture origin differs: " + entry["folder"])
        if git(target, "rev-parse", "HEAD") != entry["commit"] or git(target, "status", "--porcelain", "--untracked-files=all", "--ignored"):
            raise ValueError("Fixture is dirty or at a different commit; preserved: " + entry["folder"])
        source = target / "src" / entry["mod_id"] / "42"
        values = dict(line.split("=", 1) for line in (source / "mod.info").read_text(encoding="utf-8-sig").splitlines() if "=" in line)
        if values.get("id") != entry["mod_id"]:
            raise ValueError("Fixture Mod ID differs: " + entry["folder"])
        results.append({**entry, "version": values.get("modversion"),
                        "git_source_tree": git(target, "rev-parse", f"HEAD:src/{entry['mod_id']}/42")})
    return results


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    try:
        print(json.dumps(prepare(ROOT, args.check), indent=2))
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Fixture preparation FAIL: {error}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
