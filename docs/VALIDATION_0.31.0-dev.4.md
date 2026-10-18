# Nightfall 0.31.0-dev.4 validation — 2026-10-17

Development MINOR continuation from c5fcd21f7f04d275364750bc00f871fa7fbb20a1.
Startup PASS: clean feat/effigy-container, identical upstream SHA, 0 ahead/behind
upstream, 5 ahead/0 behind main, no unfinished operation. Target dev.4 recorded
before edits. Prior reports and retained 0.27.4 Contents/packages stay historical.

## Implemented and inspected

Research-gated actual-material frame assembly and actual-item placement; bounded
server sandbox costs (4 logs/2 ropes/8 nails); localized intent-only menus; shared
frame lease, exact ID/contents/placement validation, unpublished rollback and
server GlobalModData recovery guards. The legacy research check is shared unchanged.
Knowledge's pinned dedicated storage block remains enforced. The context assembly
is immediate, not a crafting-panel/timed recipe. No frame models or migration added.

Read [construction and human cases](EFFIGY_FRAME_CONSTRUCTION.md),
[pinned dependency identities](audits/0.31.0-dev.4.dependencies.json) and
[native facts/fingerprints](audits/0.31.0-dev.4.native.json). Steam build 25485521;
exact game SemVer UNKNOWN. Packaged and differing loose IsoGridSquare normal-item
placement paths were compared; decompiled branch ordering differs, relevant frame
registration/publication semantics agree by source inspection. Active classpath and
native dispatch remain UNKNOWN. No native class was loaded/executed/installed.

## Offline commands and results

Windows Python 3.12.14, lupa 2.6 / Lua 5.1; native/world/transport/save facades.

```text
python scripts/check_versions.py
python scripts/prepare_ci_dependencies.py --check
python scripts/run_host_tests.py --dependencies .local/ci-dependencies --only tests/test_effigy_frame_construction.lua tests/test_effigy_frame_menu.lua tests/test_effigy_container_feeding.lua tests/test_effigy_container_server.lua tests/test_effigies.lua tests/test_sandbox_contract.lua
python scripts/run_host_tests.py --dependencies .local/ci-dependencies
python -m unittest discover -s tests -p "test_*.py"
python scripts/dependency_contracts.py --dependencies .local/ci-dependencies
python scripts/audit_project.py --dependencies .local/ci-dependencies --output .local/effigy-construction-audit-final.json
python scripts/check_versions.py --release
git -c core.autocrlf=false diff --cached --check
```

[TESTED: offline] Pre-edit version checker PASS at dev.3. Focused 6/6 and full
71/71 Lua files PASS; 25/25 Python tests PASS. Five clean pinned public dependency
fixtures and direct/transitive contracts PASS. Current version checker PASS. Source audit PASS: 66 Lua syntax files, case/require checks, localization parity across 29 language folders and pinned historical Contents preservation. Overview source digest validated. Final staged index checks are recorded below.

New regressions use the actual pinned Knowledge API and the shared legacy check:
SP learning succeeds offline; server reads refuse even a known SP ledger. Native
facades cover exact costs, research/provider refusal, sparse/duplicate/stale IDs,
queued-source moves, equipment, dead actors, safehouses/floors/weight/remote tiles,
empty and loaded frames, shared lease, partial removal/output insertion, native
registration before back-link, container-link-before-root-removal, verified rollback,
foreign-item preservation, missing factory, postcommit publication failures, future/
malformed server journals, reload and client-replaced player data. UI regressions
cover pooling/test probe, refreshed material selection, disabled research, pure
client intent and shared SP endpoint. Existing category/feeding/legacy tests pass.

Strict --release exits 1 on retained historical Contents/source parity;
no current package was requested/built. This remains a release consistency blocker,
not a warning. A source audit/CI PASS cannot establish package or runtime readiness.

## Runtime gates

Native/SP/dedicated NOT TESTED. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. Human
acceptance includes actual menu/controller use, native crafting/placement/guard
binding, IDs/packet order/readback, queued transfers, competing feeds, inventory/
world/global save compatibility, streaming, late join/rejoin, retained recovery and
dedicated restart. Global journals are non-secret and request-readable; never import
received tables. Save requests and independent world/player/global saves are not
crash atomicity proof. No launch, deployment, packaging or Workshop upload.

## Final review

Source audit reports no source failures; current package parity remains BLOCKED.
Public origin and existing draft PR #7 were reverified. Precommit freshness is
REVIEW solely for these intended changes: local/upstream c5fcd21 are identical,
0 ahead/behind upstream and 5 ahead/0 behind origin/main. No unfinished operation.
[TESTED: offline] Final staged audit PASS: 486 indexed files; zero denied paths or potential secret paths. Intended source, tests and documentation only; no generated/private artifacts staged. git diff --cached --check PASS. This is a heuristic review, not a comprehensive secret detector. Exact push SHA and CI results are verified and recorded in draft PR #7 after push.
