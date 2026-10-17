# Effigy container and asset plan

Agreed design: 2026-10-17. Planning baseline: canonical Nightfall 0.30.0, merged source commit 6988b57b81ff0dbb859857eb79aace81c2e65c8f. Status: approved plan; 0.31.0-dev.1 adds a read-only policy foundation only. Live container/feeding/rendering remain NOT IMPLEMENTED. The original documentation-only planning follow-up retained 0.30.0 without runtime/inventory/schema/reaction changes. The implementation checkpoint below is versioned separately; neither planning nor this foundation grants stable-release approval.

## Approved behavior

The effigy is a reusable placed container. Players transfer actual meat/body-part items through a vanilla-aligned container interface. Only eligible material is accepted. Its contents determine its appearance and source-specific behavior; the container and frame persist when food is consumed or contents are removed.

The user approved keeping source categories separate, forbidding ordinary meat/body-part mixtures, and planning exactly three initial visual states: EMPTY, MEAT_LOADED and BODY_PART_LOADED. Partial/full, damaged, destroyed and per-limb display variants are not required for this asset increment.

## Admission and source categories

| Category | Eligible contents | May coexist with |
| --- | --- | --- |
| Ordinary meat | Explicitly recognized ordinary meat with no conflicting human/infected provenance | Other eligible ordinary meat |
| Human body parts | Validated human-source material/provenance | Other eligible human-source parts |
| Regular zombie body parts | Validated regular-source material/provenance | Other eligible regular-source parts |
| Feral body parts | Validated Feral-source material/provenance | Other eligible Feral-source parts |
| Smart Feral body parts | Validated Smart-Feral-source material/provenance | Other eligible Smart-Feral-source parts |

A source category identifies a class, not one original individual. Existing same-category multi-source behavior is retained. The first successful insertion selects the category; subsequent insertions must match. The category clears only after the last physical item is removed or consumed. Zero edible material is not the same as an empty container: bones/depleted remains cannot unlock mixing while still present.

Classification must use verified item metadata/providers and canonical MORTIS/Health Care provenance. Never infer source from an item's display name, mesh, icon or appearance. Valid source provenance takes priority over generic meat tags; processing an infected/human part must not bypass separation by making it look like ordinary meat. Unknown/malformed/future provenance fails closed without deleting the item. Bags, nested containers and unrelated food/items are rejected, preventing contents from bypassing admission.

Mixed batch transfers must not choose whichever item happens to be processed first. Preflight a selected incompatible batch and reject it with a localized reason; recheck every authoritative insertion. Separate concurrent transfers are serialized: the first committed insertion wins and a conflicting transfer leaves its original item untouched. Same-category transfers must respect real capacity and existing inventory ownership rules.

## Derived visuals

| Actual container state | Visual | Category handling |
| --- | --- | --- |
| No items | EMPTY | No category lock or food/influence source |
| Eligible ordinary meat present | MEAT_LOADED | Ordinary-meat category |
| Eligible parts of one recognized source category present | BODY_PART_LOADED | Preserve human/regular/Feral/Smart-Feral identity in data |
| Unknown or inconsistent saved contents | Conservative diagnostic state | Preserve contents; refuse effects/transfers requiring trusted classification until reconciled |

Do not introduce an extra fourth production model merely for inconsistent data. Its safe fallback presentation is implementation-gated and must never imply that invalid contents are usable food. All four body-part source categories share BODY_PART_LOADED initially; changing a model must never change provenance or nutrition. Inedible body parts may remain visible without providing food. Whether they retain particular non-food reactions requires the existing policy to be traced explicitly before implementation.

Derive state after committed insert/remove/feed changes and reconcile on object load/reconnect. Cache a derived state for synchronization only if needed; do not create a second independent inventory or nutrient stockpile. Avoid global per-tick scans. A cached category/appearance must be checked against real contents after reload, not trusted to manufacture missing items.

## Asset requirements

Create one editable Blender source with a shared frame and separate ordinary-meat and body-part contents groups. Produce three matching assets:

- EMPTY: frame with no loaded contents.
- MEAT_LOADED: the same frame holding recognizable ordinary meat.
- BODY_PART_LOADED: the same frame holding body-part material.

All three need identical scale, origin, intended footprint, orientation conventions, contact points and consistent materials/UVs. The contents must read clearly at PZ camera distance. The body-part display must not promise exact limb composition when arbitrary eligible parts are allowed; use a representative or obscured display until true per-region attachment support is verified. These are static states; animation, rigging and extra category-specific meshes are not required initially. Frame shape, construction materials and final art style remain design inputs, not assumed costs or gameplay facts.

Runtime format stays open until verified. Authoring 3D source does not establish arbitrary in-world FBX swapping. If the verified Lua-only world-object route uses isometric sprites, render these same three source states to matching directional sprite sets. Prove the supported orientations, placement, draw order, scale and synchronization before final export. No paid generation, model creation, package build, deployment or publication is authorized by this plan.

## Authority, feeding and configuration

The server validates candidate classification, source/category match, inventory ownership, reach, capacity and in-flight resource claims before committing a transfer. Clients may filter the interface and submit intent, but must not own shared contents or category decisions. A client-only drag/drop filter is insufficient. All supported native transfer paths need a verified server enforcement route before gameplay implementation proceeds.

Reuse verified vanilla inventory synchronization instead of inventing a duplicate container protocol. Nightfall owns effigy reactions; MORTIS owns neutral material/nutrition semantics and feeding transactions; Health Care owns detached-part creation/provenance. The container holds actual items. Any material view used for feeding must be a revision-bound view of those items, not another consumable copy.

Feeding must lease the exact relevant items/revisions, revalidate against player transfers/destruction, commit resource loss together with the existing reversible hunger contract, and preserve the reusable frame. A failed or duplicate operation must not consume twice, grant food twice or restore stale stock. Physical item removal occurs only when the relevant item/material transaction supports it. Never reuse the old consumed-object cleanup to delete the reusable frame after feeding.

Do not carry the current combined-effigy nutrition snapshot into a new container alongside equivalent live items. That would double-count stock. Preserve native item condition/age/spoilage where available; an appearance update must not refresh food. No new rot timer is approved. Ordinary-meat attraction/feeding policy is not assigned human-source behavior by default and remains an explicit implementation design input.

Keep the existing research gate unless deliberately changed. The old three-part minimum belongs to constructing the combined effigy item and is not automatically a new-container admission or activation rule. Loading thresholds, capacity, construction costs, ordinary-meat eligibility (including raw/cooked/rotten/fish/offal), and food/effect balance still need explicit design before implementation. Meaningful gameplay values belong in validated server sandbox configuration; category identities, revision tokens and visual enum values are technical contracts, not player micro-settings. Reuse existing applicable sandbox controls.

Destroying the structure must conserve or deliberately account for real remaining items without duplication; do not assume all stock vanishes or is refunded. Existing evidence-based hunt behavior must not be cancelled just by emptying the container. Assigning responsibility after another player refills a frame also needs an explicit builder-versus-loader rule before changing the existing builder attribution.

## Saves and migration

Current schema-1 effigies store absorbed composition and feeding tombstones, not the original live container contents. Keep them loadable under their current path until a tested migration exists. Do not create equivalent item stacks from incomplete legacy snapshots or revive consumed tombstones. A new save schema/version and rollback policy must be chosen from actual implementation needs, not invented here.

Migration tests need disposable fixtures for current effigies, claimed/consumed states, canonical and legacy nutrition, missing providers and unknown schemas. New-container save/reload, category restoration, late join/rejoin and dedicated restarts must preserve items, revisions and derived visuals. Actual native save compatibility remains NOT TESTED.

## Evidence and implementation gates

[VERIFIED: installed source only] Steam build 25485521; exact game SemVer UNKNOWN. Vanilla server Lua documents item AcceptItemFunction callbacks and defines predicates in media/lua/server/Items/AcceptItemFunction.lua. This proves the inspected item-container predicate form, not a complete restricted world-container setup or server enforcement across every transfer path. Vanilla server traps in media/lua/server/Traps/STrapGlobalObject.lua select open/closed sprites and request sprite/modData synchronization on existing world objects. This is not proof of arbitrary 3D model switching. Reusable observations were recorded in the local API draft; no vanilla source is copied into this repository.

Before implementation:

1. Prove a Lua-only placed container, server-side admission enforcement for relevant transfer paths, and safe instance-preserving presentation updates. Stop affected gameplay implementation if these authority boundaries cannot be established.
2. Resolve the remaining bounded gameplay inputs above without silently assigning human effects to ordinary meat or changing the existing reaction matrix.
3. Define current-item and legacy migration ownership, concurrent transfer/feed/destruction transactions, sandbox interpretation and evidence requirements.
4. Create/validate the three source assets against the verified renderer/export contract, then implement a versioned, independently testable slice and update the project overview digest.

Required offline regressions include: all five category modes, same-category/different-individual acceptance, every cross-category rejection, meat/part rejection both directions, incompatible batch transfer, nested-container rejection, spoofed/unknown provenance, simultaneous first inserts, stale/duplicate requests, capacity failure, cancellation, partial transfer failure, concurrent looting/feeding/destruction, depletion versus emptiness, derived model changes, no frame deletion, save/reload and legacy preservation.

[RUNTIME GATE] Dedicated checks must cover native admission enforcement, real inventory transfers, feeding rollback, model/sprite update transport, late join/rejoin, streaming and restart. Planning/static inspection does not prove any of these. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.

## Planning validation

This iteration changes documentation only. Run python scripts/check_versions.py before/after; validate the project overview with the installed mod_overview.py inspection path and confirm its digest is current; check local Markdown evidence links and Git diff whitespace; audit the staged public index before commit/push. Existing Lua/Python gameplay test reports remain historical until rerun; no new runtime or asset PASS is claimed by this plan. Runtime source, VERSION, existing packages, art files and local settings remain unchanged.

Installed-source evidence fingerprint: media/lua/server/Items/AcceptItemFunction.lua SHA-256 `5a18403647286026f1dc3c6370f82e84e0539c6c47fbbf537774cda708322243`.

Installed-source evidence fingerprint: media/lua/server/Traps/STrapGlobalObject.lua SHA-256 `8658508304ea8bdefe2567f0a3886c6d6cdd712dde5dfca95d5d11c55ed20789`.

Implementation checkpoint 0.31.0-dev.1: classification, container inspection, whole-batch admission previews and the three visual identifiers are implemented with offline regressions. This does not satisfy the server transfer gate; see [native API audit](EFFIGY_CONTAINER_API_AUDIT.md). The user supplied a spiked-post concept retained in [the asset brief](../art/effigy/ASSET_BRIEF.json). Existing gameplay/save paths remain unchanged.

## 0.31.0-dev.2 implementation checkpoint

The dynamic native admission blocker is resolved in source by permanently denying native insertion and using the synchronous server loader for a separate EffigyFrame prototype. Whole-batch validation, actual-item moves, revision checks, rollback/quarantine and localized load intents are implemented. Native unloading remains available. Capacity is a server sandbox option (1-40, default 20). See [implementation, limits and human gates](EFFIGY_CONTAINER_IMPLEMENTATION.md). Older foundation findings above are historical. Construction/loot distribution, reusable feeding, attribution, migration and three production models/rendering remain pending. Native/SP/dedicated validation is NOT TESTED; no package/deploy/upload.
