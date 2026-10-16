# Regional UV tissue and metabolism

This is the current Project Nightfall UV contract. It supersedes the retired
direct-health and global `uvPoints` prototypes.

## Ownership

- Project M.O.R.T.I.S. owns canonical anatomy, missing-part state,
  clothing-to-anatomy mapping, capabilities, authority adapters, and neutral
  remains infrastructure.
- lightWorks owns natural/artificial UV facts, emitter geometry, obstruction,
  bulb semantics, and visible lighting.
- Project Nightfall owns zombie UV storage, burns, metabolism, regeneration,
  transfers, Feral ability costs, hibernation, and death/remains policy.
- medWorks consumes Project M.O.R.T.I.S. anatomy and coverage for procedures.

## Canonical regional state

Each attached canonical region stores `naturalScore`, `artificialScore`, and
`woundStage`. The two score components sum to the region's one stored UV
resource. Source attribution enforces source policy; it is not a second reserve.
Spending drains both components proportionally and never heals the wound.

Conversely, retained score alone does not recreate explicitly repaired trauma
in darkness or during a zero-duration sample. Renewed tissue exposure can
promote the wound again; the Project M.O.R.T.I.S. promotion contract applies
only the difference from its repaired magnitude. Integration tests exercise
actual anatomy persistence, repair, reload, darkness, and renewed exposure.

Current exposure is sampled separately and is never inferred from stored score.
Absent, detached, unknown, obstructed, or incompletely sampled regions fail
closed instead of receiving guessed exposure.

## Capacity and thresholds

Default capacity is 100 points per region. The seven promotion thresholds are
10%, 20%, 35%, 50%, 65%, 80%, and 95%; 100% is the storage cap, not an eighth
wound stage. Natural sunlight may contribute only
through 64% of capacity. It does not clamp an already higher score. Artificial
UV may progress a region to 100% and is the only source permitted to reach
terminal UV consequences.

Sun-only intervals cannot promote wounds beyond the sunlight ceiling even if
stored artificial UV remains from an earlier exposure. Existing greater wounds
are not lowered. Transaction journals retain current tissue-source attribution
independently from score increments, including when regional storage is full.

## Transactions and authority

Only canonical authority writes tissue state. Exposure uses a persistent journal
so partial wound commits recover without replaying score. Intervals are
non-overlapping and deduplicated. The spending API offers bounded partial
consumption, but healing uses atomic consumption of its calculated cost.
Server tissue writes retain a retryable synchronization marker. Host tests
cover replay protection; this is not certification of multiplayer transport.

The bounded scheduler is the sole zombie UV processor. `PN_ArtificialUV`
collects emitters but owns no second zombie queue and applies no direct HP
damage. Diagnostics are read-only.

`PNTestUVInspect(zombie)` includes persisted metabolism when initialized:
eligible tier, utilization fraction, base healing work/minute, pending healing,
latest allocation decision and last repair consumption. Inspection does not
generate traits. `ProjectNightfall.UVMetabolism.inspect(entity, tier)` supplies
the same read-only snapshot to developer integrations; its returned decisions
are copies, not mutable references to canonical state.

## Feral resource rules

- Sprinting draws from the locomotion regions and stops at its reserve floor.
- Detached or destroyed regions cannot supply or receive usable UV. Sprint
  eligibility also requires sufficient Project M.O.R.T.I.S. anatomical
  locomotion capability; full storage cannot override damaged-leg impairment.
- Ordinary Ferals use local score reflexively and cannot transfer it.
- Smart Ferals transfer score for healing and do not proactively optimize
  storage. Ability-specific tactical transfers remain planned.
- Alpha Ferals may strategically redistribute score, including protected areas.
- Initial Alpha policy defers healing during sprint, ambush, flank, evasion, or
  chase intent. When no repair is performed and tactical intent permits it,
  one rate-limited transfer moves score from the fullest surviving region into
  the least-filled protected region. Loss-aware equalization prevents overshoot.
  The latest preserve/transfer decision is stored in `PN_UVMetabolism.lastDecision`.
- Current local exposure at or above 60% blocks regeneration in that region.
- Missing, negative, or nonfinite tissue exposure cannot authorize regeneration.

Healing throughput and utilization efficiency are persistent per-zombie traits
within type-specific ranges. Missing anatomy and capability loss constrain which
actions may consume score.

## Healing selection and interruption recovery

Each eligible region receives a local healing opportunity per update, bounded
by the 32-region anatomy limit. Current exposure gates regions independently.
Smart/Alpha donor withdrawals share one per-interval transfer budget, and each
recipient reads refreshed storage after preceding commits. Results retain the
first repair fields plus a complete repair list and aggregate work/UV totals.
Repairs commit region by region: a failure stops the pass and retains its pending
repair; earlier repairs remain committed. Unvisited regions are not retroactively
healed for that failed interval. Engine interruption/throughput calibration is
still required.

Alpha healing uses a provisional deterministic priority: critical anatomical
regions first, then descending wound stage, then canonical region ID. Current
local exposure and viability still gate each candidate, so a blocked critical
region does not prevent another region healing. Tactical preservation takes
precedence over this ordering. Feral/Smart ordering is unchanged. The entire
anatomy count is checked before spending, transferring or repairing anything.
Priority balance still needs gameplay validation and does not implement all
planned Alpha ability/resource strategy.

Healing-transfer demand is capped by the wound's remaining magnitude before
requesting donor energy. Nearly healed regions use sufficient local reserves
without transfer; deficits include utilization and transfer loss, but not unused
healing throughput. Invalid wound magnitudes fail before energy movement.

Pending healing now terminates cleanly if its canonical target becomes detached
or destroyed before recovery. Cancellation records the transaction/region and
does not resurrect tissue, spend additional UV, or refund possibly committed
energy. Unknown/missing anatomy still defers rather than assuming removal.
This prevents a severed healing target from indefinitely blocking all later
biological updates for that zombie. In-game interruption timing remains a gate.

## Anatomy-dependent actions and lifecycle

Den-defense and independent UV-emitter attacks require one functioning
arm/hand pair on the same side, obtained from the canonical M.O.R.T.I.S.
functional snapshot. Assignment filters incapable pawns; execution rechecks
anatomy and authority, cancelling an invalid task before the physical-attack
provider runs. These gates cover Nightfall-requested fixture attacks only.
Vanilla grabbing, biting, climbing, and their animation selection still need
separate verified engine integration; they are not changed by this policy.
Cancelled fixture tasks release their matching persisted hierarchy objective;
different replacement orders are preserved. Failed cleanup remains retryable,
and failed path assignment cannot leave an untracked destruction objective.
Independent UV attacks do not overwrite existing den-defense tasks.

Night rise now queries canonical leg function before releasing hibernation.
Both legs at zero function use M.O.R.T.I.S. `State.requestCrawlerWake`, while
other bodies retain the standing wake path. Rise completion no longer resets
crawler/walking flags. Missing or malformed anatomy defers the rise. This is
the wake boundary. Active normal/Feral updates also enforce crawler posture for
bilateral leg failure, without resetting attack/path state or repeating native
writes when posture is correct. Hibernating bodies remain under the fake-dead
lifecycle. Shelter-release and crowd-flow paths preserve the anatomical walking
restriction. Active anatomy restrictions now save their prior walking permission
and restore it after leg function returns, deferring while a shelter hold is
active. Native get-up selection remains vanilla-owned; recovery does not clear
crawler mode or force an animation. Failed native writes retain the recovery
record for retry. Prior nonwalking permission is preserved.

Hibernation and shelter holds now capture walking permission before their first
restriction and preserve that baseline across nested holds and save/reload.
Injuries acquired during hibernation transfer that baseline into anatomy recovery
on crawler wake. A pre-existing nonwalker uses crawler wake even with healthy
legs. Failed shelter releases retain the baseline and retry on later updates.

Remaining recovery limits: older saves cannot reconstruct missing ownership. Concurrent mods
writing native walking flags do not yet share an ownership registry. These
cases, one-leg balance, arm-dependent actions, and animation/network behavior
still require implementation or verification before release.

Native reference: installed `IsoZombie.shouldGetUpFromCrawl` rejects standing
when `isCanWalk` is false; `ZombieIdleState.execute` maintains floor posture for
crawlers. The new adapter preflights native capabilities and requests that idle
state instead of `ZombieGetUpState`. In-game transitions still need validation.

## Sandbox controls

The sandbox exposes utilization and healing-work minimum/maximum values for
each Feral tier, Smart/Alpha transfer efficiencies and per-game-minute limits,
and Alpha protected-storage transmission/gap thresholds. Both Nightfall presets
include the defaults. Runtime mapping orders reversed ranges, bounds numeric
values, and ignores nonfinite input. Zero healing throughput or transfer rate
disables that work; utilization is bounded above zero. The local 60% exposure
healing lockout and tier eligibility remain biological rules, not balance knobs.

## Release gaps

Current source is not a release-ready build. Host validation does not prove
animation, engine serialization, save compatibility, or multiplayer behavior.

- Complete ability-specific anatomical costs/transfers and Alpha strategy.
- Calibrate multi-region healing throughput and interrupted-pass behavior.
- Complete vanilla grabbing/climbing and limb-appropriate animation integration;
  see [native combat audit](NATIVE_COMBAT_ANATOMY_AUDIT.md).
- Resolve overlapping external walking restrictions and older-save ownership.
- Verify clothing, sunlight, artificial stacking, sprint duration, save/reload,
  and server synchronization in-game.
- Complete terminal UV corpse presentation/finalization without losing clothes,
  loot or protected tissue. Current remains support records evidence only; see
  [native remains audit](UV_REMAINS_NATIVE_AUDIT.md).
- Tune score and wounds from full-day measurements; never bypass this model with
  direct health damage.
- Update versions and packages, verify Workshop/live parity, and run the final
  in-game release checklist. Undeployed source tests do not satisfy these gates.
