# MORTIS integration recovery

0.30.1-dev.1 fixes NF-M01 through NF-M04 from the MORTIS 0.26.0-dev.4 bounded
Nightfall audit. These are source corrections with offline regression evidence;
native SP/dedicated behavior remains NOT TESTED. No dependency is modified.

## Cleanup and lifecycle commit

Canonical clear releases only `ProjectNightfall.UVSlow`,
`ProjectNightfall.FeralSprint`, `ProjectNightfall.BaseSpeed` and the
`ProjectNightfall.TissueInjury` ceiling, then verifies MORTIS identity is absent.
It never invokes the global override clear or releases another consumer's owner.
Any refused release/clear retains the old phase and defers the operation. Partial
own release is idempotently retried. Ordinary regional injury policy can establish
its ceiling again on subsequent processing; its tissue/wound records are intact.

Disabled-feral cleanup runs before biological work or base-owner reacquisition.
NORMAL and cleared smart/alpha/sprint/UV flags commit only after clear succeeds.
Hibernation releases UV slow while standing, before phase/knockdown writes. A
refusal preserves `uvSlowed`; that optional boolean is now retained by the existing
schema-1 lifecycle serializer. Old records without it keep the neutral default.
Transformation, dormancy and Smart promotion now defer their phase/visual/gear
commits when assignment refuses. Existing successful eligibility/balance is unchanged.

Busy/prone native states and lost MORTIS owner stacks still refuse mutation.
There is no forced restoration, automatic global owner clear or replay of a lost
stack. Coordinated recovery after a native restart remains a human validation gate.

## Assignment compensation

Only canonical authority writes `ProjectNightfallAssignmentRecovery` in the
entity's native ModData. It is separate from MORTIS assignment components, so
clearing identity cannot erase the pending record. Missing storage refuses before
assignment. Record version 1 has exactly `version`, `prior` (type ID or false for
untyped), `target` and `status`. This is an additive internal recovery format;
existing lifecycle/component/network schemas are unchanged.

Before assignment the status is `rollback`. Before nutrition it becomes
`uncertain`; only a confirmed receipt changes it to `committed`, while a normal
nutrition refusal changes it back to `rollback`. Compensation is checked for
both result and identity readback. A failed untyped rollback releases only own
movement and attempts canonical clear; a prior typed assignment is restored
through MORTIS. A different unexpected current identity is never overwritten.
Further assignment/clear is refused while a journal exists. The bounded entity
update attempts recovery before subsequent lifecycle work and reconciles its
cached phase/flags after successful compensation. Authoritative state restoration
also refuses to project a pending target identity into lifecycle phase.

Confirmed rollback and committed-journal cleanup are idempotent. A thrown biology
provider, malformed/future record, unexpected identity or unknown outcome stays
blocked for explicit investigation; it is never silently discarded or treated as
success. Repeated identical recovery messages are suppressed per entity/reason.
There is no user-facing reset command or hidden bypass. These are technical safety
contracts, not gameplay tuning, so they add no sandbox setting.

Native ModData ownership follows existing Nightfall server authority. Clients do
not submit or apply recovery journals; MORTIS owns canonical identity persistence
and synchronization. Host tests demonstrate consumer reload/serialized-state
handling, not disk durability, engine ordering or atomic storage spanning native
saves. A crash during biology remains uncertain. Downgrade with a pending journal
is unsupported; preserve disposable save backups and resolve the record first.

## Diagnostics and dependency inputs

The first three `DependencyDiagnostics.inspect/report` results retain their
surface-presence/missing/version meaning. A fourth result reports separate source
capability readiness, food transaction contract, realm and Knowledge storage scope.
Negotiation requires MORTIS API 1.6 and used assignment/cleanup/nutrition surfaces;
food transactions must be version 1. Diagnostics only inspect the dependency's
side-effect-free AuthorityGuard; they never read or mutate player journals.

Knowledge 0.16.0 reports `MULTIPLAYER_STORAGE_UNAVAILABLE` for the affected MP
contract on server and client. SP permission is labelled SOURCE_CAPABILITIES_AVAILABLE,
never runtime readiness. Missing/unknown guard/realm is UNKNOWN. No bypass or
downgrade is supplied. Presence success prints its native evidence limit and a
separate readiness line. Current CI pins merged MORTIS 6af5d14 and Knowledge
6ba66c0; full SHAs and the other unchanged first-party inputs are in
`tests/dependencies.lock.json`.

## Regression and human acceptance

`test_mortis_recovery.lua` runs real MORTIS registries, profiles, overrides,
anatomy, assignment and persistence with modeled native zombie methods and an
explicit test species. It covers own/foreign ownership, original-field restoration,
duplicate cleanup, failed initial nutrition/compensation, consumer module reload,
typed rollback, malformed/future/conflicting records, uncertain exception and
client refusal. `test_mortis_lifecycle_recovery.lua` executes identified production
function fragments with injected boundaries: refused UV release, serialized flag,
pre-knockdown deferral, refused assignment/promotion and the early update gate.
The entire UV module and native animation are not executed by that fragment test.
Diagnostics tests use the real dependency guard across SP/server/client/unknown.

Humans run the following only after the clean-client and scoped dependency review
prerequisites. Use disposable fixtures and exact commits/builds; do not bypass the
Knowledge MP guard. Keep Nightfall out of isolated MORTIS locomotion baseline tests.

1. NF-M01: disable ferals with own base/sprint/UV/injury owners. Confirm verified
   clear before NORMAL on server and observers. Add a foreign owner and a busy
   state: cleanup must defer and preserve the foreign request; retry when safe.
2. NF-M02: UV-slow an ordinary zombie, then trigger hibernation. Refused release
   must not knock it down or drop tracking. Confirm later safe release, reload/
   stream behavior and no duplicate request. Lost stacks require coordinated review.
3. NF-M03: use a reviewed disposable nutrition-refusal surface during initial and
   typed assignment. Confirm compensation or explicit blocked journal, no false
   phase/promotion/gear commit, no later gameplay while pending, and scoped recovery.
   Exercise save/reload/rejoin/restart; without a safe fault surface mark BLOCKED.
4. NF-M04: compare source-presence and readiness output in SP and dedicated/client
   roles. A present Knowledge API must still show its MP-storage block. Diagnostic
   output does not authorize affected research/storage tests to proceed.

Record expected/observed results and redacted server/observer evidence per case.
Native SP, dedicated synchronization/persistence and full locomotion restoration
remain HUMAN / NOT TESTED. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.
