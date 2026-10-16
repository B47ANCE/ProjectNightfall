# Project Nightfall testing

## Current offline entry points — 2026-10-16

See the [takeover audit](AUDIT_2026-10-16.md) for current findings and exact evidence.
Run from the project root using Python 3 with `lupa.lua51` installed and the five
dependency source checkouts in the sibling layout described in AGENTS.md:

```text
python scripts/check_versions.py
python scripts/run_host_tests.py
python scripts/run_host_tests.py --legacy-only
python scripts/audit_project.py
python scripts/check_versions.py --release
```

Current source versions PASS. The original suite passes 57/57 files in offline
Lua 5.1. The default complete suite includes five intended-behavior assertions in
`tests/audit/test_corpse_runtime_findings.lua`; all five currently fail. The complete
suite is therefore 57/58 files PASS, exit 1. Do not report the legacy subset as
full regression success. `--only tests/audit/test_corpse_runtime_findings.lua`
isolates the findings. `--verbose` includes successful tests' diagnostic output.

The project audit exits 1 for stale Contents. The release consistency check also
fails for that drift. These failures are intentional reporting of unresolved
issues, not permission to rebuild packages. No current packaging/deployment
entry point is verified. The source-only check does not clear those blockers.

53 authoritative Lua files compile in Lua 5.1; 29 localization folders have English
key parity. This proves neither Kahlua compatibility nor translation quality.
The existing 0.27.3 ZIP matches current source bytes and passes the recorded
archive checks; no new package was generated.

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
