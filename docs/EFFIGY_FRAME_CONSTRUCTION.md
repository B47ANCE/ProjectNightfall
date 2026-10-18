# Reusable effigy frame construction — 0.31.0-dev.4

[VERIFIED: source] Lua-only, server-owned assembly and placement are implemented.
[TESTED: offline Lua 5.1] Native boundaries use facades; native/SP/dedicated NOT
TESTED. This is a development prototype. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.

## Player flow and settings

Select a loose log, rope or nail in inventory and choose **Assemble effigy frame**.
The action selects the exact required loose materials from the main inventory,
then submits their IDs. Default cost is **4 Base.Log, 2 Base.Rope, 8 Base.Nails**.
The user chose logs/rope instead of the proposed planks/cloth; nails were retained.
Bundled logs/rope and nail boxes must be unpacked first. Worn/equipped items,
other players' items, nearby containers and nested bags are not ingredients.
The output is one empty `ProjectNightfall.EffigyFrame` with permanent native
insertion guards and schema-1 revision zero. No parts/meat are construction inputs.

Right-click a selected adjacent tile and choose **Place effigy frame**, then the
owned frame. This moves that exact item to the selected tile center. Valid stored
contents move with it; original IDs, provenance, tissue, condition, age and custom
load/feed revision remain intact. It neither clones the frame nor consumes contents.
One frame per tile is permitted by this custom placement action. It uses vanilla's
50-weight floor-item ceiling, solid-floor/free-tile checks, same-floor adjacent
reach, blocked/window edges and safehouse loot plus membership permissions.

Assembly is currently an immediate, synchronous context action; there is no new
crafting-panel recipe, timed recipe, XP award or tool wear. The existing legacy
three-part effigy action and its duration remain unchanged. Cancelling a menu
sends nothing; after submission the operation commits or compensates synchronously.
A declined intent never retries automatically. Menus follow vanilla context events
and pooling/test-probe conventions; controller and real UI acceptance remain gates.
All new labels/settings have key parity with explicit English fallback in every
existing language folder; no new human translation is claimed.

| Server sandbox ID | Default | Integer bounds | Existing saves |
| --- | --- | --- | --- |
| ProjectNightfall.EffigyFrameLogs | 4 | 1–10 | Missing value uses 4 |
| ProjectNightfall.EffigyFrameRopes | 2 | 1–10 | Missing value uses 2 |
| ProjectNightfall.EffigyFrameNails | 8 | 1–40 | Missing value uses 8 |

Each value is checked by the server at commit; malformed/out-of-range values refuse
construction. Positive minima prevent accidental free production. The existing
`Enabled` controls availability. Existing `RequireEffigyKnowledge` remains true
by default: **NF-FIELD-026 / ProjectNightfall.EffigyConstruction** is checked for
assembly and custom placement, using the same helper as legacy construction.
Client knowledge is presentation only. Missing provider, exception or unknown
knowledge refuses. Knowledge 0.16.0 intentionally blocks dedicated storage;
research-required actions consequently fail closed there. This implementation
neither bypasses that dependency nor changes the authoritative research setting.

Native pickup/drop/unloading remain vanilla operations over existing items. They
are not new frame creation and are not intercepted by this custom research/one-
frame-per-tile placement policy. Requiring research for every native relocation
would need a separately proved server transfer restriction; no such claim is made.
Native insertion into frames remains permanently denied, including after crafting,
placement and reload. Loading still uses the earlier server loader.

## Authority, transactions and recovery

`PN_EffigyFrameRecipe` selects/validates read-only IDs and costs.
`PN_EffigyKnowledge` contains the extracted, unchanged research check.
`PN_EffigyFrameMenu` sends only craft/place intents; SP invokes the same endpoint.
`PN_EffigyFrameConstruction` is server-only and resolves the authenticated player,
actual root inventory, exact dense unique IDs, ownership, equipment/removal
permission and current server costs. The client cannot supply items, provenance,
knowledge, output, inventory reference, claim owner or generated world object.

Assembly takes the shared State lease on the root inventory. It creates an empty
output off inventory, records an intent, removes exact inputs, inserts the output,
and checks identities before native inventory packets. Failure removes the output
before restoring actual original inputs. A foreign/dropped item is never stolen
back. A committed output is not refunded after publication failure. Replaying a
successful request cannot resolve the consumed IDs. Native queued transfers resolve
actual IDs at commit; whichever operation moves an input first wins.

Placement takes the same frame-container lease used by loading/feeding. It validates
actual contents, sets pendingPlacement and calls the verified actual-item overload
`AddWorldInventoryItem(item,.5,.5,0,false)`. Native construction clears the item
container link before the root inventory list is removed. It registers the world
object before setting the back-link. The handler verifies both links and square
membership, opts out of floor cleanup, removes the root entry, requests a chunk save
and only then publishes native inventory/world changes. State.changed registers
the committed frame for the existing bounded feeding discovery.

Before publication, failure removes only a newly created, exact matching world
object synchronously with `RemoveTileObject(object,false)`. Rollback also finds a
partially registered object missing its item back-link. It clears the world link
and restores/relinks the same frame after verifying no world duplicate remains.
It never substitutes a newly manufactured frame or rewrites a foreign container.
Uncertain rollback or committed packet failure quarantines the frame and retains
the intent. The schema-1 pendingPlacement marker blocks loading/feeding/placement
when retained. Technical limits remain internal: 256 root items, 1,024 world objects,
2,048 pending construction journals, bounded native IDs and coordinate ranges.
These bound work/protocol representation rather than feature balance.

Construction journals live in canonical server GlobalModData table
`ProjectNightfallFrameConstruction`, schemaVersion 1 with count and entries keyed
by server-resolved username. Completed/verified-compensated entries are removed.
Unknown schemas, malformed counts and retained entries block new construction;
there is no automatic replay/reset/refund. Player ModData is not an authority
store. Nightfall installs no OnReceiveGlobalModData importer and never transmits
this store. Native GlobalModData requests can read it, so it holds only non-secret
operation, item ID, tile and username metadata; no research text, grants or secrets.
Research remains owned by Knowledge. Journal/world/player files save independently:
this is synchronous compensation, **not crash-atomic disk storage**. Normal save/
chunk requests are not flush guarantees. Recovery requires inspection of disposable
save copies and exact real inventories; downgrading uncertain records is unsupported.

## Evidence and remaining gates

[Native fingerprints](audits/0.31.0-dev.4.native.json): Steam build 25485521, exact
SemVer UNKNOWN. Vanilla drop-action Lua calls the same actual-item overload and
native publication helpers. Packaged classes and a differing loose IsoGridSquare
were inspected. The loose decompiler inverts/reorders generator branches; the normal
frame branch has the same item/world registration and publication sequence. Other
recorded relevant square methods match. Loose provenance and active classpath remain
UNKNOWN; none of these classes is shipped/required by Nightfall. Source/exposure
inspection does not prove actual Lua dispatch or networking.

Human-operated native/SP/dedicated tests must cover:

1. Learn NF-UV-003 then NF-FIELD-026; confirm default research denial and eventual
   access where the dependency supports storage. Dedicated research stays blocked
   until that dependency contract is safely reconciled. Test missing provider,
   forged client knowledge and server setting changes without client authority.
2. Assemble with exact loose materials; repeat missing/nested/equipped/bundled inputs,
   duplicate/stale requests and native transfers winning before/after construction.
   Compare exact consumed/output IDs on actor, server and observer. Confirm menu
   cancellation sends nothing; no item loss or duplicate output on disconnect.
3. Place empty and each five-category loaded frame. Check walls/windows, floors,
   stairs/occupied tiles, safehouses, remote coordinates, floor weight, competing
   placement and native pickup/drop. Verify original stock/condition/age/revision,
   permanent admission guards, depleted-part locks and bounded feeding discovery.
4. Repeat loading/feeding/unloading during placement/pickup, native transport failures,
   partial native creation and compensation. Verify retained markers/quarantine
   refuse further unsafe work and never refund committed stock.
5. Save/reload, stream out/in, late join/rejoin and dedicated restart with clean,
   retained, unknown/future and uncertain construction/frame records. Compare actual
   inventories and independent world/player/global saves. Abrupt crash behavior
   remains unproved; retain backups and do not use live player saves for fault tests.

The three EMPTY/MEAT_LOADED/BODY_PART_LOADED identifiers still derive from contents;
all production meshes/textures/sprites/rendering remain pending. The existing
Bandage item icon is a placeholder, not the supplied spiked-post model. Non-feeding
reactions/attribution, loot distribution and legacy migration remain separate work.
No package, deployment, game/server launch or Workshop upload was performed.
