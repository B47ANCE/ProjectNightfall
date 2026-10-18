# Nightfall 0.31.0-dev.5 Workshop MP testing preparation

The user explicitly requested merge and publish. PR #7 merged into main at
264f3c34dddf5da324b533e699cff14e4d1f2023 after exact-head Linux/Windows CI PASS.
Preparation occurs on a separate release branch from that main commit; no older
checkout or player/server files are modified. Source authority remains src/ProjectNightfall.

MP testing build - dedicated multiplayer NOT TESTED. G7 BLOCKED / NOT TESTED;
stable-release G8 BLOCKED. The Knowledge 0.16.0 dedicated-storage guard is retained:
default research-required construction/placement fails closed on dedicated servers.
Three frame models/rendering, non-feeding reactions/attribution, migration and human
native/SP/MP acceptance remain pending. No stable tag is created.

The user approved a deterministic local 512×512 PNG derivative for preview.png.
Original 1254×1254 supplied artwork remains unchanged in the source poster. Native
SteamWorkshopItem source (Steam build 25485521; exact SemVer UNKNOWN) rejects preview
files above 1,024,000 bytes and sizes other than 256/512 square. The same source
returns Workshop content folder Contents, whose mods child contains the mod.
This is installed-source evidence; no game class was executed or shipped.

Established BBCode description/change notes are preserved and updated with the
required test banner, SPXTRM activation name, GitHub link and explicit known limits.
Credits and Workshop item 3788593239/App ID 108600/public visibility are preserved.
The current source mirror is rebuilt using the established package builder; its
prior 0.27.4 tree and packages are retained, never relabelled as current proof.

Validation commands:

```text
python scripts/check_versions.py
python scripts/package_project.py plan
python scripts/run_host_tests.py --dependencies ../nightfall-effigy-container/.local/ci-dependencies
python -m unittest discover -s tests -p "test_*.py"
python scripts/dependency_contracts.py --dependencies ../nightfall-effigy-container/.local/ci-dependencies
python scripts/package_project.py build
python scripts/package_project.py verify
python scripts/check_versions.py --release
python scripts/audit_project.py --release --dependencies ../nightfall-effigy-container/.local/ci-dependencies
git -c core.autocrlf=false diff --cached --check
```

A release manifest is created before upload, binding final merged Git commit,
package/source/preview hashes, source commit, IDs, installed build and actual
validation status. Native content staging is built from the verified package
inventory; only Contents is sent as contentfolder, with the preview outside it.
No developer tools, logs, credentials, ZIPs or authoring assets enter runtime content.

The legacy updater points to a removed directory and is not executed. Use its
verified existing SteamCMD executable and cached-login identity, with a new local
VDF referencing the exact current staging and selected reviewed description/change
note. It never starts a game/server, deploys mods, restarts Steam or alters remote
server files. SteamCMD must report success for item 3788593239 and the exit result
must be verified. Actual upload outcome/commit/hashes are recorded in the release PR
and local provenance after completion; this preparation document makes no success
claim. Ask for explicit confirmation for a Steam desktop restart after success.

[TESTED: offline before packaging] 71/71 Lua and 25/25 Python PASS on Windows Python 3.12.14/lupa 2.6. Five original locked fixture origins/commits/clean trees and direct/transitive contracts PASS; lock values are identical across release/original checkouts (Git line endings differ). Original thumbnail preserved. Preview 512×512, 254,160 bytes, SHA-256 d08247c8a3197ad455a2d67df0d8ee935ed27b8ba7bd139ce1dd51a68d7a4532; PNG and visual inspection PASS.

[TESTED: offline packaging] Builder PASS: 165 authoritative mod/source files, 167 ZIP members, exact source/Contents parity, traversal/duplicate/case/link/CRC/data checks and source-commit provenance. Package SHA-256: 0e172895fb9b7be3f69419b2965708b06ae81f157760d6c23e2ae8294e9759cb. Source snapshot commit: 7cd88e4ee80174e19e659bcde692d89b16634745 (clean packaged inputs). [Committed package manifest](packaging/0.31.0-dev.5.manifest.json). Previous 152-file 0.27.4 mirror retained at dist/staging-backups/contents-d5b4fced0911; raw tree SHA-256 d5b4fced091145a60d8224eb13bdd2696ebe272f1efb1af5e183720b4e42b50a verified unchanged. No artifact deletion.

[TESTED: offline final artifact gates] scripts/check_versions.py --release PASS; full source/release audit PASS with no source or release consistency failures. Lua-only, case/require paths, localization, dependency contracts, PNG dimensions/size, ZIP inventory/CRC/data/traversal/duplicate checks, source/Contents/package parity, clean captured source provenance and retained-mirror hash PASS. G7/stable G8 remain BLOCKED. Final staged secret/path/whitespace audit must pass before public push.
