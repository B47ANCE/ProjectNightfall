# Project Nightfall Architecture

Nightfall requires powerWorks, lightWorks, Project M.O.R.T.I.S., medWorks, and experienceWorks. Nightfall owns all Transforming, Feral, and Smart Feral definitions and gameplay policy.

- `PN_Config.lua`: defaults plus `SandboxVars.ProjectNightfall` overlay.
- `Sandbox/Nightfall.lua` and `SANDBOX_OWNERSHIP.md`: Apocalypse-derived preset plus the narrow vanilla settings Nightfall must force to prevent competing locomotion, fake-dead, and rally-group systems.
- `PN_SolarUV.lua`: natural UV exposure.
- `PN_ArtificialUV.lua`: supplies bounded lightWorks artificial-emitter snapshots and tactical light-attack decisions. The regional scheduler is the sole owner of zombie UV processing.
- `PN_FlashlightBulbs.lua`: UV bulb registration.
- `PN_MortisIntegration.lua`: Nightfall type/profile registration through Project M.O.R.T.I.S.
- `PN_ZombieUV.lua`: regional-UV scheduling, fake-dead hibernation, close-range disturbance, rise, recovery, appearance, and optional Feral promotion. Hibernation enters the real living `FakeDeadZombieState` atomically through Project M.O.R.T.I.S.; setting `isFakeDead` on Build 42's `ZombieOnGroundState` is forbidden because that state explicitly calls `die()`. Ongoing lifecycle work is relevance-driven; saved zombies receive one cursor-based bounded discovery pass and fake-dead hibernators have a dedicated rise budget.
- `PN_NightTransition.lua`: defines a stable noon-to-noon night epoch and an O(radius) outdoor search. It issues at most one outdoor path request per relevant indoor zombie per night.
- `PN_StatePersistence.lua`: versioned lifecycle/rise scheduling, appearance locks, and durable Smart Feral state. It does not duplicate regional UV tissue state.
- `PN_UVTissueState.lua`: authoritative, journaled per-region UV score and wound-stage state, including atomic resource consumption and server synchronization.
- `PN_FeralReserve.lua`: anatomy-aware views and sprint costs over the same stored regional UV score.
- `PN_MortisIntegration.lua`: also consumes the persistent M.O.R.T.I.S. starvation clock for Feral eligibility; sunlight hibernation remains independent of that eligibility.
- `PN_FeralAI.lua`: shelter, stalking, flanking, hiding, ambush, evasion, and grudge behavior.
- `PN_UVAI.lua`, `PN_Shelter.lua`, `PN_Observation.lua`, and `PN_TargetStimulus.lua`: bounded decision helpers.
- `PN_Canopy.lua`: optional local canopy attenuation.
- `PN_FeralGroups.lua`: bounded Smart Feral recruitment, logical-group merging,
  formation movement, real-coordinate screech events, and expiring shared intent.
  Its event-fed weak spatial index replaces whole-population recruitment scans;
  a configurable leader budget bounds each group update. Delayed response calls
  use a FIFO queue with independent per-tick work and maximum-depth budgets;
  under overload, cosmetic responses are discarded and recorded diagnostically.

Project M.O.R.T.I.S. owns generic identity, profiles, authority, state adapters, and crowd-flow services. lightWorks owns bulbs, compatible lights, servicing, visible-light properties, emission channels, UV source geometry, and sunlight exposure. Neither dependency owns Nightfall zombies.

powerWorks owns batteries, stored energy, and consumption calculation. lightWorks registers lights as devices and resolves their installed bulb. Nightfall registers standard UV as a `1.25x` load and high-output UV as a `2.0x` load; powerWorks composes that value with the light profile and installed cell capacity.

All searches must remain local or bounded. Runtime code must use verified adapters and fail safely when optional engine capabilities are unavailable. Vanilla owns ordinary zombie movement and nighttime activation. At nightfall, Nightfall may rise hibernators, commit eligible Feral/Smart Feral conversions, and ask indoor zombies to roam outside; it must not globally replace the base zombie brain.

External mods, including the local research copy at
`C:\Users\willi\Zomboid\mods\FadedsTheHive`, are clean-room research references
only. Engine hooks and performance lessons may be verified independently; their
code, data, text, assets, recipes, and implementation structure are not copied.

Implemented effigies consume medWorks-created detached parts through neutral Project
M.O.R.T.I.S. provenance. Nightfall owns the reaction matrix, influence fields,
destruction/feeding behavior, and persistent Smart Feral investigation states.
See `EFFIGIES.md`.

`PN_ResearchArchive.lua` registers Nightfall-owned classified files through
experienceWorks. experienceWorks owns document registration, redaction,
restricted distribution, read completion, and character knowledge persistence;
Nightfall owns the UV/solar/behavioral content and downstream unlock effects.

Smart Ferals also own local personal-horde recruitment and may merge into
intelligent hordes. Project M.O.R.T.I.S. supplies generic group identity and
crowd-flow primitives; Nightfall owns membership rules, capacity scaling, and
shared predator intent. See `SMART_FERAL_GROUPS.md`.

lightWorks reports natural and artificial UV separately. Nightfall stores their
contributions in one capacity-limited score per anatomical region while retaining
source attribution for policy. Natural contribution stops at 64% of regional
capacity and cannot lower an already greater score; artificial UV may reach 100%.
Wound stage is persistent and independent from spendable score. With
`EnableFerals=false`, Nightfall clears its temporary Project M.O.R.T.I.S. identity
when a hibernator rises and returns it to vanilla regular-zombie behavior.
