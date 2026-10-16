"""Check declared current versions; --release also rejects stale packaging input.

Pure standard-library offline validation. Release mode checks consistency only,
and cannot grant G7/G8 or authorize packaging, deployment, or publication.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CORE = r"(?:0|[1-9]\d*)"
IDENTIFIER = r"(?:0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*)"
SEMVER = rf"{CORE}\.{CORE}\.{CORE}(?:-{IDENTIFIER}(?:\.{IDENTIFIER})*)?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?"
VERSION_CAPTURE = r"(\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?)"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release", action="store_true")
    args = parser.parse_args()
    version = (ROOT / "VERSION").read_text().strip()
    errors = []
    if not re.fullmatch(SEMVER, version):
        errors.append("VERSION must contain one Semantic Version")
    inventory = json.loads((ROOT / "SOURCE_INVENTORY.json").read_text())
    if inventory["project_version"] != version:
        errors.append("SOURCE_INVENTORY.json version differs from VERSION")
    source = "src/ProjectNightfall/42/"
    mirrors = [
        ("README.md", r"- Version: `" + VERSION_CAPTURE + "`"),
        ("AGENTS.md", r"- Canonical version: `" + VERSION_CAPTURE + "`"),
        (source + "mod.info", r"(?m)^modversion=" + VERSION_CAPTURE + r"$"),
        (source + "media/lua/shared/ProjectNightfall/PN_Config.lua", r"ProjectNightfall.VERSION\s*=\s*\"" + VERSION_CAPTURE + "\""),
        (source + "media/lua/shared/ProjectNightfall/PN_Config.lua", r"-- Project Nightfall " + VERSION_CAPTURE),
        (source + "media/lua/client/ProjectNightfall/PN_TestKit.lua", r"local KIT_VERSION = \"" + VERSION_CAPTURE + "\""),
        (source + "media/lua/client/ProjectNightfall/PN_GuidedTest.lua", r"ProjectNightfall.VERSION or \"" + VERSION_CAPTURE + "\""),
        ("src/ProjectNightfall/info.txt", r"(?m)^Version:\n" + VERSION_CAPTURE + r"$"),
        ("docs/MASTER_ROADMAP.md", r"Canonical version: " + VERSION_CAPTURE),
        ("WORKSHOP_CHANGE_NOTE.txt", r"^\[b\]Version " + VERSION_CAPTURE),
        ("WORKSHOP_DESCRIPTION.txt", r"\[b\]Mod Version:\[/b\] " + VERSION_CAPTURE),
        ("docs/STEAM_WORKSHOP_DESCRIPTION.txt", r"\[b\]Mod Version:\[/b\] " + VERSION_CAPTURE),
        ("workshop.txt", r"description=\[b\]Mod Version:\[/b\] " + VERSION_CAPTURE),
        ("tests/test_dependency_diagnostics.lua", r"ProjectNightfall(?:\.VERSION=|==)\"" + VERSION_CAPTURE + "\""),
    ]
    for path, pattern in mirrors:
        try:
            text = (ROOT / path).read_text(encoding="utf-8-sig")
            matches = re.findall(pattern, text)
            if not matches:
                errors.append(f"Missing declared version mirror: {path}")
            elif any(value != version for value in matches):
                errors.append(f"Version drift: {path}: {matches}; expected {version}")
        except OSError as error:
            errors.append(f"Cannot read mirror {path}: {error.strerror}")
    if args.release:
        # Contents is a preserved older copy, not permission to relabel its bytes.
        old = ROOT / "Contents/mods/ProjectNightfall/42"
        current = ROOT / source
        for path in sorted(current.rglob("*")):
            if path.is_file():
                mirror = old / path.relative_to(current)
                if not mirror.is_file() or path.read_bytes() != mirror.read_bytes():
                    errors.append("Contents is stale; packaging parity is BLOCKED")
                    break
        artifacts = sorted((ROOT / "dist").glob(f"ProjectNightfall-{version}-*.zip"))
        if not artifacts:
            errors.append("No current-version ZIP available for release consistency checks")
        for artifact in artifacts:
            try:
                with zipfile.ZipFile(artifact) as archive:
                    if archive.testzip():
                        errors.append(f"CRC failure: {artifact.name}")
                    metadata = [name for name in archive.namelist() if name.endswith("/42/mod.info")]
                    if not metadata:
                        errors.append(f"No mod.info in {artifact.name}")
                    for name in metadata:
                        text = archive.read(name).decode("utf-8-sig").replace("\r\n", "\n")
                        if re.findall(r"(?m)^modversion=(.+)$", text) != [version]:
                            errors.append(f"Artifact version drift: {artifact.name}:{name}")
            except (OSError, zipfile.BadZipFile) as error:
                errors.append(f"Invalid artifact {artifact.name}: {type(error).__name__}")
    for error in errors:
        print("FAIL " + error)
    print(f"Version {version}: {'FAIL' if errors else 'PASS'} ({'release consistency' if args.release else 'current source mirrors'}).")
    return int(bool(errors))


if __name__ == "__main__":
    raise SystemExit(main())
