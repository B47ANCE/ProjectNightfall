# Alpha Feral ecology

This document is the canonical design and implementation record for Alpha Ferals. It supersedes scattered development handoffs.

## Creation

- An Alpha can replace only a successful Smart Feral creation.
- The default replacement probability is `0.001` (0.1%).
- Disabling Smart Ferals also prevents Alpha creation.
- Alpha creation is authoritative and receives a persistent Project M.O.R.T.I.S. identity.
- Alphas are intended to be recognizable albinos without artificial boss-stat inflation. Final visual verification remains blocked on an Alpha visual asset or a verified safe runtime skin-tint path.

## Command structure

- An Alpha commands Smart Feral leaders through Project M.O.R.T.I.S. command relationships.
- Each Smart leader retains its own subordinate logical group. Ordinary Ferals do not understand the higher hierarchy.
- The Alpha Call is both audible and a bounded semantic signal. Only nearby loaded Smart Ferals may answer it.
- Responders rally physically; they are never teleported.
- Vanilla rally groups remain disabled.

## Rivalry and loyalty

- Nearby Alphas recognize one another and persist a mutual fight-to-the-death objective by stable identity.
- Tactical repositioning is allowed, but unloading the rival does not erase the objective.
- Smart Ferals may desert only under severe combat pressure. They cannot defect directly to a rival while their former Alpha remains alive or unresolved.
- During desertion, engaged lower-tier followers transfer to the original Alpha's exceptional direct pool, nearby unengaged followers remain with the deserter, and distant idle followers are released in place.
- Betrayal debt persists. A surviving Alpha can recognize and pursue a deserter during a later local encounter.
- Confirmed death of the former Alpha clears the debt and permits ordinary later recruitment.

## Death and succession

- Alpha death emits a Death Cry and creates a persistent power-vacuum record. It never creates a replacement Alpha.
- The dead Alpha's direct pool is disbanded without deleting its zombies.
- Succession is ecological: independent Smart Ferals and existing Alphas may investigate a nearby power vacuum through bounded local processing. Smart Ferals serving a living Alpha remain loyal, rivalry prevents an Alpha from treating a rival's death as an ordinary call, and no reaction creates a replacement Alpha or transfers allegiance automatically.

## Territory and dens

- An Alpha remains roaming until it commands at least three linked Smart Ferals and discovers a currently safe, loaded underground square through a bounded local search.
- A valid underground den establishes persistent claimed territory. Linked Smart Ferals then establish their own safe dens inside that territory; the first suitable loaded structure directly above the Alpha den is preferred as its guard den.
- Independent Smart Ferals can seek temporary shelter but cannot establish formal dens.
- Smart-den safety is revalidated from current natural-UV exposure. An unsafe Smart den is disbanded and its leader physically paths toward replacement shelter.
- Natural sunlight cannot invalidate an underground Alpha den. Sufficient actual artificial-UV exposure can compromise it and physically displace the Alpha to the literal closest loaded safe shelter, including a nearby above-ground room. This emergency shelter persists without abandoning the territory, hierarchy, or individually valid Smart dens.
- Smart den defense consumes lightWorks emission facts. It considers only relevant, powered, switched-on, actually emitting sources and uses subordinate physical attacks where the source exposes a verified destruction adapter. Active UV is prioritized; inactive fixtures remain unknowable and ignored.

## Migration policy

- Territorial pressure is persistent, evidence-labelled, capped, and configurable. Linked Smart Feral deaths, lost Smart dens, Alpha-den UV compromise, and successful weapon trauma against the hierarchy feed the same bounded API.
- Spring and summer use high-migration thresholds, fall requires substantially greater pressure, and winter categorically rejects normal migration.
- Rivalry overrides migration. A known destination supplied by actual simulation is required before migration begins.
- Beginning normal migration abandons the territorial role of the old Alpha and Smart dens but preserves the hierarchy. Loaded Alphas and linked Smart leaders receive ordinary physical path requests; subordinate groups remain associated with their Smart leader.
- No unloaded zombie is teleported. Migration remains persisted and pauses at the last physical state when engine-supported unloaded routing is unavailable.

## Prey reports and convergence

- A linked Smart Feral that actually sees prey shares the sighting with its own group and may complete a cooldown-limited Horde Call to its loaded Alpha.
- The call communicates only the observed last-known position. It assigns an expiring investigation objective to the Alpha and bounded loaded Smart Ferals already linked to that Alpha; it never follows the player after line of sight is lost.
- The Alpha and mobilized Smart Ferals path physically toward the report. Other Alphas, independent Smart Ferals, and lower-tier infected outside those subordinate groups receive no semantic command.
- Radius, response cap, cooldown, and last-known-position lifetime are sandbox configurable. Audible/world sound and semantic hierarchy communication remain separate channels.
- Completed reports also contribute bounded M.O.R.T.I.S. location evidence. Repeated observations in the same local area can promote a persistent probable survivor location; an otherwise idle Alpha may physically investigate the strongest non-expired record. Rivalry and deserter retribution always take priority.
- The evidence API accepts only observations supplied by a Smart Feral linked to a loaded living Alpha. It does not query safehouses, player factions, claimed buildings, or unseen map state.

## Ownership and limits

- Project M.O.R.T.I.S. owns stable identity, semantic signals, persistent command relationships, and reusable logical-group primitives.
- Project Nightfall owns Alpha creation, calls, rivalry, desertion, succession, and balance.
- All discovery must be spatially bounded and server authoritative. No omniscient map-wide scans are permitted.
- Zombie-on-zombie targeting is capability-gated and requires in-game validation on Build 42.20; it is not considered release-certified by host tests alone.

## Current validation

Host tests cover qualification, hierarchy, persistent ecology and den state, power-vacuum policy, den-defense selection, no-defection rules, and the combat-desertion follower split. In-game validation is still required for visible appearance, audible calls, zombie-on-zombie pursuit/combat, physical fixture destruction, den relocation, save/reload reconstruction, and dense-population performance.
