# Nightfall 0.31.0-dev.3 validation — 2026-10-17

Development MINOR prerelease continuation from 5298161734ddf4146966d6216e61dcf10472f37e.
Startup: clean feat/effigy-container; local/upstream SHA identical, 0 ahead/behind
upstream, 4 ahead/0 behind main. No unfinished Git operation. Target dev.3 was
recorded before implementation. Previous version reports remain historical.

## Implemented behavior and evidence scope

Separate server MORTIS transaction-v1 provider over actual stored items; shared
loader/feed lease; canonical item/material/revision checks; native publication;
chunk-save requests; compensation/quarantine; retained-intent recovery block;
bounded loaded-object discovery. Frames and depleted parts survive meals. The
user approved ordinary-meat feeding without part-specific reactions/searches/
grudges. No legacy fallback nutrition, cloned stock, custom Java, client feed
command, second nutrient ledger or old one-shot cleanup is introduced.

Read [feeding contracts and human cases](EFFIGY_CONTAINER_FEEDING.md),
[pinned dependencies](audits/0.31.0-dev.3.dependencies.json) and
[native fingerprints](audits/0.31.0-dev.3.native.json). Steam build 25485521;
exact game SemVer UNKNOWN. Packaged and differing loose IsoObject/IsoChunk
files were inspected for the relevant save/load hooks; those hooks agree.
Loose provenance/actual classpath precedence remain UNKNOWN. No engine class
was executed or installed, and no loose class is shipped/required by Nightfall.
Source/exposure inspection is not actual Lua/native invocation evidence.

## Offline validation

Windows Python 3.12.14, lupa 2.6 / Lua 5.1. Commands from the active worktree:

```text
python scripts/check_versions.py
python scripts/prepare_ci_dependencies.py --check
python scripts/run_host_tests.py --dependencies .local/ci-dependencies --only tests/test_effigy_container_feeding.lua tests/test_effigy_container_server.lua tests/test_effigy_container_menu.lua
python scripts/run_host_tests.py --dependencies .local/ci-dependencies
python -m unittest discover -s tests -p "test_*.py"
python scripts/dependency_contracts.py --dependencies .local/ci-dependencies
python scripts/audit_project.py --dependencies .local/ci-dependencies --output .local/effigy-feeding-audit-final.json
python scripts/check_versions.py --release
git diff --cached --check
```

[TESTED: offline] Version checker PASS before dev.3 at dev.2 and after the bump.
Focused 3/3 files PASS; complete Lua 69/69 PASS; Python 25/25 PASS. Five immutable
public dependency fixtures and direct/transitive source contracts PASS. Source
audit PASS with 62 Lua syntax files, case/require checks, localization and pinned
historical Contents preservation. Final index audit follows targeted staging.

The new test uses actual pinned MORTIS FoodSources, hunger coordinator, event bus,
Authority, DetachedParts and material model. Native stats/world/transport/save
boundaries are facades. It covers repeated meals/refill, both resource types,
all category restrictions, existing body-part eligibility, native transfer
winning before commit, replayed callbacks, no source duplication, depleted
remnants, partial regional writes, rollback after commit, uncertain foreign
canonical state, disabled-feature compensation, publication and save-request
failures, missing save capability, source identity/revision/age changes,
walls/floors/dead actors, load hooks, stale world membership, pending recovery,
client refusal and disabled feature paths. Old one-shot feeding regressions pass.

Strict --release exits 1 on historical Contents/source parity. No current package
was requested/built. Retained 0.27.4 files are unchanged. A passing source audit
does not turn that release consistency failure into a warning or G8 PASS.

## Native gates and remaining roadmap

Native/SP/dedicated execution is NOT TESTED. Human gates include actual prototype
creation/guard loading, queued native transfers and concurrent meals, actor/client
stock and hunger readback, same-ID part replacement, chunk-save requests and disk
durability, independent player/zombie/world saves, pickup/drop, streaming, rejoin,
retained pending intents, compensation recovery and dedicated restart. The marker
blocks automatic replay; it does not provide crash-atomic multi-file storage.
CI is offline evidence only; final commit/push/exact-SHA CI results are reported
with the PR after they actually complete.

Construction/distribution, non-feeding influence/destruction/attribution, legacy
migration and all three production models/rendering remain pending. The current
frame remains an undistributed prototype; old combined effigies are unchanged.
G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. No package, deploy, game/server launch,
Workshop upload or asset generation performed.
