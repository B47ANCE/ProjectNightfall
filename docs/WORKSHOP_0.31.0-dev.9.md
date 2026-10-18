# Nightfall 0.31.0-dev.9 transparent mod-icon update

The user authorized installing the selected transparent figure as the mod icon,
then commit, merge and publication to existing Workshop 3788593239 / App 108600.
This is a compatible presentation-only prerelease after published dev.8. Current
version mirrors advance together; older artifacts/evidence remain historical.

The approved image_gen output is preserved exactly as authoring master and runtime
icon. No text, flashlight or filled background; real RGBA transparency. Thumbnail,
poster, dependency pins, research, recipes, categories and gameplay are unchanged.
[Structural/native-source evidence](ICON_0.31.0-dev.9.json) records original and
new hashes, alpha and installed Steam build 25485521's 28-pixel scaled icon draw.
Native game execution/display is NOT TESTED; exact executed game SemVer UNKNOWN.

MP testing build - dedicated multiplayer NOT TESTED. G7 BLOCKED / NOT TESTED;
stable G8 BLOCKED. Matching dependencies remain Knowledge 0.17.0 / MORTIS dev.9;
the earlier MP_TEST_BUILD_SET.json and dev.8 receipts are historical snapshots,
never rewritten as this icon iteration's evidence. Fresh-world research limits,
three models/rendering, non-feeding influence and other native gates remain.

Use the established source-based package builder, preserving the published dev.8
mirror under its hash-addressed backup before replacing current Contents. Verify
exact source/Contents/ZIP bytes, safe paths/types/case, CRC, SHA-256 and provenance.
Use fixed existing Workshop ID/visibility, current canonical BBCode and selected
dev.9 note with real paragraphs. Bind final merged release SHA and package/text/
preview/icon hashes before cached-account SteamCMD upload. Uploader must have no
Steam desktop restart stage; ask separately only after upload success. No local
deployment, game/server launch, new item, visibility change or stable tag.

Validation commands (offline CPython 3.12 / Lupa Lua 5.1):

```text
python scripts/check_versions.py
python scripts/run_host_tests.py --dependencies ../nightfall-hunger-population/.local/ci-dependencies
python -m unittest discover -s tests -p "test_*.py"
python scripts/dependency_contracts.py --dependencies ../nightfall-hunger-population/.local/ci-dependencies
python scripts/package_project.py plan
python scripts/package_project.py build
python scripts/package_project.py verify
python scripts/check_versions.py --release
python scripts/audit_project.py --release --dependencies ../nightfall-hunger-population/.local/ci-dependencies
git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --cached --check
```

Actual offline/CI/package results and upload receipt are recorded after execution;
this preparation itself makes no upload or native acceptance claim.

[TESTED: offline Windows / Python 3.12.14 / Lupa 2.6 Lua 5.1] All 73 Lua test files,
27 Python tests, current source version mirrors and direct/transitive dependency
contracts PASS against the unchanged five pinned inputs. PNG structure, RGBA
alpha, transparent corners and exact approved/master/runtime byte identity PASS.
Native mod-list display remains NOT TESTED. Production Lua diff is version-marker
updates only; no gameplay changes. The thumbnail/poster and fixture lock have no
diff. Public index and final package/CI results are recorded in the PR/receipt.

[TESTED: offline] Existing builder produced 165 source/mod files and 167 ZIP members with exact source/Contents/package parity and validated provenance. Package SHA-256: `be50c32a045719e0d95f7004c5e736ec8cb5c2648b3bf278e8320de4ae35b786`. Captured clean source commit: `0d6ae84c6153c0dd7ae62dcf3f0fb8ad5678e2dc`. Approved icon hash matches the ZIP member. Published dev.8 mirror retained at `dist/staging-backups/contents-20bd315453c6`, tree SHA-256 `20bd315453c62ce29bfaee8b9531c70e905b123b570296a3c07731c83e7491e5`. Portable manifest: [packaging/0.31.0-dev.9.manifest.json](packaging/0.31.0-dev.9.manifest.json). Actual upload not inferred from package success.

## Verified publication — 2026-10-18 America/Phoenix

SteamCMD exited 0 and confirmed `Committing update...Success.` for existing item 3788593239 after exact-head Windows/Linux CI passed. Release commit: `b47f10282953310251972fb5fd427f2e75b626df`; package SHA-256: `be50c32a045719e0d95f7004c5e736ec8cb5c2648b3bf278e8320de4ae35b786`. Approved icon SHA-256 `7d87b9db112e221a61f7db69adde94bea9cfb695ab5e64162bee0d8a8ea9f964` matches authoring master, production source, Contents, ZIP and actual upload staging. Public canonical description, existing title and public visibility match after upload; no visibility/title/tag change was submitted. Source poster and Workshop preview remain unchanged.

[Portable receipt](publications/0.31.0-dev.9-workshop-3788593239.json) records exact file hashes, release/source SHAs, text/VDF hashes, validation and actual result. Prior artifacts/receipts remain unchanged. The user declined the separate post-success Steam desktop restart; Steam was left unchanged. No local deployment or game/server launch. Native icon appearance, subscription/download and dedicated gameplay remain HUMAN / NOT TESTED; G7/stable G8 BLOCKED.
