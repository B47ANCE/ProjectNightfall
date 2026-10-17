# Nightfall Effigies

## Reusable container foundation - decision 2026-10-17

The approved next design uses a real restricted container: keep ordinary meat separate from body parts and keep human, regular-zombie, Feral and Smart-Feral source categories separate. Plan three visual states: EMPTY, MEAT_LOADED and BODY_PART_LOADED. This is not current runtime behavior. See [container/asset plan](EFFIGY_CONTAINER_PLAN.md) for ownership, transactions, unresolved gameplay inputs, migration and rendering gates. The implementation descriptions below retain the existing combined-item/consumed-object contract until a versioned replacement is verified.

Effigies are a Project Nightfall system being built from detached body parts
created by medWorks. Nightfall reads the neutral Project M.O.R.T.I.S. provenance
stored on each part. It does not infer anatomy or source type from an item name.

Constructed effigy items record the builder's stable player key, and placement
persists it on the world object. When a Smart Feral completes a
`destroy_search` reaction, that key becomes its existing persistent grudge:
an online builder is targeted directly, while an offline builder leaves the
normal sector search active until resolution. Player lookup uses the authoritative
online-player collection with local/split-screen fallback. Hosted/dedicated
reconnect and builder-death behavior remain release-test gates.

## Ownership and data flow

1. Project M.O.R.T.I.S. owns anatomy state, source traits/components, sever-event
   identity, and the neutral detached-part provenance contract.
2. medWorks performs an authoritative sever operation and creates the detached
   part with validated provenance.
3. Nightfall constructs an effigy from one or more qualifying parts, transfers
   their canonical detached-material records into the effigy, and owns all
   resulting zombie reactions and nutrition application.

Removing medWorks after creating persistent part or effigy data must not cause a
Lua error. Unknown, old, or third-party provenance fails closed and produces no
special Nightfall effect.

## Source signatures

The source signature is resolved from registered Project M.O.R.T.I.S. identity,
traits, and components at sever time. Initial Nightfall signatures are:

- `human`: an uninfected human/player/NPC compatible with the humanoid anatomy
  profile;
- `regular`: a regular zombie that is neither Feral nor Smart Feral;
- `feral`: a Nightfall Feral that is not Smart Feral;
- `smartFeral`: a Nightfall Smart Feral.

The provenance stores the resolved signature, its schema version, and the source
type identifiers used to derive it. Later changes to the source entity must not
silently rewrite an already detached part.

## Reaction matrix

| Effigy source | Regular zombie | Intelligent regular | Feral | Smart Feral |
| --- | --- | --- | --- | --- |
| Human | Attract; eat when hungry | Attract; eat when hungry | Attract; eat when hungry | Attract; eat when hungry |
| Regular zombie | Ignore | Destroy | Approach and consume as food | Destroy, then briefly search the local area for the player |
| Feral | Ignore | Avoid | Avoid | Destroy, then hunt/search for the player for 24 in-game hours |
| Smart Feral | Avoid | Avoid | Avoid | Destroy, then conduct a several-day regional hunt |

“Intelligent regular” is an observer capability resolved from a registered
Project M.O.R.T.I.S. cognition trait/component. It is not equivalent to being a
Nightfall Smart Feral.

Human-source effigies attract every zombie type. On arrival, a zombie consumes
the human parts only when the Project M.O.R.T.I.S. hunger API classifies it as
hungry. A non-hungry zombie retains interest according to Nightfall policy but
must not consume the parts merely because it reached the effigy.

Newly constructed effigies retain each part's bounded Project M.O.R.T.I.S.
subtree material record. Their food value is derived from canonical edible
calories and the configurable `EffigyCaloriesPerFullFeed` conversion rather
than a fixed reward. A successful feeding claim depletes the preserved material
with replay-safe M.O.R.T.I.S. transactions before removing the world object.
Older effigies without material records remain loadable and use the historical
0.50 hunger-value fallback; malformed canonical records fail closed.

## Search-state requirements

Effigy reactions are server-authoritative persistent states, not one-shot path
commands. A state records the effigy/event identifier, suspected player or last
known player evidence when available, origin, start/end world age, current mode,
searched locations, and next decision time.

### Regular-source / Smart Feral

- destroy the effigy;
- search the immediate area for a short configurable duration;
- abandon the search if no useful player evidence is found.

### Feral-source / Smart Feral

- destroy the effigy;
- search for 24 in-game hours by default;
- take several breaks in locally evaluated safe locations;
- resume until the deadline or until normal target logic supersedes it.

### Smart-Feral-source / Smart Feral

- destroy the effigy;
- enter an enraged regional search lasting several in-game days;
- search nearby buildings within a large bounded radius;
- rest or hide rarely;
- if the player is spotted, retain evidence and permit existing stalking,
  flanking, hiding, and ambush behavior to select the next action;
- do not receive omniscient knowledge of the player's current location.

## Implementation constraints

- Searches must be bounded, incremental, and scheduler-driven; never scan the
  whole cell or world in one update.
- Player and living-animal discovery/chase remains vanilla behavior. Nightfall
  registers effigies as local food/influence providers and does not make Project
  M.O.R.T.I.S. rescan vanilla targets.
- Attraction and avoidance use local influence queries with cached expiration,
  not per-zombie global effigy scans.
- Consumption/destruction must be claimed atomically so a horde cannot process
  one effigy multiple times.
- Effigy identity and reaction claims must survive save/load and support late
  join without duplicate destruction, consumption, or hunt creation.
- “Find the player” means investigation of evidence, buildings, last-known
  positions, sound, and sightings. Effigies do not grant map-wide omniscience.
- Search radius, local-search duration, 24-hour duration, multi-day duration,
  rest cadence, and influence strength will be sandbox settings.

## Composition

An effigy may contain multiple parts and multiple source signatures. Composition
rules will be registered data, not nested conditionals. Until mixed-source rules
are explicitly designed, construction should reject ambiguous mixtures rather
than selecting whichever source happens to be processed first.

## Current implementation boundary

Version `0.27.0` implements sever-time source classification, immutable
composition snapshots, mixed-source rejection, the canonical reaction policy,
bounded placed-effigy indexing, save/load restoration, atomic claims, local
pathing, persistent Smart Feral investigation state, and a 600-tick inventory
timed action that revalidates three selected same-source parts before consuming
them. Canonical material/nutrition survives part consumption into the constructed
effigy and is consumed transactionally when feeding completes. Host tests cover
composition/reaction policy, nutrition conservation, legacy migration, and the timed-action adapter,
not the complete inventory transaction in the engine.

Menu availability, queued-action validity and authoritative construction now use
one `validateConstruction` function. Parts must be unique, present in their
container, and owned by the character (including nested bags). Provider errors
fail closed. Queued selections are copied rather than retaining a mutable UI list.
Host regressions cover foreign inventories, disappeared parts, duplicate parts
and throwing container providers. Guided-test persistence retains its 0.19.0 key
because this patch does not change the test-step schema.

Remaining release work includes:

- validate engine-side rollback and replication failures before claiming transactional safety;
- verify actual part consumption, placement, restoration and reactions in game;
- final art and dedicated multiplayer validation.

## Optional research requirement

`ProjectNightfall.RequireEffigyKnowledge` connects construction validation to
B47ANCEDKnowledgeAndWisdom's `ProjectNightfall.EffigyConstruction` knowledge key. Reading
`NF-UV-003` then `NF-FIELD-026` unlocks construction; possession alone does not.
The shared validator applies this to menus, queued-action revalidation and
authoritative construction. Missing or failing knowledge providers reject the
action when the requirement is enabled. Already-placed effigies are unaffected.

The setting and packaged presets default to true, as approved by the project
director. An absent setting also requires knowledge; explicitly disabling it
restores unrestricted construction.
Host tests exercise the real knowledge registry and prerequisite chain, plus
missing providers, provider failures and disabling the requirement.

The inventory menu uses vanilla `ISInventoryPane.getActualItems` to expand
selected stacks and remove duplicate child selections. With three same-source
parts selected, failed construction validation displays a disabled option and
its reason rather than silently hiding the action. The click handler rechecks
eligibility before queueing. Menu regression tests cover disabled hints,
duplicate menu callbacks, stale eligibility and malformed selection providers.

## Construction failure handling

Construction creates the effigy off-inventory with vanilla `instanceItem`, then
removes original part objects using `ItemContainer.Remove`, verifies their
absence, and inserts the output with `AddItem`. It does not call `UseAndSync`,
which could alter part state before recovery. On a local failure it removes any
inserted output before restoring the original objects to their original bags.
Per-part guards reject reentrant construction. Replication is requested only
after commit, using vanilla container add/remove helpers.

Failure-injection host tests cover a second-part exception, no-op removal,
insert-then-throw, and reentrant factory callbacks. This is not crash-atomic:
unverifiable container state or failed rollback returns a recovery error and
must not be represented as successful recovery. Engine/network failures and
save interruption still need in-game and multiplayer testing. A committed
construction is not reported as retryable merely because replication fails.

## MORTIS API 1.6 feeding adapter (0.29.1-dev.1)

[TESTED: offline Lua 5.1] The real effigy provider now uses transaction version 1. Reservation exclusively leases an active source without changing tissue, claims, persisted data or the world. The quote uses canonical nutrition (or the existing .5 material-less legacy fallback). It checks server authority, exact object/source identity, a loaded square, finite positions, the same floor, 1.25-tile reach and the actual reaction. Commit rechecks source revision, identity and eligibility after MORTIS verifies hunger and stages its cache.

Commit installs the planned material losses, claim and consumed tombstone silently. Rollback restores the original composition, claim, status, revision and persisted snapshot, releasing only its own lease. Unknown/newer state refuses compensation rather than overwriting it; MORTIS quarantines failed compensation. An optional nonnegative integer revision remains within schema 1, with zero for existing saves. Claims, direct material consumption and destruction cannot compete with a food lease. No additional player setting is needed for internal transaction bookkeeping.

Only the matching successful ZombieFed event transmits the committed record and attempts native world/square removal. Duplicate events do nothing. A cleanup exception leaves an inert consumed record, emits a bounded diagnostic and never grants a second feed. OnObjectAdded and explicit registration cannot revive a consumed tombstone. Existing IDs attached to another object are rejected, not silently rebound. Wrapper replacement needs native lifecycle evidence; this adapter does not guess identity.

Leases are transient and callbacks must not yield. This is compensation for synchronous failures, not crash-atomic storage spanning hunger and world saves. A crash between resource writes, native removal/replication failure, streaming, late join/rejoin and dedicated restart remain [RUNTIME GATE]. Failed native cleanup may leave a visible inert object; inspect it without reactivating or duplicating stock. Existing destruction uses its separate claim path and now also enforces canonical authority. No balance/configuration or automatic lease recovery change is introduced.

Run `python scripts/run_host_tests.py --only tests/test_effigy_food_transactions.lua tests/test_effigies.lua`. The integration uses actual MORTIS FoodSources, hunger coordinator, FaultIsolation, event bus and tissue models, with native stats/world/persistence boundaries mocked. See [current validation](VALIDATION_0.29.1-dev.1.md) for exact dependency snapshots and native gates.

## 0.31.0-dev.1 read-only container foundation

`PN_EffigyContainerPolicy.classify(item)`, `inspect(container)` and `validateInsertion(container, candidates)` now implement the agreed category/visual policy as read-only queries. They reject meat/part and cross-provenance mixing, duplicate/sparse/invalid batches, nested bags and malformed/future provenance/materials. Physically present depleted parts retain their category and body-part-loaded appearance. Validation returns a proposal, never a transfer authorization or lease; ownership/reach/capacity and committed resource changes are outside this foundation. No player-facing UI/reason strings or extra sandbox settings are introduced.

The native transfer boundary is unsafe for a simple dynamic predicate: [audit](EFFIGY_CONTAINER_API_AUDIT.md). World binding, actual item transactions, migration, ordinary-meat effects and rendering stay blocked. Existing combined-item effigies/food transactions are unchanged. All three assets still need authoring; [concept brief](../art/effigy/ASSET_BRIEF.json). See [validation](VALIDATION_0.31.0-dev.1.md).

## 0.31.0-dev.2 implementation checkpoint

The dynamic native admission blocker is resolved in source by permanently denying native insertion and using the synchronous server loader for a separate EffigyFrame prototype. Whole-batch validation, actual-item moves, revision checks, rollback/quarantine and localized load intents are implemented. Native unloading remains available. Capacity is a server sandbox option (1-40, default 20). See [implementation, limits and human gates](EFFIGY_CONTAINER_IMPLEMENTATION.md). Older foundation findings above are historical. Construction/loot distribution, reusable feeding, attribution, migration and three production models/rendering remain pending. Native/SP/dedicated validation is NOT TESTED; no package/deploy/upload.

## 0.31.0-dev.3 reusable feeding checkpoint

[Reusable frame feeding](EFFIGY_CONTAINER_FEEDING.md) now uses actual stored meat/part resources through the server MORTIS transaction coordinator. The user approved ordinary-meat feeding for hungry infected without part-specific reactions/search/grudges. Frames and depleted parts persist; category separation, shared load/feed leases, compensation and recovery guards remain authoritative. Existing calorie/hunger sandbox settings apply; no phantom legacy fallback stock is created. Construction, non-feeding influence/attribution, migration and three models remain pending. Native/SP/dedicated NOT TESTED; G7/stable G8 BLOCKED.
