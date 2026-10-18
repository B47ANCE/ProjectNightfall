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
