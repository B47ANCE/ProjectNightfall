# Artificial UV tile-strength handoff

Status: blocked by request/source mismatch; no production-code change authorized.

## Requested narrow change

Replace artificial-UV bulb/count scaling with the sum of established attenuated
UV contributions reaching the zombie's current tile, and use that total only as
the multiplier on the existing damage calculation.

## End-to-end source trace

The authoritative source tree does not contain the described direct-health
damage path or a current `baseDamage` calculation:

1. `PN_ArtificialUV.lua` collects and deduplicates active player/world emitters.
   It applies no damage and owns no zombie queue.
2. `PN_ZombieUV.lua` obtains the current emitter snapshot for each zombie handled
   by the existing bounded lifecycle scheduler.
3. `PN_UVTissueScheduler.lua` calls `PN_UVTissuePipeline.sampleAndProcess` with
   the zombie and those emitters.
4. `lightWorks_UV.getVerifiedExposure` samples the zombie's current position.
   For every eligible emitter, `sourceContribution` preserves the established
   floor, range, cone and falloff rules; the obstruction pass then applies its
   established transmission.
5. `lightWorks_UV.getArtificialExposure` sums every accepted attenuated
   contribution into `uv.artificial`. There is no strongest-source, average,
   source-count multiplier or cap.
6. `PN_UVTissuePipeline.process` passes that exact `uv.artificial` value to
   `PN_UVTissueState.advance` as `incident.artificial`.
7. `PN_UVTissueState.advance` applies the current exposure at the narrow dose
   point: `incident.artificial * transmission * exposureFactor * elapsed`.
   Existing thresholds, wound promotion and optional tissue-loss behavior are
   downstream of that dose.

The effective current contract is therefore already:

```text
tileUVStrength = sum(attenuated, obstruction-checked emitter contributions)
artificialDose = existing regional dose factors * tileUVStrength
```

## Old logic located only in stale build backups

Historical `dist/staging-backups` copies contain the retired direct-damage path.
That path selected either `HighOutputArtificialUVDamagePerGameMinute` or
`StandardArtificialUVDamagePerGameMinute` from exposure classification. Those
settings and the corresponding damage function are absent from authoritative
`Contents/mods/ProjectNightfall`.

Generated staging backups are not an implementation target. Reintroducing their
formula into current source would violate the current regional-tissue contract,
the request not to rebuild `baseDamage`, and the explicit instruction to stop if
broader UV semantics would have to change.

## Existing regression coverage

- `lightWorks/tests/test_uv.lua` proves standard and high-output attenuated
  intensities stack in `uv.artificial`.
- `lightWorks/tests/test_uv_occluded_exposure.lua` proves obstruction-aware
  contributions sum, blocked sources contribute zero, window transmission is
  proportional, and verified darkness is a valid zero sample.
- `Project Nightfall/tests/test_uv_tissue_pipeline.lua` proves the sampler reads
  the target's current coordinates, blocked exposure contributes no artificial
  dose, clear exposure contributes the established attenuated strength, zero
  artificial exposure does not heal or backfill, and clothing, thresholds,
  tissue loss, smoke gates, authority and transaction behavior remain intact.

## Required decision before any code patch

Clarify whether the requested target is:

1. a historical direct-health branch/build that is not present in the current
   authoritative source; or
2. the current regional-tissue pipeline, in which case the requested strength
   behavior is already implemented and only additional explicit regression
   naming/coverage may be desired.

No cap ambiguity exists in the current sampler: artificial contributions are
summed without a cap. Introducing one would be a new balance decision.

## Verification performed

On 2026-09-02, `tools/Run-HostTests.ps1` completed with exit code 0:

```text
All 237 host Lua tests passed.
itjustWorks console session-boundary checks passed
```

This included `lightWorks/tests/test_uv.lua`,
`lightWorks/tests/test_uv_occluded_exposure.lua`, and
`Project Nightfall/tests/test_uv_tissue_pipeline.lua`. No new regression test
was added because there was no production behavior change and the requested
contract is already exercised by those tests. If the intended follow-up is only
to make each acceptance case explicit, add a narrowly named contract test
without changing the sampler or tissue pipeline.

## Systems explicitly left untouched

All production behavior remains untouched, including natural UV, scheduler
cadence and budgets, regional storage, clothing protection, thresholds, wound
and tissue loss, infection/type checks, geometry, obstruction, cone, range,
falloff, source eligibility, corpse/remains, smoke, persistence, recovery,
network markers, hooks, configuration, diagnostics and release packaging.
