# Project Zomboid Codex startup

<!-- PZ-CODEX-MANAGED-STARTUP -->
Read the current global rules at C:\Users\willi\.codex\AGENTS.md before work.
Team skills are installed at C:\Users\willi\.agents\skills.
Preserve project-specific identity, instructions, source, local settings and runtime evidence.
<!-- /PZ-CODEX-MANAGED-STARTUP -->

# Project Nightfall instructions

## Identity and source ownership

- Display name: Project Nightfall; Mod ID: `ProjectNightfall`; author: B47ANCE.
- Canonical version: `0.27.3` in root `VERSION`; policy: `docs/VERSION_POLICY.md`.
- Public repository: https://github.com/B47ANCE/ProjectNightfall
- Existing Workshop item: `3788593239`; item creation and visibility changes need separate authorization.
- Authoritative runtime source: `src/ProjectNightfall/42/`.
- `src/ProjectNightfall/info.txt`, `src/ProjectNightfall/thumbnail.png`, and `art/` are source/support assets.
- `Contents/mods/ProjectNightfall/42/` is a preserved **stale 0.27.1 packaging copy**. It is not interchangeable with src. Do not edit, relabel, overwrite, or package it implicitly.
- `dist/`, staging backups, ZIPs, and `SHA256SUMS.txt` are generated/historical evidence, not implementation sources. Preserve them.
- `SOURCE_INVENTORY.json` records these classifications. Packaging/deployment tools referenced by old handoffs are missing; do not execute guessed replacements.

## Team skills and local setup

Use the installed user-profile skills at `%USERPROFILE%/.agents/skills`; never vendor that store or machine configuration into this repository. Shared tools live at `%USERPROFILE%/.codex/b47anced-team/tools`.

Select skills by the actual work:

| Work | Required installed skill(s) |
| --- | --- |
| Every session before edits; before commit/deploy/publish | `pz-repository-startup` |
| Setup, canonical versions, source/package ownership | `pz-repository-governance`, `pz-github-versioning` |
| Audit and organization | `pz-repository-hygiene`; cleanup separately uses `pz-artifact-retention` |
| Bugs, APIs, game-build changes | `pz-debug-root-cause`, `pz-api-audit`, `pz-build42-compatibility` as applicable |
| Authority, networking, persistence, migration | `pz-mp-audit`, `pz-persistence-and-migration` |
| Sandbox/UI, items/recipes, interoperability | `pz-ui-ux-development`, `pz-item-and-recipe-development`, `pz-mod-compatibility` as applicable |
| External-mod research | `pz-clean-room-research` before inspection; no upstream changes |
| CI, secrets, remote diagnostics | `pz-ci-automation`, `pz-security-permissions`, `pz-dedicated-server-sftp` as applicable |
| Artwork, geometry, animation | Appropriate `pz-2d-asset-pipeline`, `pz-3d-asset-pipeline`, or `pz-character-animation` |
| Explicit deploy/publish commands | `pz-deploy` / `pz-publish`, plus all applicable gates |

Codex owns production writes. Any separately authorized scouts/reviewers inspect read-only. Follow current global delegation rules; this file does not itself request agents. Preserve local `.codex` settings; do not import their linked shared configuration into Git.

## Behavioral invariants

- Lua-only runtime. Vanilla engine APIs exposed to Lua are permitted; custom Java/JAR/bridge/native dependencies are prohibited.
- Clients submit intent; canonical authority validates, mutates, persists, and synchronizes shared gameplay. Never fall back to client ownership when an adapter is unavailable.
- Nightfall owns infected policy; M.O.R.T.I.S. owns generic entity/anatomy/authority services; lightWorks owns UV/emitter facts; powerWorks owns energy; medWorks owns detached-part provenance; experienceWorks owns research/knowledge infrastructure.
- Use the regional tissue pipeline and its bounded lifecycle scheduler. Never restore retired direct-health UV damage or a second zombie exposure queue from backups.
- Preserve clothing, loot, canonical tissue, transaction/replay protection, save schemas, hibernation/rise, and source-specific natural/artificial UV rules.
- Meaningful shared gameplay configuration belongs in server-authoritative sandbox options with stable identifiers, localization, bounds, and existing-save behavior. Technical safety bounds remain internal with rationale.
- Searches and scheduled work must remain bounded and fair. Successful diagnostics must reflect actual successful processing.
- Preserve custom artwork. Do not use branding defaults to overwrite supplied assets.
- Do not add Project Remnants detection or compatibility. EXT-27 remains deferred until its documented release and treatment gates are met.

## Validation and iteration

Read `docs/AUDIT_2026-10-16.md` before choosing the next slice. Before editing, name intended files and invariants. Use a feature/fix branch, targeted staging, a public-push secret audit, and a PR before merging main. Run freshness checks; never auto-stash, reset, clean, pull, or rebase.

Run from this project root with a real Python 3 executable (the Windows Store alias may be unusable):

```text
python scripts/check_versions.py
python scripts/run_host_tests.py
python scripts/audit_project.py
```

Host tests require `lupa.lua51` and the five dependency source checkouts in sibling folders (`Project MORTIS`, `lightWorks`, `powerWorks`, `medWorks`, `experienceWorks`). The default runner includes audit regressions and currently fails on known defects. `--legacy-only` runs only the original 57 files; passing that subset is not an all-clear. Legacy debug-surface tests also rely on the documented sibling layout.

Before G8 also run `python scripts/check_versions.py --release`; current stale Contents blocks that check. No packaging script is verified for the present layout. No package/release is authorized by an audit or version update.

Distinguish [VERIFIED] source, [TESTED] offline, [INFERRED], [UNKNOWN], and [RUNTIME GATE]. The 2026-09 handoffs and their test totals are historical, not current runtime proof. Current game build/API exposure, native Kahlua, SP, hosted, and dedicated behavior remain unverified by this audit. Gameplay G7 is BLOCKED / NOT TESTED and stable-release G8 is BLOCKED. Only current global policy governs an explicitly requested Workshop MP test upload; an upload is never MP PASS.
