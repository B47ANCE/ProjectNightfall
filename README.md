# Project Nightfall

Project Nightfall is a UV-driven infected overhaul for Project Zomboid Build 42.

- Version: `0.31.0-dev.4`
- Mod ID: `ProjectNightfall`
- Author: B47ANCE
- Minimum game version: `42.20.3`
- Required Mod IDs: `B47ANCEDSPXTRM`, `ProjectMORTIS`, `B47ANCEDPower`, `B47ANCEDHealthCare`, `B47ANCEDKnowledgeAndWisdom`

## Ownership

Nightfall defines and controls Transforming, Feral, and Smart Feral zombies. It registers those types through the public Project M.O.R.T.I.S. API. Project M.O.R.T.I.S. supplies reusable zombie systems but no zombie types. lightWorks supplies serviceable lights and artificial-UV emissions but no zombie reactions.

## Implemented gameplay

- Natural UV damage to a 50% health floor, true fake-dead sunlight hibernation, and staggered nighttime rise with rapid recovery.
- Relevance-driven, server-authoritative lifecycle scheduling with bounded initial discovery, nighttime rise, and artificial-UV work budgets.
- Compact `PNPerformanceStatus()` stress diagnostics combining Nightfall lifecycle/group pressure with M.O.R.T.I.S. scheduler totals.
- `PNReleaseTest(true)` sequences the required lightWorks visual tour and Nightfall guided checklist without optional Works modules.
- Indoor zombies receive at most one outdoor roaming request per night; vanilla remains responsible for ordinary nighttime activity.
- Smart Ferals share fixed effigy-hunt origins, expiry, rage, and builder identity
  with members of their established intelligent horde.
- Packaged `Project: Nightfall â€” No Ferals` preset: UV damage and optional sun knockdown remain, but hibernators rise as regular zombies.
- Standard and high-output lightWorks UV bulbs with violet visible light.
- Regular-zombie UV slowing and shelter seeking.
- Feral solar reserve, rare tactical sprinting, and daytime shelter behavior.
- Feral creation requires seven continuous days of starvation after hunger stores are fully depleted; feeding resets the timer.
- Hunger contributes to starting and sustaining chase decisions through the Project M.O.R.T.I.S. hunger-drive API.
- Health Care detached-part provenance is classified at sever time; three selected same-source parts can be assembled through a validated timed action, while ambiguous mixtures are rejected before consumption.
- Smart Feral promotion, stalking, flanking, hiding, ambushing, evasion, and grudge targeting.
- Smart Feral-led personal hordes with local recruitment, deterministic intelligent-horde merging, population-scaled follower caps, and spaced formation movement.
- Real-coordinate Smart Feral call-and-response screeches and expiring shared investigation intent, with a bounded and overload-safe delayed-response queue.
- Persistent Alpha hierarchy, rivalry, desertion, Death Cry power vacuums, underground territories, distributed Smart dens, prey reports, and light defense.
- Pressure- and season-gated Alpha migration toward physically discovered destinations, with a hard winter lock, rivalry priority, physical loaded movement, and persisted temporary daylight shelters.
- Artificial-UV Alpha-den compromise causes persistent emergency local displacement to the literal closest safe loaded shelter without abandoning the territory or hierarchy.
- Bounded tree-canopy attenuation of natural UV.
- Bald, clean-shaven Feral and Smart Feral appearances.
- M.O.R.T.I.S.-powered deeper-interior crowd flow for shelter entry.
- Packaged `Project Nightfall` sandbox settings page.
- Selectable `Project: Nightfall` and `Project: Nightfall â€” No Ferals` presets based on Apocalypse.
- Rare classified Project files registered through B47ANCED Knowledge & Wisdom, with genuine redactions, prerequisites, persistent knowledge unlocks, and restricted scientific/military loot pools.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Testing](docs/TESTING.md)
- [Roadmap](docs/ROADMAP.md)
- [Vanilla horde/pathing audit](docs/VANILLA_HORDE_INTEGRATION.md)

The authoritative mod source is `src/ProjectNightfall/42/`. `Contents/mods/ProjectNightfall` retains the historical 0.27.4 generated mirror, including parent support files. Edit source; rebuild only when packaging is explicitly requested. Root `VERSION` is canonical; see [version policy](docs/VERSION_POLICY.md) and [source inventory](SOURCE_INVENTORY.json).

Public development repository: [B47ANCE/ProjectNightfall](https://github.com/B47ANCE/ProjectNightfall).

The remains-condition UI introduced in 0.29.0 adds a read-only remains-condition row and tooltip when vanilla selects a Nightfall-marked corpse with a valid synchronized remains stage. The UI handles controller probing and pooled menus without scanning the world or changing corpse state. Health Care's current Mod ID is B47ANCEDHealthCare; its verified Lua/item namespace remains medWorks.

Development PATCH 0.29.1 completes source audit/CI tooling and validates pinned public dependency commits. All 63 Lua tests and 25 Python tests pass offline. Direct and transitive dependency source contracts pass. Native UI, corpse synchronization, SP and dedicated MP remain NOT TESTED. Existing 0.27.4 Contents/packages are historical; no current package, deployment or upload was requested. See [current audit and validation](docs/VALIDATION_0.29.1.md) and [roadmap](docs/MASTER_ROADMAP.md).

See [offline CI and exact commands](docs/CI.md), [localization support policy](docs/LOCALIZATION_POLICY.md), and the [runtime acceptance handoff](docs/RUNTIME_ACCEPTANCE_0.29.1.md). Source audit success does not grant release consistency or runtime approval.

The integrated 0.29.1 candidate also includes the effigy transaction fix originally developed as 0.29.1-dev.1: exclusive reservations, reversible tissue/claim snapshots, verified source revisions and world removal only after successful ZombieFed. Consumed tombstones cannot feed twice or be re-registered. Reaction rules and nutrition values are unchanged; native persistence/replication remain untested. See [effigy contract](docs/EFFIGIES.md).

Retained 0.30.0 dependency transition: B47ANCED SPXTRM (B47ANCEDSPXTRM) replaces the lightWorks activation Mod ID. Existing Lua/save contracts and infected consequences remain unchanged. The prior audit/CI and effigy changes are retained from main. See [current validation](docs/VALIDATION_0.30.0.md). Actual loader/SP/dedicated NOT TESTED; no package/deploy/upload.

Agreed effigy design: a reusable restricted container with separate ordinary-meat and provenance-based body-part categories, and empty/meat-loaded/body-part-loaded visuals. Its implementation is staged; see [the agreed container plan](docs/EFFIGY_CONTAINER_PLAN.md).

Historical development MINOR prerelease 0.31.0-dev.1 started the effigy container foundation. The read-only policy classifies ordinary Meat food and validated human/regular/Feral/Smart-Feral parts, rejects mixing and nested bags, validates whole batches, and derives EMPTY/MEAT_LOADED/BODY_PART_LOADED. It does not move items or enable a world container. The [native admission audit](docs/EFFIGY_CONTAINER_API_AUDIT.md) identifies a queued-transfer authority gap; live admission/feeding and rendering remain blocked. The supplied spiked-post concept is preserved under art/references. See [foundation validation](docs/VALIDATION_0.31.0-dev.1.md).

Development PATCH 0.30.1-dev.1 fixes the four audited MORTIS integration findings:
verified own-owner cleanup before phase commit, retryable UV release before
hibernation, checked assignment compensation with a retained recovery journal,
and separate capability-readiness diagnostics. See [recovery contracts and human
cases](docs/MORTIS_RECOVERY.md) and [recovery validation](docs/VALIDATION_0.30.1-dev.1.md).
The reviewed [feature overview](docs/MOD_OVERVIEW.json) describes source capability
and blocked work. All runtime tests remain human-operated; Knowledge MP storage
is intentionally blocked. G7/stable G8 remain BLOCKED. No package/deploy/upload.

Historical 0.31.0-dev.2 implemented a Lua-only server-owned loader for a separate, real EffigyFrame container prototype. Native insertion remains permanently closed; the server validates and synchronously moves actual items, preventing competing first-load and mixed-batch admission. A localized world menu labels source categories; sandbox capacity is server authoritative (1-40, default 20). Normal native unloading remains available. The prototype has no recipe/loot placement, feeding integration or production model yet; existing effigies remain intact. See [implementation and human gates](docs/EFFIGY_CONTAINER_IMPLEMENTATION.md) and [current offline evidence](docs/VALIDATION_0.31.0-dev.2.md). G7/stable G8 remain BLOCKED.

Historical 0.31.0-dev.3 adds reusable feeding to the real EffigyFrame prototype through server MORTIS reserve/commit/rollback transactions. Meals consume actual meat items or a part's edible canonical tissue, preserve the frame and depleted part items, and keep every source category separate until physical emptiness. Ordinary meat has no part-specific reactions/search/grudge. Source identity, item/material preimages and revisions are revalidated; loading shares the feeding lease. Pending/uncertain state blocks automatic replay, and native packets/save requests publish committed changes. Existing calorie/hunger settings are reused. The prototype remains undistributed, with construction, non-feeding reactions/attribution, migration and three models still pending. See [feeding contract](docs/EFFIGY_CONTAINER_FEEDING.md) and [current validation](docs/VALIDATION_0.31.0-dev.3.md). Native/SP/dedicated NOT TESTED; G7/stable G8 BLOCKED.

Current 0.31.0-dev.4 adds [frame crafting and placement](docs/EFFIGY_FRAME_CONSTRUCTION.md). Right-click loose logs/rope/nails to assemble an empty frame (defaults: 4 logs, 2 ropes, 8 nails in main inventory); right-click an adjacent clear tile to place an owned frame. Server sandbox costs and the existing NF-FIELD-026 research requirement are checked again on the server. The actual frame and stored items move together; native insertion remains closed. Assembly is a synchronous context action, not a new crafting-panel recipe or timed recipe. Recovery guards are server owned. Knowledge 0.16.0 dedicated storage remains blocked, so research-required construction/placement also fails closed there. Placeholder appearance remains; non-feeding influence/attribution, migration and three production assets are pending. [Current validation](docs/VALIDATION_0.31.0-dev.4.md) is offline only; native/SP/dedicated NOT TESTED, G7/stable G8 BLOCKED.
