# Nightfall version policy

Root `VERSION` is the single canonical project Semantic Version. The user approved onboarding the existing `0.27.3` source on 2026-10-16. This establishes metadata; it does not invent a release, increment gameplay, or certify earlier tests.

Use PATCH for compatible bug fixes, MINOR for compatible new features, and MAJOR for incompatible public/save/configuration contracts. Record the target development version and compatibility impact before implementation. The documentation/tooling-only onboarding retained 0.27.3. The user-authorized corpse-runtime bug-fix slice is PATCH 0.27.4, with no save schema, public protocol, or balance changes. It is a development iteration, not an approved stable release.

`scripts/check_versions.py` declares exact current mirrors: README and AGENTS identity; SOURCE_INVENTORY; authoritative mod.info and source info.txt; PN_Config version and banner; PN_TestKit session version; PN_GuidedTest fallback; the current Nightfall diagnostics fixture; MASTER_ROADMAP identity; and current Workshop description/change-note headers. Update these together with CHANGELOG in every runtime version iteration. Run the checker before and after changes. Review other current documents against the implemented behavior in the same PR.

Game `versionMin=42.20.3`, dependency versions, sandbox file `VERSION=1`, Workshop descriptor `version=1`, state/protocol schemas, and framework provenance are separate namespaces. Do not rewrite them as the project version.

Historical changelog entries, dated audits/handoffs, old validation records, `SHA256SUMS.txt`, staging backups, and immutable released ZIPs retain their original versions and evidence. `Contents/mods/ProjectNightfall/42/` contains actual 0.27.1 bytes, has 85 fewer files than authoritative source, and is classified as stale packaging input. Preserve it; do not relabel it as the current version. The 0.27.3 ZIP is historical after the 0.27.4 source iteration. This classification does not resolve release parity.

`python scripts/check_versions.py` checks current source metadata. `--release` additionally requires source/Contents parity and current artifact version/CRC consistency. It must fail on stale packaging; release consistency failures block G8. This limited checker is not the full package integrity/provenance or runtime gate. `scripts/audit_project.py` inspects ZIP paths, duplicates, case, CRC, hashes, and source payload parity separately.

Every intentional runtime version iteration needs a changelog, honest evidence, commit, public push with remote-SHA verification, and feature-branch PR. A failed push is NOT BACKED UP. Never force-push or tag unverified development as stable. G7 dedicated multiplayer PASS is required before stable-release G8. Current source/static tests are not SP/MP proof. Deployment and Workshop publication need their own authorization and gates.
