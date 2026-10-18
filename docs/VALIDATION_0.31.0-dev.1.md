# Nightfall 0.31.0-dev.1: effigy container foundation

2026-10-17. Development MINOR prerelease. Base d62af85b08956e4426994113d1393986edc1fb94 (approved container-plan branch), containing main 6988b57b81ff0dbb859857eb79aace81c2e65c8f. Isolated branch feat/effigy-container; startup freshness PASS, clean base, upstream identical and ahead 1/behind 0 relative to main. The original checkout remains untouched.

## Implemented

[TESTED: offline Lua 5.1] `PN_EffigyContainerPolicy.lua` is a read-only foundation with three APIs:

- `classify(item)`: uses actual MORTIS detached provenance/material validation first, then recognizes native Food objects with FoodType Meat. Body-part classes are human, regular, feral and smartFeral; ordinary meat is its own category. Unknown/future/malformed provenance never falls back to ordinary meat. Nested bags and unrelated foods fail closed.
- `inspect(container)`: reads a bounded native-list-shaped inventory and derives physical item count, category and only EMPTY, MEAT_LOADED or BODY_PART_LOADED. Mixed/invalid contents return an explicit error, not a false empty result. Physically present depleted parts remain body-part-loaded/category-locked.
- `validateInsertion(container, candidates)`: checks the current inventory and the whole dense batch without moving items. Rejects mixed source categories, meat/part mixtures, duplicate/already-present items, sparse/malformed batches and excessive inspection size. Same-category parts may come from different individuals. A result is a read-only proposal, not a lease or transfer authorization.

The module creates no world object, writes no canonical inventory/stock/save fields, registers no callback/event/food source and changes no existing recipe, effigy feeding, schema, balance, lease or synchronization code. It is usable for subsequent validators and presentation consumers, not a currently playable container. The MORTIS read API may allocate/read native modData; the policy does not modify its contents. Existing legacy effigies retain their production behavior.

The 256-item ceiling is an internal inspection safety limit, not a storage capacity or balance setting. Oversized collections are rejected, not truncated. No meaningful gameplay value is introduced, so no extra sandbox setting is appropriate for this foundation. Future capacity/activation/effect settings still require server sandbox design. Error identifiers are internal; no unlocalized player-facing UI is added.

## Stopped native integration

[VERIFIED: packaged source ordering; runtime consequence INFERRED] The [API audit](EFFIGY_CONTAINER_API_AUDIT.md) finds a request/commit gap in native item transactions. Dynamic admission can pass multiple incompatible entries against an empty pre-commit inventory; the inspected commit/AddItem path does not repeat it. A current-contents predicate alone therefore cannot establish the required atomic authority boundary.

In accordance with the global multiplayer-first invariant, affected gameplay binding stops here. No client-side authority fallback, optimistic world-container filter, timer-based category reservation or post-transfer item cleanup is introduced. The safe Lua-only next investigation is a proven server-owned transfer/lease adapter with exclusion of competing native transfer paths, or another verified engine extension that revalidates at commit. Custom commands alone are insufficient if native transfers still bypass the lease.

No renderer or models are enabled. The user-supplied concept is preserved byte-identically under art/references, with SHA-256 03cb7944ba3c7c03280ec0d9410a114cb3cf155a8d6f3fa34559b2b462e2d377. The asset brief specifies the shared spiked wooden post, rope lashings and braced base plus separate meat/part groups. Empty/meat-loaded/body-part-loaded assets still need authoring and native integration. Reference art is not game evidence or independently established provenance.

## Regression evidence

The new test was observed failing for the absent policy module, then passing after implementation. It uses real pinned MORTIS DetachedParts, DetachedMaterialModel and TissueModel modules. Only native item/container methods and instanceof are substituted; native engine transaction/synchronization is not exercised.

Cases cover every pair of the five categories in both directions, same-category/different-individual parts, all three visuals, last-physical-item removal, zero-edible body-part retention, source precedence over meat metadata, corrupt/future schemas/materials, supported legacy provenance without fabricated tissue, bags, unrelated foods, duplicate/sparse/malformed batches, NaN items, unavailable/oversized/changing collections, provider exceptions and canonical-input preservation. Write/move/transmit canaries are never called. `next=nil` checks the existing Kahlua compatibility boundary. Client inspection cannot commit anything because no write/bind/create API exists.

The queue counterexample shows two independent previews against an empty container passing, while the combined batch is rejected and a recheck after the first simulated insertion rejects the other category. This proves the policy requirement and unsafe integration pattern; it is not a dedicated exploit reproduction.

## Exact commands and results

[TESTED: offline Windows] Python 3.12.14, lupa 2.6 Lua 5.1. [Pinned public dependencies](audits/0.31.0-dev.1.dependencies.json) are clean before/after tests.

| Command | Result |
| --- | --- |
| `python scripts/check_versions.py` | PASS before (0.30.0) and after (0.31.0-dev.1) |
| `python scripts/prepare_ci_dependencies.py` | PASS; selected public commit fixtures |
| `python scripts/run_host_tests.py --dependencies .local/ci-dependencies --only tests/test_effigy_container_policy.lua` | Initial missing-module FAIL, then 1/1 PASS |
| `python scripts/run_host_tests.py --dependencies .local/ci-dependencies` | 64/64 Lua files PASS |
| `python -m unittest discover -s tests -p "test_*.py"` | 25/25 Python tests PASS |
| `python scripts/dependency_contracts.py --dependencies .local/ci-dependencies` | Direct/transitive source contracts PASS |
| `python scripts/audit_project.py --dependencies .local/ci-dependencies --output .local/source-audit.json` | Source PASS; 56 Lua syntax files, family require/case, localization and historical mirror PASS; final index scan recorded on PR |
| `python scripts/prepare_ci_dependencies.py --check` | PASS; fixtures preserved |
| `python scripts/check_versions.py --release` | Expected FAIL: retained historical Contents/current source differ; no package |
| `git diff --cached --check` | Required before commit; no whitespace errors |

The overview is refreshed against canonical version/source digest using the installed mod_overview.py helper, separating Foundation, Planned and Blocked. The source/index heuristic scan must pass before public push; it is not exhaustive secret detection. GitHub CI evidence is recorded on the exact pushed PR SHA, never inferred from a workflow definition.

## Remaining gates

[RUNTIME GATE] Native Lua invocation/binding of admission, server enforcement at commit, concurrent transfers/feeding/removal, current capacity/ownership/reach validation, callback rebinding, real save migration, world construction and stock conservation, native visual updates, SP, streaming, late join/rejoin and dedicated restart remain NOT TESTED. Exact engine SemVer UNKNOWN; source inspection is tied to Steam build 25485521. No new-container items/schemas/assets are fabricated to hide these gaps.

G7 BLOCKED / NOT TESTED. Stable G8 BLOCKED. No production package, deployment, Workshop upload, game/server launch, stable tag, main merge, external repository modification, paid generation or artifact deletion. Canonical version mirrors and current documentation change; historical packages, source layouts, schemas and evidence remain preserved.
