# Changelog

## 0.31.0-dev.6 - Workshop description size gate, 2026-10-17

- Compatible publishing/packaging follow-up: shorten the canonical description below the Steam UTF-8 byte limit while preserving implemented features, research/MP limitations and credits. Add a fail-closed pre-packaging size check for both canonical and serialized descriptions, including multibyte regression coverage.
- Preserve the immutable unpublished dev.5 candidate and prior mirror/provenance; generate a new dev.6 package instead of overwriting artifacts. Gameplay, research, configuration defaults and save/network schemas are unchanged apart from current version markers. Use the latest user-supplied B47ANCE-branded thumbnail, retaining exact original source bytes and an approved deterministic 512-square Workshop derivative. G7/stable G8 remain blocked; upload outcome is separate.

## 0.31.0-dev.5 - frame recipe and reusable tools, 2026-10-17

- Authorized Workshop MP testing distribution preparation: retain the supplied original poster, make an approved 512-square preview, update test labels/dependencies/source link/known limits, regenerate the current Contents mirror through the established builder and preserve prior provenance. Upload outcome is recorded separately; G7/stable G8 remain blocked.

- Artwork follow-up: use the user-supplied Nightfall/UV image unchanged for the project/Workshop preview and source mod thumbnail. Preserve the separate icon and historical packages. This artwork-only change retains the development version; no gameplay change or upload.

- User-selected default materials: 1 log, 3 large branches, 1 rope, 8 loose nails. Add bounded EffigyFrameLargeBranches sandbox quantity; update default logs/ropes without overriding saved explicit values.
- Require working, distinct hammer/sharp-knife tools and a Base.HandDrill in main inventory; equipped tools count and are never consumed or worn. Recheck authoritative tools before creating the committed output; compensate materials if a tool disappears.
- Update localized cost/tool tips, source/native evidence and regressions for missing, broken, moved/nested and wrong tools/branches, retained condition/equipment, server costs and rollback. Research, placement and category contracts remain unchanged. Native/SP/dedicated NOT TESTED; G7/stable G8 BLOCKED.

## 0.31.0-dev.4 - reusable frame crafting and placement, 2026-10-17

- Add server-owned context-menu assembly of an empty reusable frame from actual main-inventory materials. Defaults: 4 logs, 2 ropes and 8 loose nails, each with bounded server sandbox settings. Reuse the existing NF-FIELD-026 research check; missing/blocked knowledge fails closed. Legacy construction delegates to the same unchanged check.
- Place the actual frame, including valid stored contents, through the vanilla world-inventory-item route. Validate ownership, equipment, knowledge, loaded adjacent tile, floor/obstruction, safehouse permission, weight and shared frame lease. Publish only committed changes; repeated IDs cannot create a second frame.
- Compensate partial native construction/placement failures without cloning or stealing foreign items. Retain uncertain guards in server GlobalModData and frame state; unknown/pending records block automatic replay. Player ModData is not trusted for recovery. Native saves are not crash/cross-file atomicity proof.
- Localized intent-only UI, source/native fingerprints and new regressions. Native/SP/dedicated NOT TESTED; Knowledge MP storage, non-feeding influence/attribution, migration and all three production models remain gates. No package, deploy or upload.

## 0.31.0-dev.3 - reusable frame feeding, 2026-10-17

- Add a server/SP MORTIS transaction-v1 provider over actual stored items. Each meal removes one complete ordinary-meat item or consumes the edible canonical tissue from one part; frames, remaining stock and depleted physical parts survive. No duplicate nutrient ledger or legacy .5 fallback.
- Ordinary meat feeds hungry infected without body-part reactions, searches or grudges. Existing source-specific body-part consumption eligibility and all five exclusive categories remain; only physical emptiness clears a category.
- Share a server lease with loading; revalidate exact items/material preimages, world identity, reach, actor/reaction and revision. Compensate failed meals; preserve foreign state and quarantine uncertain rollback or successful-publication failure. Retained pending feed intents block automatic replay after reload.
- Use native same-ID part replacement/removal packets and explicit frame chunk-save requests. Add bounded loaded-object discovery and real-coordinator regressions. Construction, non-feeding reactions/attribution, migration and three production models remain pending. Native/SP/dedicated NOT TESTED; G7/stable G8 BLOCKED.

## 0.31.0-dev.2 - server-owned effigy frame loading, 2026-10-17

- Merge current main MORTIS recovery fixes and the current pinned dependency contracts, retaining all prior validation as historical.
- Resolve the dynamic-admission race through permanently closed native insertion and synchronous server Lua loading of actual items; validate whole batches, ownership, reach, safehouses, equipment, capacity, category and replay revision. Preserve native unloading, original item identity/provenance and legacy effigies. No custom Java or private queue access.
- Add an undistributed EffigyFrame container prototype, localized source-aware load menu and server sandbox capacity (1-40, default 20). Derive only the three agreed visual states. No recipe/loot replacement, reusable feeding, migration or production renderer/model is enabled.
- Restore failed batches before publication; quarantine uncertain rollback or committed transport failure without recreating items. Add server, client-intent and race regressions. Dedicated/native durability remains NOT TESTED; G7/stable G8 BLOCKED. See docs/VALIDATION_0.31.0-dev.2.md.

## 0.31.0-dev.1 - effigy container policy foundation, 2026-10-17

- Development MINOR prerelease: read-only classification/admission for separate ordinary meat, human, regular-zombie, Feral and Smart-Feral categories. Validate whole insertion batches and derive only EMPTY, MEAT_LOADED and BODY_PART_LOADED from physical contents. Reject mixing, bags, duplicate/sparse/malformed input, unsupported provenance and invalid material; depleted parts stay category-locked until physically removed.
- Record the native queued-transfer admission gap; do not expose a client-authoritative or optimistic world container. Existing effigy construction, feeding, schemas, balance and synchronization are unchanged.
- Preserve the user-supplied spiked-post concept and define the three matching asset groups. No meshes, sprites or renderer generated.
- 64 Lua files and 25 Python tests PASS offline; no native/SP/dedicated validation. G7/stable G8 BLOCKED; no package, deploy or upload. See docs/VALIDATION_0.31.0-dev.1.md.

## 0.30.1-dev.1 - MORTIS recovery fixes, 2026-10-17

- Release only Nightfall-owned movement requests/ceiling before canonical clear; disable commits NORMAL only after verified cleanup, with other owners preserved.
- Defer hibernation when UV-slow release refuses and retain its flag across lifecycle serialization.
- Check assignment compensation and readback; retain a versioned server recovery journal across consumer reload, gate further lifecycle work, and preserve uncertain/future/conflicting records for explicit review.
- Separate source API presence from capability readiness; require MORTIS API 1.6 / food transaction v1 and report Knowledge 0.16.0's intentional MP-storage block without bypass.
- Pin current merged MORTIS and Knowledge inputs, add real-module and production-fragment failure regressions, and update human acceptance cases. Compatible PATCH; balance/settings and existing schemas unchanged, additive recovery record version 1.
- Offline evidence only. Runtime tests remain human-operated; G7/stable G8 BLOCKED. No package/deploy/launch/upload.

## 0.30.0 - SPXTRM dependency transition, 2026-10-16

- Documentation planning follow-up, 2026-10-17: record the user-approved reusable effigy container, separate source categories, prohibition on meat/body-part mixing, and three planned visual states. No runtime/art/version change or new gameplay validation.

- MINOR before 1.0: required activation Mod ID changes from lightWorks to B47ANCEDSPXTRM. Update server/client mod lists together; existing Lua imports, saved fields, optical geometry and infected policy stay unchanged.
- Preserve current main audit/CI and reversible MORTIS effigy fixes. Pin the matching public SPXTRM source for offline CI. Source checks do not prove native loader or multiplayer behavior. G7/stable G8 BLOCKED.

## 0.29.1 - audit completion tooling, 2026-10-16

- Integrate the independently developed 0.29.1-dev.1 MORTIS effigy reserve/commit/rollback adapter. Preserve exclusive claims, revision checks, tissue/claim compensation, post-success native cleanup and consumed tombstones. Retain 0.29.1 as the existing canonical development PATCH; no stable tag or runtime certification.

- Development PATCH: separate source audit success from strict release consistency; protect historical Contents by pinned Git tree and worktree/index evidence. Apply operation snapshots explicitly, preserving prior evidence. Source defects and corrupt/unclassified archives still fail.
- Add commit-pinned public dependency fixtures and least-privilege Linux/Windows offline CI with pinned actions/interpreter wheels. Preserve the historical archive helper and concurrent effigy work.
- Validate locale file/key inventories, nonempty values and substitution placeholders. Declare English fallback accurately; fluent translation remains unreviewed.
- 62 Lua files and 25 Python regressions PASS offline. Current package is absent; native/SP/dedicated NOT TESTED. G7 and stable G8 BLOCKED. See docs/VALIDATION_0.29.1.md and runtime acceptance handoff. No deploy, upload or stable tag.

## 0.29.1-dev.1 - 2026-10-16

- Fix effigy consumption under MORTIS API 1.6 using exclusive reversible reservations, staged tissue loss and compensation. Remove native objects only after confirmed ZombieFed; retain inert consumed tombstones on cleanup failure.
- Revalidate authority, object identity/liveness, source revision, floor/range and reaction at reserve/commit. Exclude other food claims/destruction during the lease. Prevent consumed-state re-registration and cross-object ID rebinding; completeClaim now enforces canonical authority.
- Add actual MORTIS coordinator/model/event-bus integration regression with mocked native boundaries. 63 Lua and 19 Python tests PASS offline; native SP/dedicated durability, ownership, replication and restart NOT TESTED. G7 and stable G8 BLOCKED. No packaging/deployment/publication.

## 0.29.0 - remains inspection and current dependency audit, 2026-10-16

- Target development MINOR: add read-only client remains-condition presentation; preserve canonical gameplay, loot and saved schemas. Update the required medical Mod ID/source layout to B47ANCEDHealthCare while preserving its verified medWorks Lua/item contracts.
- Dependency source contracts PASS; 62 Lua and 19 Python tests PASS offline. The own-requirements gate now rejects inventory/runtime drift. See docs/VALIDATION_0.29.0.md. Existing packages are preserved; no new package, deployment or upload. Actual native UI/SP/dedicated remain NOT TESTED; G7/G8 BLOCKED.

## 0.28.0 - current-family integration and audit fixes, 2026-10-16

- Development MINOR: use current Power/Knowledge dependency IDs and APIs, including battery/debug/preset contracts. Nightfall API, save and sandbox schemas stay unchanged; dependency installations migrate as a set.
- Bound native corpse collection reads and pause discovery at waiting admissions. Retire successfully committed candidates under saturation so later corpses receive dose.
- Enable intelligent regular effigy destruction; only successful smart destruction propagates hunts/grudges.
- Prepare recoverable package transactions, resume missing outputs without overwrites, and verify builder/commit/evidence provenance.
- All 61 Lua and 18 Python offline tests pass. Whole-family startup remains blocked by remaining upstream migrations. See docs/VALIDATION_0.28.0.md.
- Preserve 0.27.4 Contents, artwork and all artifacts. No new package, deployment, upload or game/server launch. SP/dedicated NOT TESTED; G7/G8 BLOCKED.

## 0.27.4 â€” corpse-runtime fixes, 2026-10-16

- Honor both Nightfall and regional-tissue disable gates for corpse discovery, death marking, and processing. Re-enable by discovering at the current minute, with no disabled-time exposure backfill.
- Preserve per-emitter discovery offsets across bounded chunks, rotate sources fairly under the scan ceiling, and follow moved sources without restarting other emitters' work.
- Surface rejected/throwing pipeline calls, retain successful-work diagnostics, and advance the candidate cursor so failures cannot monopolize the processing turn.
- Retain actual journal commit time and retry derived remains stages without replaying dose. Corpse/tissue/remains schemas and gameplay balance are unchanged.
- All 59 Nightfall host test files pass offline in Lua 5.1, including the five former audit failures and new disable/movement/budget/recovery regressions. Current version mirrors pass. See `docs/VALIDATION_0.27.4.md`.
- Restored a reproducible packaging workflow and refreshed Contents from source with a verified retained backup of the old mirror. The 0.27.4 development ZIP has exact source/support/wrapper parity, checksum and per-member provenance; ten packaging safety/integrity tests pass. See `docs/PACKAGING_0.27.4.md`.
- Runtime source, artwork and all earlier generated artifacts are unchanged by the packaging follow-up. No deployment, Workshop upload, SP test or dedicated MP test. G7 BLOCKED / NOT TESTED; G8 BLOCKED.
- Concurrent dependency identity migrations removed the default source lookup. The 59 Lua tests were rerun successfully using SHA-256-pinned matching first-party archives in ignored fixtures; this is not compatibility validation for the renamed current family. No runtime dependency migration is included in 0.27.4.

## 0.27.3 â€” repository onboarding, 2026-10-16

- Imported the existing development source into the user-authorized public GitHub repository; no earlier Git history was available.
- Established root VERSION from the existing source/README/mod.info value, with declared mirrors, a version policy, and consistency checks.
- Added Nightfall-specific AGENTS guidance, source/artifact inventory, a portable offline test runner, and a dated audit with reproductions.
- Preserved runtime source, stale Contents, artwork, saves, and existing packages byte-for-byte. No deployment, packaging, Workshop upload, or game/server launch.
- Original host tests: 57/57 PASS in offline Lua 5.1. Five new corpse-runtime audit cases fail; full suite and release gates remain blocked. SP/hosted/dedicated NOT TESTED in this audit.

## Earlier development

The imported source and Workshop change notes predate repository onboarding. Preserve their original dates, versions, and claims as historical evidence. This changelog does not reconstruct or certify missing release history.
