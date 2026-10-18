# Nightfall 0.31.0-dev.7 validation

Scope: compatible development research integration. Root VERSION/current mirrors
advance together; published dev.6 Contents and packages remain historical. No
packaging, deployment, upload or native process launch.

[VERIFIED] Pin Knowledge 0.17.0 at eebfa3797bc95aab963816ec659896f5f018d982,
an unmerged pushed development branch. The other four pins are unchanged. Five
clean public fixtures are checked by origin, full SHA, Mod ID and post-test state.
See [authority/persistence and dedicated acceptance](EFFIGY_DEDICATED_RESEARCH.md).

[TESTED: offline Windows, Python 3.12.14, Lupa 2.6 Lua 5.1] Before changes, the three
targeted research/construction/diagnostics files passed against the old 0.16.0 pin.
The new ready-backend diagnostic regression failed before the diagnostic fix.
After the fix, all 73 Lua test files pass. Native file/player/read/network APIs are
simulated; real dependency implementations run. All 27 Python tests also PASS. Final source/index audit and exact-head CI results
are recorded below when complete. No old validation is promoted to current proof.

Exact commands from the feature checkout:

```text
python scripts/check_versions.py
python scripts/prepare_ci_dependencies.py
python scripts/run_host_tests.py --dependencies .local/ci-dependencies --only tests/test_dedicated_research_diagnostics.lua tests/test_effigy_frame_construction.lua tests/test_dependency_diagnostics.lua tests/test_effigy_research_projection.lua
python scripts/run_host_tests.py --dependencies .local/ci-dependencies
python -m unittest discover -s tests -p "test_*.py"
python scripts/dependency_contracts.py --dependencies .local/ci-dependencies
python scripts/audit_project.py --dependencies .local/ci-dependencies --output .local/source-audit.json
python scripts/prepare_ci_dependencies.py --check
git -c core.autocrlf=false diff --cached --check
```

G7 BLOCKED / NOT TESTED and stable G8 BLOCKED. Dedicated is the first required
native validation target; SP is not a prerequisite. Current release consistency
is intentionally BLOCKED because no dev.7 package was requested. Existing-world
private migration, lifecycle/class precedence and coordinated storage failure/
backup tests remain gates. The Knowledge PR must be reviewed and the exact
matching dependency supplied before native integration testing.

Final local results: current versions PASS; 73/73 Lua and 27/27 Python PASS;
direct/transitive contracts PASS; five locked fixtures remain clean. Full source
audit PASS, no source failures. Retained published mirror PASS against pinned Git
tree 8a20e828fd4d659364a7087e8cd1b60cfa162e19. Public index review: 514 files,
no denied/potential-secret paths (heuristic, not comprehensive). Staged whitespace
PASS. No production package, native/SP/dedicated run or broader guard bypass.
Exact-head CI and remote SHA are recorded in the feature PR after push.
