"""Read-only current dependency inventory and transitive installation gate."""
from pathlib import Path
import json
import hashlib
import re

ROOT = Path(__file__).resolve().parents[1]

def inspect(root: Path, dependency_root: Path) -> dict:
    inventory = json.loads((root / "SOURCE_INVENTORY.json").read_text())
    selected = {entry["mod_id"] for entry in inventory["dependency_sources"]}
    direct, transitive, snapshots = [], [], []
    declared = inventory.get("required_mod_ids")
    if declared is not None:
        metadata = root / "src/ProjectNightfall/42/mod.info"
        values = (dict(line.split("=", 1) for line in metadata.read_text(encoding="utf-8-sig").splitlines() if "=" in line)
                  if metadata.is_file() else {})
        if values.get("id") != "ProjectNightfall" or values.get("require", "").split(",") != declared or set(declared) != selected:
            direct.append({"mod_id": "ProjectNightfall", "error": "runtime requirements differ from selected inventory contracts"})
    for entry in inventory["dependency_sources"]:
        source = dependency_root / entry["folder"] / "src" / entry["mod_id"] / "42"
        metadata = source / "mod.info"
        if not metadata.is_file():
            direct.append({"mod_id": entry["mod_id"], "error": "missing source/mod.info"})
            continue
        values = dict(line.split("=", 1) for line in metadata.read_text(encoding="utf-8-sig").splitlines() if "=" in line)
        if values.get("id") != entry["mod_id"]:
            direct.append({"mod_id": entry["mod_id"], "error": "Mod ID differs from selected contract"})
        hashes = {path.relative_to(source).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
                  for path in sorted(source.rglob("*")) if path.is_file()}
        snapshots.append({"mod_id": entry["mod_id"], "version": values.get("modversion"),
                          "source_tree_sha256": hashlib.sha256(json.dumps(hashes, sort_keys=True).encode()).hexdigest()})
        for required in filter(None, values.get("require", "").split(",")):
            if required not in selected:
                transitive.append({"mod_id": entry["mod_id"], "missing_required_mod_id": required})
        for path in (source / "media/lua").rglob("*.lua"):
            for old in re.findall(r'require\s*\(?\s*["\']((?:powerWorks|experienceWorks)/[^"\']+)', path.read_text(encoding="utf-8-sig")):
                transitive.append({"mod_id": entry["mod_id"], "path": path.relative_to(source).as_posix(), "obsolete_import": old})
    return {"direct": "FAIL" if direct else "PASS", "direct_errors": direct,
            "transitive": "BLOCKED" if transitive else "PASS", "transitive_errors": transitive,
            "source_versions": snapshots, "scope": "source contracts only; no game/runtime evidence"}

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dependencies", type=Path, default=ROOT.parent)
    report = inspect(ROOT, parser.parse_args().dependencies.resolve())
    print(json.dumps(report, indent=2))
    raise SystemExit(int(bool(report["direct_errors"] or report["transitive_errors"])))
