# Hunger at extreme populations — 0.31.0-dev.8

[VERIFIED: source] Nightfall delegates canonical hunger to M.O.R.T.I.S. This
iteration pairs Nightfall with MORTIS 0.26.0-dev.9, commit
`a8a50e40732bebcee70ddb8d9bc7abd5403c1890`. Its old per-zombie staggering did not
impose a global ceiling: 10,000 Engine callbacks caused 34 immediate food searches
in the baseline regression. The revised Engine admits work to a server-local FIFO
and performs zero immediate searches in that wave.

| Server control | Default | Supported bounds | Existing saves |
| --- | --- | --- | --- |
| MORTISSystems.HungerWorkPerTick | 32 | Integer 1–512 | Missing uses 32; valid explicit values retained |

The Nightfall preset selects 32. MORTIS owns this option, its validation and
localized name/tooltip; Nightfall does not add a competing setting. Invalid values
defer automatic work. Lower budgets reduce peak work but increase food-search
latency. The setting caps automatic hunger work units per global scheduler tick,
including stale nodes, rather than changing hunger rates or guaranteeing FPS.
Trusted on-demand hunger queries and external provider execution are not all
covered by this cap.

## Bounded work and unchanged ownership

MORTIS uses a deduplicated weak FIFO: constant-time admission, dequeue and death
cancellation, no population scan/sort/compaction, no eviction of accepted work.
Repeated callbacks retain an actor's position. Repeated or nested drains cannot
multiply a frame's budget. Collected/dead/missing-square actors are skipped under
the same limit. A technical 131,072-node metadata ceiling reports overflow and
rejects new admissions until space exists; rejected actors can retry their next
staggered callback. Fairness applies to admitted actors within that ceiling.
Missing global tick support disables automatic searching instead of restoring
unbounded per-zombie work. No client is allowed to own canonical hunger.

Elapsed world time still determines hunger. Ordinary queries retain hourly write
batching; delayed processing catches up in one calculation. A shared per-frame
admission observation lets an uninitialized actor account for known initial queue
delay, with at most one admission clock query per frame. Unknown/future anchors
never manufacture elapsed time. Both direct and source meals settle all elapsed
pre-meal time, including a partial hour, before relief. This also fixes stale
direct feeding and charging pre-meal time again after relief. Feeding still resets
continuous starvation; Feral qualification, desiccation, transaction compensation,
quarantine, source categories and schemas remain intact.

Nightfall now queries hunger in the AI weight map only when an actually visible
target can use its CHASE bonus. It does not cache hunger across polls. Real chase
decisions still observe current meals/time and retain the larger continued-chase
bonus. Starvation/lifecycle checks still query their own required current facts;
the existing bounded lifecycle scheduler remains responsible for that work.

Legacy effigy discovery now matches the reusable-frame technical ceiling of 128
examined local entries. Overfull queries return no candidate, avoiding an
unbounded sort or a partial nearest-choice result. No stored source is removed;
normal discovery resumes when density falls within the bound. This safety ceiling
is internal, not a new balance control. Actual frame inventory validation, shared
load/feed leases and permanent native insertion denial remain unchanged.

## Diagnostics and current evidence

`PNPerformanceStatus()` includes detached MORTIS hunger diagnostics: queue depth,
configured budget, attempts, nonthrowing checks, actual feeds/seeking, skips,
errors, overflow and oldest wait ticks. A check finding no food is not a feed.
These counters describe only the process where the function runs. Client output
explicitly says the authoritative server queue is unavailable; no new diagnostic
network request, server-data projection or zero-queue claim is added.

[TESTED: offline Windows, Python 3.12.14, Lupa 2.6 Lua 5.1] MORTIS serves 100,000
admitted actors once each in 3,125 ticks at 32 units/tick. Its actual Engine test
observes zero direct searches in 10,000 callbacks and at most 32 worker operations
in one tick. Nightfall performs zero hunger queries across 10,000 idle AI maps,
retains visible start/continued chase behavior, refuses a 129-entry legacy query
without losing sources, and discovers all 128 again after pressure is removed.
These are operation-count assertions with simulated native boundaries, not native
Kahlua timing, FPS or dedicated multiplayer benchmarks. See
[exact commands and validation](VALIDATION_0.31.0-dev.8.md).

The dependency lock selects pushed, unmerged development work: MORTIS PR #17 and
Knowledge PR #2. This Nightfall branch builds on dedicated-research PR #9. Matching
dependency builds will be required on the server and clients. Published dev.6 and
its artifacts remain historical; this source iteration makes no new package,
deployment or Workshop upload.

## Human dedicated acceptance still required

G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. On a disposable dedicated test world
with exact matching builds, record Insane-population server frame/tick times,
loaded actor counts, peak/steady backlog and wait ticks, and error/overflow counts.
Exercise crowded/dense effigies, clients joining/rejoining, deaths/stream-out,
concurrent loading/feeding, time acceleration, seven-day starvation qualification,
save/reload and server restart. Verify native object lifecycle, FIFO recovery and
persisted hunger clocks. Budget tuning must use measured headroom; host counts
alone do not establish a universally safe budget or native queue latency. Native
read-back/save requests do not prove disk or cross-file atomicity. No game/server
launch is authorized by this source optimization request.
