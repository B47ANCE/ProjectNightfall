# Third-party research ledger

Research is a source of neutral requirements, not permission to copy a mod.
Runtime implementation, packaging, deployment, publication and native testing
require their own task scope and gates. Canonical Nightfall version remains
0.31.0-dev.9; this documentation-only review creates no mod version iteration.

## CR-2026-11-01-QuietDark

| Field | Evidence/status |
| --- | --- |
| Purpose | Identify independently implementable shelter/day-night ideas for Nightfall, without inspecting third-party implementation |
| Mod / author | It's Quiet, Too quiet. / Gouge, as credited by the indexed Workshop page |
| Public identifiers | Workshop 3827348913; advertised Mod ID QuietDark; consumer App 108600 |
| Source | [Workshop listing](https://steamcommunity.com/sharedfiles/filedetails/?id=3827348913) and Steam GetPublishedFileDetails API |
| Research date | 2026-11-01 America/Phoenix |
| Reported publication/update | Created 2026-10-25 22:07:22 UTC; updated 2026-10-25 23:32:24 UTC (15:07:22 / 16:32:24 America/Phoenix) |
| Exact mod version | UNKNOWN: no semantic version obtained from public metadata |
| Description snapshot | SHA-256 52da50548d4f52acfad0f92bc8cfa740356b8ffa842bca7e9a44f13af74ba6f5 over the API's UTF-8 description string, preserving its returned line endings |
| Access evidence | Anonymous API result 1, visibility 0, App 108600; direct page/changelog/discussion extraction failed in the web reader; indexed listing available |
| License / permission | UNKNOWN: no affirmative source/asset reuse license or owner permission obtained; public availability is not reuse permission |
| Material inspected | Public description, author/identifiers/timestamps, indexed comments; Nightfall's own source/docs/tests |
| Material not inspected | QuietDark implementation, algorithms, installed files, downloads, binaries, assets and runtime behavior |
| Code/assets/text imported | NONE. This ledger records identifiers, brief factual observations and independently authored requirements only |
| Reuse / attribution obligations | No third-party component is shipped, so no component-license obligations have been assumed. The research reference is retained; it is not a license grant or legal clearance |
| Nightfall baseline | 0.31.0-dev.9; main 2333cffc53108ffab5cdc16dc26fa1c24c1320cc |
| Result | Useful design prompt; much of the premise already exists in Nightfall. Prioritize bounded shelter-group observation, optional clustering of existing actors, then staged egress |
| Signoff | Research prepared; independent reviewer/project-owner design signoff PENDING. No implementation approved by this document |

[VERIFIED: public description] The advertised behavior is daytime indoor
concentration/rest followed by nighttime outdoor activity and groups, with reduced
vision and heightened hearing. The author recommends new saves.

[UNVERIFIED: indexed user reports] Some comments describe excessive indoor density
or ask about population controls; another reports trouble on a 42.22 dedicated
server with other mods. These are test questions, not reproduced findings. They
do not establish spawning, deletion, sandbox overrides or a defect's cause.

[UNKNOWN] Population mechanics, authority, scheduling, persistence, exact supported
builds, internal APIs and actual compatibility were not inspected. Generic Steam
moderation/incompatibility text in indexed extraction is not accepted as proof
of the item's live status; the API returned a public accessible item.

The [neutral review and proposed acceptance contract](research/QUIETDARK_REVIEW_2026-11-01.md)
contains original Nightfall decisions, separate from the observations above.
No QuietDark strings, assets, source, characteristic algorithms or architecture
may be transplanted or AI-rewritten into Nightfall under this review. Any future
proposal to import material requires verified rights, obligations and explicit
owner approval; independently designed mechanics do not require copying it.

Review checklist:

- [x] Purpose, authorship, identifiers, dates and evidence scope recorded.
- [x] Unknown version/license and access limitations explicitly retained.
- [x] Third-party implementation and assets not opened, downloaded or executed.
- [x] Observable claims and user reports separated from verified internals.
- [x] Neutral requirements use Nightfall's established ownership and services.
- [x] No gameplay, metadata version, package or deployment changed.
- [x] No native/SP/dedicated or compatibility PASS inferred.
- [ ] Independent reviewer/project-owner signs off the proposed requirements.
- [ ] A separately scoped implementation verifies any new native/API contract and configuration choices.

G7 remains BLOCKED / NOT TESTED; stable G8 remains BLOCKED. Source review or host
tests of Nightfall cannot close these gates or validate QuietDark.
