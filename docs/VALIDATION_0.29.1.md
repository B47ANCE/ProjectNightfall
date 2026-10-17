# Nightfall 0.29.1 audit completion - 2026-10-16

## Scope and outcome

[VERIFIED: source] Development PATCH 0.29.1 completes the remaining offline audit tooling from the 0.29.0 findings. Runtime gameplay, balance, schemas and authority remain unchanged. The only runtime-source edits are synchronized version mirrors. Current source is not packaged. Historical Contents/artifacts and the historical archive fixture helper are preserved.

Work started from 21aa63ef63cf3814c355cecaf4863f068d190b70 in an isolated feature worktree, branch fix/nightfall-audit-completion. Freshness was PASS, upstream identical, ahead 5/behind 0 relative to origin/main. The original checkout is independently on fix/effigy-food-transactions with uncommitted source/test changes; those are outside this audit slice and were not touched. Do not treat this branch as containing that concurrent fix. Reconcile it before a combined candidate is packaged.

## Findings and disposition

| 0.29.0 finding | Current disposition | Completion boundary |
| --- | --- | --- |
| P1 Health Care Mod ID drift | Fixed in prior iteration; regression retained | Selected public commit contracts pass; native startup remains untested |
| P2 own dependency metadata blind spot | Fixed in prior iteration; regression retained | Source evidence, not runtime transport |
| P2 native renderer/runtime capability gaps | BLOCKED / NOT TESTED | No safe owned renderer exists in selected MORTIS source; no gameplay fallback invented |
| P3 localization | Structural remediation complete; translation-quality work open | EN authored, 28 explicit English fallback locales, 6,300 identical values; fluent/native review needed |
| P3 audit/release workflow debt | Fixed in this iteration | Source audit passes independently; release consistency remains strict and blocked |

The next executable runtime cases and unresolved asset/capability inputs are in [the acceptance handoff](RUNTIME_ACCEPTANCE_0.29.1.md). This is not a claim that every roadmap feature is complete. Native smoke, anatomical/physical remains, live calibration, final audio, unloaded migration and the deferred condition/history gates remain unresolved at their documented boundaries. Project Remnants remains excluded.

## Changes and invariants

- `audit_project.py` reports source and release consistency separately. Default success checks current source/package inputs without constructing a production archive. `--release` still fails on stale Contents or absent current artifacts. `check_versions.py --release` and the package verifier remain strict and unchanged.
- `audit_policy.py` protects the historical mirror using Git tree 78ee60785451301993de205f252ffd14e9aaf09b, recorded from the 0.27.4 packaging commit, plus worktree/index and untracked/ignored checks. This permits Git's line-ending normalization on fresh Windows/Linux checkouts while rejecting historical content changes. Historical archives present are still checked for paths, duplicates/case, CRC/data, special/encrypted members and classification. Missing ignored archives in a new worktree are not claimed validated.
- Old operation baselines no longer freeze intentionally mutable source forever. A caller may explicitly select an operation baseline with `--protected-baseline`; all its entries then remain byte-protected. Historical mirror protection applies independently without that option. No old evidence is rewritten.
- Localization now checks file/key inventories, nonempty string values and substitution identifiers/multiplicities. Missing Lua syntax tooling is a source failure rather than silent success. [Localization policy](LOCALIZATION_POLICY.md) distinguishes structural fallback from fluent translations.
- `prepare_ci_dependencies.py` selects full public commit SHAs and validates origin/commit/clean state/Mod ID, without executing dependency scripts or changing sibling repositories. Differing existing fixtures fail and are preserved. The original `prepare_test_dependencies.py` remains the 0.27.4 archive helper. An initial Windows long-path checkout failure was retained locally; long-path support is now explicit in fixture Git operations.
- CI runs offline checks on Linux and Windows with contents-read permissions, no persisted checkout credentials or project secrets, full action SHA pins, exact Python and hashed binary Lupa wheels. No production package, deploy, publication, SFTP or game/server launch is scheduled. See [CI details](CI.md).

No meaningful gameplay configuration, authority boundary or persistence schema changes are introduced, so no new sandbox option is warranted. Historical packages, supplied art and independent effigy work are preserved. The Git index secret/path scan is heuristic and cannot prove absence of every possible secret.

## Exact validation commands

[TESTED: offline] Windows, Python 3.12.14, lupa 2.6 Lua 5.1. All dependency fixtures are clean at the [recorded public commits/tree hashes](audits/0.29.1.dependencies.json), checked again after tests.

| Command | Result |
| --- | --- |
| `python scripts/prepare_ci_dependencies.py` | PASS; five public commit-pinned source fixtures |
| `python scripts/check_versions.py` | PASS before implementation (0.29.0), PASS after (0.29.1) |
| `python scripts/run_host_tests.py --dependencies .local/ci-dependencies` | 62/62 Lua files PASS |
| `python -m unittest discover -s tests -p "test_*.py"` | 25/25 PASS, including 17 disposable packaging tests |
| `python scripts/dependency_contracts.py --dependencies .local/ci-dependencies` | Direct/transitive source contracts PASS |
| `python scripts/audit_project.py --dependencies .local/ci-dependencies --output .local/source-audit.json` | Source PASS; 55 Lua syntax files, family requires, case, Lua-only, locale structure and historical mirror PASS |
| `python scripts/prepare_ci_dependencies.py --check` | PASS; no fixture changes |
| `python scripts/audit_project.py --release --dependencies .local/ci-dependencies` | Expected FAIL: current Contents/package consistency; source remains PASS |
| `python scripts/check_versions.py --release` | Expected FAIL: historical Contents differs from current source |
| `git -c core.autocrlf=false diff --cached --check` | Required before commit; no whitespace errors |

New regressions exercise source/release separation without hiding source failures, archive integrity/classification, historical committed/staged/unstaged/ignored mutation, translation substitutions, lock validation and non-repair of dirty/wrong-origin fixtures. The retained 62 Lua files cover existing production behavior; no mock output is relabeled native evidence.

The first CI attempt was rejected for YAML quoting of the pip colon-bearing argument; this was corrected. Windows setup then showed that GitHub has no 3.12.14 Windows distribution. The matrix now pins Linux 3.12.14 and Windows 3.12.10 (verified against the official distribution manifest). These were CI setup failures, not runtime evidence. CI status is recorded on the pull request for the exact pushed SHA. A workflow definition alone is not a green run, branch protection or release approval.

## Runtime and release gates

[RUNTIME GATE] Actual native UI, Kahlua loading, corpse creation/serialization/transport, SP, hosted and dedicated execution remain NOT TESTED. The retained native research does not prove Lua instance cleanup or corpse render support. No candidate renderer was enabled. Exact game SemVer remains UNKNOWN; prior installed-source observations were tied to Steam build 25485521, not this test environment.

G7 BLOCKED / NOT TESTED. Stable G8 BLOCKED. No production packaging, deployment, Workshop upload, stable tag, main merge, game/server launch or artifact deletion occurred. Public GitHub iteration history is separate from release readiness. Completion of the blocked cases requires the capability/evidence/assets identified in the current handoff; source and CI checks cannot supply those results.
