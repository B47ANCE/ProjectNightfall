# Nightfall 0.28.0 development validation - 2026-10-16

## Scope and compatibility

[VERIFIED] Canonical VERSION is 0.28.0 (development MINOR). This requested integration changes required dependency installations to B47ANCEDPower and B47ANCEDKnowledgeAndWisdom. Nightfall Mod ID/Workshop ID, public APIs, existing research/knowledge IDs, persisted corpse/tissue/remains schemas and sandbox identifiers are unchanged. Dependency storage migration stays owned by the dependencies. Old dependency installations must migrate as a set.

Nightfall production registration, knowledge queries, Power sandbox presets, test-kit battery item types, diagnostic globals, test discovery and debug-surface paths now use current contracts. Spectrum still exposes lightWorks in the recorded snapshot. No legacy global/module alias is installed. The runner's default is current sibling sources, not the historical 0.27.4 archive fixtures.

## Regressions and fixes (audit findings 2-6)

2. [TESTED: offline Lua 5.1] Saturated queues no longer permanently exclude later healthy corpses. Discovery pauses its per-square cursor at the first denied admission; processing releases a slot only after a committed positive dose interval with no pending stage synchronization. Fifty illuminated corpses at limit 16/process budget 2 all eventually receive processing. Failed/pending journal work remains enrolled for retry; retries do not advance a rejected clock.
3. [TESTED: offline native-shaped collections] PN_CorpseDiscovery visits at most eight collection records per square-budget unit, with weak square cursors. A 10,000-body square stays bounded per update and eventually reaches every member. Shrink/missing-method/backpressure cases are covered. Existing server square budget scales grid/record work; eight is an internal batching ceiling, not a new gameplay option. Actual high-density engine performance is a runtime gate.
4. [TESTED: offline Lua 5.1] Intelligent regular `destroy` reactions receive a destruction weight and action. Successful `destroy_search` alone can propagate a hunt/grudge. Destruction statistics and follow-up behavior require successful completion.
5. [TESTED: disposable Git-backed packaging fixtures] Stage ZIP, manifest and checksum before installing outputs. A persistent owned transaction under .local/packaging-pending survives process interruption. Atomic hard-link creation installs missing files only; retries verify captured bytes and never overwrite an existing differing output. Tests inject preparation failure, mirror install failure and each of the three output-install failures, then verify recovery and unchanged existing bytes. Unexpected collisions fail before installation. This tests NTFS/Python, not other filesystems or power-loss durability.
6. [TESTED: disposable Git-backed packaging fixtures] Manifest validation checks builder bytes, SHA format, commit existence/HEAD ancestry, dirty-flag type and fixed offline gate/evidence labels. A clean source record must match the committed inventory/content (Git LF/CRLF text equivalence is accepted; raw source/package hashes remain exact). Dirty builds bind exact snapshot hashes plus a real ancestor base; they are not claimed to be committed-source builds. Invalid and well-formed forged hashes/commits, false clean claims and gate tampering are rejected. This is local consistency verification, not cryptographic authorship authentication.

## Commands and outcomes

Run from repository root with real Python 3.12.14, lupa 2.6 Lua 5.1 and Git available. Tests use temporary project trees, never player saves or actual release outputs.

| Command | Outcome |
| --- | --- |
| `python scripts/check_versions.py` | PASS, declared current source mirrors |
| `python scripts/run_host_tests.py` | 61/61 PASS using recorded current sibling snapshots |
| `python -m unittest discover -s tests -p "test_*.py"` | 18/18 PASS (17 packaging, 1 transitive-contract test) |
| `python scripts/dependency_contracts.py` | Nightfall direct contracts PASS; upstream transitive contracts BLOCKED |
| `python scripts/audit_project.py` | Expected FAIL: retained historical Contents differs, current package absent, historical protection baseline includes changed source, and upstream migration is incomplete. Source syntax/requires/case/Lua-only and index secret/path checks are evaluated separately. |
| `python scripts/check_versions.py --release` | Expected FAIL: current source is not packaged |

The new saturation, AI reaction, interrupted-write and provenance assertions were observed failing before their fixes. Later checks added native collection fairness, real current API registration and post-link interruption coverage. Host boundary mocks remain mocks; passing them does not prove whole-family startup or native transport.

## Recorded dependency evidence

Source versions and full runtime-tree SHA-256 values below were stable before/after the final Lua test run. See [machine-readable contracts](audits/0.28.0.dependencies.json). Other projects were inspected read-only; concurrent changes there are independent of this iteration.

| Mod ID | Version | Source tree SHA-256 |
| --- | --- | --- |
| lightWorks | 0.25.5 | `2c4977deaaeaef7682bdbe40c9bc03fc80c1f171d7e4140f82d6d0776976477b` |
| ProjectMORTIS | 0.24.0-dev.2 | `0e1e4572910a0941815595fb4b65a0249ba262e1064177411b326b4416793512` |
| B47ANCEDPower | 0.17.0-dev.1 | `3a06a5ba3a25d31e5c65c1ee735e7279b45df7f6697627615bbaeb4e1a8c2db5` |
| medWorks | 0.9.2 | `cc540527c7a2d1503de9823ec8defae8407886fb17e569e742cf71697b048cd2` |
| B47ANCEDKnowledgeAndWisdom | 0.13.0 | `069b883a798812f32a03e6159d7ae4db9fdb985bde3ea01c7ed63705727fa05c` |

Remaining upstream blockers in this snapshot: Spectrum/lightWorks requires removed Mod ID powerWorks; medWorks requires experienceWorks and imports its API/Progression modules. M.O.R.T.I.S. migrated during the work and passes this contract check in the final recorded snapshot. Nightfall's independent host tests do not exercise those entire startup paths. Resolve the upstream migrations before assembling a full-family test installation.

## Native evidence and authority

[VERIFIED: vanilla client Lua call form] Steam build 25485521, exact game SemVer UNKNOWN. ISWorldObjectContextMenu.lua lines 307-310 obtains square:getStaticMovingObjects(), then uses collection:size() and zero-based collection:get(index). File SHA-256: `980e67622e34422983cd33d64ea4f6dbff5cdf151a6dd9aef6acb669261fb47f`. The bounded adapter also reuses the existing Mortis corpse classifier and square collection forms; no custom Java code is introduced. A reusable observation was recorded in the local API draft.

[VERIFIED: source] Runtime.update/markDeath still require canonical Mortis authority, use server Config, and fail without an emitter provider. Clients perform no corpse discovery/dose mutation. Discovery cursors and admission pressure are authority-local; canonical tissue journal and remains synchronization retain their existing persistence/replay ownership. No new network protocol or client-owned shared state is added. Join/reconnect, serialization and restarts remain [RUNTIME GATE]. Failed candidates/pending synchronization deliberately retain slots; persistent upstream failures must be repaired, not evicted by discarding work.

## Preserved outputs and gates

[TESTED: SHA-256] The retained 0.27.4 ZIP remains a5d10a92d46634e6c89e57eaaf0eab24dbd2f1d0f5f5549d1413768faa74f6d1; 0.27.3 ZIP remains 1481c1565b85bc357e557f7fec1799cb69a101ca5a7e0eb6081b53b5a28df765. Full 0.27.4 Contents tree digest remains d5b4fced091145a60d8224eb13bdd2696ebe272f1efb1af5e183720b4e42b50a. Historical docs/provenance, staging backups and custom artwork are preserved. No actual 0.28.0 build was run; packaging tests use disposable fixtures.

SP/native Kahlua/hosted/dedicated multiplayer: NOT TESTED. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. No deploy, Workshop upload, game/server launch, stable tag or main merge. Next gates: finish upstream migrations, explicitly package a current test build, then validate crowded-square UV fairness, darkness/re-entry, save/reload, pending-sync recovery, effigy destruction, client join/rejoin and dedicated restarts in the real game.
