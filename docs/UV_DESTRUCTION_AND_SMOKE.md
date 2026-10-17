# Living and postmortem UV destruction

## Status and ownership

Accepted extension to [regional UV biology](UV_TISSUE_DESIGN.md). This is a
development contract, not a claim of playable smoke or corpse disposal.

- lightWorks: generic irradiance, emitter output, spectrum, attenuation,
  obstruction, and valid Z-level exposure.
- Project M.O.R.T.I.S.: canonical anatomy, remaining tissue, regional weights,
  missing parts, clothing mapping, corpse anatomy and remains lifecycle.
- Nightfall: infected sensitivity, living/postmortem UV destruction policy,
  smoke-generation semantics, UV death and disposal balance.
- medWorks: consumes the resulting canonical anatomy; does not own UV damage.

UV destruction is not ordinary fire. Never invoke destructive vanilla skeleton
or burning conversion merely to obtain a visual effect.

## Required behavior

1. Living infected emit localized wisps/smoke during meaningful active UV injury,
   before death. Prefer anatomical attachment points; document any fallback.
2. Death preserves wounds, missing limbs, remaining tissue, UV state, regional
   presentation, clothing coverage/condition, and original death cause.

The UV-death provenance record freezes each region's valid canonical tissue
capacity, remaining quantity and remaining fraction alongside attachment,
integrity, wound and UV evidence. Unknown legacy quantity stays absent rather
than being inferred. Frozen death evidence is distinct from mutable corpse
anatomy that subsequent artificial UV can continue consuming.
3. Artificial UV can progressively destroy any infected corpse, including melee
   and firearm kills. It must not relabel their original death cause as UV.
4. Reuse the living exposure/protection architecture. Corpse clothing, condition,
   holes and layers continue protecting their actual regions.
5. Destruction is gradual and driven by received output, elapsed time, protection
   and tissue availability, not item-ID exceptions or instant corpse deletion.
6. Overall destruction is derived from canonical regional tissue weights. Do
   not use an independently incrementing global destruction meter.
7. Missing limbs stay missing. Surviving clothing, equipment, loot and protected
   tissue survive appropriate remains transitions.
8. Final presentation can include skeletal, desiccated/charred and liquefied
   material. Preserve evidence rather than making the corpse disappear.
9. Living-to-corpse presentation continues at the existing damaged regions;
   neither tissue state nor smoke should reset to an intact corpse.

## One smoke model

`PN_UVSmokeModel.evaluate` now provides the bounded pure calculation, with living
and corpse curves and explicit per-region severity, destruction rate, remaining
tissue fraction, attachment and canonical weight inputs. It returns regional
generation and weighted totals without modifying/persisting inputs. Missing
weights/facts are rejected, not inferred from integrity. Detached regions are
excluded from the target's tissue denominator. Living inspection now connects
this helper to committed tissue-loss intervals; no renderer is enabled and no
visible smoke is produced in-game.

Use one regional calculation for living infected and corpses, with centrally
configured curves. Input must distinguish severity, current destruction rate
and remaining destructible tissue. Stored UV is not a smoke input by itself.

Conceptual generation is severity factor × active destruction rate × remaining
tissue factor × presentation multiplier. Tune rather than treating this as a
validated final formula. High destruction with no active UV cannot sustain
heavy smoke. Brief residual cosmetic decay is allowed after generation stops.
Near-depleted tissue produces minimal smoke even under high UV.

Starting living severity bands: below 20% none; 20/35/50/65/80/95% progress from
wisps through extreme output. Starting corpse bands: below 10% none;
10/25/45/65/80/95% progress from wisps to heavy breakdown and final taper.
These are configurable starting values, not fixed rendering constants. The
combined rate/tissue curve should generally peak around 60–80% destruction.

Expose derived regional/target smoke intensity, generation rate and source for
future consumers. Do not persist every derived field or replicate particles.
Do not add air quality, sickness, sanitation or attraction gameplay merely
because those future integrations are possible.

Feral healing remains regional: current local exposure at or above 60% blocks
healing there, while eligible less-exposed regions can still heal. Smoke in one
region cannot become a global healing lockout.

## Authority and scheduling

Server owns exposure, tissue destruction, protection, remains changes and
gameplay smoke semantics. Clients render/interpolate from synchronized target
identity, regional severity, remaining tissue and active rates.

Use emitter-bounded candidate discovery, batches, dirty/cached anatomy and
coverage, and lower-frequency corpse updates. Corpses outside relevant UV
should incur essentially no continuing Nightfall simulation cost. Stop tissue
processing when no destructible tissue remains; do not globally scan corpses.

## Current evidence and implementation order

Existing source confirms UV death evidence before native corpse copying and now
processes marked infected corpses through an emitter-bounded postmortem UV
runtime backed by canonical soft-tissue quantities. It does not yet render smoke
or apply a verified loot-preserving native visual-stage adapter.
See [native corpse audit](UV_REMAINS_NATIVE_AUDIT.md).
The [native smoke audit](NATIVE_UV_SMOKE_AUDIT.md) identifies direct sprite
attachment as a candidate and rules out native burning/world smoke as cosmetic
shortcuts. Lua exposure, per-instance cleanup and anatomical placement remain
unverified.

The inspected `IsoGameCharacter.getTimeSinceLastSmoke` is not evidence of a
particle-emission API; no rendering integration should be inferred from its name.
M.O.R.T.I.S. now supports optional persisted regional tissue capacity/remaining
quantity, weighted inspection and transactional tissue loss (see its
`docs/TISSUE_STATE.md`). New default humanoids receive 100 relative gameplay
tissue units. Unknown legacy tissue remains unenrolled rather than fabricated;
live calibration remains pending. Do not substitute health/integrity for
remaining tissue.

### Exposure-to-tissue integration checkpoint

The living regional pipeline now accepts `artificialTissueLossPerDose` in each
compiled region profile. It is a fraction of canonical tissue capacity lost per
received artificial irradiance-game-minute, after existing clothing transmission
and regional exposure factors. Loss is capped by remaining tissue and continues
when UV fuel storage is saturated. Sunlight and stored fuel alone never consume
tissue through this path. Zero (the default) disables loss; no release balance
or default gameplay destruction rate has been selected by this increment.

Loss requests are frozen inside the existing dose/wound interval journal with
expected remaining quantity. M.O.R.T.I.S. commits loss with a per-region receipt;
partial failures and reload retry do not repeat earlier loss. Detached regions
are excluded on recovery; their items are not burned using the old body's
exposure. Unknown legacy tissue quantities reject an enabled loss transaction
rather than inventing mass. Existing dose behavior remains available at rate zero.

Host regressions cover real anatomy loss, partial-save recovery, duplicate
intervals, protected exposure, sunlight/darkness, depletion and invalid/unknown
inputs. Smoke rendering, tissue restoration, final visual remains, and live
balance calibration remain open.

The production regional policy now exposes
`ProjectNightfall.ArtificialUVTissueLossPerDose` (bounded `0`–`0.01`, provisional
default `0.0005`). It is included in both packaged presets; zero disables gradual
tissue destruction. Policy revision 2 invalidates cached revision-1 profiles.
This is an active implementation default, not validated release balance.

### Emitter-bounded corpse runtime

`PN_UVCorpseRuntime` now marks infected entities at the authoritative death
event after confirming canonical anatomy and UV tissue state. Native corpse
modData copying carries that marker and anatomy forward. Only marked infected
corpses are eligible; unknown corpses never receive fabricated anatomy.
The marker also requires a complete canonical tissue snapshot, preventing an
unquantified legacy corpse from entering a permanent failing retry loop.
M.O.R.T.I.S. anatomy initialization may initially be cache-only; the death
boundary therefore flushes canonical anatomy before writing the marker and
before native `IsoDeadBody` copies modData. A failed flush aborts marker creation.

The runtime constructs a bounded square queue around current artificial-UV
emitters, deduplicates overlapping emitter areas, and examines a configurable
number of squares/corpses per tick. With no active emitters it performs no square
discovery or corpse processing. Candidates leaving every emitter are dropped.
Square discovery, corpse processing, retained candidates and constructed scan
queues have separate bounded sandbox controls. Candidate processing is
round-robin so a dense early group cannot starve later corpses indefinitely.
The initial discovery establishes a timestamp rather than backfilling unknown
past exposure. Subsequent elapsed time is capped by the regional scheduler.

Corpse exposure reuses lightWorks obstruction sampling, M.O.R.T.I.S. anatomy,
Nightfall clothing transmission and the journaled loss path. Its policy disables
living movement and death consequences, preserving the corpse and its original
cause. This runtime does not yet select final visual remains, render smoke,
remove loot, or claim multiplayer/native corpse-event certification.

`PN_UVRemainsState` derives persistent semantic presentation stages from the
canonical weighted tissue aggregate: `INTACT`, `SCORCHED`, `DESICCATED`,
`CRITICAL`, and `RESIDUAL`. Starting destruction thresholds are 10%, 35%, 65%
and 90%. Stage transitions are monotonic, record entry/update game minutes, and
retain exact capacity, remaining quantity and destruction fraction. A tissue
increase cannot silently regress a corpse through a subsystem that does not own
restoration. Unknown schemas fail closed.

These records deliberately do not alter native sprites, invoke fire, remove the
corpse, clear worn items/inventory, or rewrite cause of death. They are stable
input for a future verified presentation adapter, not evidence those visuals
already render.

On a dedicated server, only new remains-stage transitions request a native
modData transmission. A failed send leaves a durable authority-local retry marker;
the next otherwise unchanged update retries it once, while synchronized unchanged
stages do not transmit every processing interval. Host tests prove retry/dedup
logic, not actual client visibility or late-join behavior.

### Committed destruction diagnostics

New dose journals retain their original start/end game minutes and commit a
bounded per-region loss-amount record after successful recovery. A dark/no-loss
interval replaces the old record with empty amounts. This record is observation
history, not a second destruction counter or permission to continue burning.

`PN_UVDiagnostics.inspect(entity, exposure, policy, nowMinute)` optionally accepts
the inspection time in elapsed game minutes; otherwise it reads the game clock.
When canonical tissue is available, `report.destruction` contains tissue totals,
per-region facts and a living smoke-model result. Missing legacy tissue is
reported separately without breaking the original UV inspection.

The diagnostic derives severity from canonical tissue destruction, not stored
UV fuel. Its active rate is the lesser of observed fractional tissue loss per
game minute and the current protected artificial-exposure policy rate. Darkness
therefore suppresses output immediately; rising intensity cannot invent damage
before a new committed interval. Partial journals, incomplete geometry, missing
clock, future-dated records and stale records produce no active generation.
`policy.smokeMaxAgeMinutes` controls diagnostic freshness (default one game
minute); this is not a simulation or particle lifetime setting.

This view is read-only and provisional for both living targets and marked infected
corpses. It is not a particle replication protocol or native renderer.
Snapshot/clock synchronization, visual curves and physical localization still
require implementation/testing.

`PNPerformanceStatus()` also reports a bounded corpse-runtime snapshot: current
emitters/candidates, the last update's processed and scanned work, remaining scan
queue and cumulative failures. The snapshot is copied and observational; it does
not expose or mutate runtime queues.

Host integration now exercises a native-like corpse copied from living modData
through the real M.O.R.T.I.S. anatomy restore, Nightfall dose journal, clothing
coverage/transmission and tissue-loss pipeline. It verifies asymmetric clothing
protection, artificial loss, sunlight non-destruction, cause preservation and
reload persistence. Native Build 42 inspection confirms `IsoDeadBody` copies
modData and worn items and exposes position plus `getItemVisuals(ItemVisuals)`;
actual Lua binding behavior and multiplayer remain in-game gates.

For live inspection, `PNTestUVCorpseInspect(nil,12)` searches only a bounded
radius around the player for the nearest marked infected corpse. It recomputes
current verified exposure and clothing protection, then prints canonical tissue,
committed smoke semantics, remains stage and corpse processing timestamps.
Passing an explicit corpse avoids the local search. The command is read-only,
single-player-only, and cannot enroll an ordinary corpse or advance simulation.

Implementation sequence:

1. Audit B42 smoke/fire effects, attachments, bones, lifetime and synchronization;
   audit corpse rendering and loot-preserving presentation boundaries.
2. Define neutral regional tissue quantity/weight and persistence in M.O.R.T.I.S.
3. Preserve state across ordinary and UV deaths, then expose protected corpse
   regions to the existing lightWorks sampling path.
4. Implement bounded postmortem destruction and weighted aggregates.
5. Add the shared smoke model and semantic diagnostics; prototype localization.
6. Add continuous living/dead presentation, tissue-loss stages and remains.
7. Verify synchronization, sleeping, limits, and balance in-game.

## Acceptance

- Living standard UV produces wisps; higher output increases active smoke.
- Switching UV off stops sustained generation; residual particles dissipate.
- Death retains regional damage and continues effects without resetting tissue.
- Ordinary infected corpses degrade under subsequently applied artificial UV.
- Protective clothing creates uneven destruction; holes change local protection.
- Roughly 98%-destroyed remains taper smoke rather than emit forever.
- Missing limbs never reappear; equipment and protected tissue are preserved.
- Two clients observe server-owned destruction consistently.

Inspection must show lifecycle, per-region exposure, injury/destruction,
remaining tissue, clothing/transmission, active rate and smoke; plus weighted
totals, contributing emitters, UV death flag and transition state. Native visuals,
server behavior and disposal balance remain release gates, not host-test claims.

### First client presentation increment - 0.29.0

The selected-corpse context menu now shows a localized semantic remains-condition row and tooltip from the existing synchronized marker/stage. This is read-only information, not a native sprite replacement or smoke renderer. It uses no new networking or world scan and never changes loot, cause or tissue. All five stages, corrupt/future records, controller probes, pooled menus and disabled behavior have offline coverage. English fallback is declared for untranslated locales. SP/controller rendering and actual dedicated/late-join transport remain NOT TESTED. The native renderer gates above remain open.
