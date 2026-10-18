# Project Nightfall Sandbox Ownership

Project Nightfall inherits Apocalypse for unrelated survival balance, then changes only settings that conflict directly with its infected lifecycle. Runtime enforcement applies the same ownership rules to existing saves while Nightfall gameplay is enabled.

## Nightfall-owned and forced

| Vanilla setting | Nightfall value | Reason |
| --- | ---: | --- |
| `ZombieLore.Speed` | `3` (`Project: Nightfall`) | Provides an engine-safe shambler base; M.O.R.T.I.S. applies type/state locomotion. |
| `ZombieLore.SprinterPercentage` | `0` | Prevents untyped vanilla random sprinters. |
| `ZombieLore.ActiveOnly` | `1` (`Project: Nightfall`) | Prevents vanilla day/night speed modifiers from stacking with UV behavior. |
| `ZombieLore.DisableFakeDead` | `3` (`Project: Nightfall`) | Disables vanilla fake-dead spawning so Nightfall exclusively owns hibernation and rising. |
| `ZombieConfig.RallyGroupSize` | `0` | Disables vanilla idle rally groups; only Smart Feral-led Nightfall groups may recruit. |
| `ZombieConfig.RallyGroupSizeVariance` | `0` | Removes an inert and misleading variance after rally groups are disabled. |

Nightfall base locomotion is regular/transforming `shambler`, Feral/Smart Feral `fastShambler`, UV slow `shambler`, and decision-gated Feral sprint `sprinter`. The M.O.R.T.I.S. priority stack ensures UV slow and deliberate sprint states supersede the base without competing direct setters.

## Vanilla retained

- Population count, distribution, peak, respawn, and cell redistribution remain world-population policy.
- Follow-sound distance, sight, hearing, memory, cognition, door interaction, vehicle crawling, thumping, fence lunges, and drag-down remain vanilla sensory/combat inputs unless a specific Nightfall behavior temporarily overrides an individual zombie.
- Strength, toughness, armor, fall damage, transmission, infection mortality, and human-corpse reanimation remain vanilla balance.
- Meta events, migration, and zombie cleanup remain vanilla world simulation. Cell redistribution is not rally-group formation.
- Day/night and climate cycles remain user-selectable. Endless day/night are supported challenge configurations, not silently rewritten.

## Smart Feral horde boundary

Disabling vanilla rally groups prevents ordinary zombies from autonomously forming idle hordes. Nightfall replaces them only with bounded Smart Feral-led personal and intelligent hordes described in `SMART_FERAL_GROUPS.md`; ordinary zombies never become independent rally leaders.

## Dependency-owned hunger budget — 0.31.0-dev.8

MORTISSystems.HungerWorkPerTick belongs to MORTIS, with server authority, default 32 and integer bounds 1–512. The Nightfall preset selects 32; Nightfall runtime does not force this value over an explicit server choice. Missing existing-save values use the MORTIS default. Invalid values defer automatic work. This controls peak automatic hunger work rather than hunger rate; lower values increase food-search latency. Names/tooltips and validation live in the paired MORTIS development source. No duplicate Nightfall option is added. See [performance and evidence limits](HUNGER_POPULATION_SCALING.md).
