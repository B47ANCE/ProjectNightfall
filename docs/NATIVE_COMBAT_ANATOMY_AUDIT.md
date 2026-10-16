# Native combat / anatomy integration audit

## Verified local evidence

The installed game's decompiled `IsoZombie.java` registers `battack` as a
getter-backed animation variable using private `getShouldAttack()`. That getter
checks global attack disabling, target state, height, fake-dead/crawler state,
obstacles, and range. No arm-function condition appears in that method.

This does not establish that replacing `battack` is safe or that it controls
every damage/animation path. Do not implement a guessed writable attack toggle,
globally disable zombie attacks, or disable biting merely to prevent grabbing.

## Current implemented boundary

`AttackState.animEvent` handles `AttackCollisionCheck`, checks `isNoTeeth`,
then calls private `triggerPlayerReaction`. That path performs range/obstacle
checks and invokes the target's `BodyDamage.AddRandomDamageFromZombie`.
`FakeDeadAttackState` independently calls the same damage routine from its
collision event after alive/cone/vehicle checks; its finishing event sets crawler
mode. `AttackNetworkState` handles remote attack outcomes, sounds and blood
effects separately. A standing-state-only override would miss these paths.

Use `PNTestCombatInspect(zombie)` in single-player debug Lua to capture the
current native state, crawling/walking flags, AttackType, AttackOutcome,
ZombieBiteDone and PlayerHitReaction. It performs only native reads on the
supplied zombie, with no scan, canonical anatomy initialization or behavior
override. Sampling does not establish event ordering or multiplayer correctness.

Nightfall-requested fixture attacks require a canonical functioning arm/hand
pair and authority, checked at assignment and execution. Malformed third-party
emitter records are rejected individually without preventing valid targets from
being selected. Independent attacks require positive on/powered/emitting facts.

## Remaining work

Trace native attack-state animation events and damage application separately,
including crawling, vehicles, grapple transitions, and networking. Identify a
verified per-entity hook for selecting arm-appropriate behavior while retaining
valid bites. Climbing restrictions need their own state/pathfinding audit.
These engine behaviors are not implemented or certified by the fixture gate.
