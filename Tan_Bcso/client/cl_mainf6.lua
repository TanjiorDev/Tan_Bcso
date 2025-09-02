-- 📦 Initialisation
local zUI = exports["zUI-v2"]:getObject()
local ESX = exports["es_extended"]:getSharedObject()

local function fmtMoney(n)
    n = tonumber(n) or 0
    -- Si ESX fournit déjà un groupage, on l'utilise
    if ESX and ESX.Math and ESX.Math.GroupDigits then
        return ESX.Math.GroupDigits(n)
    end
    -- Fallback simple (espaces 000)
    local sign = n < 0 and "-" or ""
    n = math.abs(math.floor(n + 0.0))
    local s = tostring(n)
    while true do
        local s2, k = s:gsub("^(%d+)(%d%d%d)", "%1 %2")
        s = s2
        if k == 0 then break end
    end
    return sign .. s
end

-- Met à jour les données du joueur lorsqu'il se connecte
RegisterNetEvent('esx:playerLoaded', function(playerData)
    ESX.PlayerData = playerData
end)

RegisterNetEvent("esx:setJob", function(job)
    ESX.PlayerData = ESX.PlayerData or {}
    ESX.PlayerData.job = job
end)

-- Helper : vérifier le job
local function hasJob(requiredJob, minGrade)
    local data = ESX.GetPlayerData()
    if not data or not data.job or data.job.name ~= requiredJob then return false end
    local grade = data.job.grade or data.job.grade_level or 0
    return grade >= (minGrade or 0)
end



-- 🔁 Fonctions utilitaires
local function getClosestPlayer(maxDistance)
    local player, distance = ESX.Game.GetClosestPlayer()
    if player ~= -1 and distance <= (maxDistance or 2.0) then
        return player
    end
    return nil
end

local function GetVehicleInFront()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local destination = coords + forward * 4.0
    local rayHandle = StartShapeTestRay(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z, 10, playerPed, 0)
    local _, _, _, _, entityHit = GetShapeTestResult(rayHandle)
    if entityHit and IsEntityAVehicle(entityHit) then return entityHit end
    return nil
end

local function AttachObjectToPed(model)
    local ped = PlayerPedId()
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(50) end
    local prop = CreateObject(GetHashKey(model), GetEntityCoords(ped), true, true, true)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 57005), 0.13, 0.02, 0.02, 10.0, 180.0, 180.0, true, true, false, true, 1, true)
    return prop
end

object = {}
function loadDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) RequestAnimDict(dict) end
end

-- 📋 MENU PRINCIPAL
local mainMenu = zUI.CreateMenu(
    "MENU BCSO",                -- Titre
    "INTERACTIONS",               -- Sous-titre
    "Intéractions BCSO :",      -- Description
    ConfigBcso.themes           -- Thème personnalisé
)

-- 👤 INTERACTIONS CITOYEN
local citoyen = zUI.CreateSubMenu(
    mainMenu,
    "INTERACTIONS CITOYEN",       -- Titre
    "",                           -- Sous-titre vide
    "Intéractions citoyen :",     -- Description
    ConfigBcso.themes
)

-- 🚘 INTERACTIONS VÉHICULE
local vehicule = zUI.CreateSubMenu(
    mainMenu,
    "INTERACTIONS VÉHICULE",      -- Titre
    "", 
    "Intéraction véhicule", 
    ConfigBcso.themes
)

-- 🧾 RÉSULTAT DE RECHERCHE
local Information = zUI.CreateSubMenu(
    mainMenu,
    "RÉSULTAT DE LA RECHERCHE",   -- Titre
    "",
    "Résultat de la recherche",
    ConfigBcso.themes
)

-- 📡 APPELS RADIO
local Appels = zUI.CreateSubMenu(
    mainMenu,
    "APPELS BCSO",                -- Titre
    "",
    "Appels BCSO",
    ConfigBcso.themes
)

local menuRenforts = zUI.CreateSubMenu(
    mainMenu,
    "Menu Renfort",                -- Titre
    "",
    "Menu Renfort",
    ConfigBcso.themes
)
local menuObjets = zUI.CreateSubMenu(
    mainMenu,
    "Menu menuo bjet",                -- Titre
    "",
    "Menu menu objet",
    ConfigBcso.themes
)
local menuSuppression = zUI.CreateSubMenu(
    mainMenu,
    "menuSuppression",                -- Titre
    "",
    "menuSuppression",
    ConfigBcso.themes
)

local amendeMenu = zUI.CreateSubMenu(
    mainMenu,
    "Bcso",                -- Titre
    "",
    "Choisir une infraction",
    ConfigBcso.themes
)

local vehicleInfos = nil
-- S'assurer que la variable est bien booléenne dès le départ
    local enService = false

zUI.SetItems(mainMenu, function()
    -- ✅ Checkbox - prise/fin de service

    zUI.Checkbox("Prise de service", "Mettez-vous en service / hors service", enService, {
    }, function(onSelected)
        if onSelected then
            enService = not enService
            if enService then
                     ESX.ShowNotification("~g~Vous êtes maintenant en service")
                else
                    ESX.ShowNotification("~r~Vous êtes maintenant hors service")
            end
            end
    end)
    -- ✅ Affiche les autres boutons uniquement si en service
    if enService then
        zUI.Button("Intéraction citoyen", nil, { RightLabel = "➤" }, function() end, citoyen)
        zUI.Button("Intéraction véhicule", nil, { RightLabel = "➤" }, function() end, vehicule)
        zUI.Button("Appels BCSO", nil, { RightLabel = "➤" }, function() end, Appels)
        zUI.Button("Demande de renfort", nil, { RightLabel = "➤" }, function() end, menuRenforts)
        zUI.Button("Menu Objets", nil, { RightLabel = "➤" }, function() end, menuObjets)
        zUI.Button("Menu amend", nil, { RightLabel = "➤" }, function() end, amendeMenu)
    end
end)

zUI.SetItems(amendeMenu, function()
    if not ConfigBcso or not ConfigBcso.amende or next(ConfigBcso.amende) == nil then
        zUI.Separator("~r~Aucune amende configurée")
        return
    end

    -- Parcourt des catégories d'amendes : ConfigBcso.amende = { ["Circulation"] = { {label="", price=0}, ... }, ... }
    for categorie, items in pairs(ConfigBcso.amende) do
        zUI.Separator(("~b~%s"):format(categorie))

        for _, i in pairs(items) do
            local label = i.label or "Amende"
            local price = tonumber(i.price) or 0

            zUI.Button(label, nil, { RightLabel = ("~g~%s$"):format(fmtMoney(price)) }, function(onSelected)
                if not onSelected then return end

                local player, distance = ESX.Game.GetClosestPlayer()
                if player ~= -1 and distance and distance <= 3.0 then
                    local targetSid = GetPlayerServerId(player)

                    -- Confirmation (ox_lib si présent, sinon envoi direct)
                    local choice = (lib and lib.alertDialog) and lib.alertDialog({
                        header   = 'Envoyer la facture ?',
                        content  = ('%s\nMontant : $%s'):format(label, fmtMoney(price)),
                        centered = true,
                        cancel   = true,
                        labels   = { confirm = 'Envoyer', cancel = 'Annuler' }
                    }) or 'confirm'

                    if choice == 'confirm' then
                        -- Si tu veux aussi le libellé côté serveur, ajoute-le ici
                        -- TriggerServerEvent("bcso:SendFacture", targetSid, price, label)
                        TriggerServerEvent("bcso:SendFacture", targetSid, price)

                        if ESX.ShowNotification then
                            ESX.ShowNotification(
                                ('Facture envoyée à ~y~%s~s~ : ~g~$%s'):format(GetPlayerName(player), fmtMoney(price))
                            )
                        else
                            TriggerEvent("esx:showNotification", "Facture envoyée.")
                        end

                        zUI.CloseAll()
                    end
                else
                    if ESX.ShowNotification then
                        ESX.ShowNotification("Aucun joueur proche")
                    else
                        TriggerEvent("esx:showNotification", "Aucun joueur proche", 3000, "warning")
                    end
                end
            end)
        end
    end
end)

-- Interaction "Fouiller" via ox_target
exports.ox_target:addGlobalPlayer({
    {
        name = "bcso_search",                         
        label = '🔍 Fouiller',
        icon = 'fa-solid fa-magnifying-glass',
        distance = 2.0,
        groups = { bcso = 0 },
        canInteract = function(entity, distance)
            if not entity or entity == PlayerPedId() then return false end

            local playerData = ESX.GetPlayerData()
            if not playerData.job or playerData.job.name ~= 'bcso' or not playerData.job.onDuty then
                return false
            end

            return distance and distance <= 2.0 or false
        end,
        onSelect = function(data)
            local ped = data.entity
            local player = NetworkGetPlayerIndexFromPed(ped)
            if not player or player == -1 then
                ESX.ShowNotification("~r~Aucune personne valide.")
                return
            end

            local serverId = GetPlayerServerId(player)
            ExecuteCommand('me fouille l’individu')
            
            -- Ouvre l'inventaire côté serveur
            TriggerServerEvent('ox_inventory:openInventory', 'player', serverId)
        end
    },

    {
        name = 'bcso_toggle',                  
        label = 'Menotter / Démenotter',
        icon = 'fa-solid fa-handcuffs',
        distance = 2.0,
        groups = { bcso = 0 },
        canInteract = function(entity, distance)
            if not entity or entity == PlayerPedId() then return false end

            local playerData = ESX.GetPlayerData()
            if not playerData.job or playerData.job.name ~= 'bcso' or not playerData.job.onDuty then
                return false
            end

            return distance and distance <= 2.0 or false
        end,
        onSelect = function(data)
            local ped = data.entity
            local player = NetworkGetPlayerIndexFromPed(ped)
            if not player or player == -1 then
                ESX.ShowNotification("~r~Aucune personne valide.")
                return
            end

            local serverId = GetPlayerServerId(player)
            TriggerServerEvent('Bcsojob:handcuff', serverId)
        end
    }
})

-- 👤 Citoyen
zUI.SetItems(citoyen, function()
-- Ajoute deux options globales sur TOUS les joueurs (côté client)
    zUI.Button("Mettre dans le véhicule", nil, { RightLabel = "➤" }, function(onSelected)
        if onSelected then
            local target = getClosestPlayer(2.5)
            if target then
                TriggerServerEvent('Bcsojob:putInVehicle', GetPlayerServerId(target))
            else
                ESX.ShowNotification('~r~Aucune personne proche.')
            end
        end
    end)

    zUI.Button("Sortir du véhicule", nil, { RightLabel = "➤" }, function(onSelected)
        if onSelected then
            local target = getClosestPlayer(3.5)
            if target then
                TriggerServerEvent('Bcsojob:OutVehicle', GetPlayerServerId(target))
            else
                ESX.ShowNotification('~r~Aucune personne proche.')
            end
        end
    end)
end)

-- 🚘 Véhicule
zUI.SetItems(vehicule, function()
    zUI.Button("Vérifier une plaque", nil, { RightLabel = "➤" }, function(onSelected)
        if onSelected then
            local playerPed = PlayerPedId()

            -- ❄️ Geler le joueur
            FreezeEntityPosition(playerPed, true)
            SetEntityInvincible(playerPed, true)

            -- ✅ Bloquer seulement les mouvements (conserve la caméra + ox_target)
            SetPlayerControl(PlayerId(), false, 2) -- 2 = désactive déplacement/sprint/saut, pas la caméra

            -- 📥 Input plaque
            local input = lib.inputDialog('Vérification véhicule', {
                { type = 'input', label = 'Numéro de plaque', description = 'Ex: AB123CD', required = true, icon = 'car-side' }
            })

            -- 🔓 Défreeze proprement
            FreezeEntityPosition(playerPed, false)
            SetEntityInvincible(playerPed, false)
            SetPlayerControl(PlayerId(), true, 0)

            if not input or not input[1] or input[1] == "" then
                ESX.ShowNotification("~r~Vous devez entrer une plaque valide.")
                return
            end

            ESX.TriggerServerCallback('Bcsojob:getVehicleInfos', function(retrivedInfo)
                vehicleInfos = retrivedInfo
            end, input[1])
        end
    end, Information)



    zUI.Button("Véhicule en fourrière", nil, { RightLabel = "➤" }, function(onSelected)
        if not onSelected then return end
        local playerPed = PlayerPedId()
        local vehicle = IsPedSittingInAnyVehicle(playerPed) and GetVehiclePedIsIn(playerPed, false) or GetVehicleInFront()

        if not vehicle or not DoesEntityExist(vehicle) then
            ESX.ShowNotification("~r~Aucun véhicule détecté.")
            return
        end

        if GetPedInVehicleSeat(vehicle, -1) ~= 0 then
            ESX.ShowNotification("~r~Quelqu’un est au volant.")
            return
        end

        lib.requestAnimDict("missheistdockssetup1clipboard@base")
        TaskPlayAnim(playerPed, "missheistdockssetup1clipboard@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)

        local clipboard = AttachObjectToPed("prop_notepad_01")
        local crayon = AttachObjectToPed("prop_pencil_01")

        local success = lib.progressBar({
            duration = 5000,
            label = "Mise en fourrière du véhicule...",
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true,
            },
        })

        ClearPedTasks(playerPed)
        if DoesEntityExist(clipboard) then DeleteEntity(clipboard) end
        if DoesEntityExist(crayon) then DeleteEntity(crayon) end

        if not success then
            ESX.ShowNotification("~r~Action annulée.")
            return
        end

        ESX.Game.DeleteVehicle(vehicle)
        ESX.ShowNotification("~g~Véhicule placé en fourrière.")
    end)
end)

-- 📄 Résultats d'infos véhicule
zUI.SetItems(Information, function()
    if vehicleInfos then
        zUI.Separator("Numéro de la Plaque : " .. (vehicleInfos.plate or "Inconnu"))
        zUI.Separator("Propriétaire : " .. (vehicleInfos.owner or "Inconnu"))
    else
        zUI.Separator("~r~Aucune information disponible")
    end
end)

zUI.SetItems(Appels, function()
    local statusOptions = {
        { label = "Prise de service",    value = "pris le service" },
        { label = "Fin de service",      value = "terminé son service" },
        { label = "Pause de service",    value = "mis en pause" },
        { label = "Standby",             value = "passé en standby" },
        { label = "Retour Commissariat", value = "retourné au commissariat" },
    }

    for _, status in ipairs(statusOptions) do
        zUI.Button(status.label, nil, { RightLabel = "➤" }, function(onSelected)
            if onSelected then
                TriggerServerEvent('Bcsojob:PriseEtFinservice', status.value)
                zUI.CloseAll()
            end
        end)
    end
end)


-- 📦 Menu objets avec zUI-v2
zUI.SetItems(menuObjets, function()
    for _, obj in pairs(ConfigBcso.Objects) do
        zUI.Button(
            obj.label,
            "Appuyez sur [~b~E~s~] pour placer l'objet",
            { RightLabel = "→" },
            function(onSelected)
                if onSelected then
                    SpawnObj(obj.model)
                end
            end
        )
    end

    zUI.Button("🗑️ Suppression", nil, { RightLabel = "→" }, function() end, menuSuppression)
end)

-- 🧹 Menu suppression
zUI.SetItems(menuSuppression, function()
    for k, v in pairs(object) do
        local entity = NetworkGetEntityFromNetworkId(v)
        local modelName = GoodName(GetEntityModel(entity))

        if modelName == 0 then
            table.remove(object, k)
        else
            zUI.Button(
                "Objet: " .. modelName .. " [" .. v .. "]",
                nil,
                {},
                function(onSelected, onHovered)
                    if onHovered then
                        local coords = GetEntityCoords(entity)
                        DrawMarker(20, coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0,
                            180.0, 0.0, 0.0,
                            0.2, 0.2, 0.2,
                            0, 0, 200, 170,
                            true, false, 2, false, nil, nil, false)
                    end
                    if onSelected then
                        RemoveObj(v, k)
                    end
                end
            )
        end
    end
end)

-- 🚨 Menu renforts
zUI.SetItems(menuRenforts, function()
    zUI.Button("🚓 Petite demande", nil, { RightLabel = "→" }, function(onSelected)
        if onSelected then
            local coords = GetEntityCoords(PlayerPedId())
            TriggerServerEvent('renfortbcso', coords, 'petitebcso')
        end
    end)

    zUI.Button("🚔 Moyenne demande", nil, { RightLabel = "→" }, function(onSelected)
        if onSelected then
            local coords = GetEntityCoords(PlayerPedId())
            TriggerServerEvent('renfortbcso', coords, 'moyennebcso')
        end
    end)

    zUI.Button("🚨 Grosse demande", nil, { RightLabel = "→" }, function(onSelected)
        if onSelected then
            local coords = GetEntityCoords(PlayerPedId())
            TriggerServerEvent('renfortbcso', coords, 'grossebcso')
        end
    end)
end)



RegisterNetEvent('Bcsojob:handcuff')
AddEventHandler('Bcsojob:handcuff', function()
    IsHandcuffed = not IsHandcuffed
    local playerPed = PlayerPedId()

    if IsHandcuffed then
        RequestAnimDict('mp_arresting')
        while not HasAnimDictLoaded('mp_arresting') do
            Citizen.Wait(100)
        end

        TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
        SetEnableHandcuffs(playerPed, true)
        SetPedCanPlayGestureAnims(playerPed, false)
        -- Ne fige plus le joueur :
        -- FreezeEntityPosition(playerPed, true)

        -- Cache la mini-map pendant le menottage
        DisplayRadar(false)
    else
        ClearPedSecondaryTask(playerPed)
        SetEnableHandcuffs(playerPed, false)
        SetPedCanPlayGestureAnims(playerPed, true)
        -- FreezeEntityPosition(playerPed, false)

        DisplayRadar(true)
    end
end)

-- Bloque certaines touches pendant qu’il est menotté
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsHandcuffed then
            -- Désactive tir, visée, arme
            DisableControlAction(0, 24, true) -- Tir
            DisableControlAction(0, 25, true) -- Visée
            DisableControlAction(0, 37, true) -- Weapon wheel
            DisableControlAction(0, 47, true) -- Armes
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 263, true)

            -- Désactive courir/sauter (optionnel)
            DisableControlAction(0, 21, true) -- Sprint (SHIFT)
            DisableControlAction(0, 22, true) -- Saut (ESPACE)
        else
            Citizen.Wait(500) -- pas besoin de boucler si pas menotté
        end
    end
end)

RegisterNetEvent('Bcsojob:putInVehicle')
AddEventHandler('Bcsojob:putInVehicle', function()
    local playerPed = GetPlayerPed(-1)
    local coords = GetEntityCoords(playerPed)
    if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
        local vehicle = GetClosestVehicle(coords.x,  coords.y,  coords.z,  5.0,  0,  71)
        if DoesEntityExist(vehicle) then
            local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
            local freeSeat = nil
            for i=maxSeats - 1, 0, -1 do
                if IsVehicleSeatFree(vehicle, i) then freeSeat = i
                break
                end
            end
            if freeSeat ~= nil then TaskWarpPedIntoVehicle(playerPed,  vehicle,  freeSeat)
            end
        end
    end
end)

RegisterNetEvent('Bcsojob:OutVehicle')
AddEventHandler('Bcsojob:OutVehicle', function(t)
    local ped = GetPlayerPed(t)
    ClearPedTasksImmediately(ped)
    plyPos = GetEntityCoords(GetPlayerPed(-1),  true)
    local xnew = plyPos.x+2
    local ynew = plyPos.y+2
    SetEntityCoords(GetPlayerPed(-1), xnew, ynew, plyPos.z)
end)


-- Charger la configuration

RegisterNetEvent('Bcsojob:InfoService')
AddEventHandler('Bcsojob:InfoService', function(service, nom)
    local messages = {
        prise = {
            title = 'Prise de service',
            description = '👮 Agent : '..nom..'\n📻 Code : 10-7\n✅ Information : Prise de service',
            type = 'success'
        },
        fin = {
            title = 'Fin de service',
            description = '👮 Agent : '..nom..'\n📻 Code : 10-8\n❌ Information : Fin de service',
            type = 'error'
        },
        pause = {
            title = 'Pause de service',
            description = '👮 Agent : '..nom..'\n📻 Code : 10-6\n☕ Information : Pause de service',
            type = 'inform'
        },
        standby = {
            title = 'Mise en standby',
            description = '👮 Agent : '..nom..'\n📻 Code : 10-9\n⌛ Information : Standby, en attente de dispatch',
            type = 'inform'
        },
        rdv = {
            title = 'Retour au poste',
            description = '👮 Agent : '..nom..'\n📻 Code : 10-19\n🏢 Information : Retour Commissariat',
            type = 'inform'
        }
    }

    local notif = messages[service]
    if notif then
        -- Son radio CB
        PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)

        -- Vérifier quel type de notification afficher
        if ConfigBcso.Notifications.ox_lib then
            -- Affichage notification ox_lib
            lib.notify({
                title = 'LSPD • '..notif.title,
                description = notif.description,
                type = notif.type, -- 'success', 'error', 'inform'
                position = 'top-right',
                duration = 7000 -- durée en ms
            })
        elseif ConfigBcso.Notifications.esx_notify then
            -- Affichage notification esx_notify
            ESX.ShowAdvancedNotification('LSPD INFORMATIONS', notif.title, notif.description, 'CHAR_CALL911', 8)
        end

        Wait(1000)
        PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
    end
end)


RegisterNetEvent('renfortbcso:setBlip')
AddEventHandler('renfortbcso:setBlip', function(coords, raison)
    local color = 0

    if raison == 'petitebcso' then
        PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", true)
        PlaySoundFrontend(-1, "OOB_Start", "GTAO_FM_Events_Soundset", true)
        Wait(1000)
        PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", true)
        color = 2

    elseif raison == 'moyennebcso' then
        PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", true)
        PlaySoundFrontend(-1, "OOB_Start", "GTAO_FM_Events_Soundset", true)
        Wait(1000)
        PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", true)
        color = 47

    elseif raison == 'grossebcso' then
        PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", true)
        PlaySoundFrontend(-1, "OOB_Start", "GTAO_FM_Events_Soundset", true)
        PlaySoundFrontend(-1, "FocusIn", "HintCamSounds", true)
        Wait(1000)
        PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", true)
        PlaySoundFrontend(-1, "FocusOut", "HintCamSounds", true)
        color = 1
    end

    -- Correction ici :
    local blipId = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blipId, 161)
    SetBlipScale(blipId, 1.2)
    SetBlipColour(blipId, color)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('Demande renfort')
    EndTextCommandSetBlipName(blipId)

    Wait(80 * 1000)
    RemoveBlip(blipId)
end)



function SpawnObj(obj)
    local playerPed = PlayerPedId()
	local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
    local objectCoords = (coords + forward * 1.0)
    local Ent = nil
    SpawnObject(obj, objectCoords, function(obj)
        SetEntityCoords(obj, objectCoords, 0.0, 0.0, 0.0, 0)
        SetEntityHeading(obj, GetEntityHeading(playerPed))
        PlaceObjectOnGroundProperly(obj)
        Ent = obj
        Wait(1)
    end)
    Wait(1)
    while Ent == nil do Wait(1) end
    SetEntityHeading(Ent, GetEntityHeading(playerPed))
    PlaceObjectOnGroundProperly(Ent)
    local placed = false
    while not placed do
        Citizen.Wait(1)
        local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
        local objectCoords = (coords + forward * 2.0)
        SetEntityCoords(Ent, objectCoords, 0.0, 0.0, 0.0, 0)
        SetEntityHeading(Ent, GetEntityHeading(playerPed))
        PlaceObjectOnGroundProperly(Ent)
        SetEntityAlpha(Ent, 170, 170)
        if IsControlJustReleased(1, 38) then
            placed = true
        end
    end
    FreezeEntityPosition(Ent, true)
    SetEntityInvincible(Ent, true)
    ResetEntityAlpha(Ent)
    local NetId = NetworkGetNetworkIdFromEntity(Ent)
    table.insert(object, NetId)
end

function SpawnObject(model, coords, cb)
	local model = GetHashKey(model)
	Citizen.CreateThread(function()
		RequestModels(model)
        Wait(1)
		local obj = CreateObject(model, coords.x, coords.y, coords.z, true, false, true)
		if cb then
			cb(obj)
		end
	end)
end

function RequestModels(modelHash)
	if not HasModelLoaded(modelHash) and IsModelInCdimage(modelHash) then RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do Citizen.Wait(1)
		end
	end
end

function RemoveObj(id, k)
    Citizen.CreateThread(function()
        SetNetworkIdCanMigrate(id, true)
        local entity = NetworkGetEntityFromNetworkId(id)

        if not DoesEntityExist(entity) then return end

        local timeout = 0
        while not NetworkHasControlOfEntity(entity) and timeout < 100 do
            NetworkRequestControlOfEntity(entity)
            Wait(10)
            timeout = timeout + 1
        end

        if NetworkHasControlOfEntity(entity) then
            DeleteEntity(entity)
            DeleteObject(entity)
            TriggerServerEvent("DeleteEntity", id)
            table.remove(object, k)
        else
            print("[ERREUR] Impossible de prendre le contrôle de l'entité.")
        end
    end)
end


function GoodName(hash)
    for _, obj in ipairs(ConfigBcso.Objects) do
        if GetHashKey(obj.model) == hash then
            return obj.label
        end
    end
    return tostring(hash)
end

-- 🔔 Gestion de la notification ESX (à ajouter si tu ne l’as pas déjà dans ton client)
RegisterNetEvent('esx:showNotification')
AddEventHandler('esx:showNotification', function(msg)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end)


-- 🧭 Commande + touche
RegisterCommand(ConfigBcso.CommandeMenu, function()
    local PlayerData = ESX.GetPlayerData()
    if PlayerData and PlayerData.job and PlayerData.job.name == ConfigBcso.JobBcso then
        local visible = zUI.IsVisible(mainMenu)
        zUI.SetVisible(mainMenu, not visible)
    end
end, false)

RegisterKeyMapping(ConfigBcso.CommandeMenu, "Ouvrir le menu personnel", "keyboard", ConfigBcso.ToucheMenu)
