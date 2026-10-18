# Project Nightfall testing

Current source is 0.31.0-dev.1. Run the existing version, host, Python, dependency and source-audit commands. Latest 64 Lua and 25 Python files PASS offline; see [current validation](VALIDATION_0.31.0-dev.1.md). Native/SP/dedicated remain NOT TESTED. Use the B47ANCEDSPXTRM activation ID on every peer; old lightWorks imports/save keys remain compatible. Current source is not packaged.

Current reproducible commands use `prepare_ci_dependencies.py` and `--dependencies .local/ci-dependencies`; see [CI](CI.md). The historical archive helper below remains unchanged. See the [current runtime handoff](RUNTIME_ACCEPTANCE_0.29.1.md) for blocked native/SP/dedicated cases.

## Historical offline entry points — 0.27.4, 2026-10-16

See [packaging validation](PACKAGING_0.27.4.md) for current artifacts and
[0.27.4 runtime-fix validation](VALIDATION_0.27.4.md) for behavior/evidence;
the [takeover audit](AUDIT_2026-10-16.md) preserves the original 0.27.3 failures.
Run from the project root using Python 3 with `lupa.lua51` installed. The selected
0.27.4 contract uses five hash-pinned matching historical dependency archives;
prepare isolated fixtures rather than substituting the renamed current APIs:

```text
python scripts/check_versions.py
python scripts/prepare_test_dependencies.py
python scripts/run_host_tests.py --dependencies .local/validation-dependencies
python -m unittest discover -s tests -p test_packaging.py -v
python scripts/package_project.py verify
python scripts/audit_project.py --dependencies .local/validation-dependencies
python scripts/check_versions.py --release
```

Current source versions PASS. The complete suite passes all 59 files in offline
Lua 5.1 against the pinned historical set, including all five formerly failing intended-behavior assertions in
`tests/audit/test_corpse_runtime_findings.lua` and the new corpse-runtime regression
file. `--only tests/audit/test_corpse_runtime_findings.lua tests/test_uv_corpse_runtime_regressions.lua`
isolates those cases. `--legacy-only` selects 58 top-level files and omits the
audit path; use the default complete suite for current regression evidence.
`--verbose` includes successful tests' diagnostic output. Include the explicit
`--dependencies` fixture root with targeted/subset commands too.

The default sibling lookup is intentionally unchanged and currently fails: the
powerWorks source directory disappeared and experienceWorks moved to the new
knowledge namespace without its old import alias. The matching archives listed
in `tests/dependencies_0.27.4.json` retain their original bytes. The helper checks
SHA-256, identity, version, paths, case, CRC and forbidden runtime payloads, then
copies only selected first-party runtime files into `.local/validation-dependencies`.
It caches originals under `.local/validation-archives` so unrelated directory
renames cannot alter the selected test set. A fresh setup must supply those exact
archives at the lock's retained locations or in that ignored cache. No code or
aliases are added to production Nightfall or upstream dependencies. Current
renamed-family interoperability remains a separate migration/runtime gate.

All ten Python packaging tests pass. Current `Contents`, package verification,
project audit with the explicit pinned root, and release consistency checks pass after the explicitly authorized
0.27.4 package build. The source/art/artifact protection check uses the operation's
captured pre-packaging baseline; older audit records retain their original scope.
Declared historical ZIPs are checked for integrity without pretending they are
current source. No deployment/uploader workflow is verified by these checks.

53 authoritative Lua files compile in Lua 5.1; 29 localization folders have English
key parity. This proves neither Kahlua compatibility nor translation quality.
The existing 0.27.3 ZIP passed integrity/parity against the historical 0.27.3
source. It is preserved, is not a 0.27.4 package, and was not relabeled or rebuilt.

When packaging is explicitly requested, run `python scripts/package_project.py plan`
then `python scripts/package_project.py build`. The build verifies source metadata,
retains a superseded mirror, refreshes Contents, and writes/verifies the local ZIP,
manifest and checksum. It rejects unexpected mirror files and different existing
versioned artifacts. A second identical build must retain exactly the same bytes.
This manual command never deploys, uploads, or starts the game/server.

SP, hosted, native transport/serialization, clean-launcher compatibility and
dedicated multiplayer were not exercised. G7 BLOCKED / NOT TESTED; G8 BLOCKED.
The [in-game handoff](IN_GAME_TEST_HANDOFF.md) remains useful as a historical
checklist, but its missing tools and old test totals are not current evidence.

## Historical preflight and regression coverage

The shared `tools/Verify-NightfallRelease.ps1`, `tools/Run-HostTests.ps1` and
`tools/Analyze-NightfallConsole.ps1` paths referenced below were unavailable in
the takeover layout. Preserve these earlier instructions as historical evidence;
use the current offline commands above until the shared workflow is recovered.

Den-defense tests inject explicit path rejection, native path exceptions, and
failed objective cleanup. A cancellation waiting for cleanup must never attack;
successful retry removes its task and matching objective. Native void-returning
path calls remain accepted, but an explicit false result is rejected.

`test_uv_healing_integration.lua` runs real anatomy, trauma, UV storage and
metabolism modules with only the native facade/species registration substituted.
It interrupts after score spending and after trauma repair, reloads anatomy,
and verifies no duplicate spending/restoration, local-only repair and completed
wound-stage synchronization. Native engine serialization and network transport
remain separate in-game gates.

During source development, run `tools/Verify-NightfallRelease.ps1 -SourceOnly`
from the workspace root. This runs metadata, description/change-note validation
and all six release mods' host tests, but explicitly does not certify packages,
Workshop staging, live deployment, or gameplay. The default command below still
requires package and live parity; `-SkipLive` skips only the live-folder check.

Latest source audit covers 173 six-mod host tests. The 0.27.3 candidate and its
required dependency versions have been packaged and exact-verified against an
isolated Workshop staging root. They have not been deployed to live mods;
previous installed builds remain separate from current-source evidence.

The rise-contract test also executes the production shelter-release functions
with injected native boundaries: failed writes/retry, single hold-end counting,
temporary release with a false baseline, transfer to injury ownership, unknown
anatomy, and unavailable world time. A missing clock defers expiry; it must not
release the hold or discard the saved baseline.

Lifecycle persistence regression coverage now checks every explicit false flag
against true restore defaults, true-to-false saves, invalid namespace/state
containers, and malformed schema values. Previously the Lua and/or assignment
dropped false values. Older saves with already-omitted fields cannot recover
those values retrospectively; current saves preserve them. In-game save/reload
after ending hibernation and shelter hold remains required.

Close Project Zomboid, then run:

```powershell
.\tools\Verify-NightfallRelease.ps1
```

This validates dependency metadata, localization, Workshop text, all host Lua
tests, release ZIPs, selected Workshop staging, and active-mod parity. After
playing, run:

```powershell
.\tools\Analyze-NightfallConsole.ps1
```

## In-game commands

- `PNTestPoliceRoof()` teleports to 10643.5,10408.5,1 in single-player.
  If unloaded, it stages at ground level and checks for a walkable roof for up
  to 600 ticks. A missing/blocked roof leaves the character at ground level.
  The exact garage roof at these user-supplied coordinates needs live verification.

- `PNTestCombatKit()` drops ten movable floodlights on the current tile and
  supplies ten high-output UV bulbs, loaded M16, six loaded spare magazines,
  mounted high-output UV gunlight, thirteen riot/police clothing pieces and tools.
  Single-player only; repeated calls spawn another kit. Gear is supplied, not
  auto-equipped. Place and power floodlights; install a gunlight battery normally.

- `PNTestUVCorpseInspect(nil,12)` performs a bounded read-only search for the
  nearest Nightfall-marked infected corpse within 12 tiles and reports current
  protected exposure, canonical tissue, destruction/smoke semantics, remains
  stage, death minute and last processing minute. Pass a corpse object as the
  first argument to inspect it directly. This single-player diagnostic neither
  enrolls corpses nor advances damage.

- `PNReleaseTest(true)` starts the six-mod lightWorks/Nightfall release flow.
- `PNTestKit()` grants lighting, battery, tool, and UV fixtures.
- `PNTestPrepareStarvation(20)` changes nearby hunger eligibility to a one-hour
  test window for the current session.
- `PNTestGiveEffigyParts('feral')` and `PNTestGiveResearch()` prepare effigy and
  knowledge tests without silently granting learned knowledge.
- `PNPerformanceStatus()` prints bounded lifecycle, scheduler, response-queue,
  and follower-path counters.
- `PNTestAlphaMigrationStatus()` prints persistent territory, pressure, season,
  and migration state.
- `PNTestAlphaMigrationDestination()` records the player's current safe interior
  as a test destination for the nearest loaded Alpha (single-player only).
- `PNTestAlphaMigrationPressure(60)` adds explicit test pressure to that Alpha.

## Core release checklist

1. Confirm all six required mods load: experienceWorks, Project M.O.R.T.I.S.,
   medWorks, powerWorks, lightWorks, and Project Nightfall.
2. Confirm both Nightfall presets appear. Verify custom Nightfall speed, rally
   size zero, canopy protection on, and cognition zero disabling Smart Ferals.
3. Test direct sun: slow movement, 50% health floor, knockdown, true fake-dead
   hibernation, clothing retention, and no mass deaths. Confirm no
   `UNEXPECTED HIBERNATION DEATH EVENT` appears after fake-dead engagement.
4. Approach hibernators: disturbance is rare and close; disengagement restores
   hibernation. At night, verify staggered rise and rapid health recovery.
5. Verify random initial hunger, seven continuous starving days for normal Feral
   eligibility, feeding reset, bald/clean-shaven Feral appearance, and reserve
   drain during rare tactical sprints. Use the accelerated command once, then
   complete an uninterrupted seven-day stability pass before release.
6. Test blue (RGB 0,0,255) standard/high-output UV in handheld, attached, weapon-mounted,
   and placed lamps. Verify occlusion, room rendering, damage stacking, lethal
   artificial UV, and no duplicate multiplayer exposure.
7. Build every effigy signature. Verify source-specific attraction, avoidance,
   feeding, destruction, persistent hunts, cancellation safety, and save/load.
8. Verify Smart Feral recruitment, spaced follower movement, communication,
   stalking, flanking, ambush, grudges, and crowded-house deeper flow.
9. Verify Alpha calls, rivalry, desertion, Death Cry succession pressure,
   underground settlement, Smart dens, and active-light suppression.
10. Put real active artificial UV in an Alpha den. Confirm natural sunlight never
    clears it, artificial UV displaces the Alpha to the literal closest safe
    shelter, territory/hierarchy remain, and save/load does not snap it back.
11. For migration, record a safe destination and add pressure. Spring/summer
    should permit movement, fall should require more pressure, winter must reject
    normal migration. Rivalry must override it. Confirm physical travel, persisted
    temporary daylight shelters, nighttime resume, old-den disbanding, and new
    underground settlement without teleportation.
12. Repeat sunset/rise/dawn, effigies, UV, and groups at very-high population.
    Review `PNPerformanceStatus()` and the newest `console.txt` for recurring
    errors or periodic stalls.
13. Repeat authority, persistence, late join, and emitter tests in hosted and
    dedicated multiplayer before making a compatibility claim.

Counters and host tests do not prove native animation, rendering, pathfinding,
audio, multiplayer replication, or long-session balance. Those remain visual
and in-game release gates.

Current 0.30.0 dependency transition: B47ANCED SPXTRM (B47ANCEDSPXTRM) replaces the lightWorks activation Mod ID. Existing Lua/save contracts and infected consequences remain unchanged. The prior audit/CI and effigy changes are retained from main. See [current validation](VALIDATION_0.31.0-dev.1.md). Actual loader/SP/dedicated NOT TESTED; no package/deploy/upload.

Container foundation target: `python scripts/run_host_tests.py --dependencies .local/ci-dependencies --only tests/test_effigy_container_policy.lua`. This exercises the actual MORTIS provenance/material modules with native item/container boundaries mocked; it does not exercise a live world container or engine transactions.

## 0.31.0-dev.2 implementation checkpoint

The dynamic native admission blocker is resolved in source by permanently denying native insertion and using the synchronous server loader for a separate EffigyFrame prototype. Whole-batch validation, actual-item moves, revision checks, rollback/quarantine and localized load intents are implemented. Native unloading remains available. Capacity is a server sandbox option (1-40, default 20). See [implementation, limits and human gates](EFFIGY_CONTAINER_IMPLEMENTATION.md). Older foundation findings above are historical. Construction/loot distribution, reusable feeding, attribution, migration and three production models/rendering remain pending. Native/SP/dedicated validation is NOT TESTED; no package/deploy/upload.

## 0.31.0-dev.3 reusable feeding checkpoint

[Reusable frame feeding](EFFIGY_CONTAINER_FEEDING.md) now uses actual stored meat/part resources through the server MORTIS transaction coordinator. The user approved ordinary-meat feeding for hungry infected without part-specific reactions/search/grudges. Frames and depleted parts persist; category separation, shared load/feed leases, compensation and recovery guards remain authoritative. Existing calorie/hunger sandbox settings apply; no phantom legacy fallback stock is created. Construction, non-feeding influence/attribution, migration and three models remain pending. Native/SP/dedicated NOT TESTED; G7/stable G8 BLOCKED.

Focused command: `python scripts/run_host_tests.py --dependencies .local/ci-dependencies --only tests/test_effigy_container_feeding.lua tests/test_effigy_container_server.lua tests/test_effigy_container_menu.lua`. This uses real pinned MORTIS coordinator/material APIs with native boundaries mocked.
