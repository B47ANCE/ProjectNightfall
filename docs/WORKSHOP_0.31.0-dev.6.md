# Nightfall 0.31.0-dev.6 Workshop MP testing candidate

The user requested merge and publish. PR #7 is merged at 264f3c34dddf5da324b533e699cff14e4d1f2023.
PR #8 carries publication preparation. A dev.5 candidate was built before the final
Steam description-size check. Its 9,757-byte description exceeds the SDK's 8,000-byte
limit; it was never uploaded. Retain that immutable ZIP/provenance/mirror and publish
a new dev.6 candidate. This is a compatible metadata/packaging fix; gameplay, sandbox
defaults, research/authority, save/network schemas are unchanged apart from version markers. The latest
user-supplied branded thumbnail replaces the prior artwork for this candidate. No stable tag or approval.

The shorter canonical text removes redundant recruitment, upcoming-feature and
repeated construction/UV wording, preserving implemented features, credits, source
link, dependency identity and the known MP/research limitations. Both canonical and
serialized descriptions must be under 8,000 UTF-8 bytes; the builder now rejects
oversize descriptions before mutation. Regression coverage includes multibyte text
and no artifact/mirror changes after refusal. Source constraint:
https://partner.steamgames.com/doc/api/isteamremotestorage

Latest user-supplied branded artwork: exact 1254-square source poster, SHA-256
608d09e8919a997e8d950aab84280dbd1617652d50765c42d2f1b42b1d17c41e.
Approved deterministic Pillow LANCZOS 512-square preview: 259710 bytes,
SHA-256 7bd12db011fdaf3a0a5c583f88f0a4a0ae353cf060012cf3c25c9f12cd4e238d.
Both PNGs were structurally validated and visually inspected. The separate mod icon
is unchanged. Prior native preview/content-layout inspection is retained in
audits/0.31.0-dev.5.workshop.json and is not runtime proof. Old candidate hashes
remain historical; neither prior package nor provenance is overwritten.

MP testing build - dedicated multiplayer NOT TESTED. Default research-required frame
construction/placement fails closed on dedicated Knowledge 0.16.0 storage. Three
models/rendering, non-feeding frame reactions/attribution, migration and human
native/SP/dedicated transfer/feed/persistence/rejoin/restart acceptance remain
pending. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. Upload is distribution only.

Validation commands from the release checkout:

```text
python scripts/check_versions.py
python scripts/run_host_tests.py --dependencies ../nightfall-effigy-container/.local/ci-dependencies
python -m unittest discover -s tests -p "test_*.py"
python scripts/dependency_contracts.py --dependencies ../nightfall-effigy-container/.local/ci-dependencies
python scripts/package_project.py plan
python scripts/package_project.py build
python scripts/package_project.py verify
python scripts/check_versions.py --release
python scripts/audit_project.py --release --dependencies ../nightfall-effigy-container/.local/ci-dependencies
git -c core.autocrlf=false diff --cached --check
```

Before upload, bind the final merged Git SHA, package/source/preview/description/
changenote hashes, Workshop 3788593239, App 108600, Mod ID ProjectNightfall,
installed Steam build 25485521 (exact SemVer UNKNOWN) and actual validation status.
Stage exactly the verified package inventory, pass Contents as contentfolder, and
keep preview/metadata outside it. Use only the existing verified SteamCMD executable
and cached identity; do not run the stale wrapper. Preserve public visibility.
No credentials, diagnostic data, scripts or archives enter runtime content. No
local deploy or game/server launch. Actual upload result and final provenance are
recorded in PR #8 and a local manifest; this preparation is not an upload success
claim. Request separate Steam desktop restart confirmation only after success.

[TESTED] Offline Windows / Python 3.12.14 / lupa.lua51: 71/71 Lua files and
27/27 Python tests PASS. Current source version mirrors PASS. These tests do not
prove native/SP/dedicated behavior. Package build/integrity, strict parity and
final exact-head CI results are recorded below after completion.
