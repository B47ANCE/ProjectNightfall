# Nightfall version policy

Root `VERSION` is the single canonical project Semantic Version. The user approved onboarding the existing `0.27.3` source on 2026-10-16. This establishes metadata; it does not invent a release, increment gameplay, or certify earlier tests.

Use PATCH for compatible bug fixes, MINOR for compatible new features, and MAJOR for incompatible public/save/configuration contracts. Record the target development version and compatibility impact before implementation. The documentation/tooling-only onboarding retained 0.27.3. The user-authorized corpse-runtime bug-fix slice is PATCH 0.27.4, with no save schema, public protocol, or balance changes. It is a development iteration, not an approved stable release.

`scripts/check_versions.py` declares exact current mirrors: README and AGENTS identity; SOURCE_INVENTORY; authoritative mod.info and source info.txt; PN_Config version and banner; PN_TestKit session version; PN_GuidedTest fallback; the current Nightfall diagnostics fixture; MASTER_ROADMAP identity; and current Workshop description/change-note headers. Update these together with CHANGELOG in every runtime version iteration. Run the checker before and after changes. Review other current documents against the implemented behavior in the same PR.

Game `versionMin=42.20.3`, dependency versions, sandbox file `VERSION=1`, Workshop descriptor `version=1`, state/protocol schemas, and framework provenance are separate namespaces. Do not rewrite them as the project version.

Historical changelog entries, dated audits/handoffs, old validation records, `SHA256SUMS.txt`, staging backups, and immutable ZIPs retain their original versions and evidence. The user explicitly authorized refreshing Contents for 0.27.4; its superseded 67-file tree is retained at `dist/staging-backups/contents-51c590fbd9d0` with its original mixed 0.27.1 runtime / 0.27.3 support metadata. At the end of that historical follow-up Contents was an exact generated mirror of `src/ProjectNightfall/`; 0.28.0 retains those bytes as historical output. Never relabel old backup/package bytes as current. The 0.27.3 ZIP remains historical and unchanged.

`python scripts/check_versions.py` checks current source metadata. `--release` delegates to the same strict package verifier as `python scripts/package_project.py verify`: full source/support/Contents parity, exact ZIP inventory and bytes, identity/version, safe paths, duplicate/case/link rejection, CRC, and SHA-256 manifest/checksum binding. Missing, stale, extra or mismatched outputs fail. `scripts/audit_project.py` also inspects retained ZIP integrity, classifies declared historical artifacts without requiring them to match current source, and checks an operation-bound protection baseline when present. Packaging checks are offline consistency gates, never G7/G8 approval.

The packaging-only follow-up retains 0.27.4 because the user explicitly selected that version and runtime source is unchanged. `scripts/package_project.py build` is manual: it stages verified output, retains the prior mirror before replacement, and never overwrites a differing existing versioned ZIP or silently deletes unexpected mirror files. Source changes after an artifact is built require a new version or separately reviewed artifact recovery. Sidecars record input commit/dirty state, builder hash and every packaged member's hash. Repeated identical builds leave ZIP and provenance bytes unchanged. New generated ZIPs/sidecars stay ignored; reviewed provenance/evidence records are committed under docs.

Every intentional runtime version iteration needs a changelog, honest evidence, commit, public push with remote-SHA verification, and feature-branch PR. A failed push is NOT BACKED UP. Never force-push or tag unverified development as stable. G7 dedicated multiplayer PASS is required before stable-release G8. Current source/static tests are not SP/MP proof. Deployment and Workshop publication need their own authorization and gates.

The 0.28.0 development MINOR reconciles the explicitly requested current dependency family integration. Nightfall APIs, persisted schemas and sandbox identifiers stay compatible; the required dependency installation set changes to current public IDs. Users must migrate the family together. The existing generated 0.27.4 tree and immutable archives are historical, excluded from current source mirrors and blocked for current release use. No 0.28.0 package is authorized by this fix request.

0.29.0 is a development MINOR for the localized read-only remains-inspection presentation increment and current Health Care Mod ID reconciliation. Nightfall schemas, network ownership and gameplay values remain unchanged. Existing 0.27.4 outputs stay historical.

0.29.1 is a development PATCH for audit phase separation, reproducible dependency fixtures, CI and localization validation. Gameplay, schemas, authority and public runtime contracts remain unchanged. Historical Contents is protected by its recorded Git tree and index/worktree checks; it is never promoted to a current release input.

The merge candidate retains canonical 0.29.1, the existing development PATCH from audit PR #3, while including the compatible 0.29.1-dev.1 effigy adapter from PR #2. Original prerelease validation and dependency reports remain historical, not current combined proof. Provider/source IDs, balance, configuration and existing schema-1 records remain compatible. No stable release or tag is implied.

0.30.0 is a pre-1.0 MINOR compatibility transition for the required SPXTRM activation ID. Existing Nightfall schemas, balance, lightWorks API imports and infected UV ownership are unchanged. Matching mod lists on all peers are required. No stable-release approval is implied.

0.31.0-dev.1 is a development MINOR prerelease starting the reusable effigy container foundation. Read-only admission/classification and derived visual states are added; native transfer binding is blocked by a confirmed queued-transfer validation gap. Existing schema-1 effigies, authority, feeding, recipes and balance remain unchanged. No live container or renderer is enabled.

0.30.1-dev.1 is a compatible development PATCH for the four MORTIS integration
findings. Balance, sandbox IDs and existing state/network schemas are unchanged.
The additive ProjectNightfallAssignmentRecovery record has its own version 1;
uvSlowed is an optional boolean in existing lifecycle schema 1. Pending/unknown
recovery records require review before downgrade; native save durability remains
unverified. The reviewed docs/MOD_OVERVIEW.json version is also a current mirror.
Its source digest follows the shared hub's raw-byte algorithm, including retained
Contents: differing checkout line endings/layout safely require review, not a
runtime PASS. Do not relabel historical validation or generated artifacts.

0.31.0-dev.2 continues the development MINOR feature begun in dev.1, now including main's compatible MORTIS recovery patch. It adds a separate EffigyFrame item/protocol and schema-1 load-revision record without changing legacy Effigy/save/food contracts. Native insertion is permanently closed; no stable release is implied. New sandbox capacity defaults to 20 on existing saves and never truncates stored items when lowered. Unknown/newer or quarantined frame records refuse loading; no downgrade/migration reconstruction is provided.

0.31.0-dev.3 continues the development MINOR with actual-item reusable feeding. Legacy Effigy schemas/contracts remain unchanged. Prototype frame schema 1 gains an optional opaque pendingFeed marker; existing clean dev.2 records continue without migration. The existing revision now tracks custom feeding as well as loading. Retained/unknown intents and foreign/future state require human review; no automatic replay, rollback reconstruction or downgrade of uncertain records is supported. No new gameplay setting is added: existing calorie calibration and MORTIS hunger settings apply.

0.31.0-dev.4 continues the compatible development MINOR with frame assembly/placement and additive bounded construction-cost sandbox IDs. Missing existing-save costs use 4 logs/2 ropes/8 nails; invalid server values refuse construction rather than creating free frames. Legacy research behavior is extracted unchanged to a shared helper. Frame schema 1 gains an optional pendingPlacement guard; the separate server GlobalModData construction journal has schemaVersion 1. No automatic recovery, downgrade or migration of retained/unknown operations is provided. Native saves are not immediate or cross-file atomicity proof; stable release remains blocked.
