ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.VERSION = "0.27.4"
ProjectNightfall.Config = ProjectNightfall.Config or {}

-- Project Nightfall 0.27.4
ProjectNightfall.Config.POC = {
    Enabled = true,
    Debug = true,
    Diagnostic = true,
    -- Bound detailed per-zombie output during dense-population stress tests.
    DetailLogSamplesPerUpdate = 0,
    VerboseShelterLogs = false,

    -- Solar UV Points
    FeralizationThreshold = 100.0,
    EnableFerals = true,
    RequireStarvationForFerals = true,
    FeralRequiredStarvationDays = 7.0,
    -- Actual nutritional value relative to baseline humanoid tissue. These
    -- profiles are committed into M.O.R.T.I.S. anatomy on type assignment.
    TransformingNutritionMultiplier = 0.50,
    FeralNutritionMultiplier = 0.25,
    SmartFeralNutritionMultiplier = 0.15,
    AlphaFeralNutritionMultiplier = 0.10,
    EnableSunKnockdown = true,
    NaturalUVHealthFloor = 0.50,
    NightRiseHealth = 1.0,
    -- Repository migration gate. These provisional values exist so the complete
    -- pipeline can be exercised, but remain disabled until the full-day dose
    -- meter establishes release balance and the old direct-HP path is removed.
    EnableRegionalUVTissue = true,
    RegionalUVTissueMaximumElapsedMinutes = 5.0,
    RegionalUVTissuePolicyRevision = 2,
    -- Fraction of canonical regional tissue capacity lost per received
    -- artificial-UV irradiance-game-minute. Provisional until live calibration.
    ArtificialUVTissueLossPerDose = 0.0005,
    RegionalUVHibernateMinimumNaturalDose = 50.0,
    RegionalUVHibernateMinimumAffectedRegions = 1,
    RegionalUVTissuePolicy = {
        default = {
            exposureFactor = 1.0,
            capacity = 100.0,
            naturalCapFraction = 0.64,
            thresholds = {0.10,0.20,0.35,0.50,0.65,0.80,0.95},
            woundMagnitudes = {8,20,45,80,160,360,700},
            artificialTissueLossPerDose = 0.0005,
        },
        regions = {},
        artificialDeath = true,
        traumaMovement = {enabled=true,slowBelow=0.45,noSprintBelow=0.75},
    },
    UVRegenerationExposureReference = 1.0,
    UVRegenerationHardBlockFraction = 0.60,
    UVRegenerationExposureBands = {
        {maximum=0.20,multiplier=1.00},
        {maximum=0.40,multiplier=0.70},
        {maximum=0.50,multiplier=0.40},
        {maximum=0.60,multiplier=0.15},
    },
    UVFeralUtilizationMin = 0.35,
    UVFeralUtilizationMax = 0.55,
    UVFeralHealingMin = 0.3,
    UVFeralHealingMax = 0.6,
    UVSmartFeralUtilizationMin = 0.55,
    UVSmartFeralUtilizationMax = 0.8,
    UVSmartFeralHealingMin = 0.65,
    UVSmartFeralHealingMax = 1.1,
    UVAlphaFeralUtilizationMin = 0.8,
    UVAlphaFeralUtilizationMax = 1,
    UVAlphaFeralHealingMin = 1.2,
    UVAlphaFeralHealingMax = 2,
    UVUtilizationRanges = {
        FERAL={minimum=0.35,maximum=0.55},
        SMART_FERAL={minimum=0.55,maximum=0.80},
        ALPHA_FERAL={minimum=0.80,maximum=1.00},
    },
    UVHealingWorkPerGameMinuteRanges = {
        FERAL={minimum=0.30,maximum=0.60},
        SMART_FERAL={minimum=0.65,maximum=1.10},
        ALPHA_FERAL={minimum=1.20,maximum=2.00},
    },
    UVSmartHealingTransferEfficiency = 0.85,
    UVSmartHealingTransferPerGameMinute = 2.0,
    UVAlphaTransferEfficiency = 0.95,
    UVAlphaTransferPerGameMinute = 4.0,
    UVAlphaProtectedTransmissionMaximum = 0.25,
    UVAlphaRedistributionMinimumGap = 0.20,
    RecoveryMaxDLS = 0.05,
    NegligibleMaxDLS = 0.10,
    LowMaxDLS = 0.25,
    ModerateMaxDLS = 0.50,
    HighMaxDLS = 0.70,
    VeryHighMaxDLS = 0.90,
    RecoveryPointsPerMinute = -0.25,
    -- Rise is based on PZ's astronomical night-strength signal, not daylight
    -- strength. Weather can sharply reduce DLS during rain/fog and must never
    -- masquerade as night.
    RiseAtOrAboveNightStrength = 0.60,
    RiseConfirmMinutes = 5.0,
    RiseSpreadMinutes = 10.0,

    -- Recurring Feral lifecycle.
    -- Regular Ferals return to daytime torpor; Smart Ferals remain active and
    -- deliberately seek strong natural sunlight.
    FeralDayDormancyMaxNightStrength = 0.10,
    FeralDayDormancyMinDLS = 0.05,

    -- Smart Feral classification. In vanilla ZombieLore, cognition tier 1 is
    -- the highest cognition/navigation tier; eligible Ferals promote once.
    EnableAutomaticSmartFeralPromotion = true,
    SmartFeralRawCognitionMax = 1,

    -- Rolled only after a successful Smart Feral promotion. 0.001 = 0.1% of
    -- Smart Ferals, never 0.1% of the general zombie population.
    EnableAlphaFerals = true,
    AlphaReplacementChance = 0.001,
    AlphaCallSound = "MetaScream",
    AlphaCallSemanticRadius = 100,
    AlphaCallWorldSoundRadius = 60,
    AlphaCallWorldSoundVolume = 60,
    AlphaCallSmartResponseLimit = 32,
    EnableAlphaHordeCalls = true,
    AlphaHordeCallCooldownTicks = 1800,
    AlphaHordeCallSemanticRadius = 120,
    AlphaHordeCallResponseLimit = 32,
    AlphaReportedPreyLifetimeHours = 0.5,
    AlphaHordeCallWorldSoundRadius = 45,
    AlphaHordeCallWorldSoundVolume = 45,
    EnableProbableBaseMemory = true,
    ProbableBaseMergeRadius = 8,
    ProbableBaseEvidenceThreshold = 3,
    ProbableBasePlayerSightingWeight = 1,
    ProbableBaseMaximumRecords = 32,
    ProbableBaseMaximumAgeDays = 30,
    AlphaRallyPathBudgetPerUpdate = 8,
    AlphaRallyRepathTicks = 120,
    SmartFeralDesertionFollowerRadius = 6,
    EnableSmartFeralDesertion = true,
    SmartFeralDesertionScoreThreshold = 0.78,
    SmartFeralDesertionMaximumChance = 0.20,
    SmartFeralDesertionRetributionDeterrent = 0.12,
    EnableAlphaTerritories = true,
    AlphaTerritoryMinimumSmartFerals = 3,
    AlphaTerritoryRadius = 60,
    AlphaDenSearchRadius = 24,
    AlphaDenSearchMinimumZ = -8,
    AlphaDenSearchBudgetPerUpdate = 2,
    DenValidationBudgetPerUpdate = 8,
    DenValidationIntervalTicks = 300,
    DenUnsafeNaturalUVThreshold = 0.01,
    AlphaDenArtificialUVUnsafeThreshold = 0.10,
    EnableAlphaMigration = true,
    AlphaMigrationPressureMaximum = 100,
    AlphaMigrationSpringPressureThreshold = 55,
    AlphaMigrationSummerPressureThreshold = 60,
    AlphaMigrationFallPressureThreshold = 90,
    AlphaMigrationSmartLossPressure = 20,
    AlphaMigrationSmartDenLossPressure = 5,
    AlphaMigrationDenUVPressure = 35,
    AlphaMigrationTraumaPressurePerDamage = 0.25,
    AlphaMigrationTraumaPressurePerHitMaximum = 5,
    EnableAlphaMigrationTemporaryShelters = true,
    AlphaMigrationSmartShelterBudgetPerUpdate = 4,
    EnableDenLightSuppression = true,
    DenLightDefenseRadius = 20,
    DenLightDefenseIntervalTicks = 300,
    DenLightDefenseSmartBudgetPerUpdate = 4,
    DenLightDefenseVisiblePriority = 1.0,
    DenLightDefenseUVPriority = 4.0,
    DenLightAttackReach = 1.5,
    EnableIndependentSuicidalUVAttacks = true,
    IndependentSuicidalUVAttackChance = 0.005,
    IndependentSuicidalUVDecisionCooldownTicks = 1800,
    AlphaDeathCrySound = "MetaScream",
    AlphaDeathCrySemanticRadius = 120,
    AlphaDeathCryWorldSoundRadius = 75,
    AlphaDeathCryWorldSoundVolume = 75,
    AlphaPowerVacuumRecordCap = 256,
    EnablePowerVacuumResponses = true,
    AlphaPowerVacuumResponseRadius = 120,
    AlphaPowerVacuumResponseLimit = 32,
    AlphaPowerVacuumLifetimeHours = 24,
    AlphaMutualRecognitionRadius = 20,
    AlphaRivalryBudgetPerUpdate = 4,

    -- Daytime Smart Feral solar-seeking.
    SmartFeralSunSearchRadius = 14,
    SmartFeralSunRepathTicks = 90,
    SmartFeralMinimumSunGain = 0.08,

    -- Smart Feral nighttime predator behavior.
    SmartFeralStalkAcquireRadius = 30,
    SmartFeralStalkGiveUpRadius = 55,
    SmartFeralStalkRepathTicks = 45,
    SmartFeralFlankDistanceMin = 5,
    SmartFeralFlankDistanceMax = 10,
    SmartFeralAmbushDistance = 5.0,
    SmartFeralHideSearchRadius = 20,
    -- Baseline horde requirement at 1.0x sandbox zombie population.
    SmartFeralHideMinHorde = 8,
    -- Low-population worlds still need a meaningful "horde".
    SmartFeralHideMinHordeFloor = 3,
    SmartFeralHideMinHours = 2.0,
    SmartFeralHideMaxHours = 8.0,
    SmartFeralHideDensityThreshold = 0.08,
    SmartFeralHideRepathTicks = 120,

    -- Smart Feral-owned logical hordes. Vanilla rally groups remain disabled.
    EnableSmartFeralHordes = true,
    SmartFeralBaseFollowerCap = 8,
    SmartFeralCapacityPerSmartBonus = 0.10,
    SmartFeralRecruitmentRadius = 10,
    SmartFeralMergeRadius = 12,
    SmartFeralFollowerDistance = 3,
    SmartFeralGroupUpdateTicks = 180,
    SmartFeralFollowerRepathTicks = 90,
    SmartFeralFollowerPathBudgetPerUpdate = 16,
    SmartFeralMaxCandidatesPerLeader = 64,
    SmartFeralLeaderBudgetPerUpdate = 16,
    EnableSmartFeralCommunication = true,
    SmartFeralScreechCooldownTicks = 1800,
    SmartFeralScreechResponseDelayTicks = 45,
    SmartFeralResponseBudgetPerTick = 8,
    SmartFeralMaxPendingResponses = 256,
    SmartFeralSharedIntentLifetimeTicks = 600,
    SmartFeralScreechSound = "MetaScream",

    -- Gear transformation behavior.
    -- Normal -> Feral damages each worn item's condition by a random fraction
    -- of that item's maximum condition. Held items are dropped intact.
    FeralWornGearDamageMin = 0.20,
    FeralWornGearDamageMax = 0.40,

    -- Runtime cadence
    UpdateEveryTicks = 20,
    ZombieListScanEveryTicks = 120,
    InitialDiscoveryBudgetPerTick = 32,
    RelevantZombieBudgetPerTick = 32,
    NightRiseBudgetPerTick = 8,
    ArtificialUVZombieBudgetPerUpdate = 32,
    ArtificialUVCorpseSquareBudgetPerUpdate = 16,
    ArtificialUVCorpseProcessBudgetPerUpdate = 8,
    ArtificialUVCorpseCandidateLimit = 256,
    ArtificialUVCorpseMaximumScanSquares = 4096,
    UVCorpseDestructionStageThresholds = {0.10,0.35,0.65,0.90},
    HeartbeatEveryTicks = 300,
    DetailLogEveryTicks = 300,
    MaxElapsedGameMinutesPerUpdate = 5.0,

    EnableNightIndoorExit = true,
    NightIndoorExitSearchRadius = 12,
    NightIndoorExitRetryTicks = 300,

    -- Local/non-omniscient shelter search
    ShelterSearchRadius = 12,
    ShelterRepathTicks = 90,

    -- Once a UV-exposed zombie reaches interior shelter, briefly suppress
    -- ordinary wandering so low-cognition Apocalypse zombies do not immediately
    -- bounce back outside. Higher cognition gets shorter holds because those
    -- zombies should continue evaluating progressively better/deeper shelter.
    ShelterHoldMinMinutes = 10.0,
    ShelterHoldMaxMinutes = 60.0,
    ShelterHoldBurdenThreshold = 0.10,
    ShelterHoldSmartMultiplier = 0.25,
    ShelterHoldMediumMultiplier = 0.55,
    ShelterHoldDumbMultiplier = 1.00,

    -- UV AI weight map. These are POC tuning constants, not final balance.
    DecisionHoldTicks = 90,
    WeightNoiseMax = 30.0,
    MinimumOverrideWeight = 35.0,

    -- Impairment: current UV severity and accumulated burden are distinct.
    CurrentExposureImpairmentShare = 0.40,
    AccumulatedBurdenImpairmentShare = 0.60,
    MaxCognitionImpairment = 0.70,
    MaxStrengthImpairment = 0.55,
    MaxMemoryImpairment = 0.75,

    -- Locomotion and solar-reserve economy.
    UVSlowMinimumExposure = 0.10,
    ArtificialUVSlowHoldTicks = 60,
    FeralReserveChargeScale = 1.0,
    FeralSprintMinimumReserve = 10.0,
    -- A full 100-point reserve has 90 usable points above the 10-point cutoff:
    -- 0.3 point/second gives exactly 300 in-game seconds (5 minutes) of sprinting.
    FeralSprintUVPerGameMinute = 18.0,
    RegularFeralSprintDecisionTicks = 300,
    RegularFeralSprintDurationTicks = 90,
    RegularFeralSprintCooldownTicks = 600,
    RegularFeralAmbushSprintChance = 0.12,
    RegularFeralAmbushRadius = 8.0,
    RegularFeralShelterRepathTicks = 90,
    ShelterCrowdFlowTicks = 240,
    ShelterCrowdFlowRepathTicks = 45,
    ShelterCrowdFlowArrivalDistance = 1.25,
    SmartFeralEvasionThreatRadius = 12.0,
    SmartFeralGrudgeAcquireAggro = 100,

    -- Target proximity -> Chase weight.
    ProximityMaxDistance = 20.0,

    -- Hunger contributes to Nightfall's chase weighting without replacing
    -- vanilla target acquisition. Starting responds above the low threshold;
    -- an established chase receives the larger high-hunger persistence bonus.
    HungerChaseStartThreshold = 0.25,
    HungerChaseKeepThreshold = 0.65,
    HungerChaseStartBonus = 20.0,
    HungerChaseKeepBonus = 35.0,

    -- medWorks-part effigy influence and Smart Feral investigation.
    RequireEffigyKnowledge = true,
    EffigyInfluenceRadius = 24.0,
    EffigyAvoidWeight = 130.0,
    EffigyDestroyWeight = 145.0,
    EffigyHumanEatHungerThreshold = 0.25,
    EffigyCaloriesPerFullFeed = 2000.0,
    EffigyRegularSearchHours = 1.0,
    EffigyFeralSearchHours = 24.0,
    EffigySmartFeralSearchHours = 72.0,
    EffigySearchRadius = 40.0,
    EffigyRepathTicks = 180,

    -- Observe-from-shelter / local interest propagation.
    ObservationSearchRadius = 8,
    ObservationRepathTicks = 90,
    ObserveBaseWeight = 42.0,
    ObserveVisibleTargetBonus = 26.0,
    ObserveTooFarBonus = 28.0,
    ObserveShelterSafetyBonus = 20.0,

    InterestSignalRadius = 10.0,
    InterestSignalLifetimeTicks = 360,
    InterestSignalCooldownTicks = 180,
    InterestBaseWeight = 18.0,
    InterestCognitionWeight = 38.0,
    InterestDistanceWeight = 24.0,

    -- Integration feature flags.
    EnableUVWeightAI = true,
    EnableObserveFromShelter = true,
    EnableInterestSignals = true,
    EnableCanopyAttenuation = true,
    EnableTargetBleedingModifier = true,

    -- Dynamic local canopy attenuation. The tree scan uses actual IsoTree
    -- objects near the zombie. This is intentionally local rather than zone-only.
    CanopyScanRadius = 4,
    CanopyTreeSizeWeight = 1.0,
    CanopyDistanceFalloff = 0.70,
    CanopyMaxAttenuation = 0.80, -- minimum local solar factor = 0.20
    CanopyScoreForMaxAttenuation = 28.0,

    -- Target bleeding chase modifier.
    -- Regular zombies are the 1x reference. Ferals use 2x.
    TargetBleedingRegularSensitivity = 1.0,
    TargetBleedingFeralSensitivity = 2.0,
    TargetBleedingLightBonus = 5.0,
    TargetBleedingModerateBonus = 12.5,
    TargetBleedingHeavyBonus = 25.0,
    TargetBleedingSevereBonus = 35.0,

    -- Delay between visible fall and play-dead state.
    TransformPlayDeadDelayTicks = 0,

    -- A disturbed hibernator may make one close-range surprise crawl. It gives
    -- up quickly and returns to true fake-dead hibernation.
    HibernationWakeDistanceMin = 2.0,
    HibernationWakeDistanceMax = 3.0,
    HibernationGiveUpDistanceMin = 5.0,
    HibernationGiveUpDistanceMax = 7.0,
    HibernationCloseWakeChance = 0.03,
    HibernationWakeCheckTicks = 300,

    -- Only the absolute lowest vanilla cognition tier may abandon play-dead
    -- and crawl toward visible prey while transforming. In the current
    -- ZombieLore mapping, raw cognition >= 3 is the "stupidest" tier.
    TransformCrawlerRawCognitionThreshold = 3,

    -- Canopy runtime diagnostics. Scans only around the local player,
    -- never per zombie, and logs only changes / newly-seen tree metadata.
    EnableCanopyRuntimeDiagnostic = true,
    CanopyDiagnosticRadius = 5,
    CanopyDiagnosticEveryTicks = 600,
    -- Smart Feral gear-survival classification.
    -- These are conservative type/name hints used in addition to item APIs/tags.
    SmartFeralSunResistantTypeHints = {
        "gun","rifle","pistol","revolver","shotgun","firearm",
        "belt","holster","sheath","scabbard",
        "leather","denim","welding","helmet","hardhat","armor","armour",
        "boots","shoes","gloves","goggles","glasses","watch",
        "metal","plastic","polymer","rubber"
    },
    SmartFeralFabricTypeHints = {
        "shirt","tshirt","t-shirt","sweater","jumper","hoodie","blouse",
        "skirt","dress","pants","trousers","shorts","underwear","socks",
        "scarf","bandana","balaclava","tie","apron","robe","pajama",
        "cotton","wool","linen","fabric","cloth"
    },

    -- Body-bound transformation visuals.
    -- These are visual identifiers, not inventory item types.  The future
    -- Feral asset pass should register texture/outfit visual IDs here rather
    -- than creating lootable clothing.
    LockedFeralVisuals = {
        Male = "PN_Feral_Male",
        Female = "PN_Feral_Female",
    },
    LockedSmartFeralVisuals = {
        Male = "PN_SmartFeral_Male",
        Female = "PN_SmartFeral_Female",
    },

}

-- SandboxVars are copied into this stable table so modules that cache POC keep
-- seeing updated values. Missing values retain the production defaults above.
local SANDBOX_KEYS = {
    "UVFeralUtilizationMin",
    "UVFeralUtilizationMax",
    "UVFeralHealingMin",
    "UVFeralHealingMax",
    "UVSmartFeralUtilizationMin",
    "UVSmartFeralUtilizationMax",
    "UVSmartFeralHealingMin",
    "UVSmartFeralHealingMax",
    "UVAlphaFeralUtilizationMin",
    "UVAlphaFeralUtilizationMax",
    "UVAlphaFeralHealingMin",
    "UVAlphaFeralHealingMax",
    "UVSmartHealingTransferEfficiency",
    "UVSmartHealingTransferPerGameMinute",
    "UVAlphaTransferEfficiency",
    "UVAlphaTransferPerGameMinute",
    "UVAlphaProtectedTransmissionMaximum",
    "UVAlphaRedistributionMinimumGap",
    "Enabled",
    "EnableFerals",
    "RequireStarvationForFerals",
    "EnableSunKnockdown",
    "EnableAutomaticSmartFeralPromotion",
    "EnableAlphaFerals",
    "AlphaReplacementChance",
    "AlphaMutualRecognitionRadius",
    "AlphaCallSemanticRadius",
    "AlphaCallSmartResponseLimit",
    "EnableAlphaHordeCalls",
    "AlphaHordeCallCooldownTicks",
    "AlphaHordeCallSemanticRadius",
    "AlphaHordeCallResponseLimit",
    "AlphaReportedPreyLifetimeHours",
    "EnableProbableBaseMemory",
    "ProbableBaseMergeRadius",
    "ProbableBaseEvidenceThreshold",
    "ProbableBasePlayerSightingWeight",
    "ProbableBaseMaximumRecords",
    "ProbableBaseMaximumAgeDays",
    "EnableSmartFeralDesertion",
    "SmartFeralDesertionScoreThreshold",
    "SmartFeralDesertionMaximumChance",
    "SmartFeralDesertionFollowerRadius",
    "EnableAlphaTerritories",
    "AlphaTerritoryMinimumSmartFerals",
    "AlphaTerritoryRadius",
    "AlphaDenSearchRadius",
    "DenValidationIntervalTicks",
    "DenUnsafeNaturalUVThreshold",
    "AlphaDenArtificialUVUnsafeThreshold",
    "EnableAlphaMigration",
    "AlphaMigrationPressureMaximum",
    "AlphaMigrationSpringPressureThreshold",
    "AlphaMigrationSummerPressureThreshold",
    "AlphaMigrationFallPressureThreshold",
    "AlphaMigrationSmartLossPressure",
    "AlphaMigrationSmartDenLossPressure",
    "AlphaMigrationDenUVPressure",
    "AlphaMigrationTraumaPressurePerDamage",
    "AlphaMigrationTraumaPressurePerHitMaximum",
    "EnableAlphaMigrationTemporaryShelters",
    "AlphaMigrationSmartShelterBudgetPerUpdate",
    "EnableDenLightSuppression",
    "DenLightDefenseRadius",
    "DenLightDefenseIntervalTicks",
    "DenLightDefenseVisiblePriority",
    "DenLightDefenseUVPriority",
    "EnableIndependentSuicidalUVAttacks",
    "IndependentSuicidalUVAttackChance",
    "IndependentSuicidalUVDecisionCooldownTicks",
    "EnableUVWeightAI",
    "EnableObserveFromShelter",
    "EnableInterestSignals",
    "EnableTargetBleedingModifier",
    "EnableCanopyAttenuation",
    "EnableSmartFeralHordes",
    "EnableSmartFeralCommunication",
    "EnableNightIndoorExit",
    "FeralizationThreshold",
    "FeralRequiredStarvationDays",
    "NaturalUVHealthFloor",
    "RiseConfirmMinutes",
    "RiseSpreadMinutes",
    "NightRiseHealth",
    "RiseAtOrAboveNightStrength",
    "RecoveryPointsPerMinute",
    "SmartFeralRawCognitionMax",
    "FeralReserveChargeScale",
    "FeralSprintMinimumReserve",
    "FeralSprintUVPerGameMinute",
    "RegularFeralAmbushSprintChance",
    "ShelterHoldMinMinutes",
    "ShelterHoldMaxMinutes",
    "SmartFeralHideMinHorde",
    "SmartFeralHideMinHours",
    "SmartFeralHideMaxHours",
    "SmartFeralStalkAcquireRadius",
    "SmartFeralStalkGiveUpRadius",
    "SmartFeralFlankDistanceMin",
    "SmartFeralFlankDistanceMax",
    "SmartFeralAmbushDistance",
    "SmartFeralHideSearchRadius",
    "SmartFeralHideMinHordeFloor",
    "SmartFeralHideDensityThreshold",
    "SmartFeralSunSearchRadius",
    "SmartFeralMinimumSunGain",
    "SmartFeralEvasionThreatRadius",
    "SmartFeralBaseFollowerCap",
    "SmartFeralCapacityPerSmartBonus",
    "SmartFeralRecruitmentRadius",
    "SmartFeralMergeRadius",
    "SmartFeralFollowerDistance",
    "SmartFeralGroupUpdateTicks",
    "SmartFeralFollowerRepathTicks",
    "SmartFeralFollowerPathBudgetPerUpdate",
    "SmartFeralMaxCandidatesPerLeader",
    "SmartFeralLeaderBudgetPerUpdate",
    "SmartFeralScreechCooldownTicks",
    "SmartFeralScreechResponseDelayTicks",
    "SmartFeralResponseBudgetPerTick",
    "SmartFeralMaxPendingResponses",
    "SmartFeralSharedIntentLifetimeTicks",
    "InitialDiscoveryBudgetPerTick",
    "RelevantZombieBudgetPerTick",
    "NightRiseBudgetPerTick",
    "ArtificialUVZombieBudgetPerUpdate",
    "ArtificialUVTissueLossPerDose",
    "ArtificialUVCorpseSquareBudgetPerUpdate",
    "ArtificialUVCorpseProcessBudgetPerUpdate",
    "ArtificialUVCorpseCandidateLimit",
    "ArtificialUVCorpseMaximumScanSquares",
    "NightIndoorExitSearchRadius",
    "NightIndoorExitRetryTicks",
    "FeralWornGearDamageMin",
    "FeralWornGearDamageMax",
    "ShelterSearchRadius",
    "ShelterHoldBurdenThreshold",
    "UVSlowMinimumExposure",
    "ProximityMaxDistance",
    "HungerChaseStartThreshold",
    "HungerChaseKeepThreshold",
    "HungerChaseStartBonus",
    "HungerChaseKeepBonus",
    "EffigyInfluenceRadius",
    "RequireEffigyKnowledge",
    "EffigyAvoidWeight",
    "EffigyDestroyWeight",
    "EffigyHumanEatHungerThreshold",
    "EffigyCaloriesPerFullFeed",
    "EffigyRegularSearchHours",
    "EffigyFeralSearchHours",
    "EffigySmartFeralSearchHours",
    "EffigySearchRadius",
    "EffigyRepathTicks",
    "ObservationSearchRadius",
    "InterestSignalRadius",
    "CanopyScanRadius",
    "CanopyMaxAttenuation",
    "CanopyScoreForMaxAttenuation",
    "TargetBleedingRegularSensitivity",
    "TargetBleedingFeralSensitivity",
    "HibernationCloseWakeChance",
    "HibernationWakeDistanceMin",
    "HibernationWakeDistanceMax",
    "HibernationGiveUpDistanceMin",
    "HibernationGiveUpDistanceMax",
}

local METABOLISM_BOUNDS = {
    UVFeralUtilizationMin = {0.01,1},
    UVFeralUtilizationMax = {0.01,1},
    UVFeralHealingMin = {0,20},
    UVFeralHealingMax = {0,20},
    UVSmartFeralUtilizationMin = {0.01,1},
    UVSmartFeralUtilizationMax = {0.01,1},
    UVSmartFeralHealingMin = {0,20},
    UVSmartFeralHealingMax = {0,20},
    UVAlphaFeralUtilizationMin = {0.01,1},
    UVAlphaFeralUtilizationMax = {0.01,1},
    UVAlphaFeralHealingMin = {0,20},
    UVAlphaFeralHealingMax = {0,20},
    UVSmartHealingTransferEfficiency = {0,1},
    UVSmartHealingTransferPerGameMinute = {0,100},
    UVAlphaTransferEfficiency = {0,1},
    UVAlphaTransferPerGameMinute = {0,100},
    UVAlphaProtectedTransmissionMaximum = {0,1},
    UVAlphaRedistributionMinimumGap = {0,1},
    ArtificialUVTissueLossPerDose = {0,0.01},
    EffigyCaloriesPerFullFeed = {100,10000},
}

local function ordered(config,minKey,maxKey)
    local minimum,maximum=tonumber(config[minKey]),tonumber(config[maxKey])
    if minimum and maximum and minimum>maximum then config[minKey],config[maxKey]=maximum,minimum end
end

function ProjectNightfall.Config.applySandbox()
    local root = rawget(_G, "SandboxVars")
    local values = root and root.ProjectNightfall or nil
    if not values then return false end
    local config = ProjectNightfall.Config.POC
    for _, key in ipairs(SANDBOX_KEYS) do
        if values[key] ~= nil then
            local bounds = METABOLISM_BOUNDS[key]
            if bounds then
                local value = tonumber(values[key])
                if value and value == value and value ~= math.huge and value ~= -math.huge then
                    config[key] = math.max(bounds[1],math.min(bounds[2],value))
                end
            else
                config[key] = values[key]
            end
        end
    end
    ordered(config,"ShelterHoldMinMinutes","ShelterHoldMaxMinutes")
    ordered(config,"UVFeralUtilizationMin","UVFeralUtilizationMax")
    config.UVUtilizationRanges.FERAL = {minimum=config.UVFeralUtilizationMin,maximum=config.UVFeralUtilizationMax}
    ordered(config,"UVFeralHealingMin","UVFeralHealingMax")
    config.UVHealingWorkPerGameMinuteRanges.FERAL = {minimum=config.UVFeralHealingMin,maximum=config.UVFeralHealingMax}
    ordered(config,"UVSmartFeralUtilizationMin","UVSmartFeralUtilizationMax")
    config.UVUtilizationRanges.SMART_FERAL = {minimum=config.UVSmartFeralUtilizationMin,maximum=config.UVSmartFeralUtilizationMax}
    ordered(config,"UVSmartFeralHealingMin","UVSmartFeralHealingMax")
    config.UVHealingWorkPerGameMinuteRanges.SMART_FERAL = {minimum=config.UVSmartFeralHealingMin,maximum=config.UVSmartFeralHealingMax}
    ordered(config,"UVAlphaFeralUtilizationMin","UVAlphaFeralUtilizationMax")
    config.UVUtilizationRanges.ALPHA_FERAL = {minimum=config.UVAlphaFeralUtilizationMin,maximum=config.UVAlphaFeralUtilizationMax}
    ordered(config,"UVAlphaFeralHealingMin","UVAlphaFeralHealingMax")
    config.UVHealingWorkPerGameMinuteRanges.ALPHA_FERAL = {minimum=config.UVAlphaFeralHealingMin,maximum=config.UVAlphaFeralHealingMax}
    config.RegionalUVTissuePolicy.default.artificialTissueLossPerDose=config.ArtificialUVTissueLossPerDose
    ordered(config,"SmartFeralHideMinHours","SmartFeralHideMaxHours")
    ordered(config,"SmartFeralFlankDistanceMin","SmartFeralFlankDistanceMax")
    ordered(config,"FeralWornGearDamageMin","FeralWornGearDamageMax")
    ordered(config,"HibernationWakeDistanceMin","HibernationWakeDistanceMax")
    ordered(config,"HibernationGiveUpDistanceMin","HibernationGiveUpDistanceMax")
    if values.EnableDiagnosticLogging ~= nil then
        config.Debug = values.EnableDiagnosticLogging
        config.Diagnostic = values.EnableDiagnosticLogging
    end
    if config.Enabled ~= false then
        root.ZombieConfig = root.ZombieConfig or {}
        root.ZombieConfig.RallyGroupSize = 0
        root.ZombieConfig.RallyGroupSizeVariance = 0
        root.ZombieLore = root.ZombieLore or {}
        -- This is the engine-safe base tier displayed as Project: Nightfall.
        root.ZombieLore.Speed = 3
        root.ZombieLore.SprinterPercentage = 0
        root.ZombieLore.ActiveOnly = 1
        root.ZombieLore.DisableFakeDead = 3
    end
    return true
end

ProjectNightfall.Config.applySandbox()
if Events and Events.OnGameStart then Events.OnGameStart.Add(ProjectNightfall.Config.applySandbox) end
if Events and Events.OnServerStarted then Events.OnServerStarted.Add(ProjectNightfall.Config.applySandbox) end
