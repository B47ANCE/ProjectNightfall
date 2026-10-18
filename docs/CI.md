# Offline CI and reproducible fixtures

The Offline validation workflow runs on pushes and pull requests on Linux and Windows. It checks current versions, the Python regressions (including disposable package fixtures), all Lua host regressions, source inputs, requires/case safety, Lua-only payloads, localization structure and the Git index public-file audit. It checks fixture immutability again after testing. It never builds a production package, deploys, uploads, connects to SFTP or launches PZ.

The workflow has only `contents: read`, does not persist checkout credentials, and uses no project secrets. It uses ordinary `pull_request`, not a privileged fork execution trigger. Official actions are pinned to reviewed full commit SHAs; CPython is pinned to 3.12.14 on Linux and 3.12.10 on Windows and Lupa 2.6 x64 wheels to SHA-256. The action manifests were inspected at the pinned commits. Sources: [checkout](https://github.com/actions/checkout/tree/11d5960a326750d5838078e36cf38b85af677262), [setup-python](https://github.com/actions/setup-python/tree/a26af69be951a213d495a4c3e4e4022e16d87065), [PyPI Lupa wheel metadata](https://pypi.org/pypi/lupa/2.6/json). Lupa is development tooling, not a mod runtime dependency.

`tests/dependencies.lock.json` selects public first-party commits. `prepare_ci_dependencies.py` fetches them only into this checkout's ignored `.local/ci-dependencies`, verifies origin, exact commit, clean state and Mod ID, and never executes their scripts. Existing differing fixtures fail and are preserved. Windows Git uses long-path support during checkout. No sibling repositories or installed mods are changed. Refreshing a lock requires contract tests and review; a sibling checkout moving does not update this lock.

```text
python -m pip install --only-binary=:all: --require-hashes -r tests/requirements-ci.txt
python scripts/prepare_ci_dependencies.py
python scripts/check_versions.py
python -m unittest discover -s tests -p "test_*.py"
python scripts/run_host_tests.py --dependencies .local/ci-dependencies
python scripts/dependency_contracts.py --dependencies .local/ci-dependencies
python scripts/audit_project.py --dependencies .local/ci-dependencies --output .local/source-audit.json
python scripts/prepare_ci_dependencies.py --check
```

`prepare_test_dependencies.py` and `dependencies_0.27.4.json` remain the historical archive-fixture workflow. They are not the current CI dependency selector.

Default audit success means current source checks passed. `audit_project.py --release` additionally requires current Contents/package consistency. `check_versions.py --release` and `package_project.py verify` retain their strict existing verifier. A declared historical mirror must match its pinned Git tree plus clean index/worktree, including no ignored extras. An operation protection snapshot is applied only when explicitly supplied with `--protected-baseline`; it is not a permanent freeze of source across intentional iterations. Historical archives present in this checkout still receive integrity and classification checks. Absent ignored archives are not claimed validated by a fresh checkout.

Current source has no package. Release consistency remains BLOCKED, as do gameplay G7 and stable G8 pending dedicated evidence. The index scan is heuristic and not an exhaustive secret detector. Green offline CI is not native Kahlua, SP, Linux dedicated or multiplayer proof. Branch protection must be configured separately when authorized; this workflow alone does not enforce merging policy.

GitHub's [Python distribution manifest](https://github.com/actions/python-versions/blob/main/versions-manifest.json) has no Windows 3.12.14 artifact; the initial Windows setup failed before testing. The matrix uses the verified available Windows 3.12.10 distribution while Linux/local evidence uses 3.12.14. Both use CPython 3.12 x64 Lupa wheels. The first run also exposed and corrected YAML quoting for pip's colon-bearing argument. Failed runs remain visible in GitHub history.

The 0.30.1-dev.1 recovery slice advances only the MORTIS and Knowledge fixture
pins to merged 6af5d141a2342179233db9131e749ee7b819383e and
6ba66c0d8f246d438f2e2f3c974fee9f77fdb426. The Knowledge MP guard remains enabled.
New real-module recovery regressions use these exact inputs; fragments are labelled
as fragment evidence. Other dependency pins remain unchanged.

0.31.0-dev.7 advances only the Knowledge fixture to development commit eebfa3797bc95aab963816ec659896f5f018d982 (Knowledge PR #2, unmerged). The pinned private document backend and owner projection run in real-module regressions with simulated native boundaries. Diagnostics report structural document support without probing storage, and do not infer readiness from the broader AuthorityGuard; those other guards remain closed. CI is still offline, never a dedicated PASS.

0.31.0-dev.8 advances only the MORTIS pin to `a8a50e40732bebcee70ddb8d9bc7abd5403c1890` (0.26.0-dev.9, PR #17 unmerged). Knowledge stays at the dev.7 private-document pin; the other three pins remain unchanged. The real pinned modules run with simulated native boundaries. Population regressions assert operation counts, idle query avoidance and bounded dense discovery; these are not Kahlua/FPS or dedicated benchmarks. See [current validation](VALIDATION_0.31.0-dev.8.md).
