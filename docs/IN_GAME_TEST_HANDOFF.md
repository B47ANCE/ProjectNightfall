# Nightfall release-candidate test handoff

Source audit updated 2026-09-24. Phase: release preflight and preparation for
in-game validation, followed by fixes driven by test findings. This is not 1.0
certification. Source versions below supersede the stale September 1 table;
they do not assert that these versions are installed in the live mods folder.

## Current source test set

| Mod ID | Version |
| --- | --- |
| ProjectNightfall | 0.27.3 |
| ProjectMORTIS | 0.23.2 |
| medWorks | 0.9.2 |
| lightWorks | 0.25.2 |
| powerWorks | 0.15.3 |
| experienceWorks | 0.12.2 |

Registered release host tests: 173.

Run `tools/Verify-NightfallRelease.ps1 -SourceOnly` for the source preflight;
after preparing artifacts, use `-SkipLive -WorkshopRoot <candidate staging>`
for package parity. Neither mode certifies gameplay, translated-language quality,
or multiplayer. Structural JSON localization coverage and English fallback key
parity are automated separately. See the current [release preparation audit](../../docs/NIGHTFALL_RELEASE_PREPARATION.md)
for observed results and remaining blockers. The normal verifier also checks
live parity; no live deployment is authorized by preparing a candidate.

The September 20 console contains no Works load or release-runner evidence.
It cannot validate this set. Obtain a fresh console from the authorized test.

## Live installation boundary

As of the 2026-09-24 audit, none of the six candidate Mod IDs is present under
`C:\Users\willi\Zomboid\mods`; unrelated installed mods were left untouched.
Deployment therefore still requires explicit authorization after Project
Zomboid is closed. The prepared command is:

```powershell
.\tools\Deploy-LiveMods.ps1 -ModIds experienceWorks,ProjectMORTIS,medWorks,powerWorks,lightWorks,ProjectNightfall
```

The deployment tool validates canonical `src` trees, uses a verified temporary
copy, and preserves any previous selected live copy before replacement. After an
authorized deployment, verify live/source parity together with the prepared
artifacts using:

```powershell
.\tools\Verify-NightfallRelease.ps1 -WorkshopRoot 'C:\Users\willi\AppData\Local\Temp\Nightfall-Release-Staging-0dd08ecdc3b44ce9bae53ee68a0bee63'
```

Do not launch the test if that parity gate fails.

## Start

Use a disposable new `-debug` save and only the six mods above. The validation
commands intentionally do not register during a normal player launch. Choose the main
Nightfall preset. Keep a separate save for No Ferals and another for the normal
seven-day starvation test. Do not use the accelerated command on that last save.

```lua
PNReleaseTest(true)
```

This grants fixtures, starts the lightWorks API checks and guided visual tour,
then starts Nightfall's guided checklist. It does not automatically drive zombie
AI, sunsets, multiplayer sessions, or every checklist scenario.

Record Nightfall steps with `PNTestPass()`, `PNTestFail("issue")`, or
`PNTestSkip("reason")`. A skip remains blocked/pending evidence, never PASS.
Finish with `PNTestReport()` and `PNPerformanceStatus()`. Return
`%USERPROFILE%\Zomboid\Lua\theWorks Test Results - ProjectNightfall.txt`.

## Test priorities

1. Presets/dependencies; ordinary and No Ferals settings.
2. Bulb and battery install/remove/replace; cancel, nested inventory, attachments.
3. UV is blue RGB 0,0,255 across emitters; compare hue, not brightness. Test gun
   barrel direction, small rooms, wall occlusion, vanilla fixtures, and dropped
   lights: switch, cardinal aim, drain, destruction, chunk reload.
4. Sun: 50% health floor, living fake-dead, clothing, rare close disturbance,
   disengagement, sunset rise and healing. No mass deaths or stuck crawlers.
5. Kill an initialized infected by any cause, place artificial UV on its corpse,
   and use `PNTestUVCorpseInspect(nil,12)`. Confirm marked-corpse discovery,
   gradual protected tissue loss, monotonic remains stages, persistence, no
   darkness backfill, no sunlight tissue destruction, and unchanged loot/cause.
6. On the accelerated save only: `PNTestPrepareStarvation(20)`, then allow one
   game hour and test sunlight knockdown/night conversion. Verify bald Ferals,
   Smart behavior, feeding reset, and sprint reserve limits.
7. Acquire real corpse parts through medWorks, learn the required literature,
   build effigies, check source-specific reactions and cancellation. Test-kit
   parts alone do not validate the corpse-to-effigy integration.
8. Smart groups/crowd flow; Alpha calls, dens, rivalry, UV displacement and
   physical migration. These Alpha scenarios supplement the guided runner.
9. Save/reload and very-high-population sunset/dawn, shove/trip piles and stalls.
10. Before release: normal seven-day starvation run, hosted and dedicated-server
   authority, late join, persistence, and emitter tests.

Send issues plus `C:\Users\willi\Zomboid\console.txt` before another launch
replaces the log. Skipped checks remain pending, not passed.

## Scope control

Pause unrelated waterWorks and other ecosystem additions. The unfinished pump
content remains in waterWorks source only and was not deployed as part of this
test set. Existing broader roadmap items remain tracked, including lasers,
electrical grids, expanded medicine, journals, and additional migration sources.
Do not equate those unimplemented features with a tested Nightfall requirement.
Resume runtime changes for reproducible test failures or a demonstrated missing
requirement in this release scope; do not bump any mod to 1.0 before gameplay
and compatibility evidence supports that designation.
