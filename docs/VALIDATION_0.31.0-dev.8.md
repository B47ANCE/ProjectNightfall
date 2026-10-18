# Nightfall 0.31.0-dev.8 validation

Scope: compatible performance/correctness follow-up within the ongoing MINOR
prerelease. Current source/version mirrors advance together. Published dev.6
Contents and artifacts remain historical and unchanged. No production package,
deployment, game/server launch or Workshop upload.

[VERIFIED: source] Pin MORTIS 0.26.0-dev.9 to
`a8a50e40732bebcee70ddb8d9bc7abd5403c1890` (PR #17, unmerged). Knowledge remains
`eebfa3797bc95aab963816ec659896f5f018d982` (PR #2, unmerged); other three pins are
unchanged. This branch is stacked on Nightfall dedicated-research PR #9. Fixture
preparation verifies exact public origins, commits and Mod IDs without running
dependency scripts; post-test verification checks all five stay clean.

[TESTED: offline Windows, Python 3.12.14, Lupa 2.6 Lua 5.1] All **73 Lua test files
PASS** against the final MORTIS pin. Native file/player/collection/network APIs
are simulated; real dependency modules run. Regressions cover 10,000 idle AI polls
without a hunger query, visible start/continued chase, dense legacy discovery
128/129 boundaries and retained sources, plus authority-local hunger diagnostics.
MORTIS's separate suite covers its 100,000-actor FIFO/global budget, clock catch-up,
pre-meal settlement, failure/authority/weak-reference/capacity cases and actual
Engine admission. Counts do not prove native FPS, Kahlua or dedicated behavior.

Commands from this feature checkout (Python is the configured CPython 3.12 runtime):

```text
python scripts/check_versions.py
python scripts/prepare_ci_dependencies.py
python scripts/run_host_tests.py --dependencies .local/ci-dependencies
python -m unittest discover -s tests -p "test_*.py"
python scripts/dependency_contracts.py --dependencies .local/ci-dependencies
python scripts/audit_project.py --dependencies .local/ci-dependencies --output .local/source-audit.json
python scripts/prepare_ci_dependencies.py --check
git -c core.autocrlf=false diff --cached --check
```

[TESTED: offline Windows] All **27 Python tests PASS**. Source audit, dependency
contracts, current version mirrors and all five post-test fixture checks PASS.
The source audit reports release consistency BLOCKED for current Contents parity
and package validation, as expected for an intentionally unpackaged source slice.
Historical mirror protection PASS. Final staged/public-file review and exact-head
CI results are recorded in the PR; CI is still offline evidence.

See [bounds, time, settings and human acceptance](HUNGER_POPULATION_SCALING.md).
Server authority, research, five source categories, recipe costs, actual-item
transactions and existing save/network schemas are retained. Native/SP/dedicated
Insane-population timing and persistence remain NOT TESTED. G7 BLOCKED / NOT TESTED;
stable G8 BLOCKED. No old validation is promoted to current runtime proof.
