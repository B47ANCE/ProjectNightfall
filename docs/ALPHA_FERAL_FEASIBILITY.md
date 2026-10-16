# Alpha Feral implementation boundaries

## Confirmed Build 42 surfaces

- `IsoZombie:getTarget`, `setTarget`, `getOnlineID`, and ordinary character pathing are exposed by the current engine. Nightfall will continue routing movement through M.O.R.T.I.S. navigation adapters instead of calling unverified methods throughout gameplay code.
- `WorldSoundManager:addSound` provides positional zombie-attraction sound, while an emitter sound provides audible presentation. Alpha and Horde calls therefore require two deliberately separate channels: an engine world sound and a Nightfall semantic signal.
- Zombie `modData` is saveable/transmittable. M.O.R.T.I.S. persistent replicated components are the canonical home for hierarchy and command memory.
- Barricade-capable doors/windows expose `isBarricaded`; generators are world objects with sound and activation state. These can contribute local evidence only after a Smart Feral physically observes the loaded area.

## Hard boundaries

- `getOnlineID()` is a network identity, not a guaranteed permanent save identity. M.O.R.T.I.S. stable IDs remain canonical across stream-out/save restoration.
- Loaded zombie objects cannot safely represent unloaded hordes. No teleportation, global zombie-list scan, or invented off-screen combat will be used. Coarse unloaded simulation remains capability-gated until chunk persistence and rehydration are verified in-game.
- A barricaded structure is not automatically a player base. Base knowledge requires accumulated local observations such as repeated player sightings/activity and visible fortification evidence.
- Client ownership of streamed zombies does not authorize strategic decisions. Alpha rolls, hierarchy writes, calls, and target-memory writes are server/SP authoritative.
- Custom vocal assets and interruption timing require in-game animation/audio validation. Until then calls use a registered/fallback vocal and semantic event without claiming a fair interrupt window.

## Implementation sequence

1. Persistent M.O.R.T.I.S. parent-command relationship and last-known objective.
2. Nightfall-only Alpha type and 0.1% replacement roll after successful Smart Feral promotion.
3. Dual-channel Alpha call and bounded, spatially indexed Smart Feral response.
4. Physical rally/recruit/migration using existing Smart Feral-owned groups.
5. Loaded-area patrol/report/convergence and last-known-position searches.
6. Evidence-based probable-base memory and capability-gated coordinated approaches.

Sources checked: official Project Zomboid Build 42 Java documentation for `IsoZombie`, `WorldSoundManager`, `BarricadeAble`, and `IsoGenerator`, plus the installed Build 42 Lua distribution.
