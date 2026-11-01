# Nightfall: independent shelter/day-night design review

Research date: 2026-11-01 America/Phoenix. Nightfall baseline: 0.31.0-dev.9,
main `2333cffc53108ffab5cdc16dc26fa1c24c1320cc`. Scope: requirements and feasibility
review only. [Provenance, external observations, license limits and checklist](../THIRD_PARTY_RESEARCH.md).
All recommendations below are original proposals, not claims about QuietDark's
implementation. No third-party source, assets or nontrivial algorithms were seen.

## Conclusion

Nightfall already has the main day/night loop. The worthwhile addition is a more
deliberate spatial rhythm: some locally observed shelters become concentrations
of existing infected, followed by controlled movement back outside. Preserve
population ownership, UV biology and intelligent hierarchy; do not add an
independent zombie spawner or global sensory controller.

Start with read-only shelter-group diagnostics before changing movement. The
highest-risk unknown is reliable shelter/exit observation in partially loaded
and multilevel buildings, not the availability of a basic path-request method.

## Existing foundations and actual gaps

[VERIFIED: Nightfall source, not native runtime]

| Area | Current source | Remaining opportunity |
| --- | --- | --- |
| Shelter choice | [PN_Shelter.findNearby](../../src/ProjectNightfall/42/media/lua/shared/ProjectNightfall/PN_Shelter.lua) examines a local same-level radius and scores safe interior candidates using room preference and distance | No building-wide occupancy/reservation policy in this selector; clustering would be an added policy, not a replacement for shelter seeking |
| Interior flow | [PN_MortisIntegration.pathDeeperIntoShelter](../../src/ProjectNightfall/42/media/lua/shared/ProjectNightfall/PN_MortisIntegration.lua) delegates to MORTIS crowd flow with radius 6, minimum depth gain 1.5 and maximum occupancy 1 | Keep this existing per-square spacing; a shelter-group density target is different from piling actors onto one tile |
| Daylight dormancy | [PN_SunHibernation.evaluate](../../src/ProjectNightfall/42/media/lua/shared/ProjectNightfall/PN_SunHibernation.lua) uses committed regional natural-UV dose; [PN_ZombieUV](../../src/ProjectNightfall/42/media/lua/shared/ProjectNightfall/PN_ZombieUV.lua) owns lifecycle transitions | Do not replace this with a simple wall-clock sleep flag or make sheltered actors accumulate invented UV dose |
| Nighttime movement | [PN_NightTransition.requestIndoorExit](../../src/ProjectNightfall/42/media/lua/shared/ProjectNightfall/PN_NightTransition.lua) limits requests by a noon-to-noon epoch and searches bounded radial probes for loaded outdoor squares | One request per actor is not a coordinated shelter release or proof of arrival; track real progress if a release policy is added |
| Population scheduling | PN_ZombieUV.runTick uses authority checks and budgets for initial discovery, relevant actors and the hibernator set; configured defaults include 32 relevant entries and 8 night-rise visits per tick | Reuse this discipline; do not add a second all-zombie/all-building scan or confuse a gameplay emergence window with the existing CPU budget |
| Groups and dens | [Smart Feral groups](../SMART_FERAL_GROUPS.md) and [Alpha ecology](../ALPHA_ECOLOGY.md) already implement hierarchy, physical travel, observed destinations and bounded calls | Shelter concentrations must not grant ordinary zombies Smart leadership or overwrite formal dens/territories |
| Hunger | [Population work contract](../HUNGER_POPULATION_SCALING.md) preserves elapsed-world-time hunger and server budgets | Shelter/rest must not pause starvation, manufacture food, change the seven-day rule or add a parallel hunger queue |
| Population/senses | [Sandbox ownership](../SANDBOX_OWNERSHIP.md) retains vanilla population policy and most sensory settings, and disables vanilla rally groups | Preserve player population choices and existing subtype/perception ownership |

The inspected NightTransition call reports that a path request did not throw. It
does not prove reachability or that a zombie exited. This is an explicit limit of
the existing one-request policy, not a reproduced native defect. Blocked doors,
stairs, missing floors and a later overriding AI goal need observation before a
coordinated release can claim success.

## Priority 1: optional concentrations of existing actors

[PROPOSED; not implemented]

Inputs are authoritative loaded Nightfall actors, actual local shelter/UV facts,
current ownership and optional owner-approved server settings. A candidate output
is a preferred known shelter destination for an eligible actor, with a transient
server reservation. It is never an instruction to populate a building.

Decisions and invariants:

- Move only existing eligible actors through ordinary physical routing. Create,
  clone, teleport and delete none. Leave vanilla population, respawn and indoor
  distribution policy intact.
- Permit empty buildings. Prefer a limited selection of observed safe locations;
  do not turn every building into an obligatory encounter or claim a world-wide
  occupancy census.
- Preserve per-square crowd-flow spacing. A density preference or soft group
  target must avoid doorway jams and yield to UV emergency/attack/owned den or
  hierarchy behavior according to an explicitly reviewed priority contract.
- A strict building cap is not safe to claim when only part of the building is
  loaded. Initially use a clearly scoped loaded shelter group, or refuse a
  building-wide reservation until all necessary authority/occupancy facts exist.
- Use observed coordinates and verified stable actor identities. Do not invent
  a persistent native building-ID guarantee. Incomplete/stale/foreign ownership
  observations defer the proposal; they never transfer control to a client.
- Overflow or lack of safe destinations leaves actors under existing behavior.
  It never removes excess actors, opens an unbounded scan or creates free capacity.

This is a new distribution policy on existing shelter services. It is not a copy
of another mod's clustering logic, and no such logic was inspected.

## Priority 2: staged movement out of known shelters

[PROPOSED; not implemented]

Build on the existing night-strength threshold, per-night epoch and bounded
relevance scheduling. Introduce a meaningful in-game emergence window only if
the owner wants this pacing; the existing staggered waking work is already present.

Observable states would be eligible indoors, waiting for an authorized release,
moving toward a loaded exit, and actually outside. Track request, arrival,
interruption and failure separately. A successful call is not successful movement.
Retries must be finite, throttled and budgeted; a new client or repeated update
must not grant an additional nightly release.

Use actual light/night facts, supporting seasonal and endless-day/night settings.
Keep movement subordinate to reviewed current combat, UV survival, rivalry and
den priorities. Do not follow live player coordinates after visibility is lost.
Missing routes/loaded squares defer ordinary movement; they never teleport an
actor through a wall, open locks or silently substitute scripted destruction.
Vanilla pathing may interact with doors/windows under normal rules; that outcome
needs explicit native testing rather than a promise of damage-free exits.

## Priority 3: truthful cues and local disturbance

[PROPOSED; not implemented]

Make concentrations readable through original sound/presentation at the real
location of loaded actors, with bounded frequency and ordinary audibility. Do not
fabricate off-screen populations or expose a hidden building map to clients.
Source/asset ownership must be established for any new sound; import nothing from
the reviewed mod. Nightfall's existing positional call presentation is a possible
integration surface, not proof that all desired audio behavior is already supported.

Any gameplay disturbance must come from a server-accepted actual stimulus. Cosmetic
audio must not independently recruit, wake or target actors. Reuse existing Smart
group semantics only for members qualified for them; ordinary infected can retain
vanilla perception. Audio failure or duplicate delivery must not duplicate gameplay.
This is lower priority than safe routing and measurable population conservation.

## Approaches to reject

- Additional room-fill spawns, population multipliers hidden in Lua, or deletion/
  respawn to make streets appear empty.
- Sweeping the whole map/loaded zombie list per actor or repeatedly sorting all
  actors/buildings at dawn or dusk; unbounded metadata or stale cleanup.
- Global day/night rewrites of sight, hearing, cognition, speed or generic horde
  settings that conflict with Nightfall/vanilla ownership. A separate opt-in
  sensory preset, if wanted, must be independently audited and reviewed.
- Assuming an option or event exists because it appears in another mod or an
  indexed error report. Installed-build API verification precedes implementation.
- Unloaded teleportation or an omniscient player/base locator. Existing Alpha
  unloaded migration limitations remain in force.
- Permanent shared state in client-owned ModData; client-supplied occupancy or
  release grants; restoring uncertain reservations from untrusted tables.
- Running two competing behavior controllers as a substitute for integration.
  Compatibility with QuietDark is UNKNOWN; this research is not a co-enable recommendation.

## Lua-only implementation boundary and configuration

[INFERRED feasibility] Loaded shelter selection and bounded path intent can build
on services already used in Nightfall's Lua source. This does not establish native
arrival, streaming or dedicated correctness. Reliable multilevel exit discovery,
partial-building accounting, persistence and any additional API exposure remain
[UNKNOWN / RUNTIME GATE]. Stop an affected gameplay slice if safe authority cannot
be established. No custom Java/JAR/bridge or third-party runtime dependency.

Shared state belongs to the server. Consumers submit no trusted counts, ownership
claims or wake grants. Revalidate actor identity, ownership, square and UV facts
before acting; clean only owned transient reservations on death, expiry or loss
of relevance. Do not pin streamed-out actors with strong references. Restart and
reconnect must not duplicate assignments or replay an old release. Any later saved
assignment requires a reviewed schema/migration/recovery contract rather than an
invented durable building key.

Use bounded queues/indexes and existing fair scheduling; stale work consumes the
same cap as live work. Count attempts, accepted requests, actual entries/exits,
failures, waits, overflow and actor creation/deletion by this feature separately.
Do not claim native FPS from operation counts. Third-party callback costs and
ordinary engine pathfinding still need measured budgets.

Meaningful proposed server controls are an optional shelter policy, a loaded-group
density target and an emergence window. Final identifiers, defaults, bounds,
localization and state priority are NOT chosen by this research. Missing existing-
save options must preserve baseline behavior until the owner approves otherwise;
lowered targets never truncate a population. Reuse existing search/path/processing
controls where appropriate. Technical queue bounds are internal, not dozens of
new balance settings. Invalid values fail closed; disabling releases only owned
transient policy state without resetting vanilla actors or hierarchy.

## Next slice and acceptance

Recommended next implementation task, after design signoff: read-only server
telemetry for observed shelter groups, entry/exit progress and doorway/path
pressure using already relevant actors. No movement, spawning, new persistent
state or client-visible hidden coordinates in that first slice. This tests whether
clustering and a longer emergence window are needed without introducing a second
population controller.

Subsequent acceptance must include:

1. Controlled actor-ID conservation, explicitly accounting for legitimate vanilla
   creation, death and stream events; feature-created/deleted counts remain zero.
2. Empty buildings, dense districts, no valid shelter, missing roofs, artificial UV,
   multilevel buildings, blocked doors/windows/stairs and destroyed destinations.
3. Hard per-tick/candidate/memory bounds at Insane populations, fair admitted work,
   bounded retry/cleanup, no global fallback and separate request/arrival metrics.
4. No stealing foreign actors, starvation pauses, duplicate groups or sensory-
   setting writes; preserve regular/Feral/Smart/Alpha and No Ferals behavior.
5. Two-client dedicated join/rejoin, time acceleration, dawn/dusk and endless-day/
   night transitions, save/reload, restart, invalid settings and lowering targets.
6. Explicit human native evidence and exact tested build/package/commit before
   claiming gameplay results. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED meanwhile.

## Review status and validation scope

Research-only. Version, gameplay, API/schema, presets, dependencies, art and packages
are unchanged. No third-party package was downloaded and no game/server was run.
No QuietDark compatibility, performance or runtime correctness claim is made.
Independent reviewer/project-owner signoff is pending; the research PR stays draft.

Nightfall's relevant existing host regressions and static checks may be rerun to
check the stated baseline; they do not execute QuietDark or prove native behavior.
Actual commands/outcomes are recorded with this review after execution. Full older
release tests/receipts remain historical evidence tied to their original commits.

Local review validation on 2026-11-01:

- `python -B scripts/check_versions.py`: PASS, canonical 0.31.0-dev.9 unchanged.
- `python -B ../nightfall-hunger-population/scripts/prepare_ci_dependencies.py --check`:
  PASS for all five clean public fixture origins, full SHAs and Mod IDs. This is
  input verification only; fixtures contain first-party family source, not QuietDark.
- `python -B scripts/run_host_tests.py --dependencies ../nightfall-hunger-population/.local/ci-dependencies --only tests/test_night_transition.lua tests/test_ai_boundaries.lua tests/test_sun_hibernation.lua tests/test_uv_tissue_scheduler.lua`:
  NOT RUN; the selected local Python environment lacks `lupa.lua51`. The runner
  stopped before tests. No local Lua PASS is claimed and no global environment
  was changed to disguise the missing dependency.
- Source inspection compared local source/docs with fetched current main before
  review; no baseline source difference. The two new documents are the only
  project changes. No code/assets/API proof is obtained from QuietDark's listing.

The draft PR's existing pinned Windows/Linux workflow can run the full Nightfall
host suite in its own declared environment; actual exact-head CI is reported in
the PR. It remains offline Nightfall evidence, never QuietDark or dedicated proof.
