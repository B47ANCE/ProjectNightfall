# Dedicated effigy research — 0.31.0-dev.7

[VERIFIED: source] Nightfall now selects Knowledge 0.17.0 development commit
`eebfa3797bc95aab963816ec659896f5f018d982`. It is the pushed head of
[Knowledge PR #2](https://github.com/B47ANCE/B47ANCEDKnowledgeAndWisdom/pull/2),
currently unmerged. This integration does not merge or change that repository.
Matching server/client installations are required; a test fixture pin does not
install, publish or distribute the dependency. Other dependency pins are unchanged.

## Cause and change

The previous pin was Knowledge 0.16.0 at `6ba66c0`. Its multiplayer character
ledger queries intentionally refused native player ModData because clients can
replace it, while GlobalModData is request-readable. Nightfall correctly denied
construction. Disabling research or trusting an old player ledger would bypass
the requirement rather than solve storage authority.

Knowledge 0.17.0 implements a separate, server-loaded private document ledger.
Its existing `hasKnowledge(character, "ProjectNightfall.EffigyConstruction")`
API resolves the authenticated server-listed life through that backend. Nightfall's
shared `PN_EffigyKnowledge` check remains unchanged: missing provider, exception or
anything other than literal `true` denies. Server assembly and custom placement
still recheck this API; client research only controls menu presentation.

Nightfall diagnostics previously equated the broader AuthorityGuard refusal with
all document knowledge. That is no longer correct: progression, claims, journal/
recovery and history still have independent guards. Diagnostics now identify the
pinned 0.17 document-backend installation surface **without calling it**. They
never install/initialize a backend, inspect a player, bind a life, query readiness,
read a journal or grant knowledge. Host Lua's package.loaded was not established
as a native Kahlua contract and is not used by production code. These reports are
structural API evidence, not runtime validation or per-character eligibility:

| Context | Report |
| --- | --- |
| Server API supports private document backend | PRIVATE_DOCUMENT_BACKEND_SUPPORTED / UNKNOWN readiness |
| Older server/client API lacks that surface | BLOCKED |
| Client API supports owner projection | CLIENT_PROJECTION_SUPPORTED / PRESENTATION_ONLY |
| SP with existing permitted guard | SP_SOURCE_PERMITTED |
| Unknown realm or incomplete guard | UNKNOWN |

Supported storage does not establish an initialized store, valid life binding or
earned research. The real server hasKnowledge query decides each gameplay action.
No diagnostic retries or background work are added.

## Persistence, existing saves and restrictions

The selected dependency supports **fresh disposable dedicated worlds and server-
created lives**. It owns its append-only private journal, world epoch, account/slot/
life binding, owner-targeted projection and write/read-back verification. Nightfall
does not duplicate this state. Client-replaceable ModData holds only the dependency's
opaque reference, never authoritative knowledge. Cross-account, missing, retired or
ambiguous references refuse access. Clients have no grant/read-complete RPC.

Read **NF-UV-003**, then **NF-FIELD-026** through the server-completed held-item
reading path. Cancellation, missing prerequisite or lost book ownership denies the
grant. Duplicate completion is idempotent. Optional claims remain independently
blocked; document qualification does not enable XP/recovery features.

Existing worlds with no private ledger return `PRIVATE_MIGRATION_REQUIRED`; there
is no automatic import, reset or permissive fallback. Failed or uncertain writes
latch the dependency closed, so previously known characters also cannot construct
or place until the underlying recovery is reviewed. Keep native and private saves
together. Read-back is not fsync or native/private cross-file atomicity. Safe
existing-world migration and crash/backup recovery remain dependency work.

No new sandbox option is appropriate: existing server `RequireEffigyKnowledge`
(default true) remains the gameplay setting. This change adds no bypass, recipe
cost, balance, save/network schema or container-category change. Frame models,
non-feeding reactions/attribution and legacy migration remain pending.

## Evidence and next native gate

[TESTED: offline Windows / Python 3.12.14 / Lupa 2.6 Lua 5.1] Real pinned Knowledge
modules run against in-memory native file/player/event/action boundaries. Tests
cover document prerequisites, owned/cancelled reads, private grants, real assembly/
placement, replay, forged old ledgers, cross-account references, restart/rejoin,
failed writes, missing migration and stale/foreign owner projections. The original
diagnostic test failed with BLOCKED after backend initialization before the fix.
This is not actual dedicated save/network/reading evidence.

Installed Steam build is 25485521. The dependency's portable native evidence at
the pinned commit records packaged Core 42.21, JAR SHA-256
`e1a69eb743ede60b213a0fe7f8b83d4fcab773036d256cc4543a336f3b058a33`
and unresolved effective class precedence. No new vanilla API is called by this
Nightfall change; the existing birth/reading/file bindings retain their native
invocation gates. No current dedicated failure log was supplied; this diagnosis is
source/host-test evidence, not a reproduced live-server incident.

With explicit separate launch/install authorization, humans must test a fresh
disposable dedicated world and two clients using the exact paired source builds:

1. Both players initially fail assembly/placement without consuming ingredients.
2. Player A reads NF-UV-003 then NF-FIELD-026; only A's menu and server permission
   change. Cancelled, unheld and out-of-order reads must not unlock anything.
3. A assembles and places the actual restricted frame; B remains denied. Replay
   intents and forged native ledger/reference/foreign projection inputs do not
   grant B permission or duplicate outputs. Container source restrictions persist.
4. Rejoin and graceful dedicated restart preserve A's life/research and leave B
   unqualified. Verify late projection and actual native lifecycle/slot behavior.
5. On disposable copies, test missing private migration, denied/truncated writes,
   uncertain binding, new character/death and coordinated crash/backup recovery.
   Preserve uncertain evidence; never repair real player saves automatically.

G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. Published 0.31.0-dev.6 and its dependency
selection are unchanged. No current package, deployment, upload or game/server
launch is authorized/performed by this iteration.
