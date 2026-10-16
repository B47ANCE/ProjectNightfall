# Native UV smoke presentation audit

## Evidence scope

Inspected the installed `projectzomboid.jar`, using CFR output in the workspace
scratch directory. Findings concern that local engine build, not proof that
every Java method is exposed to Lua or rendered correctly for every character.
No third-party implementation was copied and no native files were modified.

Inspected classes:

- `IsoGameCharacter`: `SetOnFire`, `StopBurning`, `SpreadFireMP`, `FireCheck`.
- `IsoObject`: `AttachAnim`, `AttachExistingAnim`, `RemoveAttachedAnim`,
  `RemoveAttachedAnims`.
- `IsoFire`: smoke constructor and animation-stage selection.
- `IsoFireManager`: `StartSmoke` and smoke tint/delay configuration.

## Confirmed boundaries

### Do not use character burning as UV presentation

`SetOnFire` sets native fire state, adds the character to the burning manager,
attaches a Fire animation and starts BurningFlesh audio. Other native methods
apply fire damage and server fire spread. This is gameplay mutation, not a
cosmetic smoke API. `StopBurning` can clear the entire attached sprite list,
which would also remove unrelated effects. Neither is a suitable UV effect hook.

### World smoke is not an anatomy-attached cosmetic emitter

`IsoFireManager.StartSmoke` uses the StartFire packet family with a smoke flag
on clients/servers. Its local path creates an `IsoFire`, adds it to the fire
manager and square object list, and the smoke constructor marks the square with
the native smoke property. It may be useful for an explicitly designed future
world smoke interaction, but is not an appropriate default for localized UV
wisps or a way to synchronize individual cosmetic particles.

The installed Build 42.20 implementation also rejects squares that are already
burning or smoky, and its smoke constructor registers a managed `IsoFire` object
and the square smoke flag. Nightfall must not start or stop this effect merely
to visualize tissue destruction: doing so would compete with real gameplay
smoke/fire ownership, and cleanup could affect a source Nightfall did not create.
The native world-smoke path is therefore a confirmed unsupported presentation
adapter, not a remaining implementation candidate.

### Sprite-only attachment is a candidate, not yet a verified renderer

`IsoObject.AttachAnim` creates an animated sprite, sets tint and screen offsets,
looping/deletion flags and frame rate, adds the instance to the object's attached
animation list, and returns the instance. That method does not itself set fire
state or register with the fire manager. Native `IsoFire` uses Smoke/01, Smoke/02
and Smoke/03 animations with 30 frames, demonstrating available animation names
in the installed native implementation.

The inspected overload uses offsets rather than a bone identifier. Parameters
named `zBias` and `finishHoldFrameIndex` are not consumed by that implementation;
do not assume they provide anatomical depth or lifetime control. Bone-local
placement needs separate model/attachment research. Sprite-offset placement is
only a potential fallback and must follow orientation/posture if used.

`RemoveAttachedAnim(index)` disposes and pools one instance. `RemoveAttachedAnims`
disposes the whole collection. A safe provider must retain ownership of its
returned instance and resolve its current index before removing it; a stored
numeric index can point at another mod's effect after list changes. Verify Lua
access, identity comparison, pooling and render invalidation before using this.

## Next implementation gates

Further render inspection found `IsoGameCharacter` updates/renders its attached
sprite instances. When real fire is active, that loop repositions attached
sprites around the spine; a UV provider cannot assume independent offsets survive
coexisting fire. `IsoDeadBody.render` instead renders its atlas texture and does
not invoke the attached-sprite loop in the inspected implementation. Inheritance
of AttachAnim therefore does not prove corpse smoke will render. A shared semantic
model may need different living/corpse presentation adapters.

The native object exposes `getAttachedAnimSprite` and single-index removal, but
Lua exposure and instance pooling remain runtime checks. No generic collection
clear is acceptable for provider cleanup.

1. Inspect character/corpse render and update paths for attached sprites; verify
   native collection access and Lua exposure rather than inferring from Java.
2. Audit bone/model attachment transforms and posture/orientation support.
3. Define canonical remaining-tissue quantities and weights in M.O.R.T.I.S.;
   structural integrity is not automatically equivalent to remaining soft tissue.
4. Build one semantic living/corpse smoke model from real destruction rate,
   severity and remaining tissue, with centralized curves and no stored-UV shortcut.
5. Prototype a bounded client-only provider with owned-instance cleanup,
   inactivity decay and distance limits. No native fire state/world smoke objects.
6. Verify living, prone, corpse, streaming, real fire coexistence and two-client
   presentation before enabling the provider in normal gameplay.

No smoke renderer or corpse-disposal runtime is enabled by this audit. Native
effect assets may be reused only through verified engine facilities; custom
artwork remains user-supplied.

An earlier unloaded `PN_UVSmokeRenderer.lua` prototype was removed during the
release audit. It guessed an entity-update event and `AttachAnim` signature,
could not identify and remove only its own attached instances, referenced
undefined state, and was never part of the client load graph. Its orphan test
only exercised the already-covered pure smoke model. Keeping either file would
have contradicted this fail-closed presentation boundary.
