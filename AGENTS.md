# Project Zomboid Codex startup

<!-- PZ-CODEX-MANAGED-STARTUP -->
Read the current global rules at C:\Users\willi\.codex\AGENTS.md before work.
Team skills are installed at C:\Users\willi\.agents\skills.
Preserve project-specific identity, instructions, source, local settings and runtime evidence.
<!-- /PZ-CODEX-MANAGED-STARTUP -->

# Project Nightfall instructions

## Identity and source ownership

- Display name: Project Nightfall; Mod ID: `ProjectNightfall`; author: B47ANCE.
- Canonical version: `0.29.0` in root `VERSION`; policy: `docs/VERSION_POLICY.md`.
- Public repository: https://github.com/B47ANCE/ProjectNightfall
- Existing Workshop item: `3788593239`; item creation and visibility changes need separate authorization.
- Authoritative runtime source: `src/ProjectNightfall/42/`.
- `src/ProjectNightfall/info.txt`, `src/ProjectNightfall/thumbnail.png`, and `art/` are source/support assets.
- `Contents/mods/ProjectNightfall/` is the retained historical 0.27.4 generated mirror. Current 0.29.0 source is not packaged. Source remains authoritative. Rebuild it only through the explicitly requested packaging command, never by independently editing mirrored code.
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
- Nightfall owns infected policy; M.O.R.T.I.S. owns generic entity/anatomy/authority services; lightWorks owns UV/emitter facts; B47ANCEDPower owns energy; Health Care (public Lua namespace medWorks) owns detached-part provenance; B47ANCEDKnowledgeAndWisdom owns research/knowledge infrastructure.
- Use the regional tissue pipeline and its bounded lifecycle scheduler. Never restore retired direct-health UV damage or a second zombie exposure queue from backups.
- Preserve clothing, loot, canonical tissue, transaction/replay protection, save schemas, hibernation/rise, and source-specific natural/artificial UV rules.
- Meaningful shared gameplay configuration belongs in server-authoritative sandbox options with stable identifiers, localization, bounds, and existing-save behavior. Technical safety bounds remain internal with rationale.
- Searches and scheduled work must remain bounded and fair. Successful diagnostics must reflect actual successful processing.
- Preserve custom artwork. Do not use branding defaults to overwrite supplied assets.
- Do not add Project Remnants detection or compatibility. EXT-27 remains deferred until its documented release and treatment gates are met.

## Validation and iteration

Read `docs/VALIDATION_0.29.0.md` for current audit/implementation/evidence. Earlier 0.28.0/0.27.4 reports and fixture locks are historical, tied to their recorded snapshots. Preserve their versions and results. Before edits, name files/invariants. Use feature branches, freshness, targeted staging, an index secret audit and a PR before main merge. Never auto-stash/reset/clean/pull/rebase.

Run with real Python 3.12+ and lupa.lua51:

```text
python scripts/check_versions.py
python scripts/run_host_tests.py
python -m unittest discover -s tests -p "test_*.py"
python scripts/dependency_contracts.py
python scripts/audit_project.py
```

Current evidence: 62 Lua files and 19 Python tests pass offline; direct/transitive source dependency contracts pass for the recorded snapshots. SOURCE_INVENTORY declares actual source folders and Mod IDs. B47ANCEDHealthCare intentionally retains the medWorks Lua/global/item namespace; do not rename public APIs based on folder branding. The gate also compares Nightfall mod.info requirements with selected inventory contracts. Whole-family native startup/transport is not proved by tests.

The first remains presentation increment is a production client context-menu row using vanilla's selected corpse and replicated stage. It performs no world scan, transmission, anatomy work or gameplay action. Existing Enabled controls availability; no extra micro-setting. Stage-only labels avoid presenting stale between-stage quantities as live measurements. All translation folders have key parity; non-English entries currently use explicit English fallback. Native smoke, anatomy attachments and visual corpse replacement stay gated until safe adapters/runtime evidence exist.

Contents and old ZIPs retain 0.27.4 bytes. They are not current source mirrors or valid 0.29.0 release inputs. Packaging/release checks intentionally fail until new packaging is explicitly requested. `package_project.py plan` is read-only; `build` is manual and never implicit in a source fix, audit or version bump. Disposable package tests are permitted. Builds retain superseded mirrors and a durable local transaction under .local/packaging-pending; retries install only missing identical outputs, never overwrite immutable artifacts. No implicit artifact cleanup.

[VERIFIED] source and [TESTED] offline evidence are separate from actual PZ/SP/dedicated results. Steam build 25485521 supplied the observed native collection call forms; exact game SemVer and dedicated execution remain unverified. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. No deployment, game/server launch or Workshop upload is authorized by this fix request. Preserve custom art, local settings and all historical artifacts.
