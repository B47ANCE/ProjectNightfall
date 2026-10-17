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
