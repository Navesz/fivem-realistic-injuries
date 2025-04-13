Config = {}

-- Configurações Gerais
Config.Locale = 'pt-br'
Config.DebugMode = false
Config.UseStamina = true
Config.UseScreenEffects = true
Config.UseSoundEffects = true

-- Configurações de Ferimentos
Config.InjurySystem = {
    EnableSystem = true,
    DisableControlsWhenInjured = true,
    DisableWeaponsWhenArmInjured = true,
    EnableLimping = true,
    EnableFalling = true,
    HealOverTime = true,
    HealTimePerLevel = 300000, -- 5 minutos por nível de ferimento
    MaxInjuryLevel = 3, -- Níveis de ferimento (1-3)
    
    -- Chance de ferimento por tipo de dano
    InjuryChance = {
        Gunshot = 80,  -- 80% de chance
        Melee = 40,    -- 40% de chance
        Vehicle = 60,  -- 60% de chance
        Fall = 35,     -- 35% de chance
        Explosion = 90 -- 90% de chance
    },
    
    -- Chance de afetar uma parte específica do corpo
    BodyPartChance = {
        Head = 10,      -- 10% chance
        Torso = 30,     -- 30% chance
        LeftArm = 15,   -- 15% chance
        RightArm = 15,  -- 15% chance
        LeftLeg = 15,   -- 15% chance
        RightLeg = 15,  -- 15% chance
    }
}

-- Mapeamento dos ossos do GTA V
Config.Bones = {
    Head = {
        11816, -- SKEL_Head
        31086  -- IK_Head
    },
    Torso = {
        24818, -- SKEL_Spine2
        24817, -- SKEL_Spine1
        24816, -- SKEL_Spine0
        57597  -- SKEL_Spine3
    },
    LeftArm = {
        18905, -- SKEL_L_UpperArm
        61163, -- SKEL_L_Forearm
        18905, -- SKEL_L_Hand
        26610  -- L hand
    },
    RightArm = {
        57005, -- SKEL_R_UpperArm
        58866, -- SKEL_R_Forearm
        57005, -- SKEL_R_Hand
        4089   -- R hand
    },
    LeftLeg = {
        58271, -- SKEL_L_Thigh
        63931, -- SKEL_L_Calf
        14201, -- SKEL_L_Foot
        2108   -- L Foot
    },
    RightLeg = {
        51826, -- SKEL_R_Thigh
        36864, -- SKEL_R_Calf
        52301, -- SKEL_R_Foot
        20781  -- R Foot
    }
}

-- Efeitos dos ferimentos
Config.InjuryEffects = {
    Head = {
        Level1 = {
            ScreenEffect = "damage",
            MovementEffect = false, 
            BlurEffect = true,
            TimedEffect = true,
            EffectDuration = 10000
        },
        Level2 = {
            ScreenEffect = "damage_heavy",
            MovementEffect = "dizzy", 
            BlurEffect = true,
            TimedEffect = true,
            EffectDuration = 30000
        },
        Level3 = {
            ScreenEffect = "damage_critical",
            MovementEffect = "unconscious", 
            BlurEffect = true,
            TimedEffect = true,
            EffectDuration = 60000
        }
    },
    Torso = {
        Level1 = {
            ScreenEffect = "pain_minor",
            MovementEffect = false, 
            StaminaReduction = 0.1
        },
        Level2 = {
            ScreenEffect = "pain_medium",
            MovementEffect = "pained", 
            StaminaReduction = 0.3
        },
        Level3 = {
            ScreenEffect = "pain_critical",
            MovementEffect = "heavily_injured", 
            StaminaReduction = 0.6
        }
    },
    LeftArm = {
        Level1 = {
            DisableWeapon = false,
            MovementEffect = "minor_arm_pain",
            AccuracyReduction = 0.2
        },
        Level2 = {
            DisableWeapon = false,
            MovementEffect = "moderate_arm_pain",
            AccuracyReduction = 0.5
        },
        Level3 = {
            DisableWeapon = true,
            MovementEffect = "disabled_arm",
            AccuracyReduction = 1.0
        }
    },
    RightArm = {
        Level1 = {
            DisableWeapon = false,
            MovementEffect = "minor_arm_pain",
            AccuracyReduction = 0.2
        },
        Level2 = {
            DisableWeapon = false,
            MovementEffect = "moderate_arm_pain",
            AccuracyReduction = 0.5
        },
        Level3 = {
            DisableWeapon = true,
            MovementEffect = "disabled_arm",
            AccuracyReduction = 1.0
        }
    },
    LeftLeg = {
        Level1 = {
            MovementEffect = "slight_limp",
            SpeedReduction = 0.1
        },
        Level2 = {
            MovementEffect = "moderate_limp",
            SpeedReduction = 0.3
        },
        Level3 = {
            MovementEffect = "severe_limp",
            SpeedReduction = 0.7
        }
    },
    RightLeg = {
        Level1 = {
            MovementEffect = "slight_limp",
            SpeedReduction = 0.1
        },
        Level2 = {
            MovementEffect = "moderate_limp",
            SpeedReduction = 0.3
        },
        Level3 = {
            MovementEffect = "severe_limp",
            SpeedReduction = 0.7
        }
    }
}

-- Itens para tratamento
Config.MedicalItems = {
    Bandage = {
        HealAmount = 1,
        BodyParts = {"LeftArm", "RightArm", "LeftLeg", "RightLeg", "Torso"},
        UseTime = 5000,
        Animation = "bandage"
    },
    FirstAid = {
        HealAmount = 2,
        BodyParts = {"LeftArm", "RightArm", "LeftLeg", "RightLeg", "Torso"},
        UseTime = 10000,
        Animation = "firstaid"
    },
    MedKit = {
        HealAmount = 3,
        BodyParts = {"Head", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Torso"},
        UseTime = 15000,
        Animation = "medkit"
    },
    Splint = {
        HealAmount = 3,
        BodyParts = {"LeftArm", "RightArm", "LeftLeg", "RightLeg"},
        UseTime = 12000,
        Animation = "splint"
    },
    Painkillers = {
        HealAmount = 0,
        TemporaryRelief = true,
        ReliefDuration = 120000, -- 2 minutos
        BodyParts = {"Head", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Torso"},
        UseTime = 3000,
        Animation = "pills"
    }
}