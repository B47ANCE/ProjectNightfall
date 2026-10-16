"""Prepare ignored, hash-pinned historical dependency fixtures for 0.27.4 tests.

Reads retained first-party ZIPs without modifying their owning projects. The
fixtures are offline test inputs, never deployment, distribution or compatibility
approval for the newly renamed dependency family.
"""
import json
from pathlib import Path, PurePosixPath
import stat
import zipfile

try:
    from .package_project import MAX_BYTES, PackageError, owned, read_tree, sha
except ImportError:
    from package_project import MAX_BYTES, PackageError, owned, read_tree, sha

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    lock = json.loads((ROOT / "tests/dependencies_0.27.4.json").read_text())
    if lock["nightfall_version"] != (ROOT / "VERSION").read_text().strip():
        raise PackageError("Pinned fixtures belong to a different Nightfall version; review the lock")
    output = owned(ROOT, ".local/validation-dependencies")
    for entry in lock["dependencies"]:
        retained = ROOT.parent / entry["archive"]
        cached = owned(ROOT, ".local/validation-archives/" + retained.name)
        archive = cached if cached.is_file() else retained
        archive_bytes = archive.read_bytes()
        if sha(archive_bytes) != entry["sha256"]:
            raise PackageError("Dependency archive hash mismatch: " + entry["mod_id"])
        if not cached.exists():
            cached.parent.mkdir(parents=True, exist_ok=True)
            cached.write_bytes(archive_bytes)
        archive = cached
        with zipfile.ZipFile(archive) as package:
            members = package.infolist()
            names = [member.filename for member in members]
            if len(names) != len(set(names)) or len(names) != len({name.casefold() for name in names}):
                raise PackageError("Duplicate/case-colliding dependency members")
            if sum(member.file_size for member in members) > MAX_BYTES:
                raise PackageError("Dependency exceeds inspection ceiling")
            for member in members:
                name = member.filename
                if PurePosixPath(name).is_absolute() or ".." in PurePosixPath(name).parts or ":" in name or "\\" in name:
                    raise PackageError("Unsafe dependency archive member")
                if stat.S_IFMT(member.external_attr >> 16) not in (0, stat.S_IFREG):
                    raise PackageError("Special/linked dependency member")
                if PurePosixPath(name).suffix.lower() in {".java", ".class", ".jar", ".exe", ".dll"}:
                    raise PackageError("Non-Lua custom runtime payload in dependency")
            if package.testzip() is not None:
                raise PackageError("Dependency CRC failure")
            metadata = [name for name in names if name.endswith("/" + entry["mod_id"] + "/42/mod.info")]
            if len(metadata) != 1:
                raise PackageError("Dependency identity is ambiguous")
            text = package.read(metadata[0]).decode("utf-8-sig")
            values = dict(line.split("=", 1) for line in text.splitlines() if "=" in line)
            if values.get("id") != entry["mod_id"] or values.get("modversion") != entry["version"]:
                raise PackageError("Dependency version/identity mismatch")
            prefix = metadata[0][:-len("mod.info")]
            files = {name[len(prefix):]: package.read(name) for name in names if name.startswith(prefix)}
        relative = f".local/validation-dependencies/{entry['fixture_folder']}/src/{entry['mod_id']}/42"
        destination = owned(ROOT, relative)
        existing = read_tree(destination)
        if existing and existing != files:
            raise PackageError("Existing validation fixture differs; refuse overwrite")
        for name, data in files.items():
            path = owned(ROOT, relative + "/" + name)
            path.parent.mkdir(parents=True, exist_ok=True)
            if not path.exists():
                path.write_bytes(data)
        if read_tree(destination) != files:
            raise PackageError("Dependency fixture parity failure")
        print(f"PASS fixture {entry['mod_id']} {entry['version']}: {len(files)} files, archive {entry['sha256']}")
    output.mkdir(parents=True, exist_ok=True)
    (output / "LOCK.json").write_text(json.dumps(lock, indent=2) + "\n", encoding="utf-8")
    print("Offline fixtures prepared; current renamed dependencies are not validated by these tests.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, zipfile.BadZipFile) as error:
        print("FAIL dependency fixtures: " + str(error))
        raise SystemExit(1)
