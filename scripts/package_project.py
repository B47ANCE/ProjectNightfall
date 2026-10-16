"""Plan, build, or verify Nightfall's local development package. Never deploy/upload.

The established ZIP layout is Contents/mods/ProjectNightfall plus preview.png and
workshop.txt. Source is authoritative; Contents is a derived mirror. Existing
packages are immutable and superseded mirrors are retained under dist.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import tempfile
import zipfile
import zlib

try:
    from .check_versions import SEMVER
except ImportError:
    from check_versions import SEMVER

ROOT = Path(__file__).resolve().parents[1]
MOD = "ProjectNightfall"
SOURCE = f"src/{MOD}"
MIRROR = f"Contents/mods/{MOD}"
MAX_BYTES = 100_000_000  # Technical inspection/memory ceiling, not gameplay balance.


class PackageError(ValueError):
    pass


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def tree_digest(files: dict[str, bytes]) -> str:
    return sha(json.dumps({name: sha(data) for name, data in files.items()}, sort_keys=True).encode())


def owned(root: Path, relative: str) -> Path:
    root = root.resolve()
    candidate = root / relative
    if not candidate.resolve().is_relative_to(root):
        raise PackageError("Path escapes the selected project")
    for part in (candidate, *candidate.parents):
        if part == root:
            break
        if part.is_symlink() or os.path.isjunction(part):
            raise PackageError("Linked package paths are not allowed")
    return candidate


def read_tree(path: Path) -> dict[str, bytes]:
    files = {}
    if not path.exists():
        return files
    if path.is_symlink() or os.path.isjunction(path):
        raise PackageError("Linked source/mirror root")
    size = 0
    def unreadable(error: OSError) -> None:
        raise error
    for directory, folders, names in os.walk(path, followlinks=False, onerror=unreadable):
        for name in folders + names:
            entry = Path(directory) / name
            if entry.is_symlink() or os.path.isjunction(entry):
                raise PackageError("Linked source/mirror member")
        for name in names:
            entry = Path(directory) / name
            size += entry.stat().st_size
            if size > MAX_BYTES:
                raise PackageError("Source/mirror exceeds inspection ceiling")
            files[entry.relative_to(path).as_posix()] = entry.read_bytes()
    if len(files) != len({name.casefold() for name in files}):
        raise PackageError("Source/mirror case collision")
    return files


def inputs(root: Path) -> tuple[str, dict[str, bytes], dict]:
    version = owned(root, "VERSION").read_text().strip()
    if not re.fullmatch(SEMVER, version):
        raise PackageError("Invalid canonical Semantic Version")
    inventory = json.loads(owned(root, "SOURCE_INVENTORY.json").read_text())
    if inventory["project_version"] != version or inventory["mod_ids"] != [MOD]:
        raise PackageError("Inventory identity/version mismatch")
    workshop_id = owned(root, "WORKSHOP_ID.txt").read_text().strip()
    if not workshop_id.isdigit() or inventory["workshop_ids"] != [workshop_id]:
        raise PackageError("Workshop identity mismatch")
    source = read_tree(owned(root, SOURCE))
    if not source:
        raise PackageError("Authoritative source is missing")
    permitted = {".lua", ".json", ".txt", ".info", ".png"}
    if any(PurePosixPath(name).suffix.lower() not in permitted for name in source):
        raise PackageError("Unexpected source payload type; review before packaging")
    metadata = source.get("42/mod.info", b"").decode("utf-8-sig")
    values = dict(line.split("=", 1) for line in metadata.splitlines() if "=" in line)
    if values.get("id") != MOD or values.get("modversion") != version:
        raise PackageError("Runtime metadata identity/version mismatch")
    if values.get("require", "").split(",") != inventory["required_mod_ids"]:
        raise PackageError("Dependency identity/order mismatch")
    info = source.get("info.txt", b"").decode("utf-8-sig").replace("\r\n", "\n")
    if re.findall(r"(?m)^Version:\n(.+)$", info) != [version]:
        raise PackageError("Source support metadata version mismatch")
    expected = {f"{MIRROR}/{name}": data for name, data in source.items()}
    for name in ("preview.png", "workshop.txt"):
        expected[name] = owned(root, name).read_bytes()
    descriptor = expected["workshop.txt"].decode("utf-8-sig")
    if f"description=[b]Mod Version:[/b] {version}" not in descriptor:
        raise PackageError("Workshop descriptor version mismatch")
    for name in ("WORKSHOP_CHANGE_NOTE.txt", "WORKSHOP_DESCRIPTION.txt", "workshop.txt"):
        text = owned(root, name).read_text(encoding="utf-8-sig")
        if "\\n" in text or "\n\n" not in text and name != "workshop.txt":
            raise PackageError("Workshop text requires actual paragraph breaks")
    return version, expected, {"mod_id": MOD, "workshop_id": workshop_id,
                               "minimum_game_version": values.get("versionMin"),
                               "required_mod_ids": inventory["required_mod_ids"]}


def locations(root: Path, version: str) -> tuple[Path, Path, Path]:
    base = f"dist/{MOD}-{version}-workshop-ready"
    return owned(root, base + ".zip"), owned(root, base + ".manifest.json"), owned(root, base + ".sha256")


def verify_archive(archive: Path, expected: dict[str, bytes]) -> dict:
    try:
        with zipfile.ZipFile(archive) as package:
            entries = package.infolist()
            names = [entry.filename for entry in entries]
            if len(names) != len(set(names)) or len(names) != len({name.casefold() for name in names}):
                raise PackageError("Duplicate or case-colliding ZIP members")
            for entry in entries:
                name = entry.filename
                if PurePosixPath(name).is_absolute() or ".." in PurePosixPath(name).parts or ":" in name or "\\" in name:
                    raise PackageError("Unsafe ZIP member path")
                kind = stat.S_IFMT(entry.external_attr >> 16)
                if kind not in (0, stat.S_IFREG) or entry.flag_bits & 1:
                    raise PackageError("Linked, directory, special or encrypted ZIP member")
            if set(names) != set(expected):
                raise PackageError("ZIP inventory differs from authoritative package inputs")
            if sum(entry.file_size for entry in entries) > MAX_BYTES:
                raise PackageError("ZIP exceeds inspection ceiling")
            if package.testzip() is not None:
                raise PackageError("ZIP CRC/data validation failed")
            for name, data in expected.items():
                if package.read(name) != data:
                    raise PackageError("ZIP payload differs from authoritative source/metadata: " + name)
    except (OSError, zipfile.BadZipFile, RuntimeError, EOFError, zlib.error) as error:
        raise PackageError("Unreadable or corrupt package: " + type(error).__name__) from error
    return {"sha256": sha(archive.read_bytes()), "members": len(expected), "payload_parity": "PASS",
            "integrity": "PASS", "version_and_identity": "PASS"}


def verify(root: Path) -> dict:
    version, expected, identity = inputs(root)
    archive, manifest_path, checksum_path = locations(root, version)
    source = {name[len(MIRROR) + 1:]: data for name, data in expected.items() if name.startswith(MIRROR + "/")}
    if read_tree(owned(root, MIRROR)) != source:
        raise PackageError("Contents/source exact parity failed")
    report = verify_archive(archive, expected)
    manifest = json.loads(manifest_path.read_text())
    hashes = {name: sha(data) for name, data in sorted(expected.items())}
    if (manifest.get("schema") != 1 or manifest.get("archive") != archive.name or
            manifest.get("version") != version or manifest.get("identity") != identity or
            manifest.get("archive_sha256") != report["sha256"] or manifest.get("member_sha256") != hashes or
            manifest.get("source_tree_sha256") != tree_digest(source)):
        raise PackageError("Package provenance manifest mismatch")
    if checksum_path.read_text().strip() != f"{report['sha256']}  {archive.name}":
        raise PackageError("Package checksum sidecar mismatch")
    return {"version": version, "archive": archive.relative_to(root).as_posix(), **report,
            "contents_parity": "PASS", "provenance": "PASS", "source_files": len(source),
            "G7": "BLOCKED / NOT TESTED", "G8": "BLOCKED"}


def plan(root: Path) -> dict:
    version, expected, _ = inputs(root)
    source = {name[len(MIRROR) + 1:]: data for name, data in expected.items() if name.startswith(MIRROR + "/")}
    current = read_tree(owned(root, MIRROR))
    if current.keys() - source.keys():
        raise PackageError("Unexpected Contents files; refuse implicit deletion or cleanup")
    archive, _, _ = locations(root, version)
    return {"version": version, "archive": archive.relative_to(root).as_posix(),
            "source_files": len(source), "old_mirror_files": len(current), "package_members": len(expected),
            "mirror_changes": [name for name in sorted(source) if current.get(name) != source[name]],
            "old_mirror_tree_sha256": tree_digest(current),
            "backup": f"dist/staging-backups/contents-{tree_digest(current)[:12]}" if current and current != source else None,
            "deletions": [], "deployment": False, "upload": False}


def build(root: Path) -> dict:
    proposed = plan(root)
    version, expected, identity = inputs(root)
    archive, manifest_path, checksum_path = locations(root, version)
    source = {name[len(MIRROR) + 1:]: data for name, data in expected.items() if name.startswith(MIRROR + "/")}
    scratch_root = owned(root, ".local/packaging")
    scratch_root.mkdir(parents=True, exist_ok=True)
    # Only this freshly created, checked scratch directory is automatically
    # removed. Existing mirror/artifact/history data is never deleted.
    with tempfile.TemporaryDirectory(prefix="build-", dir=scratch_root) as temporary:
        scratch = Path(temporary)
        if not scratch.resolve().is_relative_to(scratch_root.resolve()):
            raise PackageError("Unexpected scratch path")
        candidate = scratch / "candidate.zip"
        with zipfile.ZipFile(candidate, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as package:
            for name, data in sorted(expected.items()):
                entry = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
                entry.compress_type = zipfile.ZIP_DEFLATED
                entry.create_system = 3
                entry.external_attr = (stat.S_IFREG | 0o644) << 16
                package.writestr(entry, data, compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
        integrity = verify_archive(candidate, expected)
        if archive.exists():
            if archive.read_bytes() != candidate.read_bytes():
                raise PackageError("Existing versioned package differs; refusing artifact overwrite")
            # A repeat build is a check, not a rewrite of package provenance.
            return verify(root)
        if manifest_path.exists() or checksum_path.exists():
            raise PackageError("Orphan/colliding sidecars; refuse overwrite")
        mirror = owned(root, MIRROR)
        staged_mirror = scratch / MOD
        staged_mirror.mkdir()
        for name, data in source.items():
            destination = staged_mirror / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(data)
        if read_tree(staged_mirror) != source:
            raise PackageError("Staged Contents verification failed")
        # Recheck captured inputs before installing any output.
        if inputs(root)[1] != expected or plan(root) != proposed:
            raise PackageError("Source/mirror drift during packaging")
        backup = owned(root, proposed["backup"]) if proposed["backup"] else None
        if backup is not None:
            if backup.exists():
                raise PackageError("Mirror backup already exists; refuse overwrite")
            backup.parent.mkdir(parents=True, exist_ok=True)
            os.replace(mirror, backup)  # Both owned absolute paths were checked.
            if tree_digest(read_tree(backup)) != proposed["old_mirror_tree_sha256"]:
                os.replace(backup, mirror)
                raise PackageError("Old mirror backup verification failed")
        if proposed["mirror_changes"]:
            try:
                mirror.parent.mkdir(parents=True, exist_ok=True)
                os.replace(staged_mirror, mirror)
            except OSError:
                if backup is not None and not mirror.exists():
                    os.replace(backup, mirror)
                raise
        try:
            source_commit = subprocess.check_output(["git", "log", "-1", "--format=%H", "--", SOURCE,
                                                     "preview.png", "workshop.txt", "VERSION"], cwd=root).decode().strip()
            source_dirty = bool(subprocess.check_output(["git", "status", "--porcelain=v1", "--", SOURCE,
                                                         "preview.png", "workshop.txt", "VERSION"], cwd=root).strip())
        except subprocess.CalledProcessError:
            source_commit = "UNKNOWN"
            source_dirty = True
        manifest = {"schema": 1, "version": version, "identity": identity,
                    "archive": archive.name, "archive_sha256": integrity["sha256"],
                    "source_tree_sha256": tree_digest(source), "source_commit": source_commit,
                    "source_worktree_dirty": source_dirty,
                    "builder_sha256": sha(Path(__file__).read_bytes()),
                    "member_sha256": {name: sha(data) for name, data in sorted(expected.items())},
                    "retained_mirror": proposed if backup is not None else None,
                    "evidence": "offline package validation only", "G7": "BLOCKED / NOT TESTED", "G8": "BLOCKED"}
        archive.parent.mkdir(parents=True, exist_ok=True)
        os.replace(candidate, archive)
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        checksum_path.write_text(f"{integrity['sha256']}  {archive.name}\n", encoding="ascii")
    return verify(root)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("plan", "build", "verify"))
    args = parser.parse_args()
    try:
        if args.command in {"build", "verify"}:
            subprocess.run([os.sys.executable, str(ROOT / "scripts/check_versions.py")], check=True, cwd=ROOT)
        result = {"plan": plan, "build": build, "verify": verify}[args.command](ROOT)
        print(json.dumps(result, indent=2))
        return 0
    except (PackageError, OSError, ValueError, subprocess.CalledProcessError) as error:
        print("FAIL packaging: " + str(error))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
