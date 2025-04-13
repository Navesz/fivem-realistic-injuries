-- Sistema de animações para ferimentos
local injuryAnimations = {
    LegInjury = {
        dict = "move_m@injured",
        name = "move_m@injured",
        blendSpeed = 1.0
    },
    ArmInjury = {
        dict = "anim@heists@prison_heiststation@cop_reactions",
        name = "cop_b_idle",
        blendSpeed = 8.0
    },
    SevereInjury = {
        dict = "combat@damage@rb_writhe",
        name = "rb_writhe_loop",
        blendSpeed = 1.0
    },
    HeadInjury = {
        dict = "misscarsteal4@actor",
        name = "stumble",
        blendSpeed = 1.0
    }
}

-- Carrega as animações necessárias para o sistema de ferimentos
function LoadInjuryAnimations()
    for _, anim in pairs(injuryAnimations) do
        RequestAnimSet(anim.dict)
    end
end

-- Aplica animação de ferimento na perna
function ApplyLegInjuryAnimation(severity)
    local anim = injuryAnimations.LegInjury
    
    if not HasAnimSetLoaded(anim.dict) then
        RequestAnimSet(anim.dict)
        while not HasAnimSetLoaded(anim.dict) do
            Citizen.Wait(100)
        end
    end
    
    local speedModifier = 1.0
    if severity == 1 then
        speedModifier = 0.9
    elseif severity == 2 then
        speedModifier = 0.7
    elseif severity == 3 then
        speedModifier = 0.5
    end
    
    SetPedMovementClipset(PlayerPedId(), anim.name, speedModifier)
end

-- Aplica animação de ferimento no braço (desativa uso de itens/armas)
function ApplyArmInjuryAnimation(isLeftArm)
    -- No futuro: implementar animações específicas para cada braço
    -- Por enquanto usamos a mesma animação
    local anim = injuryAnimations.ArmInjury
    
    if not HasAnimSetLoaded(anim.dict) then
        RequestAnimSet(anim.dict)
        while not HasAnimSetLoaded(anim.dict) do
            Citizen.Wait(100)
        end
    end
end

-- Aplica animação de ferimento na cabeça (tontura)
function ApplyHeadInjuryAnimation(severity)
    local anim = injuryAnimations.HeadInjury
    
    if not HasAnimDictLoaded(anim.dict) then
        RequestAnimDict(anim.dict)
        while not HasAnimDictLoaded(anim.dict) do
            Citizen.Wait(100)
        end
    end
    
    -- Apenas para ferimentos severos, faz o player cambalear ocasionalmente
    if severity == 3 and math.random(100) < 15 then
        TaskPlayAnim(PlayerPedId(), anim.dict, anim.name, 8.0, 1.0, -1, 0, 0, false, false, false)
    end
end

-- Animação de desmaio (quedas graves ou ferimentos críticos)
function ApplyUnconsciousAnimation(duration)
    -- Usa o ragdoll nativo do GTA para simular desmaio
    SetPedToRagdoll(PlayerPedId(), duration, duration, 0, true, true, false)
end

-- Animações para uso de itens médicos
function PlayMedicalItemAnimation(itemType)
    local animations = {
        bandage = {
            dict = "amb@world_human_clipboard@male@idle_a",
            name = "idle_c",
            flag = 49,
            duration = 5000
        },
        firstaid = {
            dict = "amb@world_human_clipboard@male@idle_a",
            name = "idle_c",
            flag = 49,
            duration = 10000
        },
        medkit = {
            dict = "amb@world_human_clipboard@male@idle_a",
            name = "idle_c",
            flag = 49,
            duration = 15000
        },
        splint = {
            dict = "amb@world_human_clipboard@male@idle_a",
            name = "idle_c",
            flag = 49,
            duration = 12000
        },
        pills = {
            dict = "mp_suicide",
            name = "pill",
            flag = 49,
            duration = 3000
        }
    }
    
    local anim = animations[itemType]
    if not anim then return end
    
    if not HasAnimDictLoaded(anim.dict) then
        RequestAnimDict(anim.dict)
        while not HasAnimDictLoaded(anim.dict) do
            Citizen.Wait(100)
        end
    end
    
    TaskPlayAnim(PlayerPedId(), anim.dict, anim.name, 8.0, -8.0, anim.duration, anim.flag, 0, false, false, false)
    
    return anim.duration
end

-- Animação de dor para diferentes partes do corpo
function PlayPainAnimation(bodyPart, severity)
    local animations = {
        Head = {
            dict = "missminuteman_1ig_2",
            name = "handsup_base",
            flag = 49,
            duration = 2500
        },
        Torso = {
            dict = "dam@base@tors@low@idle_a",
            name = "idle_a",
            flag = 49,
            duration = 2500
        },
        LeftArm = {
            dict = "anim@heists@prison_heiststation@cop_reactions",
            name = "cop_b_idle",
            flag = 49,
            duration = 2500
        },
        RightArm = {
            dict = "anim@heists@prison_heiststation@cop_reactions",
            name = "cop_b_idle",
            flag = 49,
            duration = 2500
        },
        LeftLeg = {
            dict = "anim@mp_player_intupperface_palm",
            name = "idle_a",
            flag = 49,
            duration = 2500
        },
        RightLeg = {
            dict = "anim@mp_player_intupperface_palm",
            name = "idle_a",
            flag = 49,
            duration = 2500
        }
    }
    
    local anim = animations[bodyPart]
    if not anim then return end
    
    -- Para ferimentos graves, aumenta duração da animação
    if severity == 3 then
        anim.duration = anim.duration * 1.5
    end
    
    if not HasAnimDictLoaded(anim.dict) then
        RequestAnimDict(anim.dict)
        while not HasAnimDictLoaded(anim.dict) do
            Citizen.Wait(100)
        end
    end
    
    TaskPlayAnim(PlayerPedId(), anim.dict, anim.name, 8.0, -8.0, anim.duration, anim.flag, 0, false, false, false)
    
    return anim.duration
end

-- Exporta funções para uso em outros arquivos
return {
    LoadInjuryAnimations = LoadInjuryAnimations,
    ApplyLegInjuryAnimation = ApplyLegInjuryAnimation,
    ApplyArmInjuryAnimation = ApplyArmInjuryAnimation,
    ApplyHeadInjuryAnimation = ApplyHeadInjuryAnimation,
    ApplyUnconsciousAnimation = ApplyUnconsciousAnimation,
    PlayMedicalItemAnimation = PlayMedicalItemAnimation,
    PlayPainAnimation = PlayPainAnimation
}