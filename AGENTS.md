# Project Zomboid Codex startup

<!-- PZ-CODEX-MANAGED-STARTUP -->
Read the current global rules at C:\Users\willi\.codex\AGENTS.md before work.
Team skills are installed at C:\Users\willi\.agents\skills.
Preserve project-specific identity, instructions, source, local settings and runtime evidence.
<!-- /PZ-CODEX-MANAGED-STARTUP -->

# Project Nightfall instructions

## Identity and source ownership

- Display name: Project Nightfall; Mod ID: `ProjectNightfall`; author: B47ANCE.
- Canonical version: `0.31.0-dev.8` in root `VERSION`; policy: `docs/VERSION_POLICY.md`.
- Public repository: https://github.com/B47ANCE/ProjectNightfall
- Existing Workshop item: `3788593239`; item creation and visibility changes need separate authorization.
- Authoritative runtime source: `src/ProjectNightfall/42/`.
- `src/ProjectNightfall/info.txt`, `src/ProjectNightfall/thumbnail.png`, and `art/` are source/support assets.
- `Contents/mods/ProjectNightfall/` is the retained published 0.31.0-dev.6 mirror; it is historical for current development and is not a current release input. Source remains authoritative. Rebuild only through scripts/package_project.py, never by independently editing mirrored code. The prior 0.27.4 mirror is retained under the SOURCE_INVENTORY backup entry and Git history.
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

Read `docs/VALIDATION_0.31.0-dev.8.md` for current development evidence and `docs/WORKSHOP_0.31.0-dev.6.md` for historical distribution evidence. Earlier 0.29.1-dev.1/0.29.0/0.28.0/0.27.4 reports and fixture locks are historical, tied to their recorded snapshots. Preserve their versions and results. Before edits, name files/invariants. Use feature branches, freshness, targeted staging, an index secret audit and a PR before main merge. Never auto-stash/reset/clean/pull/rebase.

Run with real Python 3.12+ and lupa.lua51:

```text
python scripts/check_versions.py
python scripts/run_host_tests.py
python -m unittest discover -s tests -p "test_*.py"
python scripts/dependency_contracts.py
python scripts/audit_project.py
```

Historical 0.31.0-dev.1 evidence: 64 Lua files and 25 Python tests pass offline; direct/transitive source dependency contracts pass for the recorded snapshots. SOURCE_INVENTORY declares actual source folders and Mod IDs. B47ANCEDHealthCare intentionally retains the medWorks Lua/global/item namespace; do not rename public APIs based on folder branding. The gate also compares Nightfall mod.info requirements with selected inventory contracts. Whole-family native startup/transport is not proved by tests.

The first remains presentation increment is a production client context-menu row using vanilla's selected corpse and replicated stage. It performs no world scan, transmission, anatomy work or gameplay action. Existing Enabled controls availability; no extra micro-setting. Stage-only labels avoid presenting stale between-stage quantities as live measurements. All translation folders have key parity; non-English entries currently use explicit English fallback. Native smoke, anatomy attachments and visual corpse replacement stay gated until safe adapters/runtime evidence exist.

Contents and old ZIPs retain 0.27.4 bytes. They are not current source mirrors or valid current development release inputs. Default source audit checks pinned historical preservation and reports release blockers separately. Strict --release checks fail until new packaging is explicitly requested. CI fixtures are selected by tests/dependencies.lock.json and prepared with scripts/prepare_ci_dependencies.py; see docs/CI.md. `package_project.py plan` is read-only; `build` is manual and never implicit in a source fix, audit or version bump. Disposable package tests are permitted. Builds retain superseded mirrors and a durable local transaction under .local/packaging-pending; retries install only missing identical outputs, never overwrite immutable artifacts. No implicit artifact cleanup.

[VERIFIED] source and [TESTED] offline evidence are separate from actual PZ/SP/dedicated results. Steam build 25485521 supplied the observed native collection call forms; exact game SemVer and dedicated execution remain unverified. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. No deployment, game/server launch or Workshop upload is authorized by this fix request. Preserve custom art, local settings and all historical artifacts.

Retained 0.30.0 dependency transition: B47ANCED SPXTRM (B47ANCEDSPXTRM) replaces the lightWorks activation Mod ID. Existing Lua/save contracts and infected consequences remain unchanged. The prior audit/CI and effigy changes are retained from main. See [current validation](docs/VALIDATION_0.30.0.md). Actual loader/SP/dedicated NOT TESTED; no package/deploy/upload.

Historical 0.31.0-dev.1 added only the read-only effigy container policy foundation. Preserve the stopped native binding: queued native transfers do not repeat dynamic category admission at commit in the inspected source. See docs/EFFIGY_CONTAINER_API_AUDIT.md and current validation. No container placement, transfer/feeding replacement, migration or renderer is enabled. Category/visual query results are not authority or leases.

Current recovery slice 0.30.1-dev.1: read docs/MORTIS_RECOVERY.md and
VALIDATION_0.30.1-dev.1.md. Preserve the version-1 assignment recovery journal;
unknown/future/uncertain or foreign-identity records are blockers, never reset
candidates. Never globally clear MORTIS owners. Diagnostics separate surface
presence from capability readiness. All tests requiring an open game/server are
human-operated. No launch, deployment, packaging or publication is authorized.

Historical 0.31.0-dev.2: retain both main recovery contracts and the permanently closed native insertion guard on the new EffigyFrame prototype. Only the synchronous server loader may insert; never temporarily open admission or use the client-only transaction consistency wrapper as a server probe. Read docs/EFFIGY_CONTAINER_IMPLEMENTATION.md. Load revision is not an inventory-wide revision; actual contents must always be validated. Unknown/quarantined records block loads. No recipe/loot, reusable feeding, legacy conversion or production model is enabled. Current source is not packaged; native/SP/dedicated NOT TESTED.

Historical 0.31.0-dev.3: reusable actual-item feeding is implemented in the separate server effigyFrames provider. Read docs/EFFIGY_CONTAINER_FEEDING.md. Use the shared State lease for loading/feeding; native insertion stays closed. Preserve physical depleted parts and the frame. The schema-1 revision tracks custom loads and feeds; native unloading still requires actual-content validation. Retained pendingFeed, future/foreign records and quarantine block gameplay and are never automatically reset or replayed. Native chunk-save requests are not disk/cross-file atomicity proof. Do not copy old one-shot cleanup, add a second nutrient stockpile or grant legacy fallback nutrition to actual stored parts. No recipe/loot, non-feeding reactions/attribution, migration or production models yet. Human native/SP/dedicated tests remain pending; no package/deploy/launch/upload authorized.

Historical 0.31.0-dev.4: read docs/EFFIGY_FRAME_CONSTRUCTION.md and VALIDATION_0.31.0-dev.4.md. Frame assembly and placement use server-only commands, exact actual IDs and NF-FIELD-026 checks; costs are server sandbox values. Keep the shared legacy/reusable research helper unchanged unless deliberately revising that contract. Construction recovery lives in server GlobalModData, never client-replaceable player ModData. No OnReceiveGlobalModData import handler or research/secret data belongs in that request-readable store. Preserve retained/future/uncertain records; do not reset/replay/refund them. State schema 1 gains pendingPlacement; loading/feeding/placement reject retained markers. Existing native pickup/drop is retained and does not create a new frame or grant research. Prototype rendering, dedicated Knowledge storage and human native/SP/dedicated gates remain blocked. No package/deploy/launch/upload.

Retained 0.31.0-dev.5 revises frame assembly to **1 log, 3 large branches (Base.LargeBranch), 1 rope and 8 loose nails**, with a working hammer, sharp knife and Base.HandDrill required as retained tools. Equipped tools count; tools must be in main inventory and remain unchanged. Server validation repeats tool availability before output insertion. Costs remain sandbox-controlled; existing explicit values are preserved. Research, category restrictions, actual-item placement, legacy effigies and recovery contracts are unchanged. See [construction](docs/EFFIGY_FRAME_CONSTRUCTION.md) and [validation](docs/VALIDATION_0.31.0-dev.5.md). Native/SP/dedicated NOT TESTED; Knowledge MP storage and G7/stable G8 remain blocked. No package/deploy/upload.

## Authorized 0.31.0-dev.5 Workshop MP testing distribution

The user explicitly requested merge and publish. PR #7 merged at 264f3c34dddf5da324b533e699cff14e4d1f2023. Follow docs/WORKSHOP_0.31.0-dev.5.md for the current packaging/upload evidence; older no-package statements are historical checkpoints. The user approved a deterministic local 512-square upload preview while retaining the original 1254-square source poster. Keep the existing Workshop ID/visibility, Lua-only authority and the Knowledge guard. G7/stable G8 remain blocked; an upload is distribution evidence only. Never run the stale legacy updater or automatically restart Steam. Ask for each Steam desktop restart only after confirmed successful upload. No game/server launch or local deployment is authorized.

Historical 0.31.0-dev.6 publication preparation: a compatible packaging/metadata follow-up with no gameplay/schema changes. The unpublished dev.5 candidate is retained unchanged because its description exceeds the Steam 8,000-byte limit. Current description removes redundant recruitment/upcoming/duplicate text while preserving implemented features, credits and known limits. A packaging gate rejects oversized UTF-8 descriptions. See docs/WORKSHOP_0.31.0-dev.6.md for exact validation/provenance; G7/stable G8 remain BLOCKED.

The current dev.6 candidate also adopts the latest user-supplied B47ANCE-branded thumbnail: exact original source poster plus the approved 512-square upload derivative. The separate icon and historical artwork/packages are preserved.

Current 0.31.0-dev.7 integrates the pushed Knowledge 0.17.0 development private document backend for fresh dedicated test worlds/server-created lives. The real research check is unchanged; diagnostics distinguish private document support from broader guards. Existing-world migration, missing identities and failed writes remain fail-closed. See [research authority and native acceptance](docs/EFFIGY_DEDICATED_RESEARCH.md) and [current validation](docs/VALIDATION_0.31.0-dev.7.md). Native dedicated NOT TESTED; G7/stable G8 BLOCKED. Published dev.6 and its artifacts are retained; no dev.7 package/deploy/upload.

Current 0.31.0-dev.8: read docs/HUNGER_POPULATION_SCALING.md and docs/VALIDATION_0.31.0-dev.8.md. Use the exact paired MORTIS scheduler pin, its server-owned HungerWorkPerTick budget and authority-local diagnostics. Preserve FIFO admission, elapsed-time/pre-meal settlement, actual-item transaction guards and no global-clock fallback. Idle AI hunger queries require a visible target; never replace this with a stale hunger cache. Legacy queries over 128 examined entries return no partial candidate, preserving sources. Host counts are not native Insane-population benchmarks. G7/stable G8 remain BLOCKED; no package/deploy/upload.
