local zUI = exports["zUI-v2"]:getObject()
local ESX = exports["es_extended"]:getSharedObject()

-- Met à jour les données du joueur lorsqu'il se connecte
RegisterNetEvent('esx:playerLoaded', function(playerData)
    ESX.PlayerData = playerData
end)

RegisterNetEvent("esx:setJob", function(job)
    ESX.PlayerData = ESX.PlayerData or {}
    ESX.PlayerData.job = job
end)

local garageMenuBCSO = zUI.CreateMenu("Garage BCSO","INTERACTIONS", "Choix des véhicules :", ConfigBcso.themes)

-- ===== Helpers =====
local function loadModel(model)
    local hash = type(model) == "string" and GetHashKey(model) or model
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        ESX.ShowNotification(("Modèle introuvable: %s"):format(tostring(model)))
        return nil
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 8000
    while not HasModelLoaded(hash) do
        Wait(0)
        if GetGameTimer() > timeout then
            ESX.ShowNotification("Chargement modèle trop long.")
            return nil
        end
    end
    return hash
end

local function normalizeVec(any)
    -- Accepte vector3, vector4, table {x=,y=,z=,w=} ou {x,y,z,w}
    if type(any) == "vector3" then
        return vector3(any.x, any.y, any.z), nil
    elseif type(any) == "vector4" then
        return vector3(any.x, any.y, any.z), any.w
    elseif type(any) == "table" then
        local x = any.x or any[1]
        local y = any.y or any[2]
        local z = any.z or any[3]
        local w = any.w or any[4]
        if x and y and z then return vector3(x,y,z), w end
    end
    return nil, nil
end

local function getSpawnPosition()
    -- 1) ConfigBcso.posbcso.spawnBcsoVehicle.position (vector3/4 ou table)
    local posCfg = ConfigBcso.posbcso
               and ConfigBcso.posbcso.spawnBcsoVehicle
               and ConfigBcso.posbcso.spawnBcsoVehicle.position
    if posCfg then
        local v3, w = normalizeVec(posCfg)
        if v3 then
            print(("[BCSO] spawn pos from posbcso vector: %.3f %.3f %.3f | heading=%.2f"):format(v3.x, v3.y, v3.z, w or 0.0))
            return v3, (w or 0.0)
        end
    end

    -- 2) ConfigBcso.Garage.SpawnBcso { coords = vector3/4/table, heading = number? }
    local spawn = ConfigBcso.Garage and ConfigBcso.Garage.SpawnBcso or {}
    if spawn.coords then
        local v3, w = normalizeVec(spawn.coords)
        local h = (spawn.heading ~= nil) and spawn.heading or (w or 0.0)
        if v3 then
            print(("[BCSO] spawn pos from Garage.SpawnBcso: %.3f %.3f %.3f | heading=%.2f"):format(v3.x, v3.y, v3.z, h or 0.0))
            return v3, (h or 0.0)
        end
    end

    -- 3) fallback joueur
    local ped = PlayerPedId()
    local pc = GetEntityCoords(ped)
    local ph = GetEntityHeading(ped)
    print(("[BCSO] spawn pos fallback player: %.3f %.3f %.3f | heading=%.2f"):format(pc.x, pc.y, pc.z, ph))
    return pc, ph
end

local function ensureGroundAndCollision(coords, tries)
    tries = tries or 20
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    ClearAreaOfEverything(coords.x, coords.y, coords.z, 3.0, false, false, false, false)
    local z0 = coords.z

    -- Premier essai
    local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, z0, false)
    if found and groundZ > -100.0 then
        return vector3(coords.x, coords.y, groundZ + 0.2)
    end

    -- Petits incréments
    for i = 1, tries do
        Wait(0)
        found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, z0 + (i * 1.0), false)
        if found and groundZ > -100.0 then
            return vector3(coords.x, coords.y, groundZ + 0.2)
        end
    end
    return coords
end

-- Optionnel : verrouiller au node routier le plus proche
local function snapToClosestRoad(coords)
    -- bool found, vector3 nodePos, float nodeHeading
    local found, nodePos, nodeHeading = GetClosestVehicleNodeWithHeading(coords.x, coords.y, coords.z, 0, 0, 1, 3.0, 0.0)
    if found and nodePos then
        return vector3(nodePos.x, nodePos.y, nodePos.z + 0.2), nodeHeading
    end
    return coords, nil
end

local function spawnBcsoCar(entry)
    if not entry then return end

    local model = type(entry) == "table" and entry.model or entry
    if not model then
        ESX.ShowNotification("Modèle non défini.")
        return
    end

    local hash = loadModel(model)
    if not hash then return end

    local coords, heading = getSpawnPosition()
    coords = ensureGroundAndCollision(coords)

    if ConfigBcso.GarageBCSO and ConfigBcso.GarageBCSO.SnapToRoad then
        local roadPos, roadH = snapToClosestRoad(coords)
        if roadPos then
            coords = roadPos
            if roadH then heading = roadH end
            print(("[BCSO] snapToRoad -> %.3f %.3f %.3f | heading=%.2f"):format(coords.x, coords.y, coords.z, heading or 0.0))
        end
    end

    ClearAreaOfEverything(coords.x, coords.y, coords.z, 3.5, false, false, false, false)

    -- Création
    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, heading or 0.0, true, false)
    if not DoesEntityExist(veh) then
        ESX.ShowNotification("Échec du spawn du véhicule.")
        SetModelAsNoLongerNeeded(hash)
        return
    end

    -- Verrouille d’abord la pos exacte (évite “glissade”)
    SetEntityCoordsNoOffset(veh, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(veh, heading or 0.0)
    FreezeEntityPosition(veh, true)
    Wait(50)
    SetVehicleOnGroundProperly(veh)  -- asseoir le véhicule
    FreezeEntityPosition(veh, false)

    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehRadioStation(veh, "OFF")
    SetVehicleDirtLevel(veh, 0.0)

    -- Plaque & options
    local cfg = type(entry) == "table" and entry or {}
    local plate = (cfg.plate or "BCSO") .. tostring(math.random(100, 999))
    SetVehicleNumberPlateText(veh, plate)

    if cfg.livery ~= nil and GetVehicleLiveryCount(veh) > 0 then
        SetVehicleLivery(veh, tonumber(cfg.livery) or 0)
    end
    if type(cfg.extras) == "table" then
        for id, enabled in pairs(cfg.extras) do
            id = tonumber(id)
            if id and DoesExtraExist(veh, id) then
                SetVehicleExtra(veh, id, enabled and 0 or 1)
            end
        end
    end
    if cfg.windowTint ~= nil then
        SetVehicleWindowTint(veh, tonumber(cfg.windowTint) or 0)
    end

    SetVehicleEngineOn(veh, true, true, false)
    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)

    SetModelAsNoLongerNeeded(hash)
    ESX.ShowNotification(("Véhicule sorti : %s"):format(cfg.label or tostring(model)))
end

-- ===== Menu Garage =====
zUI.SetItems(garageMenuBCSO, function()
    if type(ConfigBcso.AuthorizedBcsoVehicles) ~= "table" or next(ConfigBcso.AuthorizedBcsoVehicles) == nil then
        zUI.Separator("Aucun véhicule disponible.")
        return
    end

    for _, v in ipairs(ConfigBcso.AuthorizedBcsoVehicles) do
        local label = v.label or v.model or "Véhicule"
        zUI.Button(label, "Sortir ce véhicule", {}, function(onSelected)
            if not onSelected then return end
            spawnBcsoCar(v)
            if zUI.CloseAll then zUI.CloseAll() else zUI.SetVisible(garageMenuBCSO, false) end
        end)
    end
end)

-- ========== Helpers ==========
local function ShowHelp(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function notify(title, message, icon)
    if zUI and zUI.SendNotification then
        TriggerEvent('zUI:SendNotification', title or "", message or "", {
            type = "notification",
            icon = icon or "CHAR_DEFAULT",
            duration = 5000
        })
    else
        ESX.ShowNotification((title and ("%s"):format(title) or "") .. (message or ""))
    end
end

local function requestControl(entity, tries)
    tries = tries or 20
    if not DoesEntityExist(entity) then return false end
    while not NetworkHasControlOfEntity(entity) and tries > 0 do
        NetworkRequestControlOfEntity(entity)
        Wait(50)
        tries = tries - 1
    end
    return NetworkHasControlOfEntity(entity)
end

local function deleteVehicleSafe(veh)
    if not DoesEntityExist(veh) then return false end
    if not requestControl(veh) then return false end
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleAsNoLongerNeeded(veh)
    DeleteVehicle(veh)
    if DoesEntityExist(veh) then
        -- fallback
        DeleteEntity(veh)
    end
    return not DoesEntityExist(veh)
end

-- ========== Ranger bcso ==========
CreateThread(function()
    local key = (ConfigBcso.Ranger and ConfigBcso.Ranger.BcsoRanger and ConfigBcso.Ranger.BcsoRanger.key) or 38 -- E
    local distMax = (ConfigBcso.Ranger and ConfigBcso.Ranger.BcsoRanger and ConfigBcso.Ranger.BcsoRanger.distance) or 2.5
    local target = ConfigBcso.Ranger and ConfigBcso.Ranger.BcsoRanger and ConfigBcso.Ranger.BcsoRanger.coords
    if not target then return end

    local targetVec = vector3(target.x, target.y, target.z)
    local uiShown = false

    while true do
        local wait = 250
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local dist = #(coords - targetVec)

        if dist <= distMax then
            wait = 0
            -- ✅ Affiche l'invite une seule fois quand on entre dans la zone
            if not uiShown then
                lib.showTextUI('[E] - pour ranger le véhicule de bcso', {
                    position = 'right-center',
                    icon = 'fa-solid fa-gas-pump',
                })
                uiShown = true
            end

            if IsControlJustReleased(0, key) then
                local veh = 0
                if IsPedInAnyVehicle(ped, false) then
                    veh = GetVehiclePedIsIn(ped, false)
                else
                    veh = ESX.Game.GetClosestVehicle(coords)
                    if veh ~= 0 and #(GetEntityCoords(veh) - targetVec) > 6.0 then
                        veh = 0
                    end
                end

                if veh ~= 0 and DoesEntityExist(veh) then
                    local ok = deleteVehicleSafe(veh)
                    if ok then
                        notify("Rangement", "Véhicule de bcso rangé avec succès.", "CHAR_CALL911")
                    else
                        notify("Rangement", "Impossible de ranger ce véhicule (contrôle réseau).", "CHAR_BLOCKED")
                    end
                else
                    notify("Rangement", "Aucun véhicule à proximité.", "CHAR_BLOCKED")
                end
            end
        else
            -- ✅ Cache l'invite quand on sort de la zone
            if uiShown then
                lib.hideTextUI()
                uiShown = false
            end
        end

        Wait(wait)
    end
end)

-- ===== OX_TARGET zone =====
CreateThread(function()
    local zone = ConfigBcso.GarageBCSO and ConfigBcso.GarageBCSO.BcsoGarage
    if not zone then
        return
    end

    exports.ox_target:addBoxZone({
        coords = zone.coords,
        size = zone.size,
        drawSprite = true,
        options = {
            {
                name = zone.garageMenuBCSO.name,
                icon = zone.garageMenuBCSO.icon,
                label = zone.garageMenuBCSO.label,
                canInteract = function()
                    local p = ESX.PlayerData or ESX.GetPlayerData()
                    return p and p.job and p.job.name == (ConfigBcso.JobRequired or "bcso")
                end,
                onSelect = function()
                    OpenMenuGarageBCSO()
                end,
                distance = zone.garageMenuBCSO.distance or 2.0
            }
        }
    })
end)

function OpenMenuGarageBCSO()
    zUI.SetVisible(garageMenuBCSO, not zUI.IsVisible(garageMenuBCSO))
end
