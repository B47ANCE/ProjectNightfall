# Nightfall 0.29.1 runtime acceptance handoff

Status: NOT TESTED. No launch, deployment, Workshop distribution or remote modification has been performed. This document makes the remaining tests concrete; it supplies no runtime PASS. Use disposable worlds and backups. The concurrently edited effigy branch is a separate iteration and must be reconciled and retested before a combined build.

## Prerequisites and evidence

Select an exact Nightfall commit and the five dependency commits from `tests/dependencies.lock.json`. Record exact game SemVer and Steam build on server and clients (minimum metadata is not installed-build proof), OS, mod IDs/order, sandbox settings, package/source hashes, save fixture and test time. Confirm a clean full-family native startup with no missing module, duplicate registration or Kahlua errors. Keep raw console/server logs local; commit only sanitized observations. Packaging/distribution, deployment and launching the game/server require explicit authorization separately from this audit.

For every case record PASS/FAIL/NOT TESTED, observer, commit/build, reproduction steps, actual results and sanitized evidence fingerprints. A host Lua test is never a replacement for these observations.

## Selected-corpse UI (SP, then dedicated clients)

1. Use marked infected corpses with valid persisted INTACT, SCORCHED, DESICCATED, CRITICAL and RESIDUAL stages produced by the authority-owned pipeline. Do not fabricate a PASS by injecting client-owned gameplay records.
2. Select each corpse with mouse and controller, at normal and increased UI scales. Check stage row and tooltip, localization lookup/fallback and availability. Open and close pooled menus repeatedly, switch selected corpses, and include another context-menu mod.
3. Check ordinary corpses, absent/future/malformed schemas, mismatched stage/index and disabled Nightfall. No misleading stage row should appear. Controller probing should not allocate duplicate options.
4. Compare authority-side tissue, stage, cause, inventory, clothing, worn and attached items before/after simply opening the menu. They must remain unchanged. Opening a menu should create no gameplay command or new scan.

## Corpse processing and authority (dedicated required)

1. With two clients, kill infected by UV and by ordinary damage. Verify death timing, server confirmation and copied anatomy/provenance. Original cause, clothing, inventory and loot must survive.
2. Expose corpses to supported artificial emitters. Check obstruction, coverage, elapsed-time cap, disabled/re-enabled behavior without disabled-time backfill, emitter movement and overlapping sources. Sunlight/stored UV alone must not consume corpse tissue.
3. Progress all semantic stages. Confirm server-only tissue changes and stage synchronization on both clients. Disconnect one client during transitions; rejoin/late-join and verify the received stage. An unchanged stage need not transport live quantities; the menu intentionally reports stage only.
4. Save/reload and restart the dedicated server from the disposable fixture. Confirm journal/replay protection, no repeated tissue loss, correct stage recovery and loot preservation. Exercise transient send failures only with an approved test harness; successful retries must not duplicate gameplay changes.
5. Stress more eligible corpses than per-turn/candidate budgets, emitters moving while scanning, fake-dead hibernators and non-infected corpses. Check bounded work and fair eventual processing using existing debug diagnostics. Record tick-time observations and counts; do not invent performance thresholds after the test.
6. Repeat both presets, starvation/Feral eligibility, day/night rise, regional healing and dedicated effigy/group/migration regressions. Client requests must never own canonical state. Include malicious/malformed-request checks through existing bounded test facilities.

## Presentation capability blockers

No smoke or visible-remains renderer is enabled. Existing source research rules out native burning, world smoke and destructive skeleton/fire corpse conversion as cosmetic shortcuts. The selected MORTIS source has no owned smoke/remains rendering adapter. Further implementation needs verified Lua exposure, exact receiver/signature/return and per-instance cleanup, posture/orientation handling, corpse rendering and replication/recovery evidence. Shared collection clearing, stored numeric cleanup indices and loot-destroying conversion remain unacceptable.

A candidate probe must be separately designed and reviewed for an isolated test object before execution, retain instance identity, preserve unrelated effects, and demonstrate repeated cleanup/pooling, prone/corpse behavior, streaming and real-fire coexistence. Do not restore the retired guessed renderer or infer corpse support from inherited methods. Until this gate is resolved, the existing localized stage information is the safe Lua-only presentation increment.

## Other blocked roadmap inputs

- Fluent translations and native glyph/layout review: English fallback only; see LOCALIZATION_POLICY.md.
- Balance tuning: requires recorded runtime observations rather than new arbitrary defaults.
- Final screeches/audio: awaiting supplied final assets and ownership/provenance.
- Unloaded migration: needs a verified Lua population/route API and authority/save contract.
- EXT-27 condition: deferred until release and explicit canonical treatment approval. Optional history consumer: deferred until its owning schema exists. Project Remnants remains excluded.

G7 remains BLOCKED / NOT TESTED until dedicated acceptance passes for the exact candidate. Stable G8 remains BLOCKED even when offline CI is green. Any future explicitly authorized Workshop MP test upload is distribution evidence only and requires its own offline gates and labeling.
