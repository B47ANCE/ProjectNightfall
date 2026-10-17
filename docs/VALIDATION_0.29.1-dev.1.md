# Nightfall effigy feeding correction - 0.29.1-dev.1

[VERIFIED: source] Compatible development PATCH on baseline 21aa63ef63cf3814c355cecaf4863f068d190b70, branch fix/effigy-food-transactions, stacked on chore/nightfall-onboarding-audit. Root VERSION and declared current mirrors are synchronized. Optional effigy schema-1 revision defaults to zero for existing records. IDs, nutrition, reactions and sandbox values are preserved.

## Root cause and correction

MORTIS API 1.6 deliberately refuses one-phase consume callbacks because source/world destruction cannot safely precede verified hunger and cache changes. Nightfall still supplied consume only. The new actual-source integration first failed on the missing transaction contract.

PN_Effigies now implements exclusive reserve/commit/rollback. Reservation plans canonical tissue loss on copies without writes. Commit validates the exact live object/revision, authority, floor/range and current reaction, then saves a consumed tombstone silently. Compensation restores the before-images if still owned; foreign newer state fails closed for MORTIS quarantine. Successful ZombieFed alone transmits and attempts native removal, once. Cleanup failure keeps a consumed tombstone. Explicit registration cannot revive consumed data or silently rebind another object's ID. completeClaim now requires canonical authority.

[TESTED: offline Lua 5.1] The integration executes actual MORTIS FoodSources, hunger coordinator, FaultIsolation, event bus and tissue models; native statistics, world objects and component storage are mocks. Cases include two-actor contention, competing destroy claim, repeat rollback, ignored hunger setter, source persistence failure, abort after commit, planning exception, stale revision, unsafe compensation refusal, successful one-time cleanup, cleanup exception, tombstone reload/re-registration rejection, legacy nutrition, client refusal, cross-floor and unloaded object rejection. The general effigy fixture now exercises the phased contract too.

## Commands and outcomes

Environment: Windows; bundled Python 3.12.14 and lupa 2.6 Lua 5.1. Use the real Python executable configured for this workspace, not the Windows Store alias.

| Command | Result |
| --- | --- |
| `python scripts/check_versions.py` | PASS, current mirrors |
| `python scripts/run_host_tests.py` | 63/63 Lua tests PASS |
| `python -m unittest discover -s tests -p "test_*.py"` | 19/19 PASS, disposable packaging fixtures only |
| `python scripts/dependency_contracts.py` | direct/transitive source contracts PASS |
| `python scripts/audit_project.py --output .git/effigy-transaction-audit.json` | Expected overall FAIL: historical Contents/current-package/protection-baseline differences; inspect the source checks separately |
| `python scripts/check_versions.py --release` | BLOCKED: historical Contents and no authorized current package; not a release-ready source claim |

[Dependency snapshot](audits/0.29.1-dev.1.dependencies.json) records exact versions, commits, dirty flags and source-tree hashes. MORTIS coordinator input is clean 0.25.0-dev.3, 2f9b03a376aaecc751e6c10ffcf399916f444400; Knowledge & Wisdom is clean 0.15.0, ca5b724c63d49ab224f96b2daea3e17ad7498e44. Spectrum has unrelated dirty work: its tree hash, not its HEAD alone, identifies this local suite's input. No dependency is edited here. Whole-family native testing requires a reconciled, recorded build set first.

The pre-push Git-index secret/path audit and protected Contents/dist/art hash check are required for this iteration. Existing artifacts, custom art and old validation reports retain their original bytes and evidence. No package, deployment, publication, stable tag, game/server launch or main merge is part of this fix.

## Native gates and limitations

[RUNTIME GATE] G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. This synchronous adapter is not a crash-atomic cross-resource journal. Native hunger/component/world persistence, save/load after failure/success, competing clients, object-removal transport, streaming, late join/rejoin and dedicated restart remain untested. Failed cleanup may leave a visible inert object; do not reactivate it or manufacture replacement stock.

Use disposable sources. Record source ID/revision/status, tissue/calories and hunger before/after; consume exactly once, test two actors and all reaction signatures, then observe late join/rejoin and save/restart. Source or hunger faults must be injected only through an independently verified test surface, never assumed console APIs. If unavailable, mark those rows BLOCKED. Native ownership/animation/locomotion remain separate MORTIS gates; this provider does not establish them. Existing rendering, remains and audio gates remain unchanged.
