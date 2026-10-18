# Nightfall thumbnail update — 2026-10-17

Artwork-only follow-up to canonical 0.31.0-dev.5, based on
035ae96e209a48056fbef13ff910b50ff62ce7d5. Retain the existing development
version because this replaces supplied artwork without gameplay, schema, API,
configuration or runtime-code changes. Prior gameplay reports remain historical
and are not relabelled as validation of this commit.

User-provided PNG copied unchanged to `preview.png` (the established package/Workshop
preview) and `src/ProjectNightfall/thumbnail.png` (the existing mod.info poster
binding). The README displays the preview. Both copies are RGB 1254×1254,
1,492,415 bytes, SHA-256 `c6d61d90ef9d0ad87890c97ec862cd5ca0b0acb4ec82d8e64e9f8fb87013dd25`. Original attachment bytes were visually
inspected and verified with Pillow; no image editing/generation was performed.

[TESTED: offline] PNG decoding/CRC verification, dimensions/mode, exact input/copy
byte equality and SHA-256, existing poster binding and package input mapping.
The separate source icon remains SHA-256
`94c6f128b153ca804df5f69dcde19096d52b0869f6c6dda1e82c87107c14c744`.
Historical Contents thumbnail remains SHA-256
`95559538dd2c622987aa670fffd1c192626f3466bfe3dc0ced43394c8977dd6b`.
No new tests are introduced for this byte-copy change. Existing CI may run its
offline suite; it cannot validate native display or Workshop acceptance.

Validation: `python scripts/check_versions.py` before/after; read-only
`scripts.package_project.inputs(root)` verifies the established preview and
thumbnail mapping without creating outputs; PNG checks use `PIL.Image.verify`,
byte equality and `hashlib.sha256`; the reviewed overview digest is refreshed;
`git -c core.autocrlf=false diff --cached --check` and the repository index audit
run before commit/push. All PASS. Final staged audit: 490 indexed files, zero denied/potential-secret paths (heuristic, not a comprehensive detector); staged image bytes match both working copies.

Native mod display and Workshop upload acceptance NOT TESTED. The supplied
full-resolution PNG is preserved; no upload-ready size/format approval is claimed.
Existing gameplay G7/stable G8 remain BLOCKED. Historical 0.27.4 artifacts and
the current mod icon are preserved. No package, deployment, launch or upload.
