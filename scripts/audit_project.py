"""Read-only offline source, packaging, localization, and staged-file inventory.

--output saves a portable evidence snapshot. No extraction, packaging, deployment,
network connection, or game execution occurs. Findings require human interpretation.
"""
from __future__ import annotations

import argparse
from datetime import date
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src/ProjectNightfall/42"
COPY = ROOT / "Contents/mods/ProjectNightfall/42"


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def tree(root: Path) -> dict[str, str]:
    return {path.relative_to(root).as_posix(): digest(path.read_bytes())
            for path in sorted(root.rglob("*")) if path.is_file()}


def staged_audit() -> dict:
    paths = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
    paths = [path for path in paths if path]
    denied = []
    secrets = []
    patterns = [r"gh[pousr]_[A-Za-z0-9_]{20,}", r"github_pat_[A-Za-z0-9_]{20,}",
                r"AKIA[0-9A-Z]{16}", r"-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----",
                r"(?i)(?:password|api_key|access_token|secret_key)\s*[:=]\s*[\"'][^\"'\s]{8,}[\"']"]
    for path in paths:
        name = PurePosixPath(path)
        if name.parts[0] in {".agents", ".codex", ".local", "dist", "workshop"} or name.suffix.lower() in {".jar", ".zip", ".log", ".blend1"} or name.name in {"local.settings.json", ".env", "Update-Workshop.ps1", ".steamcmd-last-upload.sha256"} or name.name.startswith(("console", "server-console")):
            denied.append(path)
        data = subprocess.check_output(["git", "show", ":" + path], cwd=ROOT)
        if b"\0" not in data:
            text = data.decode("utf-8", errors="replace")
            if any(re.search(pattern, text) for pattern in patterns):
                secrets.append(path)
    return {"indexed_files": len(paths), "denied_paths": denied, "potential_secret_paths": secrets,
            "scope": "Git index, heuristic patterns and path checks; not a comprehensive secret detector"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    left, right = tree(SOURCE), tree(COPY)
    report = {"date": date.today().isoformat(), "version": (ROOT / "VERSION").read_text().strip(),
              "environment": "offline Python and Lua 5.1; no PZ or dedicated runtime evidence",
              "source_files": len(left), "packaging_copy_files": len(right),
              "source_tree_sha256": digest(json.dumps(left, sort_keys=True).encode()),
              "packaging_copy_tree_sha256": digest(json.dumps(right, sort_keys=True).encode()),
              "copy_missing": sorted(left.keys() - right.keys()),
              "copy_extra": sorted(right.keys() - left.keys()),
              "copy_changed": [path for path in sorted(left.keys() & right.keys()) if left[path] != right[path]]}
    collisions = []
    for name, paths in (("source", left), ("packaging_copy", right)):
        seen = {}
        for path in paths:
            if path.lower() in seen and seen[path.lower()] != path:
                collisions.append([name, seen[path.lower()], path])
            seen[path.lower()] = path
    report["case_collisions"] = collisions
    module_index = set()
    roots = [SOURCE / "media/lua"]
    for folder, mod_id in (("Project MORTIS", "ProjectMORTIS"), ("lightWorks", "lightWorks"),
                           ("powerWorks", "powerWorks"), ("medWorks", "medWorks"),
                           ("experienceWorks", "experienceWorks")):
        roots.append(ROOT.parent / folder / "src" / mod_id / "42/media/lua")
    for root in roots:
        for side in ("shared", "client", "server"):
            base = root / side
            module_index.update(path.relative_to(base).with_suffix("").as_posix()
                                for path in base.rglob("*.lua"))
    folded_modules = {name.lower(): name for name in module_index}
    require_errors, vanilla_unchecked = [], set()
    for path in SOURCE.rglob("*.lua"):
        text = path.read_text(encoding="utf-8-sig")
        for name in re.findall(r"require\s*\(?\s*[\"']([^\"']+)[\"']", text):
            if name in module_index:
                continue
            if name.lower() in folded_modules:
                require_errors.append({"path": path.relative_to(ROOT).as_posix(), "require": name,
                                       "actual": folded_modules[name.lower()]})
            elif name.split("/")[0] in {"ProjectNightfall", "Mortis", "lightWorks", "powerWorks", "medWorks", "experienceWorks"}:
                require_errors.append({"path": path.relative_to(ROOT).as_posix(), "missing": name})
            else:
                vanilla_unchecked.add(name)
    report["requires"] = {"family_module_errors": require_errors, "vanilla_modules_not_resolved_by_this_check": sorted(vanilla_unchecked),
                          "scope": "source and sibling family modules only; exact filename case, not native exposure or load-order proof"}
    report["non_lua_runtime_dependencies"] = [path for path in left if PurePosixPath(path).suffix.lower() in {".java", ".jar", ".class", ".dll", ".exe"}]
    translations = SOURCE / "media/lua/shared/Translate"
    languages = sorted(path.name for path in translations.iterdir() if path.is_dir())
    localization_errors = []
    english = {path.name: json.loads(path.read_text(encoding="utf-8-sig")) for path in (translations / "EN").glob("*.json")}
    equal_english = 0
    for language in languages:
        for name, expected in english.items():
            path = translations / language / name
            try:
                values = json.loads(path.read_text(encoding="utf-8-sig"))
                if set(values) != set(expected):
                    localization_errors.append(f"{language}/{name}: English key parity differs")
                if language != "EN":
                    equal_english += sum(values.get(key) == value for key, value in expected.items())
            except (OSError, ValueError) as error:
                localization_errors.append(f"{language}/{name}: {type(error).__name__}")
    report["localization"] = {"language_folders": languages, "key_parity_errors": localization_errors,
                              "non_english_values_equal_to_english": equal_english,
                              "scope": "structural/fallback parity, not translation quality"}
    try:
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime(unpack_returned_tuples=True)
        compile_lua = lua.eval("function(source,name) local f,e=loadstring(source,name);return f~=nil,e end")
        errors, count = [], 0
        for path in SOURCE.rglob("*.lua"):
            count += 1
            ok, error = compile_lua(path.read_text(encoding="utf-8-sig"), path.relative_to(ROOT).as_posix())
            if not ok:
                errors.append(str(error))
        report["syntax"] = {"environment": "Lua 5.1 via lupa", "files": count, "errors": errors}
    except ImportError:
        report["syntax"] = {"status": "NOT TESTED; lupa.lua51 unavailable"}
    archive_reports = []
    for path in sorted((ROOT / "dist").glob("*.zip")):
        item = {"path": path.relative_to(ROOT).as_posix(), "sha256": digest(path.read_bytes()), "errors": []}
        try:
            with zipfile.ZipFile(path) as archive:
                names = archive.namelist()
                item["members"] = len(names)
                if len(names) != len(set(names)):
                    item["errors"].append("duplicate members")
                if len(names) != len({name.lower() for name in names}):
                    item["errors"].append("case collisions")
                if any(".." in PurePosixPath(name).parts or PurePosixPath(name).is_absolute() or "\\" in name or ":" in name for name in names):
                    item["errors"].append("unsafe member path")
                if sum(info.file_size for info in archive.infolist()) > 100_000_000:
                    item["errors"].append("uncompressed-size safety limit; data checks skipped")
                else:
                    bad = archive.testzip()
                    if bad:
                        item["errors"].append("CRC failure")
                    metadata = [name for name in names if name.endswith("/ProjectNightfall/42/mod.info")]
                    if len(metadata) != 1:
                        item["errors"].append("expected one Nightfall mod.info")
                    else:
                        prefix = metadata[0][:-len("mod.info")]
                        payload = {name[len(prefix):]: digest(archive.read(name)) for name in names if name.startswith(prefix) and not name.endswith("/")}
                        item["payload_files"] = len(payload)
                        item["source_differences"] = [name for name in sorted(left.keys() | payload.keys()) if left.get(name) != payload.get(name)]
                        unexpected = [name for name in names if PurePosixPath(name).suffix.lower() in {".java", ".class", ".jar", ".dll", ".exe", ".log"}]
                        if unexpected:
                            item["errors"].append("unexpected runtime/binary/log members")
        except (OSError, zipfile.BadZipFile) as error:
            item["errors"].append(type(error).__name__)
        archive_reports.append(item)
    report["current_directory_archives"] = archive_reports
    protected = ROOT / ".git/nightfall-source-before.json"
    if protected.is_file():
        before = json.loads(protected.read_text())
        report["protected_source_art_files"] = len(before)
        report["protected_source_art_changed"] = [name for name, hash_value in before.items()
                                                if not (ROOT / name).is_file() or digest((ROOT / name).read_bytes()) != hash_value]
    report["index_audit"] = staged_audit()
    if args.output:
        output = args.output if args.output.is_absolute() else ROOT / args.output
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    # A stale copy is an audit finding and release blocker, not an all-clear.
    failed = bool(report["copy_missing"] or report["copy_changed"] or report["copy_extra"] or collisions or
                  localization_errors or require_errors or report["non_lua_runtime_dependencies"] or report["syntax"].get("errors") or
                  any(item["errors"] or item.get("source_differences") for item in archive_reports) or
                  report.get("protected_source_art_changed") or report["index_audit"]["denied_paths"] or
                  report["index_audit"]["potential_secret_paths"])
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
