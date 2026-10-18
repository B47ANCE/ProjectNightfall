# Original Nightfall source assets

`build_uv_bulb_geometry.py` creates an editable original bulb-envelope and
metal-base model under `models/`, outside the frozen runtime candidate. It uses
no third-party mesh or texture. Both existing UV item definitions currently
reference the same vanilla LightBulb model, so this shared source shape does not
invent a new high-output form factor or alter compatibility.

The script's isolated Blender Python run passed export/reimport checks: one mesh,
1,762 vertices retained, one UV layer, zero object location and floor-level origin.
This is source geometry, not finished artwork. Preview material colors are not
emission semantics. A 256-square basic color atlas is baked and connected to one
export material; reimport verifies its dimensions, resolved file reference and
shader connection. It still lacks detailed finished texturing, native scale
approval, runtime model registration and native visual validation.

Offline exported-FBX preview via `render_uv_bulb.py` was inspected. The first
render exposed coarse profile-ring corners despite smooth normals. One applied
subdivision pass on the envelope corrected that silhouette; the regenerated
export passed the same round-trip checks and its preview was inspected again.
This establishes offline shape review only, not native-game visual validation.
The atlas-backed exported preview was also rendered and inspected; blue envelope
and neutral base remain separate in this offline material pipeline. Native item
tint behavior must still be checked before integration.

`PN_UVBulbs.txt` currently sets item tint to RGB 0,0,255 on both UV variants.
Before assigning new artwork, verify how the native inventory/world renderer
multiplies that tint; a blue glass texture alone must not accidentally color the
metal base or obscure variant markings. Preserve emitted RGB and UV power behavior
in their existing owners. Standard/high-output differentiation remains a separate
inventory-art task, not permission to alter intensity, cone or physical fit.

## Planned effigy assets - 2026-10-17

The [approved container plan](../docs/EFFIGY_CONTAINER_PLAN.md) requires three initial visual states: EMPTY, MEAT_LOADED and BODY_PART_LOADED. Author one shared frame with separate contents groups, matching origin/scale/footprint, materials and UVs. The four provenance-based body-part categories share one body-part-loaded appearance initially; no mixed-content variant is allowed. Partial/full, broken and per-limb variants are deferred. No effigy models have been created or validated by this plan. The final runtime export format awaits a verified Lua-only world-object rendering path; Blender-authored states may need directional isometric sprite exports rather than arbitrary FBX swapping.

## Effigy concept and implementation foundation - 2026-10-17

The user supplied [this effigy concept](references/effigy-user-concept.png): an upright spiked wooden post with rope lashings and a braced foot. Exact supplied PNG bytes are preserved, SHA-256 `03cb7944ba3c7c03280ec0d9410a114cb3cf155a8d6f3fa34559b2b462e2d377`; this is a user-provided reference, not independently established provenance or native-game evidence. The [asset brief](effigy/ASSET_BRIEF.json) assigns the same frame to EMPTY, MEAT_LOADED and BODY_PART_LOADED, with separate contents groups. Skull/limb examples do not create extra states. The policy now derives those three identifiers, but no effigy mesh, texture, sprite export or renderer has been created/enabled.

## 0.31.0-dev.2 implementation checkpoint

The dynamic native admission blocker is resolved in source by permanently denying native insertion and using the synchronous server loader for a separate EffigyFrame prototype. Whole-batch validation, actual-item moves, revision checks, rollback/quarantine and localized load intents are implemented. Native unloading remains available. Capacity is a server sandbox option (1-40, default 20). See [implementation, limits and human gates](../docs/EFFIGY_CONTAINER_IMPLEMENTATION.md). Older foundation findings above are historical. Construction/loot distribution, reusable feeding, attribution, migration and three production models/rendering remain pending. Native/SP/dedicated validation is NOT TESTED; no package/deploy/upload.

## User-supplied project thumbnail — 2026-10-17

The supplied Nightfall/UV artwork is now the [project/Workshop preview](../preview.png) and [source mod thumbnail/poster](../src/ProjectNightfall/thumbnail.png). Both contain the exact supplied PNG bytes: 1254×1254, RGB, 1,492,415 bytes, SHA-256 `c6d61d90ef9d0ad87890c97ec862cd5ca0b0acb4ec82d8e64e9f8fb87013dd25`. No resize, crop, redraw or image generation was performed. Provenance is the user's attachment and instruction to use it; no independent authorship claim is made. The 32×32 mod icon is unchanged. Previous artwork remains in Git history and the protected historical Contents/packages. See [artwork validation](../docs/THUMBNAIL_2026-10-17.md). No package/deploy/Workshop upload.

## Approved Workshop derivative — 2026-10-17

For the explicit publish request, the user approved deterministic local resizing to satisfy the inspected PZ uploader's 256/512-square, 1,024,000-byte preview checks. Current preview.png is a 512×512 LANCZOS PNG derivative; source thumbnail.png retains the exact original 1254-square artwork. This supersedes the earlier shared-preview-byte checkpoint only for the upload copy. See docs/WORKSHOP_0.31.0-dev.5.md for hashes and validation. No redraw or image generation.
