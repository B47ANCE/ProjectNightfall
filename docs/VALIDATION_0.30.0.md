# Nightfall SPXTRM dependency validation

Current version: 0.30.0.

2026-10-16. Base public main 0c4c902201c7125c56b2055fc78846b12c1b8306 (0.29.1), including audit/CI and reversible MORTIS effigy work. Feature branch fix/spxtrm-mod-dependency. User explicitly authorized main reconciliation. A superseded in-progress merge was preserved locally, then aborted when public main incorporated both predecessors; the authorized merge completed as a safe fast-forward, with no source discarded or history rewritten.

Pre-1.0 MINOR compatibility transition: require B47ANCEDSPXTRM instead of lightWorks. Existing Workshop 3788593239, Nightfall Mod ID, infected tissue/UV gameplay, save schemas and lightWorks Lua imports remain intact. No second exposure processor or infected damage implementation is added. Update enabled-mod lists on server and all clients together; SPXTRM retains Workshop 3788592008.

Inventory and current pinned fixture paths/URL/Mod ID match SPXTRM. Tests use explicit host SP realm predicates by default; individual authority tests override them. This accommodates the changing Knowledge API's fail-closed unknown realm without changing production authority. Debug surface fixture paths follow the new authoring root; old imported namespaces stay unchanged.

[TESTED, offline Windows / Lua 5.1] 63 host files PASS including actual MORTIS effigy transactions, UV tissue and source contracts. 25 Python tests PASS. Version checker, dependency contracts, source audit, localization, exact require paths and public index heuristic scan PASS. Current Contents/package parity remains a separate release blocker; no package built. Current locked public dependency fixture results and exact commit are recorded in the PR/report. Current sibling snapshot is recorded in docs/audits/0.30.0.dependencies.json; a dirty external snapshot is not a pinned clean pairing.

Commands:

```text
python scripts/check_versions.py
python scripts/run_host_tests.py
python -m unittest discover -s tests -p "test_*.py"
python scripts/dependency_contracts.py
python scripts/audit_project.py --output .local/spxtrm-source-audit.json
python scripts/prepare_ci_dependencies.py
python scripts/run_host_tests.py --dependencies .local/ci-dependencies
python scripts/dependency_contracts.py --dependencies .local/ci-dependencies
git diff --check
git diff --cached --check
```

Source/runtime distinction: new Mod ID native startup, old save activation, Native UI/inventory/lighting, joins/restarts and actual dedicated authority/transport remain NOT TESTED. Existing native smoke/remains gates remain unchanged. Current Knowledge source's upstream dedicated-storage blocker is not overridden by these SP host tests. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. Historical 0.29.1 and dev.1 reports retain exact observed versions. No packaging, deployment, game/server launch or Workshop upload.

Final review pins SPXTRM 4dfd911353d1f4631feffbd3c6bfe592c52fbdea, whose native UVC validity path performs no optical scan. The prior clean 06c3072 fixture is retained unchanged under ignored .local/ci-dependency-history; no deletion or reset. Nightfall optical imports/policy are unchanged.
