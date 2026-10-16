# Smart Feral Groups

Smart Feral personal and intelligent hordes are implemented Nightfall behavior
built on Project M.O.R.T.I.S. logical-group, identity, and authority services.
Membership is reconstructed from bounded local contact after load or stream-in;
the system does not mutate vanilla rally groups.

## Personal hordes

- A regular Feral that comes into local contact with a Smart Feral may join and
  follow it.
- The Smart Feral is the rally leader and the joined Ferals form its personal
  horde.
- Recruitment is local, scheduled, and throttled. It never performs a global
  zombie scan.
- A Feral belongs to at most one personal/intelligent horde at a time.
- The base follower cap scales with the active sandbox population setting. The
  exact base and scaling curve are Nightfall sandbox values.

## Intelligent hordes

- Smart Ferals that meet locally may team up and merge their groups.
- Membership and leadership are deterministic so two simultaneous contacts do
  not create duplicate or competing groups.
- Each Smart Feral member increases the group's maximum number of following
  regular Ferals by `0.1 ×` the population-scaled base capacity.
- With `S` Smart Ferals and base follower capacity `B`, the regular-Feral cap is
  `B × (1 + 0.1 × S)`.
- The capacity bonus changes regular-Feral follower capacity; Smart Ferals do
  not consume those follower slots.

## Long-range communication

Smart Ferals coordinate through authoritative screech events after local group
contact. The current presentation uses the vanilla `MetaScream` event as a
prototype until dedicated Nightfall audio is supplied.

- A call originates at the calling Smart Feral's actual authoritative world
  coordinates. It is never offset toward a player or fabricated for ambience.
- Nightfall emits a server-authoritative communication meta event containing
  event identity, caller stable identity, group identity, real position, world
  age, call kind, recruitment radius, and expiration.
- Eligible Smart Ferals can answer and merge/coordinate without acquiring
  omniscient player information.
- A recruitment call can invite eligible regular Ferals around the caller's real
  position into the caller's personal/intelligent horde, subject to capacity.
- Recruitment uses Nightfall/M.O.R.T.I.S. identity and group rules. It does not
  use a generic vanilla world sound to recruit every nearby zombie.
- Calls are spatially bucketed, bounded, and cooldown-limited. Recipients are
  resolved from tracked/loaded entities or population-safe meta abstractions,
  never a whole-world object scan.

### Player-facing audio

The communication event has a separate positional audio presentation. Once at
least two Smart Ferals have actually established cooperation, Nightfall emits a
call-and-response screech so players can infer that an intelligent horde exists.

- The first screech plays at the caller's real location.
- A delayed response plays at the responding Smart Feral's real location.
- Server ambient delivery provides the long-range positional one-shot to MP
  clients; the gameplay event remains server authoritative.
- The vanilla `MetaScream` sound is the current prototype. A dedicated Nightfall
  screech event should replace it when the final audio asset is available.
- Audio failure must not cancel group formation, and duplicate network delivery
  must not create duplicate membership or recruitment.

Build 42.20.3 exposes `WorldSoundManager.addSound(...)` and positional ambient
delivery. A generic world sound may be emitted separately when a screech should
be physically heard by ordinary zombie AI, but it is not the authoritative
Smart Feral communication channel.

## Implemented lifecycle and behavior

- Server authority owns recruit, merge, leave, split, and leader replacement.
- Death, transformation, stream-out, and stale membership are reconciled without
  leaving permanent phantom members.
- A returning streamed member can rejoin through bounded local recruitment,
  subject to current capacity and authority.
- Groups use bounded formation offsets and M.O.R.T.I.S. crowd-flow services so
  followers do not occupy the leader's tile or form an immovable pile.
- Followers use deterministic formation offsets and throttled repathing.

Smart Ferals share expiring last-observed investigation coordinates within an
intelligent horde. The observation is a snapshot and does not track a player's
live position. When one destroys an effigy, it also shares the fixed effigy
origin, absolute hunt expiry, enraged state, and optional builder identity with
its established intelligent horde. Recipients adopt only a newer active hunt;
the shared record expires quickly and never tracks a player's live position.

## Required tests

- population scaling at low, normal, high, and very-high populations;
- cap enforcement during simultaneous recruitment;
- deterministic Smart Feral group merge;
- follower redistribution when a leader dies;
- no duplicate membership after save/load or stream-out/stream-in;
- no global-scan spikes in dense populations;
- real-coordinate call and delayed-response audio in SP and MP;
- communication/recruitment cooldown and duplicate-event rejection;
- no recruitment centered on a player or stale last-known location;
- crowd spacing through doors, stairs, and building interiors.
