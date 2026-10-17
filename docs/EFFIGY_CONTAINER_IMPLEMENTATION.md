# Effigy frame loading — 0.31.0-dev.2

[VERIFIED: source inspection] Lua-only authority design for installed Steam build
25485521; exact game SemVer UNKNOWN. [TESTED: offline Lua 5.1] Native boundaries
are facades, not a running game. SP/dedicated transport, save and UI NOT TESTED.

## Transfer race resolution

Do not admit an insertion through the delayed native transfer queue. The new,
separate `ProjectNightfall.EffigyFrame` item is a real native InventoryContainer.
Its script installs `OnlyAcceptCategory=ProjectNightfall_ServerLoadOnly` and
`AcceptItemFunction=PN_EffigyRejectNativeInsertion` in the native item factory.
The Lua predicate always returns false, on both peers. The category sentinel
also rejects the supported Food/Item categories if named-function lookup is
temporarily absent. It is an internal protocol guard, never a gameplay category.
No loader temporarily changes either guard. Missing/mismatched guards block the
custom loader as well. No dynamically accepted native insertion is queued.

The server command resolves the selected world item again using tile, bounded
world-item index and exact item ID. It checks the actual frame/world relationship,
server Enabled, living player, same floor, adjacent tile, blocked/window edge,
vanilla safehouse loot permission, supported metadata, expected load revision,
root-inventory ownership, equipment/removal eligibility, whole-batch category and
native weight/capacity. Item IDs identify existing server objects; the command
accepts no item blobs, provenance, quantities, material or source-container handles.

One synchronous server handler moves a fully validated batch with native AddItem.
Native AddItem checks destination duplicate IDs before calling the original
container's Remove; the loader must not detach items first. Identity/readback and
the complete resulting category/count are checked. No yielding, timer, optimistic
client movement or post-transfer category repair is used. Reentrant custom load
and server inspect calls refuse while a batch is in progress. The server main
loop processes native packets serially with game updates in the inspected source.

Ordinary native unloading remains available. Native Transaction.updateItem looks
up the item ID in its source again at commit. If this loader moves a root-inventory
item first, an older outgoing native transfer cannot find that item there; if the
native transfer wins first, this loader cannot resolve it in the player's root.
An outgoing transfer after a successful load moves the same actual item. It
cannot insert a conflicting category into the frame. This preserves normal loot
UI and actual-item conservation without accessing private queues. This source
argument still requires two-client native acceptance tests.

The exposed global `isItemTransactionConsistent` returns true on the server;
it is NOT a server queue probe. TransactionManager itself was not found in the
inspected explicit Lua exposure list. Do not use those as a server lease or
replace this design with a timeout-based category lock.

## State, persistence and failures

| State | Owner and storage |
| --- | --- |
| Actual contents, condition, spoilage, MORTIS records | Native items in the real ItemContainer; MORTIS remains material/provenance owner |
| First-item category and three visual states | Derived from all physical contents; no second stockpile or saved nutrition total |
| Load replay revision | Server-written frame item modData, `ProjectNightfallEffigyContainer`, schemaVersion 1, nonnegative integer revision |
| UI snapshot | Client presentation only; every server load repeats validation |
| In-progress batch guard | Transient server-only, scoped to a non-yielding call; no pending custom job to expire/cancel |

The load revision advances once per committed batch and survives normal native
item serialization. Native unloading does not advance this load-specific revision;
it cannot bypass current-contents checks. A stale/duplicate load fails before
movement and can receive a fresh snapshot. A request after physical emptying can
select another category. Bones/depleted body parts retain the old category until
removed. Different individuals of the same source category may share a frame.

Before publication, a failed batch attempts reverse-order restoration of the same
item objects, using native AddItem and readback. No replacement item is created.
Uncertain rollback sets a persistent quarantine marker and blocks further loads.
Items that cannot be restored remain in their actual native containers for human
reconciliation. A transmission exception after commit never rolls back a partly
published move; the revision remains advanced and the frame is quarantined with
`sync_failed`. Human inventory resynchronization/recovery is required. No automatic
quarantine clearing or reconstruction from metadata is provided.

On success the server uses vanilla `sendRemoveItemFromContainer` for the player's
root and `sendAddItemToContainer` for the frame, then sends a small result snapshot
to the requesting player. These exposed native helpers route player inventory
packets to its owner and world-container packets to relevant observers. Reliable
delivery, source/client readback, streaming and late joins are runtime gates.

A disconnect before command processing makes no custom change; disconnect or
acknowledgement loss after commit does not recreate items on retry. Restart has
no custom transfer lease to restore. Native item-factory construction installs
script guards before InventoryContainer.load fills the existing container.
Actual native save/reload and item-modData durability are NOT TESTED. This is not
a crash-atomic transaction across independently saved player/world inventories.
Unknown/future records and quarantine refuse loading without resetting saves.

## Prototype availability and configuration

No recipe, distribution or migration produces EffigyFrame yet. A human tester
must explicitly create the prototype through an authorized server/SP debug tool,
drop it, then use the world context menu's Load effigy submenu. Only eligible,
unequipped items in the player's main inventory appear. No nested bag/world-loot
source search is performed. The server protocol also supports a dense batch of
up to 256 distinct item IDs and rejects mixed batches before moving anything.
The same 256-item work bound applies to root inventory/contents; oversize inputs
are refused rather than truncated. Tile resolution bounds, ID/revision limits
and these work ceilings are technical safety constants, not sandbox settings.

`ProjectNightfall.EffigyContainerCapacity` is server authoritative: integer 1–40,
default 20 stored weight, in the Nightfall sandbox group. Name/tooltip exist in
all existing translation folders using the project's English fallback policy.
The server refuses invalid values and applies current capacity on load. Lowering
capacity retains existing items and prevents additional loading until there is
room. No inventory is deleted or truncated. Existing-save behavior uses the
default when the option is absent. The upper bound leaves room under the native
50-weight bag limit with the existing 8-weight effigy frame. This initial
development default needs human balance review; no activation threshold is added.

Client menu queries and inspection are presentation only. Two players may see an
empty preview simultaneously; only the first valid server load commits, and the
next request is rejected or validated against actual new contents. Responses
refresh the viewed frame's expected revision. A stale first/rejoined observer
may need to select the action again after refresh; there is no automatic retry.
Context pooling/test probes do not duplicate actions or send load commands.
Keyboard/controller layout and menu native selection remain human UI gates.

## Remaining effigy work

The three state identifiers still derive correctly: EMPTY, MEAT_LOADED and
BODY_PART_LOADED. All four body-part source categories share the last visual.
All three production models/textures and their native rendering adapter remain
missing. The prototype uses the existing Bandage icon as an explicit placeholder,
with no claimed effigy model. The user concept and asset brief remain authoritative.

Reusable-frame construction/cost/knowledge flow, ordinary-meat AI effects,
feeding actual stored parts, builder-versus-loader attribution, destruction and
legacy migration are not bound by this slice. In particular, do not register the
new frame with the old consumed-one-shot-effigy cleanup. No new AI effect or
nutrition duplication is introduced. Existing combined Effigy items, tombstones,
recipes and MORTIS food transactions remain on their previous path.

## Human acceptance gates

Run only when a human explicitly starts the game/server; this document does not
authorize launch or deployment. Use disposable saves and two dedicated clients.

1. Create/drop one prototype; confirm both guards after native load and restart.
   Drag/drop native insertion must reject meat, every part category and bags.
2. Simultaneously load human and Feral parts into empty stock; exactly one category
   commits. Repeat all category pairs and mixed server batches. Confirm exact item
   IDs, condition, spoilage and MORTIS records on server, actor and observer.
3. Race a native outgoing transfer of a selected root item with loading it; repeat
   native unloading, picking up/dropping the frame, cancellation and disconnect.
   No duplication, item loss or conflicting incoming queue may occur.
4. Remove some depleted parts, then the last one. Category stays until physically
   empty, then permits a different category. Validate derived three states through
   native unloading, rejoin and restart. Models remain a separate art gate.
5. Verify safehouse denial, wall/window/floor/range checks, other-player items,
   malformed IDs/indices/revisions and missing/future/quarantined metadata.
6. Change capacity across save/restart, including lowering below existing weight.
   Retain contents, allow unloading, and refuse excess or invalid loads.
7. Exercise rollback/transport fault fixtures, inventory recovery and human
   quarantine review. Never declare native durability from the offline facades.

G7 BLOCKED / NOT TESTED. Stable G8 BLOCKED. No package, deploy or upload performed.
