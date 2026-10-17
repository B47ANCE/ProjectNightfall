# Effigy container: native admission boundary

2026-10-17. Nightfall 0.31.0-dev.1 implementation boundary. Installed Steam build 25485521; exact game SemVer UNKNOWN. This is source/decompilation analysis and an offline policy counterexample, not an SP or dedicated exploit reproduction. Runtime behavior remains NOT TESTED.

## Findings

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
