# ProjectNightfall 0.31.0-dev.8 Workshop MP testing preparation

The user authorized merging Knowledge, MORTIS and Nightfall in dependency order
and publishing matching existing Workshop items on 2026-10-18 America/Phoenix.
Source PRs are merged: Knowledge #2, MORTIS #17, Nightfall #9 then #10.
Merged runtime commit: `b114aaa0b2139c816bcca06af970c31f82ba549e`. This publication follow-up preserves
those runtime bytes and existing schemas, authority, research and category rules.
The version stays 0.31.0-dev.8: metadata/tooling preparation for the still-unpackaged
iteration, not a gameplay change or stable-release approval.

MP testing build - dedicated multiplayer NOT TESTED. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.
Build 42 minimum declaration 42.20.3; local evidence Steam build 25485521.
Exact executed native version remains UNKNOWN / NOT TESTED. The known normal
launcher has unrelated non-Lua alterations; it is not an acceptance baseline.

## Matching source selection

[Build-set inventory](MP_TEST_BUILD_SET.json) pins the exact three merged runtime
inputs, versions and existing Workshop identities. Metadata follow-ups do not
turn prior evidence into current runtime proof. Knowledge private documents are
for fresh disposable dedicated worlds/server-created lives only. Existing-world
migration, progression, claims, journal recovery, XP and history remain guarded.
Three effigy models/rendering and other documented Nightfall gates remain open.
All server/client copies must match; other existing Nightfall dependency IDs stay
unchanged. No local deployment, server changes, native launch or stable tag.

## Packaging and upload boundary

Use only authoritative src/ source and supplied art. Preserve all earlier
Contents, packages, backups and receipts; no cleanup. Each candidate is verified
for exact inventory/bytes, SHA-256, CRC, safe paths/types/case and Lua-only payload.
Description and current changenote contain the required MP-test label and known
limits, real paragraphs and public source link. Use fixed existing item
3788593239 / App 108600; omit visibility changes and never create an item.
Each pre-upload receipt binds actual release SHA, package/source/text/preview
hashes, exact validation evidence and attempt outcome. Existing cached SteamCMD
authentication only; no credential in source/log reports. Actual SteamCMD success
and public-page verification are distinct; subscription/native acceptance remain
human / NOT TESTED. Steam desktop restart needs a new explicit confirmation
after upload success; upload scripts have no restart stage.

Offline validation and exact-head CI results will be recorded in the publication
PR and receipt. This preparation document itself does not claim upload success.

## Current offline evidence

[TESTED: Windows / Python 3.12.14 / Lupa 2.6 Lua 5.1] 73 Lua host files, 27 Python tests, current version mirrors and dependency contracts PASS against the unchanged five public fixture pins. MORTIS a8a50e4 and Knowledge eebfa37 runtime bytes are identical to their merged counterparts and the matching publication inputs. Native boundaries are simulated; source tests do not prove installed loader/MP behavior.

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
git -c core.autocrlf=false diff --cached --check
```

Packaging verification and actual upload success are recorded only after execution. Exact-head CI results and final SHA are recorded in the publication PR. All G7/stable G8 native gates remain blocked.

[TESTED: offline] Final source/release audit has no source or release-consistency
failures. All 519 indexed files pass the credential/path heuristic. Mirror bytes
retain source CRLF where present; final whitespace verification uses
`git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --cached --check`
to permit that representation while retaining ordinary whitespace checks.

[TESTED: offline] Existing builder produced 165 source/mod files and 167 ZIP members with exact source/Contents/package parity and validated provenance. Package SHA-256: `f96244e3b25d3223406d53ec1fe5abc3240551ffb8872084f994e894e9d8857d`. Captured clean source commit: `f3f997678baf95e194122faeabd89ed87cf04be7`. Previous dev.6 mirror is retained at `dist/staging-backups/contents-c883d9be73d4` with tree SHA-256 `c883d9be73d48e30e1c857f936325701d0c2fd7fa6bc2b5d77dc6e06e7b721d7`. Portable manifest: [packaging/0.31.0-dev.8.manifest.json](packaging/0.31.0-dev.8.manifest.json). No upload success claimed here.

## Verified upload — 2026-10-18 America/Phoenix

SteamCMD exited 0 and reported `Committing update...Success.` for existing item **3788593239**, after all required offline and exact-head CI checks passed. Release commit: `07b03dd4d59158a2fd1b922e52e62ee49e3785ca`. Package SHA-256: `f96244e3b25d3223406d53ec1fe5abc3240551ffb8872084f994e894e9d8857d`; 167 exact staged files. Public API description, identity/title and public visibility match.

[Portable upload receipt](publications/0.31.0-dev.8-workshop-3788593239.json) binds the exact release/source commit, all package file hashes, publication text/VDF hashes, validation and actual result. No title, visibility or tags were submitted. Knowledge, MORTIS and Nightfall uploads completed in that order. No deployment, server changes, native launch or Steam desktop restart. Steam restart confirmation was requested separately and remains pending at receipt time. Subscriber download, dedicated startup/two-client synchronization, persistence/restart and native Insane-population timing remain HUMAN / NOT TESTED; G7/stable G8 BLOCKED.
