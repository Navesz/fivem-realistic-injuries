-- Sistema de efeitos visuais e sonoros para ferimentos
local activeEffects = {}
local isScreenEffectActive = false

-- Lista de efeitos disponíveis
local screenEffects = {
    damage = {
        timecycle = "damage",
        strength = 0.2,
        screenEffect = "DeathFailOut",
        duration = 5000
    },
    damage_heavy = {
        timecycle = "hud_def_desat_cold",
        strength = 0.4,
        screenEffect = "DeathFailOut",
        duration = 8000
    },
    damage_critical = {
        timecycle = "hud_def_desat_cold_kill",
        strength = 0.8,
        screenEffect = "DeathFailOut",
        duration = 10000
    },
    pain_minor = {
        timecycle = "hud_def_desat_cold",
        strength = 0.1,
        screenEffect = false,
        duration = 3000
    },
    pain_medium = {
        timecycle = "hud_def_desat_cold",
        strength = 0.3,
        screenEffect = false,
        duration = 5000
    },
    pain_critical = {
        timecycle = "hud_def_desat_cold",
        strength = 0.6,
        screenEffect = "DeathFailOut",
        duration = 7000
    },
    drunk = {
        timecycle = "drug_wobbly",
        strength = 0.3,
        screenEffect = false,
        duration = 5000
    },
    drugged = {
        timecycle = "drug_flying_02",
        strength = 0.5,
        screenEffect = false,
        duration = 5000
    },
    blood_loss = {
        timecycle = "hud_def_desat_cold_kill",
        strength = 0.3,
        screenEffect = false,
        duration = 5000
    }
}

-- Aplica efeito visual na tela
function ApplyScreenEffect(effectType, duration)
    local effect = screenEffects[effectType]
    if not effect then return end
    
    -- Define duração personalizada se fornecida
    local effectDuration = duration or effect.duration
    
    -- Aplica modificador de timecycle
    if effect.timecycle then
        SetTimecycleModifier(effect.timecycle)
        SetTimecycleModifierStrength(effect.strength)
    end
    
    -- Aplica efeito de tela se definido
    if effect.screenEffect then
        StartScreenEffect(effect.screenEffect, 0, true)
        isScreenEffectActive = true
    end
    
    -- Aplica blur da tela se configurado para usar
    if Config.UseScreenEffects then
        TriggerScreenblurFadeIn(1000)
    end
    
    -- Define timer para remover o efeito após a duração
    Citizen.SetTimeout(effectDuration, function()
        ResetScreenEffect(effectType)
    end)
    
    -- Registra efeito ativo
    activeEffects[effectType] = {
        startTime = GetGameTimer(),
        duration = effectDuration
    }
    
    return effectDuration
end

-- Remove efeito visual da tela
function ResetScreenEffect(effectType)
    local effect = screenEffects[effectType]
    if not effect then return end
    
    -- Só reseta se não houver outro efeito mais prioritário ativo
    if not HasHigherPriorityEffect(effectType) then
        if effect.screenEffect and isScreenEffectActive then
            StopScreenEffect(effect.screenEffect)
            isScreenEffectActive = false
        end
        
        ClearTimecycleModifier()
        
        if Config.UseScreenEffects then
            TriggerScreenblurFadeOut(1000)
        end
    end
    
    -- Remove do registro de efeitos ativos
    activeEffects[effectType] = nil
end

-- Verifica se há algum efeito mais prioritário ativo
function HasHigherPriorityEffect(currentEffect)
    local priorities = {
        damage_critical = 1,
        damage_heavy = 2,
        damage = 3,
        blood_loss = 4,
        pain_critical = 5,
        drugged = 6,
        pain_medium = 7,
        pain_minor = 8,
        drunk = 9
    }
    
    local currentPriority = priorities[currentEffect] or 99
    
    for effectType, _ in pairs(activeEffects) do
        if effectType ~= currentEffect and priorities[effectType] and priorities[effectType] < currentPriority then
            return true
        end
    end
    
    return false
end

-- Aplica efeito de tremor na câmera
function ApplyCameraShake(intensity, duration)
    local shakeName = "SMALL_EXPLOSION_SHAKE"
    
    if intensity > 0.7 then
        shakeName = "LARGE_EXPLOSION_SHAKE"
    elseif intensity > 0.3 then
        shakeName = "MEDIUM_EXPLOSION_SHAKE"
    end
    
    ShakeGameplayCam(shakeName, intensity)
    
    Citizen.SetTimeout(duration or 4000, function()
        StopGameplayCamShaking(true)
    end)
end

-- Aplica efeito visual baseado na parte do corpo e severidade
function ApplyInjuryVisualEffect(bodyPart, severity)
    if not Config.UseScreenEffects then return end
    
    local effectMapping = {
        Head = {
            [1] = "pain_minor",
            [2] = "damage",
            [3] = "damage_heavy"
        },
        Torso = {
            [1] = "pain_minor",
            [2] = "pain_medium",
            [3] = "damage"
        },
        LeftArm = {
            [1] = false,
            [2] = "pain_minor",
            [3] = "pain_medium"
        },
        RightArm = {
            [1] = false,
            [2] = "pain_minor",
            [3] = "pain_medium"
        },
        LeftLeg = {
            [1] = false,
            [2] = "pain_minor",
            [3] = "pain_medium"
        },
        RightLeg = {
            [1] = false,
            [2] = "pain_minor",
            [3] = "pain_medium"
        }
    }
    
    local effectType = effectMapping[bodyPart] and effectMapping[bodyPart][severity]
    if not effectType then return end
    
    -- Aplica o efeito visual
    local duration = ApplyScreenEffect(effectType)
    
    -- Aplica tremor de câmera baseado na severidade
    local shakeIntensity = severity * 0.15 -- 0.15, 0.3, 0.45 baseado na severidade
    ApplyCameraShake(shakeIntensity, duration * 0.75)
    
    return duration
end

-- Aplica efeito de sangramento na tela
function ApplyBleedingEffect(intensity)
    if not Config.UseScreenEffects then return end
    
    local effectDuration = 5000 + (intensity * 5000)
    local effectStrength = math.min(0.8, intensity * 0.3)
    
    SetTimecycleModifier("hud_def_desat_cold_kill")
    SetTimecycleModifierStrength(effectStrength)
    
    -- Define efeito pulsante para simular batimentos cardíacos
    Citizen.CreateThread(function()
        local startTime = GetGameTimer()
        local endTime = startTime + effectDuration
        
        while GetGameTimer() < endTime do
            local elapsedTime = GetGameTimer() - startTime
            local progress = elapsedTime / effectDuration
            
            -- Efeito pulsante (seno)
            local pulse = math.abs(math.sin(progress * 8)) * 0.3
            local currentStrength = effectStrength + pulse
            
            SetTimecycleModifierStrength(currentStrength)
            
            Citizen.Wait(50)
        end
        
        ClearTimecycleModifier()
    end)
    
    return effectDuration
end

-- Reproduz som de dor baseado na parte do corpo e severidade
function PlayBodyPartPainSound(bodyPart, severity)
    if not Config.UseSoundEffects then return end
    
    local ped = PlayerPedId()
    
    -- Determina o gênero do personagem para sons apropriados
    local gender = "male"
    if GetEntityModel(ped) == GetHashKey("mp_f_freemode_01") then
        gender = "female"
    end
    
    -- Sons para diferentes níveis de dor por gênero
    local painSounds = {
        male = {
            light = {"GROAN_LOW", "GROAN", "PAIN_LOW"},
            moderate = {"PAIN_MED", "INJURED_WASTED", "WHIMPER"},
            severe = {"PAIN_HIGH", "SCREAM_PANIC", "SCREAM_TERROR"}
        },
        female = {
            light = {"GROAN_LOW", "GROAN", "PAIN_LOW"},
            moderate = {"PAIN_MED", "INJURED_WASTED", "WHIMPER"},
            severe = {"PAIN_HIGH", "SCREAM_PANIC", "SCREAM_TERROR"}
        }
    }
    
    -- Mapeia severidade para intensidade de som
    local painIntensity = "light"
    if severity == 2 then
        painIntensity = "moderate"
    elseif severity == 3 then
        painIntensity = "severe"
    end
    
    -- Seleciona um som aleatório para o gênero e intensidade
    local sounds = painSounds[gender][painIntensity]
    local sound = sounds[math.random(#sounds)]
    
    -- Parâmetros de som baseados na severidade
    local speechParams = "SPEECH_PARAMS_FORCE"
    if severity >= 2 then
        speechParams = "SPEECH_PARAMS_FORCE_SHOUTED"
    end
    
    -- Reproduz o som
    PlayPedAmbientSpeechNative(ped, sound, speechParams)
end

-- Efeitos de ferimento específicos para partes do corpo
function ApplySpecificBodyPartEffect(bodyPart, severity)
    -- Aplica efeitos baseados na parte do corpo
    if bodyPart == "Head" then
        if severity >= 2 then
            -- Visão embaçada e desfocada
            ApplyScreenEffect("drunk", 15000)
            ApplyCameraShake(0.2, 5000)
        end
        
        if severity == 3 then
            -- Possível desmaio temporário
            if math.random(100) < 40 then
                SetPedToRagdoll(PlayerPedId(), 5000, 5000, 0, true, true, false)
            end
        end
    elseif bodyPart == "Torso" then
        if severity >= 2 then
            -- Efeito de sangramento
            ApplyBleedingEffect(severity * 0.3)
        end
    end
end

-- Efeito de uso de item médico
function PlayHealingEffect(itemType)
    if itemType == "MedKit" or itemType == "FirstAid" then
        -- Efeito de cura completa
        ApplyScreenEffect("pain_minor", 3000)
        
        if Config.UseSoundEffects then
            PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
        end
    elseif itemType == "Bandage" then
        -- Efeito de cura parcial
        if Config.UseSoundEffects then
            PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
        end
    elseif itemType == "Painkillers" then
        -- Efeito de analgésico
        ApplyScreenEffect("drugged", 3000)
        
        if Config.UseSoundEffects then
            PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
        end
    end
end

-- Limpa todos os efeitos visuais
function ClearAllVisualEffects()
    StopAllScreenEffects()
    ClearTimecycleModifier()
    StopGameplayCamShaking(true)
    TriggerScreenblurFadeOut(1000)
    
    -- Limpa registro de efeitos ativos
    activeEffects = {}
    isScreenEffectActive = false
end

-- Exporta funções para uso em outros arquivos
return {
    ApplyScreenEffect = ApplyScreenEffect,
    ResetScreenEffect = ResetScreenEffect,
    ApplyCameraShake = ApplyCameraShake,
    ApplyInjuryVisualEffect = ApplyInjuryVisualEffect,
    ApplyBleedingEffect = ApplyBleedingEffect,
    PlayBodyPartPainSound = PlayBodyPartPainSound,
    ApplySpecificBodyPartEffect = ApplySpecificBodyPartEffect,
    PlayHealingEffect = PlayHealingEffect,
    ClearAllVisualEffects = ClearAllVisualEffects
}