# Effigy container: native admission boundary

2026-10-17. Nightfall 0.31.0-dev.1 implementation boundary. Installed Steam build 25485521; exact game SemVer UNKNOWN. This is source/decompilation analysis and an offline policy counterexample, not an SP or dedicated exploit reproduction. Runtime behavior remains NOT TESTED.

## Historical dev.1 findings

- ItemContainer exposes packaged public setAcceptItemFunction(String) and isItemAllowed(InventoryItem). The predicate looks up a named Lua function and passes container/item. The inspected implementation does not reject merely because that function lookup is absent. A filter therefore requires verified bootstrap/rebinding, not only a stored callback name. Native presence alone does not prove a usable Lua setter or persistence across reload.
- ItemTransactionPacket.processServer iterates entries through TransactionManager.isConsistent before accepting/queueing the transaction. isConsistent checks destination.isItemAllowed against current contents. It accounts for pending transaction weight and item conflicts, but the inspected path does not reserve a dynamic Nightfall source category.
- Transaction.update later iterates updateItem. For ordinary container transfers, that path removes the source item and calls destination.addItem. The inspected ItemContainer.addItem/AddItem implementation does not repeat isItemAllowed, and the ordinary commit path does not provide a Lua pre-commit category hook.
- Consequently, incompatible distinct items preflighted against the same empty container can each pass a contents-derived predicate before either is inserted. The same problem applies to a mixed incoming batch whose entries are validated against the empty pre-batch state. Actual occurrence/exploitability in dedicated execution is [INFERRED] from this ordering, not runtime verified.

This is an authority blocker for exposing a reusable dynamically restricted world container through the unmodified native transfer route. A client-side selection filter, optimistic admission preview, timer, or post-transfer cleanup is not a fix: none proves atomic category admission, and cleanup risks item loss. Do not expose that world object, install an optimistic native admission callback or integrate feeding until an authoritative transfer/lease design covers pending transfers, mutations and rollback. Do not substitute custom Java.

The implemented policy can independently reject a mixed batch and re-evaluate after a first insertion. It has no commit/bind/create API and registers no events. A preview result does not reserve a category or establish ownership/reach/capacity. This is a safe read-only foundation while the affected gameplay adapter remains stopped.

## Lua-only next investigation

Investigate an explicit server-owned transfer adapter with a real category/item lease and verified exclusion of competing native transfers, or another exposed engine transaction extension that revalidates at commit. Prove insertion and removal paths, cancellation, timeouts/disconnect, mixed batches and feeding contention. Custom commands alone do not secure a still-exposed vanilla container. Any alternative must preserve actual items and vanilla synchronization where verified. No such adapter is enabled by this increment.

For rendering, vanilla trap server Lua demonstrates setSprite plus sprite/modData object-change synchronization. This supports researching a sprite-state adapter; it does not establish arbitrary FBX model swapping, safe preservation of container identity during a state change, or late-join behavior. All three effigy runtime assets are still missing. The supplied concept is an authoring reference, not an in-game screenshot or render test.

## Evidence fingerprints

Only original analysis/fingerprints are committed. Selected native classes were read from the installed projectzomboid.jar and decompiled locally with existing CFR 0.152 tooling; no mod Java, bridge, injected class or runtime dependency was implemented. No loose override of the four selected classes was present at inspection.

Installed projectzomboid.jar SHA-256: `e1a69eb743ede60b213a0fe7f8b83d4fcab773036d256cc4543a336f3b058a33`.

| Packaged entry | SHA-256 |
| --- | --- |
| zombie/inventory/ItemContainer.class | `a2ac7dd6235f91255dc57b91419a2c8609bdb105214cddf7fb445b70507b6f96` |
| zombie/core/TransactionManager.class | `4a0f649f5e55edd13eff7d6788934fbec49e0073901609e1c12731fc47d7481d` |
| zombie/core/Transaction.class | `107b0a554cc46d1015398ff283a2e48faf02efbc44adf12854f66394ee2487b6` |
| zombie/network/packets/ItemTransactionPacket.class | `41608a6690d16cb0ac202a4a3196b2b0851dadb935bca2b1d9a0a3e501791e83` |

CFR 0.152 tool SHA-256: `f686e8f3ded377d7bc87d216a90e9e9512df4156e75b06c655a16648ae8765b2`. Tool/decompiled files remain ignored local research, outside runtime/package source. A reusable negative observation is stored as INFERRED / NOT_TESTED in the API local draft; native inspection is not promoted to Lua/runtime proof.

## 0.31.0-dev.2 Lua-only resolution

The dynamic-predicate blocker above remains correct for the rejected architecture. The implemented alternative permanently rejects native insertion and moves actual items in a synchronous, fully validated server Lua command; see EFFIGY_CONTAINER_IMPLEMENTATION.md. Native unloading is retained. No private queue, Java override, timer-based admission lock or client-owned gameplay is introduced.

Additional source observations (installed bytes only, native execution NOT TESTED):

- Item.InstanceItem constructs InventoryContainer and installs script OnlyAcceptCategory and AcceptItemFunction on its real container. InventoryContainer.load fills that existing container; ItemContainer.load/clear do not reset these guards. Both script guards are installed before world exposure, not lazily rebound after an open interval.
- LuaManager.Exposer explicitly exposes ItemContainer and InventoryContainer, and exposes annotated GlobalObject helpers. The server sendAddItemToContainer/sendRemoveItemFromContainer helpers call vanilla GameServer routing. Installed server ClientCommands.lua demonstrates player inventory AddItem and packet helpers. Native descriptors/exposure do not replace actual Kahlua/runtime testing.
- The global isItemTransactionConsistent only calls TransactionManager when GameClient.client is true; otherwise it returns true. The inspected explicit exposure list does not expose TransactionManager. A server queue-probe lease cannot be inferred from the client helper.
- Native Transaction.updateItem re-resolves the source item ID before a normal commit; absent items do not move. AddItem performs its duplicate-ID check before calling the previous container Remove, so server loading calls AddItem without detaching first. Postcondition/readback and compensation still apply.
- GameServer mainLoopDealWithNetData dispatches queued packets on the main loop before game-state updates. The non-yielding Lua command has no asynchronous custom transfer interval. Reentrant own operations are guarded. Actual dedicated ordering/transport remains a human gate.
- AddInventoryItemToContainerPacket has a client processing path, not a client-to-server insertion handler in the inspected class. ContainerID resolves a world bag by actual world item ID. Native send helpers explicitly support InventoryContainer world items.

Additional selected packaged classes had no loose overrides at inspection:

| Packaged entry | SHA-256 |
| --- | --- |
| zombie/Lua/LuaManager$GlobalObject.class | `80ecbd3bd702db2f992db6cba7cb09c32d775fa6f2a3297e0460874ff5ba20c7` |
| zombie/Lua/LuaManager$Exposer.class | `9727656efbc06d7772661775f7a6885c7976b9e09472d7b128a3d5638ea68efa` |
| zombie/network/GameServer.class | `308ee5247dc8bba4df2283d40d753c6839497767b9342a4adeea60e7c08cfacc` |
| zombie/iso/objects/IsoThumpable.class | `cc19adbef73edbda83a56fdb727b70210278e6e4bd3c2c1def881dab804f8323` |
| zombie/network/fields/ContainerID.class | `d7ef29f65c423135d70f829a1381b9e32ce06d68f87ae49de1980bfcf7c0244b` |
| zombie/network/packets/AddInventoryItemToContainerPacket.class | `ebbd2e60b7430b6478498257cae19f21eb9d3e656bb1f03ac1dfa4422d2947f1` |
| zombie/network/packets/RemoveInventoryItemFromContainerPacket.class | `9eaceabf11a0fc4b2e0dc843fecfeada2417f76155de03aa059e7dae766fa983` |
| zombie/inventory/types/InventoryContainer.class | `891cb2f37a7d13de869edf05909de493a55ef90aa8665368b36bff7fa6b2555e` |
| zombie/inventory/InventoryItem.class | `48f01be16d1ef1b76e37638fac6e25ca4eb285ad38ab2f462caa5597318c7f9d` |
| zombie/scripting/objects/Item.class | `9e6a2f7fe48cc66843fea06b4821063d7cc6a73eaba0de8ee51d0a15c373202e` |

The prototypes/tests do not prove native serialization, Lua invocation, UI selection or MP PASS. The per-user API draft records the server-wrapper limitation and factory/packet route as INFERRED / NOT_TESTED.
