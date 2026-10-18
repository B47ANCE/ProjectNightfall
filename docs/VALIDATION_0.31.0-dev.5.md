# Nightfall 0.31.0-dev.5 validation — 2026-10-17

Compatible MINOR prerelease continuation from 659aadbf30ba8d5cca754c9f49335d95df49c7ad.
Startup PASS: clean feature branch, identical upstream SHA, 0 ahead/behind upstream,
6 ahead/0 behind main and no unfinished operation. Pre-edit version checker PASS
at dev.4. Prior versioned evidence remains historical.

User-selected frame costs: 1 log, 3 large branches, 1 rope, 8 nails. A working hammer,
sharp knife and exact Base.HandDrill are retained tools. Tools may be equipped but
must be in main inventory. Both read-only selection and canonical validation require
them; the server rechecks after input removal and before output insertion. A tool
lost during the transaction triggers material compensation without reclaiming the
foreign tool. Research, category restrictions, placement, save/network schemas and
recovery remain unchanged. Explicit existing sandbox values are preserved; missing
costs use the new defaults and the additive LargeBranches option defaults to 3.

See [recipe definition evidence](audits/0.31.0-dev.5.recipe.json) and
[construction contract](EFFIGY_FRAME_CONSTRUCTION.md). Steam build 25485521; exact
SemVer UNKNOWN. Actual vanilla tags/call forms and distinct large-branch item were
inspected. Offline tests use native-item/world/network/save facades, not the game.

Commands (Windows Python 3.12.14, lupa 2.6 / Lua 5.1):

```text
python scripts/check_versions.py
python scripts/run_host_tests.py --dependencies .local/ci-dependencies --only tests/test_effigy_frame_construction.lua tests/test_effigy_frame_menu.lua tests/test_sandbox_contract.lua
python scripts/run_host_tests.py --dependencies .local/ci-dependencies
python -m unittest discover -s tests -p "test_*.py"
python scripts/prepare_ci_dependencies.py --check
python scripts/dependency_contracts.py --dependencies .local/ci-dependencies
python scripts/audit_project.py --dependencies .local/ci-dependencies --output .local/effigy-recipe-audit-final.json
git -c core.autocrlf=false diff --cached --check
```

[TESTED: offline] Focused 3/3 PASS. New cases cover missing/broken/nested/wrong tools,
small-branch rejection, retained equipped tool identity/condition, server setting
changes and compensation when a knife moves after validation. Existing construction,
placement, research and category regressions remain included. [TESTED: offline] Full 71/71 Lua and 25/25 Python PASS. Current versions, five clean pinned dependencies and direct/transitive contracts PASS. Source audit PASS: 66 Lua syntax files, case/require checks, localization parity and historical Contents preservation. Reviewed overview digest PASS. Current release consistency remains blocked by historical Contents/packages.

Native/SP/dedicated NOT TESTED. Knowledge 0.16.0 dedicated research storage remains
blocked, so research-required construction fails closed. Three models/rendering,
human native craft/transfer/feed/persistence/rejoin/restart acceptance and other
previous roadmap gates remain pending. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.
Current packages/Contents remain historical 0.27.4, so current release consistency
is blocked. No package, game/server launch, deployment or Workshop upload.

Final staged audit PASS: 489 indexed files; zero denied or potential-secret paths. Intended source/tests/docs only; heuristic review is not a comprehensive secret detector. Whitespace check PASS. Public push SHA and exact-head CI results are verified in draft PR #7 after push.
