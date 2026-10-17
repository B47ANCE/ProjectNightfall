# Nightfall 0.29.0 audit and roadmap increment - 2026-10-16

## Outcome and inventory

[VERIFIED: source] Canonical VERSION 0.29.0 is a development MINOR. Source remains src/ProjectNightfall/42 plus its parent support assets; generated Contents remains the historical 0.27.4 copy. No source layout, save/schema, gameplay value, server authority or item identity migration is performed. This iteration starts the presentation roadmap; it does not claim that native smoke or physical remains visuals are complete.

Audit began at b09aa532e60ede9c9641bcf49c49f8c32ed99421 with a clean working tree, matching upstream, ahead 4/behind 0 relative to remote main and no unfinished operations. The named feature branch is retained; no merge or history rewrite.

## Prioritized findings and disposition

1. **P1, confirmed source load blocker, fixed:** Nightfall still required medWorks after the repository/runtime Mod ID moved to B47ANCEDHealthCare. Required metadata, source inventory, debug-test layout, descriptions and guided dependency text now use the current Mod ID. Health Care deliberately retains medWorks Lua/global/item contracts, verified in its init.lua, scripts and test harness; blindly renaming those would introduce bugs. No dependency repository is modified. Current direct/transitive source contracts pass for the recorded snapshot.
2. **P2, validation blind spot, fixed:** The dependency gate checked selected siblings without comparing Nightfall's own mod.info requirements. It now rejects stale/missing own requirements and selection mismatches. The regression fixture proves an old medWorks requirement fails even while the selected Health Care checkout exists, then passes with the correct ID.
3. **P2, renderer/runtime capability gates, still open:** Existing native smoke research does not establish safe instance cleanup/anatomical placement or corpse rendering. Native skeleton/fire conversions discard loot or replace the body. No such fallback is implemented. Full-family startup, native Kahlua/serialization, actual corpse transport and dedicated gameplay remain NOT TESTED.
4. **P3, localization debt, explicit:** 29 language folders have key parity, but 6,300 non-English values equal English after this increment. New remains keys follow the declared English fallback policy; translation mechanisms and key parity are tested, not translated-language quality.
5. **P3, audit/release workflow debt:** General audit still fails on intentionally retained old Contents, absent current package and differences against its historical operation-protection baseline. Those are not current source regressions. No CI workflow is configured. New packaging, deployment and Workshop publication require their own request; the audit does not build or delete artifacts.

## Roadmap work implemented

[TESTED: offline Lua 5.1] PN_UVRemainsMenu adds a production client information row and vanilla tooltip for the corpse already selected by vanilla. It reads only existing PN_UVCorpse and PN_UVRemainsState records, validates supported schemas and the stage/index pair, and uses localized stage/description keys. No world/inventory traversal, timed action, anatomy creation, canonical write, send or polling loop is introduced. The row is informative and unavailable for execution.

All five stages have labels: intact, scorched, desiccated, severe breakdown and residual tissue. Only semantic stage is shown because remaining quantities can change between synchronized stage transitions. The existing Enabled sandbox setting controls visibility; no extra micro-setting or balance constant is needed for a read-only observation.

The event's controller test calls the vanilla setTest helper without allocating a row/tooltip. Duplicate protection examines the current options, allowing subsequent openings of a pooled panel. Missing/unknown/corrupt records and unloaded objects produce no misleading information. Missing translation lookup falls back to authored English strings. No new server protocol, save field or authority exception is added.

Regression evidence includes release-mode registration, all stage values, malformed/future records, disabled behavior, translation fallback, duplicate/pool reuse and controller probing. Canonical input proxies throw on writes, and mutation/transmission canaries remain untouched. The new feature test was first observed failing for the absent module, then passes with the implementation. It does not prove the actual tooltip is visible in-game.

## Exact commands and evidence

Environment: Windows, real Python 3.12.14, lupa 2.6 Lua 5.1. Packaging tests operate only in disposable temporary Git fixtures.

| Command | Result |
| --- | --- |
| `python scripts/check_versions.py` | PASS, current source mirrors |
| `python scripts/run_host_tests.py` | 62/62 Lua files PASS |
| `python -m unittest discover -s tests -p "test_*.py"` | 19/19 PASS |
| `python scripts/dependency_contracts.py` | direct PASS; transitive PASS for recorded snapshots |
| `python scripts/package_project.py plan` | PASS, read-only plan: 154 source/support files, 156 prospective ZIP members, zero deletions |
| `python scripts/audit_project.py` | expected overall FAIL for historical mirror/current-package/protection reasons; 55 Lua syntax PASS, no family require errors, no case collisions, no custom runtime binaries, translation key parity PASS |
| `python scripts/check_versions.py --release` | expected FAIL, Contents/source parity: no current package is authorized/built |

The public index secret/path audit is run before the iteration push; heuristic checks are not an exhaustive secret detector. Native runtime claims remain separate from source/offline results.

## API evidence and multiplayer boundaries

[VERIFIED: installed vanilla client Lua] Steam build 25485521; exact game SemVer UNKNOWN. ISWorldObjectContextMenu.lua lines 122-218 document the controller probe helper, assign the picked corpse to fetchVars.body and invoke OnFillWorldObjectContextMenu(player,context,worldobjects,test). Lines 2595-2604 implement the reset pooled tooltip factory. File SHA-256 980e67622e34422983cd33d64ea4f6dbff5cdf151a6dd9aef6acb669261fb47f. A scoped reusable observation is recorded in the local API draft; no native source is shipped.

The existing server owns damage, marker/stage persistence and synchronization. Clients only consume the last received stage. Missing late-join data remains hidden until it exists; the UI does not invent or request canonical state. Menu reopen reads the current selected corpse again. Actual replication, late join/rejoin and restart behavior need dedicated evidence. The selected presentation code has no gameplay mutation, but the mod's existing G7/G8 requirements remain unchanged.

## Stable test dependency snapshots

Full runtime-tree hashes below were equal before/after the Lua suite. Concurrent later dependency changes are not automatically validated. See [structured evidence](audits/0.29.0.dependencies.json).

| Mod ID | Version | Runtime tree SHA-256 |
| --- | --- | --- |
| lightWorks | 0.28.0 | `e426795d24fcdb5f38a1709c6914f054d7ee81c264cd957cd86b7a4ada6c27c4` |
| ProjectMORTIS | 0.25.0-dev.2 | `39fda1a026373a6e866c5c00c2ff0f8c890bbe59f2fa175a95a5e791fe889258` |
| B47ANCEDPower | 0.17.0-dev.1 | `464d9699f54e51fa692b0043f2afce7a2e576a9a06b469843d8e452b067f1043` |
| B47ANCEDHealthCare | 0.10.0 | `9b99cf162a26b01c8db6bd74f31d8ed8158b50503e8a5d2b414a5476a3345b8e` |
| B47ANCEDKnowledgeAndWisdom | 0.15.0 | `6eba31314928898d386086b6548aec0e75940a21b514cb7ddb63c0f0ed93dfc2` |

## Protected artifacts and next steps

[TESTED: SHA-256] Existing 0.27.4 ZIP remains a5d10a92d46634e6c89e57eaaf0eab24dbd2f1d0f5f5549d1413768faa74f6d1; 0.27.3 remains 1481c1565b85bc357e557f7fec1799cb69a101ca5a7e0eb6081b53b5a28df765. Existing Contents, backups, historical reports/provenance and supplied artwork are preserved. No 0.29.0 package, deployment, upload, stable tag, game/server launch or main merge.

1. Validate the menu in SP at all stages, with mouse/joypad, UI scale, other context-menu mods, repeated openings and different selected corpses. Check that merely opening it leaves server tissue, loot and cause unchanged.
2. Verify server-created corpse marker/stage transport, late join/rejoin and save/restart, including stage transitions while a client is absent. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.
3. Continue native smoke/anatomical/remains presentation only after safe Lua instance ownership, cleanup/render exposure and loot-preserving recovery are verified. No broad fire/skeleton cleanup substitutes.
4. Keep live balance/audio, unloaded migration and EXT-27 at their existing evidence/asset/release/treatment gates. Project Remnants stays excluded.
