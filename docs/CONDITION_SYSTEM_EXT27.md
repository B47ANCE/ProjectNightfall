# EXT-27 — Definition-driven condition system gate

Status: implementation deferred at the explicit Nightfall release gate; pipeline
and first-slice contract audited on 2026-09-05.

## Decision

Do not add the condition runtime to the current 0.27.1 source yet. The approved
coding handoff schedules EXT-27 only after the existing Nightfall release gates,
while the project roadmap still requires native calibration, preset validation,
high-population stress, hibernation/traversal checks, UV presentation checks, and
hosted/dedicated persistence and authority tests. None of those gates has an
authoritative PASS artifact in this workspace.

Adding another persistent entity lifecycle before those tests would widen the
same ModData, elapsed-time, event-order, and replication surfaces being validated.
It would also make a host-only test appear to satisfy the handoff's native and
multiplayer requirements. This is a sequencing blocker, not a technical claim
that Build 42 cannot support conditions.

## Clean-room evidence

The inactive `FadedAfflictions` installation was considered only for the observed
separation of definition, configuration, server state, scheduled lifecycle,
treatment, presentation, and administration. EXT-27 approves that separation,
not its content. No definition, identifier, condition, stage, timing, balance,
text, asset, data table, or implementation structure from that mod may enter
Nightfall.

The proposed slice below is derived from Nightfall's own source and the approved
handoff. `PN_UVTissueState` already demonstrates authority checks, a journaled
commit, monotonic elapsed intervals, schema rejection, replay-safe M.O.R.T.I.S.
trauma promotion, ModData persistence, and retryable server transmission.
`PN_StatePersistence` demonstrates bounded field validation and old-schema
restoration. Neither module is a generic condition store, and EXT-27 must not
fold condition state into or change their current UV/lifecycle semantics.

## Existing pipeline traced

| Concern | Current owner/path | EXT-27 constraint |
| --- | --- | --- |
| Entity identity/anatomy | M.O.R.T.I.S. | Read capabilities; do not duplicate or mutate identity |
| UV dose and tissue injury | `PN_UVTissueState` | Preserve its sole authority and journal exactly |
| Hibernation/Feral lifecycle | `PN_ZombieUV` + `PN_StatePersistence` | Do not reinterpret phases as generic conditions |
| Medical procedures | medWorks | Consume a declared treatment receipt; do not implement procedures |
| Condition rules | Project Nightfall | Own definitions, acquisition, transitions, and outcomes |
| Presentation | future uiWorks/client adapter | Consume public observations; never own state |
| Entity save/sync | entity ModData + server transmission | Namespace separately; authority-only writes |

## Smallest eligible implementation slice

Once the release-gate evidence is PASS, add one Nightfall-owned condition whose
gameplay requirement is independently approved. Do not invent a condition merely
to populate a registry. The first slice must include:

1. a protected definition registry with one exact condition ID and schema version;
2. explicit eligible M.O.R.T.I.S. target types/capabilities;
3. an acquisition request with source provenance and a unique operation ID;
4. one persisted current stage, monotonic revision, acquisition time, last
   processed time, and optional next transition time;
5. an absolute-world-time transition function with a bounded catch-up count;
6. one declared treatment capability whose receipt is produced by its canonical
   owner, plus expected-revision validation;
7. detached, permission-filtered public observations and presentation events;
8. server-authoritative mutation, rollback on persistence failure, replay
   suppression, and retryable synchronization;
9. schema migration from one explicit old fixture and fail-closed retention of
   malformed or future versions.

The condition state must use a separate `ProjectNightfall` ModData key. A maximum
condition count, maximum operations retained per condition, maximum transitions
per update, maximum text/ID lengths, and maximum synchronization payload are
mandatory. Registration and snapshots return copies. No world or population scan
is permitted.

## Transaction model

Every acquisition, transition, and treatment commit should validate the complete
proposed record before replacing the committed record. Requests carry condition
ID, operation ID, expected revision, actor/source provenance, and bounded
arguments. Replayed successful operation IDs return the prior outcome; a new
operation against an old revision is rejected. Treatment and scheduled transition
racing at the same revision have one deterministic authority order, recorded in
the result. Clients request and observe only.

Offline progress uses absolute world age rather than replaying every missed tick.
The definition maps a prior stage and elapsed interval to no more than the bounded
number of transitions. Time reversal, non-finite time, unknown stages, missing
definitions, and future persistence schemas fail closed without rewriting saved
evidence.

## Required proof matrix

| Proof | Host test | Native test |
| --- | --- | --- |
| Definition validation and protected copies | Required | — |
| Eligibility failure and unsupported target | Required | One real M.O.R.T.I.S. target |
| Acquire/duplicate/replay behavior | Required | SP save/reload |
| One old-schema migration | Required | Existing-save fixture |
| Future/malformed schema retention | Required | Save remains loadable |
| Offline elapsed transition | Required | Quit, advance/reload, inspect |
| Treatment-versus-transition race | Required | Hosted server with two clients |
| Authority rejection | Required | Client, host, and dedicated server |
| Transmission failure and retry | Required | Disconnect/reconnect and late join |
| Public observation filtering | Required | Owner/non-owner/admin clients |
| Existing UV/Feral/remains behavior unchanged | Full regression | Current Nightfall playtest suite |

## Preconditions to resume

- The current Nightfall 0.27.3 release gates have recorded native PASS evidence.
- A specific first-party condition, its acquisition rule, and intended gameplay
  outcome are approved; Faded Afflictions content is not a candidate.
- medWorks identifies the exact treatment receipt/capability if treatment is
  medical. If no treatment applies, a different condition is required for the
  handoff's treatment-race proof.
- Multiplayer testers can exercise hosted, late-join, reconnect, and dedicated
  authority paths.

Until then EXT-27 is audited and ready to implement, but not implemented or
complete.
