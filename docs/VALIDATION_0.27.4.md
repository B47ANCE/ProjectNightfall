# Nightfall 0.27.4 — corpse-runtime fix validation

Date: 2026-10-16. Classification: **PATCH**, user-authorized compatible development
fix. Base commit: `d437bcb989da47b27539421020491e9720cc9f15`. The source tree and
this record travel with the fixing commit; final commit and remote-SHA verification
are reported with the public PR. This is not stable-release approval.

## Root causes and implemented behavior

The historical [0.27.3 audit](AUDIT_2026-10-16.md) reproduced five failing cases.
All five now pass with the original assertions retained:

- **NF-01:** Both `Config.Enabled=false` and the internal regional-tissue disable
  gate are checked before death marking, time/provider reads, discovery, or
  processing. Authority is still checked first. Disabling clears only transient
  queues. Re-enabling discovers marked corpses at the current minute, so disabled
  time is not charged as UV exposure. Existing marker/tissue data is preserved.
- **NF-02 / NF-03:** Discovery no longer resets every 60 updates or discards the
  portion beyond a capped prefix. Each stable emitter item/owner keeps a relative
  tile cursor; sources rotate between generation steps and continue across scan
  chunks. The existing maximum-square ceiling bounds generation work as well as
  queue size, including duplicate/out-of-circle offsets. The existing scan,
  candidate and process bounds remain in force. Queued offsets use the source's
  current position and range; removed sources become inactive. Anonymous sources
  without provider identity use a geometry key, not a guessed object identity.
- **NF-04:** A rejected or throwing scheduler call returns failure, increments
  failure diagnostics and does not count rejected work as a successful processed
  corpse. Successful work earlier in the update is retained in diagnostics.
  The candidate cursor advances before the call so another admitted corpse gets
  the next turn. Rejected calls retain the uncommitted processing clock.
- Journal recovery advances the corpse clock only to the actual reported commit
  time. A failed derived remains-stage update has a transient retry marker and
  can retry at the same minute without replaying the committed dose. Persistent
  tissue journals remain owned by the existing regional pipeline. No save schema,
  custom network message, public API, damage formula or gameplay balance changed.

No new sandbox options are needed: this fixes the behavior of the existing enable
option and existing work/storage budgets. Source cursors, retry bookkeeping and
the generation ceiling are implementation details, not new balance controls.

## Changed scope and preservation

Production behavior changes only in
`src/ProjectNightfall/42/media/lua/shared/ProjectNightfall/PN_UVCorpseRuntime.lua`.
Other runtime-source changes are version mirrors in mod.info, PN_Config,
PN_TestKit, PN_GuidedTest, and source info.txt. Current README/AGENTS, inventory,
Workshop source headers/change notes, version policy, changelog, architecture,
testing and roadmap docs are synchronized. The EXT-27 release prerequisite is
version-independent and remains deferred.

The historical onboarding hash inventory contains 227 source/Contents/art files.
The six intended changed paths are:

```text
src/ProjectNightfall/info.txt
src/ProjectNightfall/42/mod.info
src/ProjectNightfall/42/media/lua/client/ProjectNightfall/PN_GuidedTest.lua
src/ProjectNightfall/42/media/lua/client/ProjectNightfall/PN_TestKit.lua
src/ProjectNightfall/42/media/lua/shared/ProjectNightfall/PN_Config.lua
src/ProjectNightfall/42/media/lua/shared/ProjectNightfall/PN_UVCorpseRuntime.lua
```

The other **221 files retain their original hashes**, including all stale Contents
and artwork. Contents remains actual 0.27.1 data, not current packaging input.
Historical audits and artifacts retain their original versions and evidence.
The existing 0.27.3 ZIP SHA-256 is unchanged:
`1481c1565b85bc357e557f7fec1799cb69a101ca5a7e0eb6081b53b5a28df765`.
No package, deployment, upload, game/server launch, real save edit, remote-server
operation or external-mod modification occurred.

## Offline validation

Environment: Windows, bundled Python 3.12.14, lupa 2.6 with isolated Lua 5.1
interpreters; required sibling dependency source versions remain the audit's
test set. The local client console from 2026-10-15 still does not supply Nightfall
runtime proof. No new engine API is introduced by this fix.

Commands run from the project root (`python` denotes the verified bundled
executable under `%USERPROFILE%/.cache/codex-runtimes/codex-primary-runtime/dependencies/python`):

| Command | Result |
| --- | --- |
| `python scripts/check_versions.py` before editing | PASS, 0.27.3 |
| `python scripts/run_host_tests.py --only tests/audit/test_corpse_runtime_findings.lua` before editing | FAIL: five original cases reproduced |
| `python scripts/run_host_tests.py --only tests/audit/test_corpse_runtime_findings.lua tests/test_uv_corpse_runtime.lua tests/test_uv_corpse_pipeline.lua tests/test_uv_tissue_state.lua` after the fix | 4/4 files PASS |
| `python scripts/run_host_tests.py --only tests/test_uv_corpse_runtime_regressions.lua` | PASS: disable/re-enable, death gates, moving/removed/range-changed sources, reordered emitters, scan/process/candidate bounds, rejection/exception reporting, retained success counts, journal time, remains retry and client rejection |
| `python scripts/run_host_tests.py` | **59/59 files PASS**, including all original and former audit cases; exit 0 |
| `python scripts/check_versions.py` after edits | PASS, 0.27.4 current source mirrors |
| `python scripts/audit_project.py --output docs/audits/0.27.4.json` | 53 Lua files compile; no family require-case errors, filename case collisions, JSON key-parity errors or custom Java/JAR/class/DLL/EXE payload. Overall exit 1 for preserved stale packaging and intentional differences from historical source/artifact baselines. |
| `python scripts/check_versions.py --release` | BLOCKED / exit 1: stale Contents and no current 0.27.4 ZIP |

Structural evidence: [audits/0.27.4.json](audits/0.27.4.json). Authoritative runtime
tree SHA-256: `933c4ddd08d1f6f602daad8a26a114523937d85fa3892dccbd49212d109a5122`.
The digest hashes the sorted relative-path-to-SHA-256 JSON mapping. The stale
Contents digest remains
`3b8a9cd1ca4dd426d615d3e8492c11855c96379bf14195ab2ab8176423864d8e`.
The current source/copy difference is 85 missing and 13 changed files; the earlier
0.27.3 audit's 12 changed files remains valid historical evidence.

## Authority, persistence and remaining gates

[VERIFIED: source] Only the existing M.O.R.T.I.S. canonical authority may mark or
process corpses. Clients do not discover/apply damage. Tissue/corpse/remains
schemas stay unchanged; per-source cursors, candidate queues and pending-stage
retries remain local runtime state. Rediscovery after restart/disable/darkness
establishes now rather than reconstructing unknown exposure. The same regional
pipeline still owns clothing, canonical tissue, journal deduplication and vanilla
synchronization; this fix does not take over inventory, loot, death cause or fire.

[TESTED: offline] Replay/recovery behavior is covered by the existing real-module
tissue/corpse integration tests plus the new runtime-boundary regressions. These
are not native save, transport, pathing, Kahlua, SP or dedicated proofs. Saturation
checks cover bounded admission and fair rotation among admitted candidates; they
do not claim that a saturated fixed-size candidate cache processes every corpse
in the world. Discovery is limited to the supplied active emitter snapshots.

[RUNTIME GATE] Recover packaging tooling separately, prepare a clean launcher
without the previously observed injected Java agent, and verify exact game build
and Lua API behavior. In a disposable SP save, place multiple UV emitters, exceed
one scan chunk, move/remove/change ranges, disable/re-enable, save/reload, and
check no disabled-time backfill, loot change or repeated transaction. Then test
dedicated server authority, synchronized remains/tissue, late join/rejoin and
restart with the same version set. Existing stale Contents and the missing current
package remain release blockers. No CI is configured. G7 **BLOCKED / NOT TESTED**;
stable-release G8 **BLOCKED**. Offline host tests passing does not clear them.
