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
import stat
import zipfile
import zlib
from audit_policy import failure_reasons, historical_mirror, localization_value_errors

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
    parser.add_argument("--release", action="store_true", help="Also require current Contents and validated package; never grants G7/G8")
    parser.add_argument("--protected-baseline", type=Path, help="Explicit operation baseline; all recorded files must remain byte-identical")
    parser.add_argument("--dependencies", type=Path, default=ROOT.parent,
                        help="Dependency source root; may be explicitly pinned historical fixtures")
    args = parser.parse_args()
    left, right = tree(SOURCE), tree(COPY)
    inventory = json.loads((ROOT / "SOURCE_INVENTORY.json").read_text())
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
    dependency_root = args.dependencies.resolve()
    report["dependency_scope"] = "default sibling checkouts" if dependency_root == ROOT.parent.resolve() else "explicit alternate dependency root; verify its provenance separately"
    for dependency in inventory["dependency_sources"]:
        roots.append(dependency_root / dependency["folder"] / "src" / dependency["mod_id"] / "42/media/lua")
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
            elif name.split("/")[0] in {"ProjectNightfall", "Mortis", "lightWorks", "powerWorks", "medWorks", "experienceWorks", "B47ANCEDPower", "B47ANCEDKnowledgeAndWisdom"}:
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
        if {path.name for path in (translations / language).glob("*.json")} != set(english):
            localization_errors.append(f"{language}: translation file inventory differs from English")
        for name, expected in english.items():
            path = translations / language / name
            try:
                values = json.loads(path.read_text(encoding="utf-8-sig"))
                localization_errors.extend(f"{language}/{name}: {error}" for error in localization_value_errors(expected, values))
                if language != "EN":
                    equal_english += sum(values.get(key) == value for key, value in expected.items())
            except (OSError, ValueError) as error:
                localization_errors.append(f"{language}/{name}: {type(error).__name__}")
    report["localization"] = {"language_folders": languages, "key_parity_errors": localization_errors,
                              "non_english_values_equal_to_english": equal_english,
                              "authored_language": "EN", "other_languages": "English fallback; fluent review NOT TESTED",
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
        item["classification"] = ("historical" if item["path"] in inventory.get("historical_records", [])
                                  else "current" if path.name == f"ProjectNightfall-{report['version']}-workshop-ready.zip"
                                  else "unclassified")
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
                if any(stat.S_IFMT(entry.external_attr >> 16) not in (0, stat.S_IFREG, stat.S_IFDIR) or entry.flag_bits & 1 for entry in archive.infolist()):
                    item["errors"].append("linked, special or encrypted member")
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
        except (OSError, zipfile.BadZipFile, RuntimeError, EOFError, zlib.error) as error:
            item["errors"].append(type(error).__name__)
        archive_reports.append(item)
    report["current_directory_archives"] = archive_reports
    report["historical_mirror"] = historical_mirror(ROOT, inventory)
    # An operation snapshot is not a permanent source freeze. Only an explicitly
    # selected baseline applies; old snapshots remain historical evidence.
    protected = args.protected_baseline
    report["protected_baseline"] = "NOT REQUESTED; historical mirror independently pinned"
    if protected is not None:
        if not protected.is_absolute():
            protected = ROOT / protected
        before = json.loads(protected.read_text())
        if any(PurePosixPath(name).is_absolute() or ".." in PurePosixPath(name).parts or "\\" in name or ":" in name for name in before):
            raise ValueError("Unsafe operation baseline path")
        report["protected_baseline"] = "explicit operation baseline"
        report["protected_files"] = len(before)
        report["protected_files_changed"] = [name for name, hash_value in before.items()
                                             if not (ROOT / name).is_file() or digest((ROOT / name).read_bytes()) != hash_value]
    from package_project import inputs, verify
    try:
        version, files, _ = inputs(ROOT)
        report["package_inputs"] = {"status": "PASS", "version": version, "files": len(files), "scope": "source inputs only; no package built"}
    except (OSError, ValueError) as error:
        report["package_inputs"] = {"error": str(error)}
    try:
        report["package_validation"] = verify(ROOT)
    except (OSError, ValueError) as error:
        report["package_validation"] = {"error": str(error)}
    from dependency_contracts import inspect
    report["dependency_contracts"] = inspect(ROOT, dependency_root)
    report["index_audit"] = staged_audit()
    report["scope"] = "release consistency" if args.release else "source audit with separate release blockers"
    report["source_failures"] = failure_reasons(report)
    report["release_consistency_failures"] = failure_reasons(report, release=True)
    report["source_status"] = "FAIL" if report["source_failures"] else "PASS"
    report["release_consistency_status"] = "BLOCKED" if report["release_consistency_failures"] else "PASS (offline only)"
    report["G7"] = "BLOCKED / NOT TESTED"
    report["G8"] = "BLOCKED; no dedicated runtime evidence"
    if args.output:
        output = args.output if args.output.is_absolute() else ROOT / args.output
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return int(bool(report["release_consistency_failures"] if args.release else report["source_failures"]))


if __name__ == "__main__":
    raise SystemExit(main())
