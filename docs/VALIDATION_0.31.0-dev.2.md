# Nightfall 0.31.0-dev.2 validation — 2026-10-17

Development MINOR prerelease continuation; no stable release or tag. Target was
recorded before implementation. Current main was explicitly approved for merge
into feat/effigy-container, preserving both the effigy foundation and MORTIS
recovery fixes. Merge commit: d70cc7edb311c7f95ff1c5e08d5e87468fa7f5fd.
Older reports and dependency locks retain their original evidence.

## Implemented and inspected

- Separate, undistributed EffigyFrame native container prototype, with permanent
  insertion denial installed by the native item factory. No temporary opening,
  private native queue, Java mod, client mutation or category-lock timeout.
- Synchronous server Lua batch loader: actual server items, access/ownership,
  native safehouse and reach, category/provenance, equipment/removal, weight,
  configured capacity, replay revision and postcondition checks. Native unloading
  remains usable; queued native commits re-resolve their actual source item IDs.
- Reverse-order compensation before publication; quarantine uncertain rollback
  or committed transmission failure without cloning/recreating items.
- Client menu sends intent only, labels all five source categories and the three
  content states; pooled/test probes do not move items. Shared server sandbox
  capacity 1–40, default 20; existing-save default/overcapacity behavior documented.
- Main MORTIS recovery changes and current public fixtures preserved. See
  [dependency evidence](audits/0.31.0-dev.2.dependencies.json),
  [native audit](EFFIGY_CONTAINER_API_AUDIT.md) and
  [implementation/authority/failure contracts](EFFIGY_CONTAINER_IMPLEMENTATION.md).

[VERIFIED: installed source/decompilation only] Steam build 25485521; exact game
SemVer UNKNOWN. Selected packaged native class hashes and absence of loose
overrides are recorded in the native audit. No game classes were executed.
API draft observations remain INFERRED / NOT_TESTED for native invocation.

## Offline evidence

Environment: Windows, Python 3.12.14, lupa 2.6 / Lua 5.1. Native world/item/network
and UI boundaries are facades; MORTIS provenance/material modules are the actual
pinned modules. All commands ran from the active worktree with this interpreter.

```text
python scripts/check_versions.py
python scripts/prepare_ci_dependencies.py
python scripts/prepare_ci_dependencies.py --check
python scripts/run_host_tests.py --dependencies .local/ci-dependencies --only tests/test_effigy_container_server.lua tests/test_effigy_container_menu.lua
python scripts/run_host_tests.py --dependencies .local/ci-dependencies
python -m unittest discover -s tests -p "test_*.py"
python scripts/dependency_contracts.py --dependencies .local/ci-dependencies
python scripts/audit_project.py --dependencies .local/ci-dependencies --output .local/effigy-source-audit.json
python scripts/check_versions.py --release
```

[TESTED: offline] Current-version checker PASS before the bump at dev.1 and after
at dev.2. Five pinned public fixtures PASS; direct/transitive dependency source
contracts PASS. Focused 2/2 files PASS; complete Lua 68/68 PASS; Python 25/25 PASS.
The first focused fixture run failed on an incorrect test-only Tissue module path;
it was corrected to the actual TissueModel module before these passes. Merge
validation caught an old diagnostics API-version assertion; it was reconciled
to main's 1.6 contract before the merge commit.

Regressions cover every category pair, mixed first batch, competing requests,
load-revision replay, native transfer order in both directions, actual-item and
metadata preservation, physical emptiness, capacity, malformed IDs/settings,
equipment/removal and safehouse/access denial, client write refusal, reentrancy,
partial-move compensation, failed compensation, publication failure, unknown
records, stale world identity, result refresh, context pooling/test probes and
the SP route to the same authority handler. Module reload reuses actual metadata
in a fixture; this is explicitly not a native save/restart test.

Source audit PASS: 59 Lua syntax files, require/path case checks, translation
parity/placeholders and pinned historical Contents preservation. Public index
path/secret heuristic audit is required again after final targeted staging.
Reviewed MOD_OVERVIEW is refreshed against current raw source/README/VERSION.

Strict `--release` exits 1: Contents/source exact parity fails. Historical 0.27.4
Contents and archives are unchanged; no current package was requested or built.
This expected release blocker is separate from the passing source audit.

## Runtime and remaining work

SP, Kahlua/native script loading, native item creation/serialization/packet
delivery, two-client dedicated contention, frame pickup/unload, safehouses,
late join/reconnect/restart, failure recovery and keyboard/controller layout are
NOT TESTED. Human cases are in EFFIGY_CONTAINER_IMPLEMENTATION.md. A server-side
source argument and offline facades cannot prove native MP correctness.

There is no recipe/loot distribution, reusable feeding/ordinary-meat AI effect,
builder-versus-loader attribution, legacy migration, or production model/renderer
for the new prototype. All three asset states still require original authoring.
Existing combined effigies remain active and unchanged. Do not reuse their
one-shot consumed-object cleanup for this reusable frame.

G7 BLOCKED / NOT TESTED. Stable G8 BLOCKED. GitHub commit/push/CI outcomes are
reported with the final iteration SHA and PR checks, not invented in this report.
No package, deployment, game/server launch, Workshop upload or asset generation.
