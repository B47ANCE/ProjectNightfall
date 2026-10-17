# Reusable effigy feeding — 0.31.0-dev.3

Source implementation and offline regressions only. Native/SP/dedicated NOT
TESTED; G7 and stable G8 remain BLOCKED. The undistributed EffigyFrame prototype
still has no construction recipe, migration or production model/renderer.

## Meals and source categories

The server MORTIS food provider `ProjectNightfall.effigyFrames` reads actual
native items inside a placed frame. It never registers that frame with the old
one-shot effigy cleanup. MORTIS Engine's existing bounded hunger schedule drives
food seeking; no second zombie updater is introduced.

One meal uses one stored piece, selected deterministically by native item ID:

- Ordinary Meat Food: consume the actual complete item. Read its current native
  calories/carbohydrates/lipids/proteins; do not rewrite age, condition, spoilage
  or other food values. No player OnEat/use/replacement-item hooks are invoked.
- Body part: use MORTIS DetachedParts/DetachedMaterialModel to remove only edible
  tissue from that item's canonical regions. Preserve the actual part, provenance
  and any inedible remaining tissue. Even a completely depleted physical part
  remains in the container until a player removes it.

The user explicitly approved ordinary-meat feeding for hungry infected of any
type, without body-part reactions, searches or grudges. For body parts, the
existing Effigies.reactionFor consumption eligibility applies: hungry actors may
consume human material; Ferals may consume regular-zombie material; categories
their policy avoids/destroys do not become food. New-frame non-feeding influence,
destruction, search and builder/loader attribution are not implemented here.

Positive finite current calories are required. Unsupported/noncanonical legacy
parts, zero-calorie meat and depleted tissue give no invented .5 fallback meal.
There is no extra nutrient store in frame metadata. Existing authoritative
EffigyCaloriesPerFullFeed converts calories into hunger value; MORTIS applies its
own FoodValueMultiplier and clamps hunger. This whole-piece meal can waste excess
nutrition when the actor becomes full; unused nutrition is not banked or restored.
No new bite/rot timers or hidden gameplay tuning tables are added. Existing
Enabled, MORTIS hunger/search options and calibration remain authoritative.

All five exclusive source categories remain intact. Depleted parts continue to
select BODY_PART_LOADED and block ordinary meat and other part categories. Only
physical emptiness clears the category. Removing the final meat item selects
EMPTY. Refilling the surviving frame can supply another meal. The three visual
identifiers remain derived views; actual models/rendering are still pending.

## Transaction ownership and replay

The provider is server/SP only; clients have no feed command and cannot nominate
food value, provenance, an actor, or a material loss. Authority is rechecked for
actor, world frame and selected item through the current MORTIS authority API.

Reserve holds the same server frame lease used by the loader and captures the
actual item, item ID, native age/condition, canonical material record, frame
revision, source identity and planned owner-API transitions. No stock changes at
reserve. Conflicting/reentrant loads, server inspections and feeding leases
cannot observe or authorize a partially completed own transaction.

Commit rechecks source registration, current loaded square/world membership,
exact world-item wrapper and source ID, matching revision, same-floor 1.25-tile
reach, blocked/window edge, living actor, current reaction, native item membership
and all planned resource preimages. It writes an opaque pendingFeed marker, then
removes the meat item or applies owner-validated regional losses. Native insertion
stays permanently denied. The ordinary transfer queue continues to resolve actual
source item IDs at commit: after meat removal it cannot find a second copy; after
part feeding it can only move that same depleted part. A transfer winning first
makes feeding revalidation fail, without recreating stock.

The frame's existing schema-1 revision now advances for both committed loading
and feeding; native unloading still requires fresh physical inspection and does
not advance it. Food source IDs include the frame ID and exact revision, so an
old ZombieFed event cannot finish a later meal on the same frame/actor. The token
is internal protocol data. No category, capacity, hunger or nutrition is inferred
from client snapshots.

On coordinator failure, rollback restores the same meat object, or the original
MORTIS record only while the current record is one of this transaction's known
states. A foreign/newer identity, source revision or material write is never
overwritten. Partial regional writes are compensated. Failed compensation leaves
the real objects and pending marker, quarantines the frame, and reports failure
to MORTIS (which quarantines the provider). There is no automatic reset/replay or
reconstruction from snapshots. Human reconciliation/restart is required.

Only the matching committed ZombieFed callback publishes the result: vanilla
sendRemoveItemFromContainer for consumed meat, or
sendReplaceItemInContainer(container, part, part) to serialize the same part ID
with its updated canonical modData. The native client packet removes/replaces the
old ID and updates queued-action references. No add packet with a duplicate ID
is used for material updates. A post-success transmission failure keeps resource
loss/revision committed, leaves recovery/quarantine state, and never refunds food
after hunger was granted. Duplicate callbacks do nothing. The frame is never
removed by this provider.

## Saves, discovery and runtime gates

Frame modData retains schemaVersion 1 and revision. The additive pendingFeed
record contains only schemaVersion, sourceId and itemId, not duplicate stock.
Any retained/unknown pending marker blocks loading and feeding after reload;
unknown/future frame schemas are preserved. A clean old dev.2 frame record needs
no migration. Do not downgrade or clear an uncertain record as routine recovery.

The exposed native IsoObject.flagForHotSave requests a chunk save for frame
contents/metadata changes, compensation and finalization. Loading now also
requests this save. Missing capability blocks mutation; a failed save request
refuses/compensates or quarantines the transaction. A requested hot save is not
an immediate disk flush or a crash-atomic save across zombie/player/world files.
Native durability, independent save failures and reconnect reconciliation remain
runtime gates. Lua debugger reload during an active transaction is unsupported.

Discovery indexes loaded frame objects through OnObjectAdded, removal and
LoadGridsquare, plus committed loading. Queries verify current cell/square and
world-item membership; stale objects are excluded. No global per-tick traversal
is added. Technical bounds are a 100-tile query radius, 2,048 tracked loaded frames, 128 examined entries
per query, 1,024 world items per load-square scan, and the existing 256-item/32-
region resource bounds. Oversized queries refuse rather than treating truncated
stock as empty. A full registry sweeps stale entries before refusing registration.
These are work bounds, not configurable balance values.

Human dedicated acceptance must cover simultaneous feeding/loading/unloading,
native queued transfers in both orders, pickup/drop, ordinary and source-specific
meals, partial-write and publication failures, depleted remnants, refill, late
join/rejoin, guard rebinding, save/reload, retained intents and dedicated restart.
Confirm exact item IDs, material receipts, native calories/condition/age, hunger,
category and visual identifiers on server and both clients. Repeat the existing
loader safehouse/capacity cases and all legacy effigy regressions. No runtime test
was launched by this implementation request.
