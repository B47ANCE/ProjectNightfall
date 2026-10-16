# Changelog

## 0.27.4 — corpse-runtime fixes, 2026-10-16

- Honor both Nightfall and regional-tissue disable gates for corpse discovery, death marking, and processing. Re-enable by discovering at the current minute, with no disabled-time exposure backfill.
- Preserve per-emitter discovery offsets across bounded chunks, rotate sources fairly under the scan ceiling, and follow moved sources without restarting other emitters' work.
- Surface rejected/throwing pipeline calls, retain successful-work diagnostics, and advance the candidate cursor so failures cannot monopolize the processing turn.
- Retain actual journal commit time and retry derived remains stages without replaying dose. Corpse/tissue/remains schemas and gameplay balance are unchanged.
- All 59 Nightfall host test files pass offline in Lua 5.1, including the five former audit failures and new disable/movement/budget/recovery regressions. Current version mirrors pass. See `docs/VALIDATION_0.27.4.md`.
- Existing Contents, artwork and generated packages remain preserved; no 0.27.4 package, deployment, Workshop upload, SP test or dedicated MP test. G7 BLOCKED / NOT TESTED; G8 BLOCKED.

## 0.27.3 — repository onboarding, 2026-10-16

- Imported the existing development source into the user-authorized public GitHub repository; no earlier Git history was available.
- Established root VERSION from the existing source/README/mod.info value, with declared mirrors, a version policy, and consistency checks.
- Added Nightfall-specific AGENTS guidance, source/artifact inventory, a portable offline test runner, and a dated audit with reproductions.
- Preserved runtime source, stale Contents, artwork, saves, and existing packages byte-for-byte. No deployment, packaging, Workshop upload, or game/server launch.
- Original host tests: 57/57 PASS in offline Lua 5.1. Five new corpse-runtime audit cases fail; full suite and release gates remain blocked. SP/hosted/dedicated NOT TESTED in this audit.

## Earlier development

The imported source and Workshop change notes predate repository onboarding. Preserve their original dates, versions, and claims as historical evidence. This changelog does not reconstruct or certify missing release history.
