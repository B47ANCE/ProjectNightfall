# Project Nightfall

Project Nightfall is a UV-driven infected overhaul for Project Zomboid Build 42.

- Version: `0.28.0`
- Mod ID: `ProjectNightfall`
- Author: B47ANCE
- Minimum game version: `42.20.3`
- Required Mod IDs: `lightWorks`, `ProjectMORTIS`, `B47ANCEDPower`, `medWorks`, `B47ANCEDKnowledgeAndWisdom`

## Ownership

Nightfall defines and controls Transforming, Feral, and Smart Feral zombies. It registers those types through the public Project M.O.R.T.I.S. API. Project M.O.R.T.I.S. supplies reusable zombie systems but no zombie types. lightWorks supplies serviceable lights and artificial-UV emissions but no zombie reactions.

## Implemented gameplay

- Natural UV damage to a 50% health floor, true fake-dead sunlight hibernation, and staggered nighttime rise with rapid recovery.
- Relevance-driven, server-authoritative lifecycle scheduling with bounded initial discovery, nighttime rise, and artificial-UV work budgets.
- Compact `PNPerformanceStatus()` stress diagnostics combining Nightfall lifecycle/group pressure with M.O.R.T.I.S. scheduler totals.
- `PNReleaseTest(true)` sequences the required lightWorks visual tour and Nightfall guided checklist without optional Works modules.
- Indoor zombies receive at most one outdoor roaming request per night; vanilla remains responsible for ordinary nighttime activity.
- Smart Ferals share fixed effigy-hunt origins, expiry, rage, and builder identity
  with members of their established intelligent horde.
- Packaged `Project: Nightfall — No Ferals` preset: UV damage and optional sun knockdown remain, but hibernators rise as regular zombies.
- Standard and high-output lightWorks UV bulbs with violet visible light.
- Regular-zombie UV slowing and shelter seeking.
- Feral solar reserve, rare tactical sprinting, and daytime shelter behavior.
- Feral creation requires seven continuous days of starvation after hunger stores are fully depleted; feeding resets the timer.
- Hunger contributes to starting and sustaining chase decisions through the Project M.O.R.T.I.S. hunger-drive API.
- medWorks detached-part provenance is classified at sever time; three selected same-source parts can be assembled through a validated timed action, while ambiguous mixtures are rejected before consumption.
- Smart Feral promotion, stalking, flanking, hiding, ambushing, evasion, and grudge targeting.
- Smart Feral-led personal hordes with local recruitment, deterministic intelligent-horde merging, population-scaled follower caps, and spaced formation movement.
- Real-coordinate Smart Feral call-and-response screeches and expiring shared investigation intent, with a bounded and overload-safe delayed-response queue.
- Persistent Alpha hierarchy, rivalry, desertion, Death Cry power vacuums, underground territories, distributed Smart dens, prey reports, and light defense.
- Pressure- and season-gated Alpha migration toward physically discovered destinations, with a hard winter lock, rivalry priority, physical loaded movement, and persisted temporary daylight shelters.
- Artificial-UV Alpha-den compromise causes persistent emergency local displacement to the literal closest safe loaded shelter without abandoning the territory or hierarchy.
- Bounded tree-canopy attenuation of natural UV.
- Bald, clean-shaven Feral and Smart Feral appearances.
- M.O.R.T.I.S.-powered deeper-interior crowd flow for shelter entry.
- Packaged `Project Nightfall` sandbox settings page.
- Selectable `Project: Nightfall` and `Project: Nightfall — No Ferals` presets based on Apocalypse.
- Rare classified Project files registered through B47ANCED Knowledge & Wisdom, with genuine redactions, prerequisites, persistent knowledge unlocks, and restricted scientific/military loot pools.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Testing](docs/TESTING.md)
- [Roadmap](docs/ROADMAP.md)
- [Vanilla horde/pathing audit](docs/VANILLA_HORDE_INTEGRATION.md)

The authoritative mod source is `src/ProjectNightfall/42/`. `Contents/mods/ProjectNightfall` retains the historical 0.27.4 generated mirror, including parent support files. Edit source; rebuild only when packaging is explicitly requested. Root `VERSION` is canonical; see [version policy](docs/VERSION_POLICY.md) and [source inventory](SOURCE_INVENTORY.json).

Public development repository: [B47ANCE/ProjectNightfall](https://github.com/B47ANCE/ProjectNightfall).

Development version 0.28.0 adopts the current Power and Knowledge dependency IDs/APIs, bounds crowded-square corpse discovery, rotates saturated corpse admission and enables intelligent regular effigy destruction. Packaging tools now resume interrupted installation and validate commit/builder provenance. See [current validation](docs/VALIDATION_0.28.0.md).

All 61 Lua host test files and 18 Python tests pass offline against the recorded current checkouts. Whole-family startup remains blocked by upstream dependency declarations/imports; run `python scripts/dependency_contracts.py`. Existing 0.27.4 Contents and packages are historical and preserved. No 0.28.0 package, deployment or Workshop publication was requested. Dedicated multiplayer is NOT TESTED; stable release remains BLOCKED.
