# Nightfall 0.27.4 — packaging workflow and evidence

Date: 2026-10-16. The user explicitly authorized fixing the packaging workflow,
refreshing stale Contents, validating the package, and committing/pushing. This
is a packaging-only follow-up: canonical version stays **0.27.4**, and runtime
source bytes, gameplay, authority, save schemas, artwork and identifiers are
unchanged from source commit `9293ab73cf162584ebe4a3047a9d5d13eeb0df23`.

## Current package and layout

- Artifact: `dist/ProjectNightfall-0.27.4-workshop-ready.zip` (1,346,215 bytes).
- SHA-256: `a5d10a92d46634e6c89e57eaaf0eab24dbd2f1d0f5f5549d1413768faa74f6d1`.
- The established 154-file ZIP layout is preserved: 150 runtime files under
  `Contents/mods/ProjectNightfall/42`, parent `info.txt` and `thumbnail.png`, plus
  top-level `preview.png` and `workshop.txt`. Authoring art/tests/tools/config and
  dependencies are excluded. This is a selected-mod package, not a dependency bundle.
- Current `Contents/mods/ProjectNightfall` exactly mirrors all **152** files in
  `src/ProjectNightfall`, including parent support metadata. Source remains the
  implementation authority. The runtime subtree's 150-file hash mapping digest
  remains `933c4ddd08d1f6f602daad8a26a114523937d85fa3892dccbd49212d109a5122`.
- Full 152-file source/support mapping digest:
  `d5b4fced091145a60d8224eb13bdd2696ebe272f1efb1af5e183720b4e42b50a`.
- Sidecars: `dist/ProjectNightfall-0.27.4-workshop-ready.manifest.json` and `.sha256`.
  Reviewed provenance is also committed as [0.27.4.manifest.json](packaging/0.27.4.manifest.json).
  It binds version, Mod ID, existing Workshop ID 3788593239, dependency IDs,
  minimum game version, source commit/dirty flag, builder hash, artifact hash and
  every packaged member hash. Packaged input dirty flag was **false**.

The filename follows the earlier package convention; “workshop-ready” is not
stable-release approval or runtime certification. No Workshop upload occurred.

## Manual workflow

Use Python **3.12+**; packaging itself uses the standard library. Lua regressions
separately require lupa's Lua 5.1 interpreter. From the project root:

```text
python scripts/check_versions.py
python scripts/package_project.py plan
python scripts/package_project.py build
python scripts/package_project.py verify
python scripts/check_versions.py --release
```

`plan` is read-only. `build` collects only declared source/support/wrapper inputs,
checks identity/version/dependencies and Workshop paragraph breaks, stages a ZIP
and mirror, verifies them, retains the superseded mirror, then installs outputs.
It refuses linked/out-of-project paths, unexpected mirror files, existing backup
collisions, orphan sidecars, and any differing existing versioned package. It
never deletes unexpected files or overwrites old ZIP/provenance records. A failed
mirror installation restores the old mirror. Task-owned scratch files are the
only automatically removed data; no retention cleanup is performed.

ZIP entries have sorted names, fixed timestamps/permissions and fixed compression
settings. A second real build produced identical ZIP bytes and left provenance
and checksum bytes unchanged. This establishes reproducibility for identical
input bytes and the tested Python 3.12.14 / zlib 1.3.2 environment. Source/mirror/ZIP
parity is byte-for-byte, including on-disk text line endings; no source or artwork
normalization is performed. Other toolchains/platforms were not tested.

`verify` independently checks full source/support/Contents parity, exact ZIP
inventory and bytes, paths, duplicate/case collisions, regular-file status,
encryption rejection, CRC/data integrity, identity/version, manifest member hashes
and artifact checksum. `check_versions.py --release` now uses that strict verifier
instead of only checking mod.info versions and CRCs. Project audits classify
declared historical artifacts without requiring them to equal current source;
unclassified artifacts still fail. These commands never build implicitly, deploy,
upload, start the game/server, or clear runtime gates.

## Preservation and backup

The previous full mirror contained 67 files: 65 runtime files with 0.27.1 metadata
plus two support files with earlier metadata. It is retained byte-for-byte at:
`dist/staging-backups/contents-51c590fbd9d0`.

Its tree digest is
`51c590fbd9d01f6ecb3aca4e4b937aa41d973ccc3b0669b9beea1e4c3c652d06`.
The build plan/retention record in the manifest captures its old file count,
fingerprint, backup location, changed paths, and an empty deletion list. No old
file was relabeled as new: current Contents was generated from actual source.

All **5,627** pre-existing source, art and generated-artifact files captured before
this operation retain their original hashes. This includes the historical 0.27.3
ZIP with SHA-256
`1481c1565b85bc357e557f7fec1799cb69a101ca5a7e0eb6081b53b5a28df765`.
Old validation/audit records remain tied to their original scope; the preceding
[corpse-fix validation](VALIDATION_0.27.4.md) accurately records the earlier phase
when no 0.27.4 package existed. New generated ZIPs, backups, sidecars and local
fixtures remain ignored; current mirror, scripts, tests and reviewed evidence
are committed. No cleanup, game-file changes or upstream dependency edits occurred.

## Dependency identity drift and honest test scope

During final validation, sibling dependency projects were renamed/reorganized.
The default powerWorks path disappeared, and the former experienceWorks source
changed to the new knowledge namespace without the old import alias. The default
unmodified sibling lookup therefore fails; [workspace audit evidence](packaging/0.27.4.workspace-audit.json)
records the missing legacy imports. Current renamed-family compatibility is
**NOT VALIDATED**. The selected 0.27.4 runtime dependency contract was not changed
as a hidden packaging fix.

The retained matching first-party ZIPs were found, hash-pinned in
[tests/dependencies_0.27.4.json](../tests/dependencies_0.27.4.json), and copied into
isolated ignored fixtures after SHA-256, identity/version, path/case, CRC and
forbidden runtime-payload checks. These are real historical modules, not renamed
API aliases or substituted implementations. The helper caches exact originals
under `.local/validation-archives` so later sibling directory renames do not change
the selected set. Fresh setups need those exact archives at the recorded retained
locations or in that local cache. Fixtures are not packaged or deployment inputs.

```text
python scripts/prepare_test_dependencies.py
python scripts/run_host_tests.py --dependencies .local/validation-dependencies
python scripts/audit_project.py --dependencies .local/validation-dependencies
```

The test runner's explicit dependency root now also resolves declared relative
debug-test file paths. Its default still targets current sibling sources and
fails loudly when they lack the required identities. No fallback namespace or
fixture is silently selected. Preparation and testing do not modify the sibling
projects, their retained archives, or installed mods.

## Validation results

| Command / check | Result and scope |
| --- | --- |
| `python scripts/package_project.py build` twice | PASS; identical artifact SHA and unchanged sidecar bytes |
| `python scripts/package_project.py verify` | PASS; 154 members, exact 152-file source/support mirror and wrapper parity, version/identity, integrity/provenance |
| `python scripts/check_versions.py` | PASS, current 0.27.4 source mirrors |
| `python scripts/check_versions.py --release` | PASS, strict offline package consistency |
| `python -m unittest discover -s tests -p test_packaging.py -v` | **10/10 PASS**: retained backup, repeat-build immutability, collision refusal, extra mirror preservation, install rollback, unsafe paths/extra/missing/duplicate/case/link members, payload/CRC damage, manifest/checksum tampering, forbidden source types |
| `python scripts/prepare_test_dependencies.py` | PASS, all five exact archive locks and fixture copies |
| `python scripts/run_host_tests.py --dependencies .local/validation-dependencies` | **59/59 PASS**, offline Lua 5.1, declared historical matching set |
| `python scripts/audit_project.py --dependencies .local/validation-dependencies --output docs/packaging/0.27.4.audit.json` | PASS: no mirror delta, 53 source Lua files compile, no family require-case/case-collision/JSON key-parity/payload errors, historical archive integrity and 5,627 protected hashes unchanged |
| Default sibling Lua/audit lookup | BLOCKED by dependency identity changes; not rewritten into PASS |

Current structural evidence: [0.27.4.audit.json](packaging/0.27.4.audit.json).
No CI is configured. SP, native Kahlua, exact native API/build compatibility,
installed-package loading, Linux, Workshop download, hosted/dedicated sync,
late join/rejoin, persistence and restart behavior remain untested. The previously
observed injected-agent launcher also needs a clean configuration before native
validation. **G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.** Resolve the renamed
dependency integration in a separately versioned scope before claiming current
ecosystem compatibility, then collect the required native runtime evidence.
