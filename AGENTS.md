# Project Zomboid Codex startup

<!-- PZ-CODEX-MANAGED-STARTUP -->
Read the current global rules at C:\Users\willi\.codex\AGENTS.md before work.
Team skills are installed at C:\Users\willi\.agents\skills.
Preserve project-specific identity, instructions, source, local settings and runtime evidence.
<!-- /PZ-CODEX-MANAGED-STARTUP -->

# Project Nightfall instructions

## Identity and source ownership

- Display name: Project Nightfall; Mod ID: `ProjectNightfall`; author: B47ANCE.
- Canonical version: `0.27.4` in root `VERSION`; policy: `docs/VERSION_POLICY.md`.
- Public repository: https://github.com/B47ANCE/ProjectNightfall
- Existing Workshop item: `3788593239`; item creation and visibility changes need separate authorization.
- Authoritative runtime source: `src/ProjectNightfall/42/`.
- `src/ProjectNightfall/info.txt`, `src/ProjectNightfall/thumbnail.png`, and `art/` are source/support assets.
- `Contents/mods/ProjectNightfall/` is the generated exact mirror of `src/ProjectNightfall/`, including the 42 runtime and parent support files. Source remains authoritative. Rebuild it only through the explicitly requested packaging command, never by independently editing mirrored code.
- `dist/`, staging backups, ZIPs, and `SHA256SUMS.txt` are generated/historical evidence, not implementation sources. Preserve them.
- `SOURCE_INVENTORY.json` records these classifications. Current packaging is `python scripts/package_project.py build`; historical deployment/uploader tools remain unverified. The superseded 67-file Contents copy is retained under `dist/staging-backups/contents-51c590fbd9d0`; preserve it.

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

Read `docs/PACKAGING_0.27.4.md` for current package evidence and `docs/VALIDATION_0.27.4.md` for the preceding corpse-runtime fix. The takeover audit and earlier validation records remain historical. Before editing, name intended files and invariants. Use a feature/fix branch, targeted staging, a public-push secret audit, and a PR before merging main. Run freshness checks; never auto-stash, reset, clean, pull, or rebase.

Run from this project root with a real Python 3.12+ executable (the Windows Store alias may be unusable; packaging checks Windows junctions):

```text
python scripts/check_versions.py
python scripts/prepare_test_dependencies.py
python scripts/run_host_tests.py --dependencies .local/validation-dependencies
python -m unittest discover -s tests -p test_packaging.py -v
python scripts/package_project.py verify
python scripts/audit_project.py --dependencies .local/validation-dependencies
```

Host tests require `lupa.lua51` and the five matching dependency sources. For 0.27.4 use the explicitly pinned fixtures in `tests/dependencies_0.27.4.json`: the preparation helper verifies retained archive hashes/identity/CRC and copies them only into ignored `.local` fixtures. All 59 files pass against that historical set. The default runner still targets sibling source checkouts and currently fails after powerWorks/experienceWorks identity migrations; never present fixture results as current-family compatibility. `--dependencies` also resolves declared relative debug-test paths. `--legacy-only` omits the audit path; use the default complete discovery with the explicit fixture root for full regression evidence. Do not distribute/deploy the fixtures or modify dependencies as part of packaging.

Before G8 also run `python scripts/check_versions.py --release`. Current package consistency passes, but this never clears G7 or stable G8. `python scripts/package_project.py plan` is read-only; `build` is an explicit manual packaging operation, not a deployment/upload command. It preserves superseded mirrors, refuses unexpected mirror files and existing-artifact collisions, and verifies its outputs. Never invoke build implicitly during an ordinary audit/version edit. Repeated builds must preserve identical ZIP/provenance bytes.

Distinguish [VERIFIED] source, [TESTED] offline, [INFERRED], [UNKNOWN], and [RUNTIME GATE]. The 2026-09 handoffs and their test totals are historical, not current runtime proof. Current game build/API exposure, native Kahlua, SP, hosted, and dedicated behavior remain unverified by this audit. Gameplay G7 is BLOCKED / NOT TESTED and stable-release G8 is BLOCKED. Only current global policy governs an explicitly requested Workshop MP test upload; an upload is never MP PASS.
