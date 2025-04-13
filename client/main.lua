local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")

-- Variáveis locais
local playerPed = nil
local playerId = nil
local injuries = {
    Head = 0,
    Torso = 0,
    LeftArm = 0,
    RightArm = 0,
    LeftLeg = 0,
    RightLeg = 0
}
local activeEffects = {}
local healingTimers = {}
local tempReliefActive = false
local isPainReduced = false

-- Evento ao iniciar o recurso
AddEventHandler('onClientResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    playerPed = PlayerPedId()
    playerId = PlayerId()
    print('[INJURIES] Sistema de ferimentos inicializado')
    InitInjurySystem()
end)

-- Inicializa o sistema de ferimentos
function InitInjurySystem()
    if not Config.InjurySystem.EnableSystem then return end
    
    -- Inicia verificação contínua de ferimentos
    Citizen.CreateThread(function()
        while Config.InjurySystem.EnableSystem do
            playerPed = PlayerPedId()
            UpdateInjuryEffects()
            Citizen.Wait(1000)
        end
    end)
    
    -- Thread principal para alterações de movimento
    Citizen.CreateThread(function()
        while Config.InjurySystem.EnableSystem do
            local wait = 1
            
            -- Verifica se precisa aplicar efeitos a cada frame
            if HasAnyInjury() then
                ApplyInjuryMovementEffects()
            else
                wait = 500 -- Espera mais tempo se não tiver ferimentos ativos
            end
            
            Citizen.Wait(wait)
        end
    end)
    
    -- Registra evento para quando o jogador levar dano
    AddEventHandler("gameEventTriggered", function(name, args)
        if name == "CEventNetworkEntityDamage" then
            -- args[1] = entidade danificada, args[2] = entidade que causou o dano
            if args[1] == playerPed then
                local health = GetEntityHealth(playerPed)
                
                -- Ignora danos fatais
                if health <= 101 then
                    return
                end
                
                -- Detecta o tipo de dano
                ProcessDamage(args[2])
            end
        end
    end)
end

-- Processa o dano recebido e aplica ferimentos
function ProcessDamage(damageSourceEntity)
    local weaponHash = GetPedCauseOfDeath(playerPed)
    if weaponHash == 0 then
        weaponHash = GetSelectedPedWeapon(damageSourceEntity)
    end
    
    local damageType = GetDamageType(weaponHash, damageSourceEntity)
    local injuryChance = Config.InjurySystem.InjuryChance[damageType] or 50
    
    if math.random(100) <= injuryChance then
        local hit, bone = GetPedLastDamageBone(playerPed)
        if hit and bone ~= 0 then
            local bodyPart = GetBodyPartFromBone(bone)
            if bodyPart then
                local currentLevel = injuries[bodyPart]
                if currentLevel < Config.InjurySystem.MaxInjuryLevel then
                    injuries[bodyPart] = currentLevel + 1
                    TriggerEvent("injuries:bodyPartInjured", bodyPart, injuries[bodyPart])
                    ApplyImmediateEffects(bodyPart, injuries[bodyPart])
                    
                    -- Inicia a cura automática se configurado
                    if Config.InjurySystem.HealOverTime then
                        StartHealingTimer(bodyPart)
                    end
                    
                    -- Envia notificação ao jogador
                    NotifyInjury(bodyPart, injuries[bodyPart])
                end
            end
        end
    end
end

-- Identifica o tipo de dano
function GetDamageType(weaponHash, damageSourceEntity)
    -- Armas de fogo
    if IsWeaponFirearm(weaponHash) then
        return "Gunshot"
    -- Armas corpo a corpo
    elseif IsWeaponMelee(weaponHash) then
        return "Melee"
    -- Dano de veículo
    elseif IsEntityAVehicle(damageSourceEntity) then
        return "Vehicle"
    -- Queda
    elseif HasPedBeenDamagedByFalling(playerPed) then
        ClearPedLastDamageBone(playerPed)
        return "Fall"
    -- Explosão
    elseif HasEntityBeenDamagedByExplosion(playerPed) then
        ClearEntityLastDamageEntity(playerPed)
        return "Explosion"
    -- Outro tipo de dano
    else
        return "Other"
    end
end

-- Verifica se uma arma é de fogo
function IsWeaponFirearm(weaponHash)
    local weaponGroup = GetWeapontypeGroup(weaponHash)
    return weaponGroup == 970310034 or weaponGroup == 416676503 or 
           weaponGroup == -957766203 or weaponGroup == 860033945 or 
           weaponGroup == 1159398588 or weaponGroup == -1212426201
end

-- Verifica se uma arma é corpo a corpo
function IsWeaponMelee(weaponHash)
    local weaponGroup = GetWeapontypeGroup(weaponHash)
    return weaponGroup == -728555052 or weaponGroup == -1609580060
end

-- Identifica a parte do corpo baseado no osso atingido
function GetBodyPartFromBone(boneId)
    for bodyPart, bones in pairs(Config.Bones) do
        for _, bone in ipairs(bones) do
            if bone == boneId then
                return bodyPart
            end
        end
    end
    return nil
end

-- Aplica efeitos imediatos após receber um ferimento
function ApplyImmediateEffects(bodyPart, level)
    local effectConfig = Config.InjuryEffects[bodyPart]["Level"..level]
    
    -- Efeitos visuais na tela
    if Config.UseScreenEffects and effectConfig.ScreenEffect then
        TriggerScreenblurFadeIn(1000)
        ApplyScreenEffect(effectConfig.ScreenEffect)
        
        if effectConfig.TimedEffect then
            Citizen.SetTimeout(effectConfig.EffectDuration, function()
                TriggerScreenblurFadeOut(1000)
            end)
        end
    end
    
    -- Efeitos sonoros
    if Config.UseSoundEffects then
        PlayPainSound(bodyPart, level)
    end
    
    -- Para ferimentos graves na cabeça, pode aplicar efeito de desmaio
    if bodyPart == "Head" and level == 3 then
        SetPedToRagdoll(playerPed, 15000, 15000, 0, true, true, false)
    end
    
    -- Desarma o jogador se ferir gravemente o braço que segura a arma
    if (bodyPart == "LeftArm" or bodyPart == "RightArm") and level == 3 and Config.InjurySystem.DisableWeaponsWhenArmInjured then
        SetCurrentPedWeapon(playerPed, GetHashKey("WEAPON_UNARMED"), true)
    end
    
    -- Faz o jogador mancar se ferir a perna
    if (bodyPart == "LeftLeg" or bodyPart == "RightLeg") and level >= 2 and Config.InjurySystem.EnableLimping then
        -- A função ApplyInjuryMovementEffects já irá cuidar do efeito de mancar
    end
end

-- Aplica efeitos contínuos dos ferimentos
function ApplyInjuryMovementEffects()
    -- Efeitos na cabeça
    if injuries.Head > 0 and not isPainReduced then
        local headLevel = injuries.Head
        if headLevel >= 2 then
            SetPedMoveRateOverride(playerPed, 0.8)
            if headLevel == 3 and math.random(100) < 5 then
                SetPedToRagdoll(playerPed, 1500, 2000, 0, true, true, false)
            end
        end
    end
    
    -- Efeitos no torso
    if injuries.Torso > 0 and not isPainReduced then
        local torsoLevel = injuries.Torso
        if torsoLevel >= 2 then
            SetPedMoveRateOverride(playerPed, 0.85)
        end
    end
    
    -- Verifica se há dano nas pernas
    local legInjury = math.max(injuries.LeftLeg, injuries.RightLeg)
    if legInjury > 0 and Config.InjurySystem.EnableLimping then
        -- Aplica animação de mancar
        if not IsEntityPlayingAnim(playerPed, "move_m@injured", "move_m@injured", 3) then
            RequestAnimSet("move_m@injured")
            while not HasAnimSetLoaded("move_m@injured") do
                Citizen.Wait(100)
            end
            SetPedMovementClipset(playerPed, "move_m@injured", 1.0)
        end
        
        -- Redução de velocidade baseada no nível de ferimento
        local speedMultiplier = 1.0
        if legInjury == 1 then
            speedMultiplier = 0.9
        elseif legInjury == 2 then
            speedMultiplier = 0.7
        elseif legInjury == 3 then
            speedMultiplier = 0.5
            
            -- Chance de cair se o ferimento for grave
            if Config.InjurySystem.EnableFalling and math.random(100) < 10 then
                SetPedToRagdoll(playerPed, 1500, 2000, 0, true, true, false)
            end
        end
        SetPedMoveRateOverride(playerPed, speedMultiplier)
    end
    
    -- Desabilita controles se configurado e com ferimentos graves
    if Config.InjurySystem.DisableControlsWhenInjured then
        local armInjury = math.max(injuries.LeftArm, injuries.RightArm)
        if armInjury >= 3 then
            DisablePlayerFiring(playerId, true)
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 47, true) -- Weapon
            DisableControlAction(0, 58, true) -- Weapon
        end
    end
end

-- Inicia timer para cura automática de ferimentos
function StartHealingTimer(bodyPart)
    if healingTimers[bodyPart] then
        -- Reset timer se já existir
        healingTimers[bodyPart].active = false
    end
    
    local currentLevel = injuries[bodyPart]
    local healTime = Config.InjurySystem.HealTimePerLevel * currentLevel
    
    healingTimers[bodyPart] = {
        active = true,
        timeRemaining = healTime
    }
    
    Citizen.CreateThread(function()
        local timerData = healingTimers[bodyPart]
        while timerData.active and timerData.timeRemaining > 0 do
            Citizen.Wait(1000)
            timerData.timeRemaining = timerData.timeRemaining - 1000
            
            if timerData.timeRemaining <= 0 then
                if injuries[bodyPart] > 0 then
                    injuries[bodyPart] = injuries[bodyPart] - 1
                    
                    if injuries[bodyPart] > 0 then
                        -- Ainda tem ferimento, continua a curar
                        StartHealingTimer(bodyPart)
                    else
                        -- Remove efeitos quando curado
                        if bodyPart == "LeftLeg" or bodyPart == "RightLeg" then
                            if not HasAnyLegInjury() then
                                ResetPedMovementClipset(playerPed, 0.0)
                            end
                        end
                        
                        NotifyHealed(bodyPart)
                    end
                end
                
                timerData.active = false
            end
        end
    end)
end

-- Verifica se ainda tem algum ferimento nas pernas
function HasAnyLegInjury()
    return injuries.LeftLeg > 0 or injuries.RightLeg > 0
end

-- Verifica se tem algum ferimento ativo
function HasAnyInjury()
    for _, level in pairs(injuries) do
        if level > 0 then
            return true
        end
    end
    return false
end

-- Atualiza efeitos visuais baseados nos ferimentos
function UpdateInjuryEffects()
    -- Atualiza a UI se houver ferimentos
    if HasAnyInjury() then
        -- Envia dados para a UI
        SendNUIMessage({
            type = "updateInjuries",
            injuries = injuries
        })
    end
    
    -- Remove efeitos se não tiver mais ferimentos nas pernas
    if not HasAnyLegInjury() and IsEntityPlayingAnim(playerPed, "move_m@injured", "move_m@injured", 3) then
        ResetPedMovementClipset(playerPed, 0.0)
    end
end

-- Aplica efeito de tela baseado no tipo
function ApplyScreenEffect(effectType)
    if effectType == "damage" then
        StartScreenEffect("DeathFailOut", 0, false)
        SetTimecycleModifier("damage")
        SetTimecycleModifierStrength(0.2)
        
    elseif effectType == "damage_heavy" then
        StartScreenEffect("DeathFailOut", 0, false)
        SetTimecycleModifier("hud_def_desat_cold")
        SetTimecycleModifierStrength(0.4)
        
    elseif effectType == "damage_critical" then
        StartScreenEffect("DeathFailOut", 0, false)
        SetTimecycleModifier("hud_def_desat_cold_kill")
        SetTimecycleModifierStrength(0.8)
        
    elseif effectType == "pain_minor" then
        SetTimecycleModifier("hud_def_desat_cold")
        SetTimecycleModifierStrength(0.1)
        
    elseif effectType == "pain_medium" then
        SetTimecycleModifier("hud_def_desat_cold")
        SetTimecycleModifierStrength(0.3)
        
    elseif effectType == "pain_critical" then
        SetTimecycleModifier("hud_def_desat_cold")
        SetTimecycleModifierStrength(0.6)
    end
    
    -- Remove efeito após 5 segundos
    Citizen.SetTimeout(5000, function()
        StopScreenEffect("DeathFailOut")
        ClearTimecycleModifier()
    end)
end

-- Notifica o jogador sobre um ferimento
function NotifyInjury(bodyPart, level)
    local messages = {
        Head = {
            [1] = "Você sofreu um ferimento leve na cabeça",
            [2] = "Você sofreu um ferimento moderado na cabeça, sua visão está prejudicada",
            [3] = "Você sofreu um ferimento grave na cabeça, precisa de atendimento médico"
        },
        Torso = {
            [1] = "Você sofreu um ferimento leve no torso",
            [2] = "Você sofreu um ferimento moderado no torso, está com dificuldade para respirar",
            [3] = "Você sofreu um ferimento grave no torso, precisa de atendimento médico"
        },
        LeftArm = {
            [1] = "Você sofreu um ferimento leve no braço esquerdo",
            [2] = "Você sofreu um ferimento moderado no braço esquerdo, está com dificuldade para usá-lo",
            [3] = "Seu braço esquerdo está gravemente ferido, não consegue usá-lo"
        },
        RightArm = {
            [1] = "Você sofreu um ferimento leve no braço direito",
            [2] = "Você sofreu um ferimento moderado no braço direito, está com dificuldade para usá-lo",
            [3] = "Seu braço direito está gravemente ferido, não consegue usá-lo"
        },
        LeftLeg = {
            [1] = "Você sofreu um ferimento leve na perna esquerda",
            [2] = "Você sofreu um ferimento moderado na perna esquerda, está mancando",
            [3] = "Sua perna esquerda está gravemente ferida, está com muita dificuldade para andar"
        },
        RightLeg = {
            [1] = "Você sofreu um ferimento leve na perna direita",
            [2] = "Você sofreu um ferimento moderado na perna direita, está mancando",
            [3] = "Sua perna direita está gravemente ferida, está com muita dificuldade para andar"
        }
    }
    
    TriggerEvent("Notify", "aviso", messages[bodyPart][level], 5000)
end

-- Notifica o jogador sobre cura de um ferimento
function NotifyHealed(bodyPart)
    local messages = {
        Head = "Sua cabeça está se sentindo melhor",
        Torso = "Seu torso está se sentindo melhor",
        LeftArm = "Seu braço esquerdo está se sentindo melhor",
        RightArm = "Seu braço direito está se sentindo melhor",
        LeftLeg = "Sua perna esquerda está se sentindo melhor",
        RightLeg = "Sua perna direita está se sentindo melhor"
    }
    
    TriggerEvent("Notify", "verde", messages[bodyPart], 5000)
end

-- Reproduz som de dor
function PlayPainSound(bodyPart, level)
    local gender = "m" -- Padrão para masculino
    -- Detecta gênero do personagem
    if GetEntityModel(playerPed) == GetHashKey("mp_f_freemode_01") then
        gender = "f"
    end
    
    local painSounds = {
        m = {
            light = {"GROAN_LOW", "GROAN", "PAIN_LOW"},
            moderate = {"PAIN_MED", "INJURED_WASTED", "PAIN_HIGH"},
            severe = {"SCREAM_PANIC", "SCREAM_TERROR", "PAIN_DYING"}
        },
        f = {
            light = {"PAIN_LOW", "GROAN_LOW", "GROAN"},
            moderate = {"PAIN_MED", "INJURED_WASTED", "PAIN_HIGH"},
            severe = {"SCREAM_PANIC", "SCREAM_TERROR", "PAIN_DYING"}
        }
    }
    
    local intensity = "light"
    if level == 2 then
        intensity = "moderate"
    elseif level == 3 then
        intensity = "severe"
    end
    
    local sounds = painSounds[gender][intensity]
    local sound = sounds[math.random(#sounds)]
    
    PlayPedAmbientSpeechNative(playerPed, sound, "SPEECH_PARAMS_FORCE_SHOUTED")
end

-- Tratamento de ferimentos com itens médicos
RegisterNetEvent("injuries:useMedicalItem")
AddEventHandler("injuries:useMedicalItem", function(itemName, targetBodyPart)
    local itemConfig = Config.MedicalItems[itemName]
    if not itemConfig then return end
    
    -- Verifica se o item pode tratar esta parte do corpo
    local canTreat = false
    for _, bodyPart in ipairs(itemConfig.BodyParts) do
        if bodyPart == targetBodyPart then
            canTreat = true
            break
        end
    end
    
    if not canTreat then
        TriggerEvent("Notify", "vermelho", "Este item não pode tratar esta parte do corpo", 5000)
        return
    end
    
    -- Verifica se a parte do corpo está ferida
    if injuries[targetBodyPart] <= 0 then
        TriggerEvent("Notify", "amarelo", "Esta parte do corpo não está ferida", 5000)
        return
    end
    
    -- Animação de uso
    PlayMedicalAnimation(itemConfig.Animation)
    
    -- Espera o tempo de uso
    TriggerEvent("progress", itemConfig.UseTime, "Aplicando "..itemName)
    Citizen.Wait(itemConfig.UseTime)
    
    -- Efeito temporário de alívio da dor
    if itemConfig.TemporaryRelief then
        isPainReduced = true
        
        -- Restaura movimento normal temporariamente
        if targetBodyPart == "LeftLeg" or targetBodyPart == "RightLeg" then
            ResetPedMovementClipset(playerPed, 0.0)
        end
        
        Citizen.SetTimeout(itemConfig.ReliefDuration, function()
            isPainReduced = false
            -- Reaplica efeitos se ainda tiver ferimentos
            if HasAnyLegInjury() then
                RequestAnimSet("move_m@injured")
                while not HasAnimSetLoaded("move_m@injured") do
                    Citizen.Wait(100)
                end
                SetPedMovementClipset(playerPed, "move_m@injured", 1.0)
            end
        end)
        
        TriggerEvent("Notify", "verde", "Você sente alívio temporário da dor", 5000)
        return
    end
    
    -- Cura normal
    local newLevel = math.max(0, injuries[targetBodyPart] - itemConfig.HealAmount)
    injuries[targetBodyPart] = newLevel
    
    -- Notificação
    if newLevel == 0 then
        TriggerEvent("Notify", "verde", "Ferimento em "..GetBodyPartName(targetBodyPart).." foi curado", 5000)
        
        -- Restaura movimento se for perna e não tiver mais ferimentos nas pernas
        if (targetBodyPart == "LeftLeg" or targetBodyPart == "RightLeg") and not HasAnyLegInjury() then
            ResetPedMovementClipset(playerPed, 0.0)
        end
    else
        TriggerEvent("Notify", "verde", "Ferimento em "..GetBodyPartName(targetBodyPart).." melhorou", 5000)
    end
    
    -- Remove timer de cura automática se existir
    if healingTimers[targetBodyPart] then
        healingTimers[targetBodyPart].active = false
    end
    
    -- Atualiza UI
    UpdateInjuryEffects()
end)

-- Função para executar animação de uso de item médico
function PlayMedicalAnimation(animType)
    if animType == "bandage" then
        vRP.playAnim(false,{"amb@world_human_clipboard@male@idle_a","idle_c"},true)
    elseif animType == "firstaid" then
        vRP.playAnim(false,{"amb@world_human_clipboard@male@idle_a","idle_c"},true)
    elseif animType == "medkit" then
        vRP.playAnim(false,{"amb@world_human_clipboard@male@idle_a","idle_c"},true)
    elseif animType == "splint" then
        vRP.playAnim(false,{"amb@world_human_clipboard@male@idle_a","idle_c"},true)
    elseif animType == "pills" then
        vRP.playAnim(false,{"mp_suicide","pill"},true)
    end
end

-- Função para obter nome da parte do corpo em português
function GetBodyPartName(bodyPart)
    local names = {
        Head = "Cabeça",
        Torso = "Torso",
        LeftArm = "Braço Esquerdo",
        RightArm = "Braço Direito",
        LeftLeg = "Perna Esquerda",
        RightLeg = "Perna Direita"
    }
    return names[bodyPart] or bodyPart
end

-- Exporta funções que podem ser usadas por outros recursos
exports("getPlayerInjuries", function()
    return injuries
end)

exports("hasInjury", function(bodyPart)
    return injuries[bodyPart] > 0
end)

exports("getInjuryLevel", function(bodyPart)
    return injuries[bodyPart]
end)

exports("healInjury", function(bodyPart, amount)
    if not bodyPart or not injuries[bodyPart] then return false end
    
    local newLevel = math.max(0, injuries[bodyPart] - (amount or 1))
    injuries[bodyPart] = newLevel
    
    if newLevel == 0 and (bodyPart == "LeftLeg" or bodyPart == "RightLeg") then
        if not HasAnyLegInjury() then
            ResetPedMovementClipset(playerPed, 0.0)
        end
    end
    
    UpdateInjuryEffects()
    return true
end)

-- Comando para resetar ferimentos (apenas para testes)
if Config.DebugMode then
    RegisterCommand("resetinjuries", function()
        for bodyPart, _ in pairs(injuries) do
            injuries[bodyPart] = 0
        end
        
        ResetPedMovementClipset(playerPed, 0.0)
        ClearTimecycleModifier()
        StopAllScreenEffects()
        
        TriggerEvent("Notify", "sucesso", "Todos os ferimentos foram resetados", 3000)
        UpdateInjuryEffects()
    end, false)
    
    RegisterCommand("debuginjury", function(source, args)
        if #args < 2 then
            TriggerEvent("Notify", "erro", "Uso: /debuginjury [bodyPart] [level]", 3000)
            return
        end
        
        local bodyPart = args[1]
        local level = tonumber(args[2])
        
        if not injuries[bodyPart] then
            TriggerEvent("Notify", "erro", "Parte do corpo inválida", 3000)
            return
        end
        
        if level < 0 or level > Config.InjurySystem.MaxInjuryLevel then
            TriggerEvent("Notify", "erro", "Nível deve ser entre 0 e " .. Config.InjurySystem.MaxInjuryLevel, 3000)
            return
        end
        
        injuries[bodyPart] = level
        
        if level > 0 then
            ApplyImmediateEffects(bodyPart, level)
            TriggerEvent("Notify", "info", "Ferimento em " .. GetBodyPartName(bodyPart) .. " definido para nível " .. level, 3000)
        else
            TriggerEvent("Notify", "sucesso", "Ferimento em " .. GetBodyPartName(bodyPart) .. " curado", 3000)
        end
        
        UpdateInjuryEffects()
    end, false)
end