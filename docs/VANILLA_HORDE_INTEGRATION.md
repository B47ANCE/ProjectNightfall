# Vanilla horde and migration integration audit

Audit target: the locally installed Project Zomboid Build 42.20 classes and Lua
files under `E:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid`.

## Confirmed engine surface

- `IsoZombie.pathToLocationF(float,float,float)` and `pathToCharacter(...)` are
  public. Nightfall uses these for loaded physical movement.
- `ZombieGroup` publicly exposes construction, `add`, `remove`, `getLeader`,
  `size`, `isEmpty`, `reset`, and `update`.
- `ZombieGroupManager` publicly exposes `instance`, `shouldBeInGroup`, `update`,
  and `findNearestGroup`.
- The `IsoZombie` rally-group field is package-private. Its public `getGroup` and
  `setGroup` methods refer to the animation `ActionGroup`, not `ZombieGroup`.
  There is therefore no verified safe Lua bridge for mutating a zombie's vanilla
  rally membership.
- `ZombiePopulationManager` exposes loaded-area updates and population sound/
  aggro entry points, but no public route-objective API for a particular unloaded
  hierarchy.
- Vanilla `ZombieMigrate`/`RedistributeHours` redistribute population into empty
  parts of a cell. Rally settings control ordinary idle real-zombie groups; zero
  disables them, and vanilla groups do not form indoors or in forest zones.

## Ownership decision

Nightfall retains only strategic hierarchy, memory, policy, and bounded logical
membership through Project M.O.R.T.I.S. Loaded movement is handed to vanilla
pathfinding. It does not construct a replacement cell-population simulator and
does not mutate undocumented rally fields. The Nightfall preset keeps ordinary
idle rally formation disabled so only Smart-Feral-led gameplay groups exist.

Unloaded strategic state persists, but entities are never teleported to fake
progress. A future unloaded adapter must first prove that Build 42 can apply a
specific hierarchy route while preserving travel time, daylight shelter, and
entity identity.
