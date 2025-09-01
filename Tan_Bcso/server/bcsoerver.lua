ESX = exports["es_extended"]:getSharedObject()

TriggerEvent('esx_phone:registerNumber', 'bcso', 'alerte bcso', true, true)

TriggerEvent('esx_society:registerSociety', 'bcso', 'bcso', 'society_bcso', 'society_bcso', 'society_bcso', {type = 'public'})


RegisterServerEvent('ox_inventory:openInventory')
AddEventHandler('ox_inventory:openInventory', function(type, targetId)
    local src = source
    local target = tonumber(targetId)
    if not target then return end

    -- Vérifie que le joueur source est BCSO et en service
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    if xPlayer.job.name ~= 'bcso' or not xPlayer.job.onDuty then return end

    -- Ouvre l'inventaire du joueur ciblé pour le joueur source
    TriggerClientEvent('ox_inventory:openInventory', src, type, target)
end)


-- Event : réception d’une demande de RDV
RegisterNetEvent("rdv:sendToBcso")
AddEventHandler("rdv:sendToBcso", function(motif, heure)
    local xPlayer = ESX.GetPlayerFromId(source)
    local name = xPlayer.getName()

    -- ✅ Notification aux policiers en service
    for _, playerId in pairs(ESX.GetPlayers()) do
        local xTarget = ESX.GetPlayerFromId(playerId)
        if xTarget.job.name == "bcso" then
            TriggerClientEvent("esx:showNotification", playerId, "📅 Nouveau RDV : "..motif.." à "..heure.." (citoyen: "..name..")")
        end
    end

    -- ✅ Message envoyé au Discord via webhook
    local message = {
        username = ConfigBcso.WebhookName,
        embeds = {
            {
                title = "📢 Nouveau rendez-vous demandé",
                description = ("**👤 Citoyen :** %s\n**📝 Motif :** %s\n**⏰ Heure souhaitée :** %s"):format(name, motif, heure),
                color = 3447003, -- bleu
                footer = { text = "Système RDV bcso - Click&Build" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }

    PerformHttpRequest(ConfigBcso.WebhookURL, function(err, text, headers) end, "POST", json.encode(message), { ["Content-Type"] = "application/json" })
end)


-- ====== Persistance ======
local _evidence = {}  -- [id] = { id, label, suspect, caseId, officer, time, closed = false }
local _persistFile = ConfigBcso.Evidence.persistFile

local function loadEvidence()
    local raw = LoadResourceFile(GetCurrentResourceName(), _persistFile)
    if raw and #raw > 0 then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then
            _evidence = data
        end
    end
end

local function saveEvidence()
    -- FiveM json.encode n'accepte qu'un seul paramètre
    SaveResourceFile(GetCurrentResourceName(), _persistFile, json.encode(_evidence), -1)
end

-- ====== Enregistrement d'un stash evidence ======
local function registerEvidenceStash(id, label)
    local slots  = ConfigBcso.Evidence.slots
    local weight = ConfigBcso.Evidence.weight
    local groups = { [ConfigBcso.Evidence.job] = (ConfigBcso.Evidence.minGrade or 0) } -- restriction job/grade

    exports.ox_inventory:RegisterStash(id, label, slots, weight, false, groups)
end

-- ====== Enregistrement des coffres fixes (Principal + Saisies) ======
local function registerFixedStashes()
    if not ConfigBcso or not ConfigBcso.Stashes then return end

    local groups = {}
    if ConfigBcso.Evidence and ConfigBcso.Evidence.job then
        groups[ConfigBcso.Evidence.job] = ConfigBcso.Evidence.minGrade or 0
    end

    for _, s in pairs(ConfigBcso.Stashes) do
        exports.ox_inventory:RegisterStash(
            s.id, s.label, s.slots, s.weight, s.owner or false, groups
        )
    end
end

AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then
        registerFixedStashes()
    end
end)
if GetResourceState(GetCurrentResourceName()) == 'started' then
    registerFixedStashes()
end




-- ====== (Re)register de tous les coffres evidence dynamiques ======
local function registerAllEvidence()
    loadEvidence()
    for id, info in pairs(_evidence) do
        registerEvidenceStash(id, info.label)
    end
end

-- ====== Hooks démarrage (unifiés) ======
AddEventHandler('onServerResourceStart', function(res)
    if res == 'ox_inventory' or res == GetCurrentResourceName() then
        registerFixedStashes()
        registerAllEvidence()
    end
end)

AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then
        registerFixedStashes()
        registerAllEvidence()
    end
end)

CreateThread(function()
    loadEvidence()
end)

-- ====== Webhook (optionnel) ======
local function sendWebhook(title, desc)
    local url = ConfigBcso.Evidence.webhook
    if not url or url == "" then return end
    local payload = {
        username = "bcso Evidence",
        embeds = {{
            title = title,
            description = desc,
            color = 44799
        }}
    }
    PerformHttpRequest(url, function() end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

-- ====== Créer un coffre evidence ======
RegisterNetEvent('bcso:evidence:create', function(payload)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    -- Pas de ?. en Lua : on teste explicitement
    if not xPlayer or not xPlayer.job or xPlayer.job.name ~= ConfigBcso.Evidence.job
        or (xPlayer.job.grade or 0) < (ConfigBcso.Evidence.minGrade or 0) then
        return
    end

    local suspect   = (payload and payload.suspect) or "Inconnu"
    local caseId    = (payload and payload.caseId) or os.date("EV-%d%m%y")
    local notes     = (payload and payload.notes) or ""
    local officer   = (xPlayer.getName and xPlayer.getName()) or ("ID %d"):format(src)
    local ts        = os.time()

    local id    = ("evidence_%d_%d"):format(src, ts)
    local label = ("Preuves | %s | %s"):format(caseId, suspect)

    registerEvidenceStash(id, label)

    _evidence[id] = {
        id = id,
        label = label,
        suspect = suspect,
        caseId = caseId,
        notes = notes,
        officer = officer,
        time = ts,
        closed = false
    }
    saveEvidence()

    sendWebhook("Coffre Evidence créé", ("**ID :** `%s`\n**Affaire :** %s\n**Suspect :** %s\n**Officier :** %s"):format(id, caseId, suspect, officer))
    TriggerClientEvent('bcso:evidence:created', src, { id = id, label = label })
end)

-- ====== Liste pour l'UI (date déjà formatée côté serveur) ======
lib.callback.register('bcso:evidence:list', function(src, includeClosed)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job or xPlayer.job.name ~= ConfigBcso.Evidence.job then
        return {}
    end

    local function pretty(ts)
        return os.date("%d/%m %H:%M", ts)
    end

    local list = {}
    for id, info in pairs(_evidence) do
        if includeClosed or not info.closed then
            list[#list+1] = {
                id      = id,
                label   = info.label .. (info.closed and " [FERMÉ]" or ""),
                suspect = info.suspect,
                caseId  = info.caseId,
                time    = info.time,
                prettyTime = pretty(info.time),
                closed  = info.closed
            }
        end
    end

    table.sort(list, function(a,b) return a.time > b.time end)
    return list
end)

-- ====== Contrôle ouverture ======
RegisterNetEvent('bcso:evidence:requestOpen', function(stashId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job or xPlayer.job.name ~= ConfigBcso.Evidence.job then
        return
    end
    local info = _evidence[stashId]
    if not info or info.closed then
        TriggerClientEvent('esx:showNotification', src, "~r~Coffre indisponible ou fermé.")
        return
    end

    TriggerClientEvent('bcso:evidence:open', src, stashId)
end)

-- ====== Sceller ======
RegisterNetEvent('bcso:evidence:close', function(stashId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job or xPlayer.job.name ~= ConfigBcso.Evidence.job then
        return
    end
    local info = _evidence[stashId]
    if not info or info.closed then
        return
    end

    info.closed = true
    info.label = "[SCELLÉ] " .. info.label
    _evidence[stashId] = info
    saveEvidence()
    sendWebhook("Coffre Evidence scellé", ("**ID :** `%s`\n**Affaire :** %s\n**Suspect :** %s\n**Par :** %s"):format(
        stashId, info.caseId, info.suspect, (xPlayer.getName and xPlayer.getName()) or src
    ))
    TriggerClientEvent('esx:showNotification', src, "~g~Coffre scellé.")
end)


-- server.lua

-- ⚙️ Grade mini pour supprimer (tu peux changer)
ConfigBcso.Evidence.deleteMinGrade = ConfigBcso.Evidence.deleteMinGrade or 1

RegisterNetEvent('bcso:evidence:delete', function(stashId, force)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job or xPlayer.job.name ~= ConfigBcso.Evidence.job
        or (xPlayer.job.grade or 0) < (ConfigBcso.Evidence.deleteMinGrade or 1) then
        return
    end

    local info = _evidence[stashId]
    if not info then
        TriggerClientEvent('esx:showNotification', src, "~r~Coffre introuvable.")
        return
    end

    -- Charger l'inventaire (si pas déjà chargé)
    local inv = exports.ox_inventory:GetInventory(stashId, false)
    -- Compter les items
    local items = exports.ox_inventory:GetInventoryItems(stashId, false) or {}
    local hasItems = next(items) ~= nil

    if hasItems and not force then
        TriggerClientEvent('esx:showNotification', src, "~y~Le coffre contient encore des objets. Utilise la suppression forcée.")
        return
    end

    -- 1) Vider l'inventaire
    exports.ox_inventory:ClearInventory(stashId)

    -- 2) Verrouiller le stash pour la session en cours (personne ne pourra l'ouvrir)
    --    On réenregistre le même ID avec aucun accès + coords absurdes
    local lockedLabel = ('[SUPPRIMÉ] %s'):format(info.label)
    exports.ox_inventory:RegisterStash(
        stashId,
        lockedLabel,
        1,              -- 1 slot
        1,              -- 1g
        false,
        { ['__deleted__'] = 999 }, -- aucun job ne possèdera ce groupe
        vec3(9999.0, 9999.0, 999.0) -- loin de tout
    )

    -- 3) Retirer de la persistance (ne sera plus recréé au prochain restart)
    _evidence[stashId] = nil
    saveEvidence()

    -- 4) Log + notif
    sendWebhook("Coffre Evidence supprimé", ("**ID :** `%s`\n**Affaire :** %s\n**Suspect :** %s\n**Par :** %s%s"):format(
        stashId, info.caseId or "—", info.suspect or "—", (xPlayer.getName and xPlayer.getName()) or ('ID %d'):format(src),
        hasItems and " (FORCE)" or ""
    ))

    TriggerClientEvent('esx:showNotification', src, "~g~Coffre supprimé.")
end)

-- (Optionnel) Commande staff
RegisterCommand('evidence_delete', function(source, args)
    local id = args[1]
    local force = args[2] == 'force'
    if not id then
        TriggerClientEvent('esx:showNotification', source, "~y~Usage: /evidence_delete <stashId> [force]")
        return
    end
    TriggerEvent('bcso:evidence:delete', id, force)
end, true)



RegisterServerEvent("bcso:AnnounceService")
AddEventHandler("bcso:AnnounceService", function(status)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if xPlayer and xPlayer.job.name == "bcso" then
        local name = xPlayer.getName()
        local message = ("👮 Service bcso\n%s a %s."):format(name, status)

        -- Envoie à tous les joueurs
        for _, playerId in ipairs(ESX.GetPlayers()) do
            TriggerClientEvent("esx:showNotification", playerId, message)
        end
    end
end)

RegisterServerEvent('renfort')
AddEventHandler('renfort', function(coords, raison)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local xPlayers = ESX.GetPlayers()

    local safeCoords = vector3(coords.x, coords.y, coords.z)

    for i = 1, #xPlayers do
        local targetId = xPlayers[i]
        local thePlayer = ESX.GetPlayerFromId(targetId)

        if thePlayer and thePlayer.job.name == 'bcso' then
            -- Blip sur la map
            TriggerClientEvent('renfort:setBlip', targetId, safeCoords, raison)

            -- Notification texte
            local notif = ("🚨 Demande de renfort\nUnité : %s\nType : %s\nLocalisation transmise à l'unité."):format(
                xPlayer.getName() or "Inconnu",
                raison
            )
            TriggerClientEvent('esx:showNotification', targetId, notif)
        end
    end
end)

RegisterServerEvent('Bcsojob:PriseEtFinservice')
AddEventHandler('Bcsojob:PriseEtFinservice', function(PriseOuFin)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local name = xPlayer and xPlayer.getName() or "Inconnu"
    for _, playerId in ipairs(ESX.GetPlayers()) do
        local targetPlayer = ESX.GetPlayerFromId(playerId)
        if targetPlayer and targetPlayer.job.name == 'bcso' then
            TriggerClientEvent("esx:showNotification", playerId, ("📻 Radio %s a %s."):format(name, PriseOuFin))
        end
    end
end)



ESX.RegisterServerCallback('Bcsojob:getVehicleInfos', function(source, cb, plate)
	MySQL.Async.fetchAll('SELECT owner, vehicle FROM owned_vehicles WHERE plate = @plate', {['@plate'] = plate}, function(result)
		local retrivedInfo = {plate = plate}
		if result[1] then
			MySQL.Async.fetchAll('SELECT firstname, lastname FROM users WHERE identifier = @identifier',  {['@identifier'] = result[1].owner}, function(result2)
				retrivedInfo.owner = result2[1].firstname .. ' ' .. result2[1].lastname
				cb(retrivedInfo)
			end)
		else
			cb(retrivedInfo)
		end
	end)
end)

RegisterServerEvent('Bcsojob:drag')
AddEventHandler('Bcsojob:drag', function(target)
  local _source = source
  TriggerClientEvent('Bcsojob:drag', target, _source)
end)

RegisterServerEvent('Bcsojob:handcuff')
AddEventHandler('Bcsojob:handcuff', function(target)
  TriggerClientEvent('Bcsojob:handcuff', target)
end)


RegisterServerEvent('Bcsojob:putInVehicle')
AddEventHandler('Bcsojob:putInVehicle', function(target)
  TriggerClientEvent('Bcsojob:putInVehicle', target)
end)

RegisterServerEvent('Bcsojob:OutVehicle')
AddEventHandler('Bcsojob:OutVehicle', function(target)
    TriggerClientEvent('Bcsojob:OutVehicle', target)
end)

-- Boss

-- Boss - retrait
RegisterServerEvent('bcso:withdrawMoney')
AddEventHandler('bcso:withdrawMoney', function(societybcso, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    local src = source

    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. societybcso, function(account)
        if account then
            amount = tonumber(amount) or 0
            if amount <= 0 then
                return TriggerClientEvent("esx:showNotification", src, "Montant invalide.")
            end

            if account.money >= amount then
                account.removeMoney(amount)
                xPlayer.addMoney(amount)
                TriggerClientEvent("esx:showNotification", src, ("- Retiré\n- Somme : %s$"):format(amount))

                -- 🔔 PUSH solde actualisé
                TriggerClientEvent('bcso:societyUpdated', src, account.money)
            else
                TriggerClientEvent("esx:showNotification", src, "- Pas assez d'argent dans la société.")
            end
        else
            TriggerClientEvent("esx:showNotification", src, "Compte société introuvable.")
        end
    end)
end)

-- Boss - dépôt
RegisterServerEvent('bcso:depositMoney')
AddEventHandler('bcso:depositMoney', function(societybcso, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    local src = source

    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. societybcso, function(account)
        if account then
            amount = tonumber(amount) or 0
            if amount <= 0 then
                return TriggerClientEvent("esx:showNotification", src, "Montant invalide.")
            end

            local money = xPlayer.getMoney()
            if money >= amount then
                xPlayer.removeMoney(amount)
                account.addMoney(amount)
                TriggerClientEvent("esx:showNotification", src, ("- Déposé\n- Somme : %s$"):format(amount))

                -- 🔔 PUSH solde actualisé
                TriggerClientEvent('bcso:societyUpdated', src, account.money)
            else
                TriggerClientEvent("esx:showNotification", src, "- Pas assez d'argent sur vous.")
            end
        else
            TriggerClientEvent("esx:showNotification", src, "Compte société introuvable.")
        end
    end)
end)

-- ✅ FIX callback argent société
ESX.RegisterServerCallback('bcso:getSocietyMoney', function(source, cb, societybcso)
    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. societybcso, function(account)
        if account then
            cb(account.money or 0)
        else
            cb(0)
        end
    end)
end)


-- SV/API : appliquer une amende et créditer la société bcso
RegisterNetEvent('bcso:SendFacture', function(target, price)
    local src = source
    local officer = ESX.GetPlayerFromId(src)

    -- ✅ Sécurité : seul le job bcso peut facturer
    if not officer or not officer.job or officer.job.name ~= 'bcso' then
        TriggerEvent("AC:Violations", 24, ("Event: bcso:SendFacture job: %s"):format(officer and officer.job and officer.job.name or 'nil'), src)
        return
    end

    price = tonumber(price) or 0
    if price <= 0 then
        return TriggerClientEvent("esx:showNotification", src, "Montant invalide.")
    end

    local targetX = ESX.GetPlayerFromId(tonumber(target) or -1)
    if not targetX then
        return TriggerClientEvent("esx:showNotification", src, "Cible introuvable / déconnectée.")
    end

    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_bcso', function(account)
        if not account then
            return TriggerClientEvent("esx:showNotification", src, "Compte société introuvable (society_bcso).")
        end

        targetX.removeAccountMoney('money', price) -- adapte si tu utilises 'bank' au lieu de 'money'
        account.addMoney(price)

        TriggerClientEvent("esx:showNotification", targetX.source, ("Votre compte a été débité de ~r~%s$~s~."):format(price))
        TriggerClientEvent("esx:showNotification", src, ("Amende de ~r~%s$~s~ appliquée."):format(price))

        -- Optionnel : push du solde après facture si l'officier a le menu ouvert
        TriggerClientEvent('bcso:societyUpdated', src, account.money)
    end)
end)


local ox_inventory = exports.ox_inventory

-- =======================
-- Helpers notifications ESX
-- =======================
local function notifyESX(target, message)
    if not target or not message then return end
    TriggerClientEvent('esx:showNotification', target, message)
end

-- esx:showAdvancedNotification(title, subject, msg, icon, iconType)
-- iconType: 1 = chat, 4 = message, 8 = phone (selon HUD)
local function notifyESXAdvanced(target, title, subject, message, icon, iconType)
    if not target then return end
    TriggerClientEvent('esx:showAdvancedNotification', target, title or '', subject or '', message or '', icon or 'CHAR_DEFAULT', iconType or 1)
end

-- =======================
-- Gestion RH bcso
-- =======================

-- Recruter (grade 0)
RegisterServerEvent('bcso:recruterpoli')
AddEventHandler('bcso:recruterpoli', function(target)
    local src = source
    local sourceXPlayer = ESX.GetPlayerFromId(src)
    if not sourceXPlayer then return end

    if sourceXPlayer.getJob().grade_name == 'boss' then
        local targetXPlayer = ESX.GetPlayerFromId(target)
        if not targetXPlayer then return end

        targetXPlayer.setJob(sourceXPlayer.getJob().name, 0)

        notifyESXAdvanced(src, "Recrutement", "", ("Vous avez recruté %s"):format(targetXPlayer.getName()), "CHAR_CALL911", 8)
        notifyESXAdvanced(target, "Recrutement", "", ("Vous avez été recruté par %s"):format(sourceXPlayer.getName()), "CHAR_CALL911", 8)
    else
        notifyESX(src, "Vous n'avez pas l'autorisation.")
    end
end)

-- Licencier
RegisterServerEvent('bcso:virerpoli')
AddEventHandler('bcso:virerpoli', function(target)
    local src = source
    local sourceXPlayer = ESX.GetPlayerFromId(src)
    local targetXPlayer = ESX.GetPlayerFromId(target)
    if not sourceXPlayer or not targetXPlayer then return end

    if sourceXPlayer.getJob().grade_name == 'boss' and sourceXPlayer.getJob().name == targetXPlayer.getJob().name then
        targetXPlayer.setJob('unemployed', 0)

        notifyESXAdvanced(src, "Licenciement", "", ("Vous avez viré %s"):format(targetXPlayer.getName()), "CHAR_CALL911", 8)
        notifyESXAdvanced(target, "Licenciement", "", ("Vous avez été viré par %s"):format(sourceXPlayer.getName()), "CHAR_CALL911", 8)
    else
        notifyESX(src, "Vous n'avez pas l'autorisation.")
    end
end)

-- Novice (grade 1)
RegisterServerEvent('bcso:novicepoli')
AddEventHandler('bcso:novicepoli', function(target)
    local src = source
    local sourceXPlayer = ESX.GetPlayerFromId(src)
    if not sourceXPlayer then return end

    if sourceXPlayer.getJob().grade_name == 'boss' then
        local targetXPlayer = ESX.GetPlayerFromId(target)
        if not targetXPlayer then return end

        targetXPlayer.setJob(sourceXPlayer.getJob().name, 1)
        notifyESXAdvanced(src, "Promotion", "", ("%s promu au grade Novice"):format(targetXPlayer.getName()), "CHAR_CALL911", 8)
        notifyESXAdvanced(target, "Promotion", "", ("Vous avez été promu au grade Novice par %s"):format(sourceXPlayer.getName()), "CHAR_CALL911", 8)
    else
        notifyESX(src, "Vous n'avez pas l'autorisation.")
    end
end)

-- Expérimenté (grade 2)
RegisterServerEvent('bcso:experimentepoli')
AddEventHandler('bcso:experimentepoli', function(target)
    local src = source
    local sourceXPlayer = ESX.GetPlayerFromId(src)
    if not sourceXPlayer then return end

    if sourceXPlayer.getJob().grade_name == 'boss' then
        local targetXPlayer = ESX.GetPlayerFromId(target)
        if not targetXPlayer then return end

        targetXPlayer.setJob(sourceXPlayer.getJob().name, 2)
        notifyESXAdvanced(src, "Promotion", "", ("%s promu au grade Expérimenté"):format(targetXPlayer.getName()), "CHAR_CALL911", 8)
        notifyESXAdvanced(target, "Promotion", "", ("Vous avez été promu au grade Expérimenté par %s"):format(sourceXPlayer.getName()), "CHAR_CALL911", 8)
    else
        notifyESX(src, "Vous n'avez pas l'autorisation.")
    end
end)

-- Chef (grade 3)
RegisterServerEvent('bcso:chiefpoli')
AddEventHandler('bcso:chiefpoli', function(target)
    local src = source
    local sourceXPlayer = ESX.GetPlayerFromId(src)
    if not sourceXPlayer then return end

    if sourceXPlayer.getJob().grade_name == 'boss' then
        local targetXPlayer = ESX.GetPlayerFromId(target)
        if not targetXPlayer then return end

        targetXPlayer.setJob(sourceXPlayer.getJob().name, 3)
        notifyESXAdvanced(src, "Promotion", "", ("%s promu au grade Chef"):format(targetXPlayer.getName()), "CHAR_CALL911", 8)
        notifyESXAdvanced(target, "Promotion", "", ("Vous avez été promu au grade Chef par %s"):format(sourceXPlayer.getName()), "CHAR_CALL911", 8)
    else
        notifyESX(src, "Vous n'avez pas l'autorisation.")
    end
end)

-- =======================
-- Liste des employés (callback)
-- =======================
ESX.RegisterServerCallback('getBcsoEmployees', function(source, cb)
    local xPlayers = ESX.GetExtendedPlayers('job', 'bcso') -- ESX Legacy
    local employees = {}

    for _, xPlayer in pairs(xPlayers) do
        table.insert(employees, {
            name = xPlayer.getName(),
            grade = xPlayer.job.grade_label
        })
    end

    cb(employees)
end)

local ox = exports.ox_inventory

local function normalizeWeaponName(name)
    return (ConfigBcso.WeaponAliases and ConfigBcso.WeaponAliases[name]) or name
end

-- Don d'équipement (sécurisé : on ne fait pas confiance au grade client)
local function giveEquipment(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end

    local grade = xPlayer.getJob() and xPlayer.getJob().grade or 0
    local equipment = ConfigBcso.EquipmentByGrade[grade]
    if not equipment or not equipment.items then return end

    for _, it in ipairs(equipment.items) do
        local name     = normalizeWeaponName(it.name)
        local count    = tonumber(it.count) or 1
        local metadata = it.metadata or ((name:find('ammo', 1, true) and ConfigBcso.BuildAmmoMetadata and ConfigBcso.BuildAmmoMetadata(playerId)) or (ConfigBcso.BuildWeaponMetadata and ConfigBcso.BuildWeaponMetadata(playerId)) or nil)

        if ox:CanCarryItem(playerId, name, count, metadata) then
            ox:AddItem(playerId, name, count, metadata)
        else
            notifyESX(playerId, ('~r~Pas de place pour %s x%d'):format(name, count))
        end
    end

    notifyESX(playerId, ("Vous avez reçu votre équipement de %s"):format(equipment.label or "service"))
end

RegisterNetEvent('armorybcso:giveEquipment', function()
    giveEquipment(source)
end)

-- Armurerie : donner des munitions pour l’arme choisie
RegisterServerEvent('bcso:armurerieMunitions')
AddEventHandler('bcso:armurerieMunitions', function(weapon)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    weapon = normalizeWeaponName(weapon)
    local ammoType = ConfigBcso.AmmoTypeByWeapon[weapon]
    if not ammoType then
        notifyESXAdvanced(src, "Armurerie", "", "Type de munitions inconnu pour cette arme.", "CHAR_AMMUNATION", 8)
        return
    end

    local amount = (ConfigBcso.Munitions and ConfigBcso.Munitions[weapon]) or 0
    if amount <= 0 then
        notifyESXAdvanced(src, "Armurerie", "", "Quantité de munitions non configurée.", "CHAR_AMMUNATION", 8)
        return
    end

    local metadata = ConfigBcso.BuildAmmoMetadata and ConfigBcso.BuildAmmoMetadata(src) or nil
    if ox:CanCarryItem(src, ammoType, amount, metadata) then
        ox:AddItem(src, ammoType, amount, metadata)
        notifyESXAdvanced(src, "Armurerie", "", ("Vous avez reçu %d munitions (%s)."):format(amount, ammoType), "CHAR_AMMUNATION", 8)
    else
        notifyESXAdvanced(src, "Armurerie", "", "Pas assez de place dans l'inventaire.", "CHAR_AMMUNATION", 8)
    end
end)

-- ===== Rendu de l'équipement (armes + munitions avec priorités) =====
local function metaMatch(meta, filter)
    if filter == nil then return true end
    for k, v in pairs(filter) do
        if not meta or meta[k] ~= v then return false end
    end
    return true
end

local function removeItemByFilters(src, item, need, filters)
    local left = need
    local slots = ox:Search(src, 'slots', item) or {}
    for _, it in ipairs(slots) do
        for _, f in ipairs(filters or {nil}) do
            if metaMatch(it.metadata, f) then
                local take = math.min(left, it.count)
                if take > 0 then
                    ox:RemoveItem(src, item, take, it.metadata, it.slot)
                    left = left - take
                end
                break
            end
        end
        if left <= 0 then break end
    end
    return left <= 0
end

RegisterNetEvent(ConfigBcso.RemoveItemEvent)
AddEventHandler(ConfigBcso.RemoveItemEvent, function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    -- Armes
    for _, w in ipairs(ConfigBcso.WeaponsToRemove or {}) do
        local name     = normalizeWeaponName(type(w) == 'table' and w.item or w)
        local metadata = type(w) == 'table' and w.metadata or nil

        if metadata then
            local removed = false
            local slots = ox:Search(src, 'slots', name) or {}
            for _, it in ipairs(slots) do
                if metaMatch(it.metadata, metadata) then
                    if ox:RemoveItem(src, name, 1, it.metadata, it.slot) then
                        removed = true
                        break
                    end
                end
            end
            if not removed then ox:RemoveItem(src, name, 1) end -- fallback
        else
            ox:RemoveItem(src, name, 1)
        end
    end

    -- Munitions
    for _, a in ipairs(ConfigBcso.AmmoToRemove or {}) do
        local item    = a.item or a[1]
        local count   = tonumber(a.count or a[2] or 0) or 0
        local filters = a.filters
        if item and count > 0 then
            local ok = removeItemByFilters(src, item, count, filters)
            if not ok then ox:RemoveItem(src, item, count) end
        end
    end

    notifyESX(src, "Équipement rendu.")
end)




local function GetActualTime() 
	date = os.date('*t')
	if date.day < 10 then date.day = '0' .. tostring(date.day) end
	if date.month < 10 then date.month = '0' .. tostring(date.month) end
	if date.hour < 10 then date.hour = '0' .. tostring(date.hour) end
	if date.min < 10 then date.min = '0' .. tostring(date.min) end
	if date.sec < 10 then date.sec = '0' .. tostring(date.sec) end

	date = "" .. date.day .. "/" .. date.month .. "/" .. date.year .. " - " .. math.floor(date.hour + 2) .. ":" .. date.min .. ":" .. date.sec 
	return date
end

RegisterNetEvent("tan:create")
AddEventHandler("tan:create", function(nameSuspect, ageSuspect, heightSuspect, nationalitySuspect, sexSuspect)
	local __src = source 
	local casierData = {}
	MySQL.Async.fetchAll("SELECT * FROM criminal_records WHERE name = @name", {
		["name"] = nameSuspect
	}, function(casierData)
		if casierData[1] == nil then
			TriggerClientEvent('esx:showAdvancedNotification', __src, "Casier Judiciaire", "~g~Succès", "Le Casier Judiciaire a bien été crée au nom de : ~g~"..nameSuspect, 'CHAR_ARIAM', 0)
	MySQL.Async.execute("INSERT INTO criminal_records (depositary, name, age, height, nationality, sex, date) VALUES (@a, @b, @c, @d, @e, @f, @g)", {
		["a"] = GetPlayerName(__src),
		["b"] = nameSuspect,
		["c"] = ageSuspect,
		["d"] = heightSuspect,
		["e"] = nationalitySuspect,
		["f"] = sexSuspect,
		["g"] = GetActualTime()
	})
	local logs = {{ ["author"] = { ["name"] = "🌌 RFS Store", ["icon_url"] = "https://media.discordapp.net/attachments/976967293793886258/976968665360654356/rfs_plus_groe.png" }, ["thumbnail"] = { ["url"] = "https://media.discordapp.net/attachments/976967293793886258/976968665360654356/rfs_plus_groe.png" }, ["color"] = "7419530", ["title"] = Title, ["description"] = "Casier Crée : "..nameSuspect.."\nAuteur de la Création : "..GetPlayerName(__src).."["..__src.."]", ["footer"] = { ["text"] = GetActualTime(), ["icon_url"] = nil }, } }
            PerformHttpRequest(configuration.webhook.createCasier, function(err, text, headers) end, 'POST', json.encode({username = "LogsBot", embeds = logs, avatar_url = "https://media.discordapp.net/attachments/976967293793886258/976968665360654356/rfs_plus_groe.png" }), { ['Content-Type'] = 'application/json' })
else
	TriggerClientEvent('esx:showAdvancedNotification', __src, "Casier Judiciaire", "~r~Echec", "Cet individu (~g~"..nameSuspect.."~s~) possède déjà un casier !", 'CHAR_ARIAM', 0)
end
end)
end)


ESX.RegisterServerCallback("tan:getList", function(source, cb)
	totalCasierData = {}
	MySQL.Async.fetchAll("SELECT * FROM criminal_records", {}, function(data)
		for _, v in pairs(data) do
		table.insert(totalCasierData, {name = v.name, age = v.age, depositary = v.depositary, height = v.height, nationality = v.nationality, sex = v.sex, date = v.date})
		end 
	cb(totalCasierData)
	end)
end)

RegisterNetEvent("tan:deletecasier")
AddEventHandler("tan:deletecasier", function(name)
	local __src = source
	MySQL.Async.execute("DELETE FROM criminal_records WHERE name = @a", {
		["a"] = name
	})
	local logs = {{ ["author"] = { ["name"] = "🌌 RFS Store", ["icon_url"] = "https://media.discordapp.net/attachments/976967293793886258/976968665360654356/rfs_plus_groe.png" }, ["thumbnail"] = { ["url"] = "https://media.discordapp.net/attachments/976967293793886258/976968665360654356/rfs_plus_groe.png" }, ["color"] = "7419530", ["title"] = Title, ["description"] = "Casier Supprimé : "..name.."\nAuteur de la Suppression : "..GetPlayerName(__src).."["..__src.."]", ["footer"] = { ["text"] = GetActualTime(), ["icon_url"] = nil }, } }
            PerformHttpRequest(configuration.webhook.supprCasier, function(err, text, headers) end, 'POST', json.encode({username = "LogsBot", embeds = logs, avatar_url = "https://media.discordapp.net/attachments/976967293793886258/976968665360654356/rfs_plus_groe.png" }), { ['Content-Type'] = 'application/json' })
end)


RegisterNetEvent("tan:addmotif")
AddEventHandler("tan:addmotif", function(name, motif)
	local __src = source
	MySQL.Async.execute("INSERT INTO criminal_records_content (depositary,name,motif,date) VALUES (@a,@b,@c,@d)", {
		["a"] = GetPlayerName(__src),
		["b"] = name,
		["c"] = motif,
		["d"] = GetActualTime()
	})
	local logs = {{ ["author"] = { ["name"] = "🌌 RFS Store", ["icon_url"] = "https://media.discordapp.net/attachments/976967293793886258/976968665360654356/rfs_plus_groe.png" }, ["thumbnail"] = { ["url"] = "https://media.discordapp.net/attachments/976967293793886258/976968665360654356/rfs_plus_groe.png" }, ["color"] = "7419530", ["title"] = Title, ["description"] = "Casier : "..name.."\nMotif Ajouté : "..motif.."\nAuteur de l'Ajout : "..GetPlayerName(__src), ["footer"] = { ["text"] = GetActualTime(), ["icon_url"] = nil }, } }
            PerformHttpRequest(configuration.webhook.addMotif, function(err, text, headers) end, 'POST', json.encode({username = "LogsBot", embeds = logs, avatar_url = "https://media.discordapp.net/attachments/976967293793886258/976968665360654356/rfs_plus_groe.png" }), { ['Content-Type'] = 'application/json' })
end)

ESX.RegisterServerCallback("tan:getList", function(source, cb)
	totalCasierData = {}
	MySQL.Async.fetchAll("SELECT * FROM criminal_records", {}, function(data)
		for _, v in pairs(data) do
		table.insert(totalCasierData, {name = v.name, age = v.age, depositary = v.depositary, height = v.height, nationality = v.nationality, sex = v.sex, date = v.date})
		end 
	cb(totalCasierData)
	end)
end)

casiera = nil
RegisterNetEvent("actualCasier:selected")
AddEventHandler("actualCasier:selected", function(name)
	casiera = name
end)

ESX.RegisterServerCallback("tan:getCasier", function(source, cb)
	motifData = {}
	MySQL.Async.fetchAll("SELECT * FROM criminal_records_content WHERE name = @a", {["@a"] = casiera}, function(data)
		for _, v in pairs(data) do
		table.insert(motifData, {depositary = v.depositary, name = v.name, motif = v.motif, date = v.date})
		end 
	cb(motifData)
	end)
end)

RegisterNetEvent("edit:motif")
AddEventHandler("edit:motif", function(name, lastMotif ,newMotif)
	local __src = source
	MySQL.Async.execute("UPDATE criminal_records_content SET motif = @a WHERE name = @b and motif = @c", {
		["a"] = newMotif,
		["b"] = name,
		["c"] = lastMotif
	})
	local logs = {{ ["author"] = { ["name"] = "🌌 RFS Store", ["icon_url"] = "https://media.discordapp.net/attachments/976967293793886258/976968665360654356/rfs_plus_groe.png" }, ["thumbnail"] = { ["url"] = "https://media.discordapp.net/attachments/976967293793886258/976968665360654356/rfs_plus_groe.png" }, ["color"] = "7419530", ["title"] = Title, ["description"] = "Casier : "..name.."\nAvant Modification : "..lastMotif.."\nAprès Modification : "..newMotif.."\nAuteur de la Modification : "..GetPlayerName(__src), ["footer"] = { ["text"] = GetActualTime(), ["icon_url"] = nil }, } }
            PerformHttpRequest(configuration.webhook.editMotif, function(err, text, headers) end, 'POST', json.encode({username = "LogsBot", embeds = logs, avatar_url = "https://media.discordapp.net/attachments/976967293793886258/976968665360654356/rfs_plus_groe.png" }), { ['Content-Type'] = 'application/json' })
end)

RegisterNetEvent("delete:motif")
AddEventHandler("delete:motif", function(name, motif)
	local __src = source
	MySQL.Async.execute("DELETE FROM criminal_records_content WHERE name = @name and motif = @motif", {
		["name"] = name, 
		["motif"] = motif
	})
	local logs = {{ ["author"] = { ["name"] = "🌌 RFS Store", ["icon_url"] = "https://media.discordapp.net/attachments/976967293793886258/976968665360654356/rfs_plus_groe.png" }, ["thumbnail"] = { ["url"] = "https://media.discordapp.net/attachments/976967293793886258/976968665360654356/rfs_plus_groe.png" }, ["color"] = "7419530", ["title"] = Title, ["description"] = "Casier : "..name.."\nMotif Supprimé : "..motif.."\nAuteur de la Suppression : "..GetPlayerName(__src), ["footer"] = { ["text"] = GetActualTime(), ["icon_url"] = nil }, } }
            PerformHttpRequest(configuration.webhook.supprMotif, function(err, text, headers) end, 'POST', json.encode({username = "LogsBot", embeds = logs, avatar_url = "https://media.discordapp.net/attachments/976967293793886258/976968665360654356/rfs_plus_groe.png" }), { ['Content-Type'] = 'application/json' })
end)

RegisterNetEvent("delete:allmotif")
AddEventHandler("delete:allmotif", function(name)
	MySQL.Async.execute("DELETE FROM criminal_records_content WHERE name = @name", {
		["name"] = name
	})
end)
