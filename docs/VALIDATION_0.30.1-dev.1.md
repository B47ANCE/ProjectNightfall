# Nightfall MORTIS recovery validation

Current version: 0.30.1-dev.1. Development PATCH based on public main
`6988b57b81ff0dbb859857eb79aace81c2e65c8f` (0.30.0). Final iteration SHA and CI
results are recorded by its PR. Earlier audits/fixtures remain historical.

[VERIFIED — source] NF-M01–NF-M04 are corrected in the candidate described by
[MORTIS_RECOVERY.md](MORTIS_RECOVERY.md). Own requests/ceiling are released before
verified identity clear; failed cleanup cannot commit NORMAL. Hibernation waits
for UV-slow release and persists that retry flag. Assignment compensation checks
results/readback and retains a versioned authoritative recovery journal; pending
or uncertain state blocks subsequent lifecycle work. Assignment callers defer
phase, promotion, gear and visual commits on failure. Diagnostics require the
used MORTIS 1.6 surface/food v1 and separate presence from Knowledge MP readiness.

The new real-module regression first failed on the old production code at the
own-owner clear assertion. Its corrected fixture uses an explicit test anatomy
species and modeled native methods; it does not depend on native bootstrap.
The original MORTIS audit remains evidence for its exact old Nightfall commit,
not a test of this corrected candidate.

[TESTED — offline Windows, CPython 3.12.14 / Lupa 2.6 Lua 5.1] 65/65 Lua host
files and 25/25 Python cases PASS. Focused probes cover own/foreign ownership,
busy refusal, original-field restoration, failed initial nutrition/compensation,
typed rollback, repeated/reloaded recovery, future/corrupt/conflicting records,
uncertain provider exception, lying-clear readback and client refusal. Identified
production lifecycle fragments check UV cleanup/serialization, knockdown and
assignment/promotion commit order, and the early update gate. They do not execute
the entire native UV lifecycle. Real Knowledge guard cases cover SP/server/client/
unknown realm; real MORTIS negotiation accepts the requested surface.

[TESTED — offline source audit] Version mirrors, direct/transitive dependency
contracts, exact-case family imports, Lua-only payload, localization structure,
55 production Lua parses and pinned historical Contents preservation PASS.
The reviewed overview uses the installed shared hub schema/fingerprint. Its raw
byte/layout binding can require review on another checkout; it is not native proof.
The final staged public-file heuristic and whitespace review are required before
push. Current Contents/package release consistency remains BLOCKED; no production
package was built. Disposable packaging unit fixtures are outside live mods/saves.

Current locked public source inputs (all other pins unchanged):

- MORTIS: `6af5d141a2342179233db9131e749ee7b819383e`, 0.26.0-dev.3, merged PR #8.
- Knowledge: `6ba66c0d8f246d438f2e2f3c974fee9f77fdb426`, 0.16.0.
- SPXTRM: `4dfd911353d1f4631feffbd3c6bfe592c52fbdea`.
- Power: `40ff9ebfe247d56d7dd2e308e7b7eabfb61a7ce0`.
- Health Care: `0c7fd8defe24d859db69d585c7a3f0b5f9649c76`.

The prepare/check helper verifies origin, exact SHA, Mod ID and fixture cleanliness;
dependency source is not edited or downgraded. Knowledge's intentional
MULTIPLAYER_STORAGE_UNAVAILABLE remains an implementation blocker.

Commands from this checkout, using Python with the pinned development requirements:

```text
python -B scripts/prepare_ci_dependencies.py
python -B scripts/check_versions.py
python -B scripts/run_host_tests.py --dependencies .local/ci-dependencies
python -B -m unittest discover -s tests -p "test_*.py"
python -B scripts/dependency_contracts.py --dependencies .local/ci-dependencies
python -B scripts/audit_project.py --dependencies .local/ci-dependencies --output .local/source-audit.json
python -B scripts/prepare_ci_dependencies.py --check
git diff --check
git diff --cached --check
```

[RUNTIME GATE] All tests requiring an open game/server are human-operated. No
PZ/server was opened, native result collected, live mod deployed, save modified,
Workshop item uploaded or stable release/tag created. Follow the four human
acceptance groups in MORTIS_RECOVERY.md after clean-baseline/dependency review.
Native journal disk ordering, old-save upgrade/downgrade, lost owner-stack
coordination, full animation/restoration, observers, streaming/late join,
reconnect/restart and dedicated persistence/transport remain NOT TESTED.
G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. Source corrections and green offline
checks do not close these gates or certify whole-family native startup.
