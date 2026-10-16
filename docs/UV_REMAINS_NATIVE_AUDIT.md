# UV remains: native implementation audit

Local Build 42 decompilation inspected:
`.tmp-nightfall-decompile/corpse-out/zombie/iso/objects/IsoDeadBody.java`.

- The constructor copies the human visual and takes the dead character's
  inventory, worn items, and attached items before clearing the original entity.
- Native rot-to-skeleton conversion clears worn items, attached items, and the
  corpse container. It also invalidates the render cache and sends the skeleton
  object change on servers. This is not suitable for loot-preserving UV remains.
- Fire conversion replaces the corpse with a burnt-floor object and removes the
  corpse. This is neither the intended visual identity nor a safe loot path.

## Implemented increment

`PN_UVRemains` freezes regional score, wound stage, attachment, destruction and
integrity before the authorized systemic death transition. The original native
corpse and its inventory remain untouched. The record is confirmed after the
health transition succeeds and can be inspected without mutating it.

Repeated prepare calls retain the frozen record. Failed transitions remove only
their pending label, while a late failed callback cannot erase confirmed
evidence. Unknown schemas are preserved and rejected. `test_uv_remains` exercises
these contracts with no native inventory or presentation mutation.

The native constructor copies modData with `LuaManager.copyTable` before
`OnDeadBodySpawn`; that event is explicitly guarded by `!GameServer.server`.
`PN_UVRemains.finalizeCorpse` confirms a copied pending UV record only on a
recognized corpse and canonical authority. Its guarded spawn-event integration
therefore runs automatically in single-player, not on MP clients or dedicated
servers. Unknown records and ordinary corpses are left untouched; confirmed
records are idempotent. Tests simulate independent source/corpse tables and
check preserved regional evidence, unrelated metadata, clothing/loot placeholders,
and client rejection. Native inventory and event timing still need live testing.

Server confirmation uses the earlier `OnZombieDead` notification instead:
installed `IsoZombie.onKilled` emits it without a server exclusion, and
`IsoGameCharacter.die` calls `Kill` before `becomeCorpse`. The guarded
`PN_UVRemains.confirmDeath` requires authority, an infected entity, and native
`isDead()` before confirming an existing record. It neither creates a record for
ordinary deaths nor treats living fake-dead hibernators as dead. The subsequent
native copy can therefore carry confirmed evidence without a server corpse scan
or spawn callback. Tests simulate that event/copy sequence and client rejection;
real server death transport and timing remain unverified.

## Still required

- Verify native ModData transfer/event timing in-game, including corpse creation
  within a native death call and server death-event/packet ordering. The spawn
  event is only a single-player fallback; server confirmation uses the earlier
  death notification.
- Establish an authority-owned corpse finalization/render provider in Project
  M.O.R.T.I.S. with loot-preserving rollback and replication.
- Implement per-region preserved tissue and skeletal/goopy presentation without
  invoking destructive native skeleton/fire conversions. No visual replacement
  is implemented by the current record-only increment.
