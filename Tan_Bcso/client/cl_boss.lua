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

local bossMenubcso   = zUI.CreateMenu("MENU bcso","INTERACTIONS", "Intéractions bcso :", ConfigBcso.themes)
local employeesMenu  = zUI.CreateSubMenu(bossMenubcso,"MENU bcso","INTERACTIONS", "Intéractions bcso :", ConfigBcso.themes)
local listMenu       = zUI.CreateSubMenu(employeesMenu,"MENU bcso","INTERACTIONS", "Intéractions bcso :", ConfigBcso.themes)

local societybcso  = "Chargement..."
local bcsoEmployees = {}

-- 🔔 Reçoit le nouveau solde et met à jour l’affichage
-- garde cet event pour rafraîchir le texte en live après dépôt/retrait
AddEventHandler('bcso:societyUpdated', function(newMoney)
    local m = tonumber(newMoney or 0) or 0
    societybcso = ESX.Math.GroupDigits(m)

    if zUI.IsVisible(bossMenubcso) then
        -- si zUI a une API de refresh, utilise-la; sinon petit toggle
        zUI.SetVisible(bossMenubcso, false)
        Wait(0)
        zUI.SetVisible(bossMenubcso, true)
    end
end)


-- === MENUS ===
zUI.SetItems(bossMenubcso, function()
    zUI.Separator("Gestion de l'entreprise")
    zUI.Separator(("Coffre : %s $"):format(societybcso or "Chargement..."))

    -- Retrait
    zUI.Button("Retirer de l'argent", nil, {}, function(onSelected)
        if not onSelected then return end
        local playerPed = PlayerPedId()

        -- ❄️ Geler le joueur
        FreezeEntityPosition(playerPed, true)
        SetEntityInvincible(playerPed, true)
        SetPlayerControl(PlayerId(), false, 2) -- désactive mouvements uniquement

        local input = lib.inputDialog('💵 Retrait Société', {
            { type = 'number', label = 'Montant à retirer', description = 'Indiquez le montant à retirer', icon = 'fa-solid fa-money-bill', required = true, min = 1 }
        })

        -- 🔓 Défreeze proprement
        FreezeEntityPosition(playerPed, false)
        SetEntityInvincible(playerPed, false)
        SetPlayerControl(PlayerId(), true, 0)

        local montant = input and tonumber(input[1] or 0)
        if montant and montant > 0 then
            TriggerServerEvent("bcso:withdrawMoney", ESX.PlayerData.job.name, montant)
            ESX.ShowNotification(("Vous avez retiré : %s$"):format(montant))
            -- Fallback si jamais le push n'arrive pas (rare) :
            SetTimeout(400, RefreshMoney)
        else
            ESX.ShowNotification("Montant invalide.")
        end
    end)

    -- Dépôt
    zUI.Button("Déposer de l'argent", nil, {}, function(onSelected)
        if not onSelected then return end
        local playerPed = PlayerPedId()

        -- ❄️ Geler le joueur
        FreezeEntityPosition(playerPed, true)
        SetEntityInvincible(playerPed, true)
        SetPlayerControl(PlayerId(), false, 2)

        local input = lib.inputDialog('💵 Dépôt Société', {
            { type = 'number', label = 'Montant à déposer', description = 'Indiquez le montant à déposer', icon = 'fa-solid fa-money-bill', required = true, min = 1 }
        })

        -- 🔓 Défreeze proprement
        FreezeEntityPosition(playerPed, false)
        SetEntityInvincible(playerPed, false)
        SetPlayerControl(PlayerId(), true, 0)

        local montant = input and tonumber(input[1] or 0)
        if montant and montant > 0 then
            TriggerServerEvent("bcso:depositMoney", ESX.PlayerData.job.name, montant)
            ESX.ShowNotification(("Vous avez déposé : %s$"):format(montant))
            -- Fallback si jamais le push n'arrive pas (rare) :
            SetTimeout(400, RefreshMoney)
        else
            ESX.ShowNotification("Montant invalide.")
        end
    end)

    zUI.Button("Gestion des employés", nil, {}, function() end, employeesMenu)
end)

zUI.SetItems(employeesMenu, function()
    zUI.Button("Recruter", nil, {}, function(onSelected)
        if not onSelected then return end
        local closestPlayer, dist = ESX.Game.GetClosestPlayer()
        if closestPlayer == -1 or dist > 3.0 then
            ESX.ShowNotification("Aucun joueur proche")
            return
        end
        TriggerServerEvent("bcso:Recruter", GetPlayerServerId(closestPlayer))
        ESX.ShowNotification("Joueur recruté")
        SetTimeout(300, GetBcsoEmployees)
    end)

    zUI.Button("Promouvoir (Chef d'équipe)", nil, {}, function(onSelected)
        if not onSelected then return end
        local closestPlayer, dist = ESX.Game.GetClosestPlayer()
        if closestPlayer == -1 or dist > 3.0 then
            ESX.ShowNotification("Aucun joueur proche")
            return
        end
        TriggerServerEvent("bcso:chiefpoli", GetPlayerServerId(closestPlayer))
        ESX.ShowNotification("Joueur promu")
        SetTimeout(300, GetBcsoEmployees)
    end)

    zUI.Button("Virer un employé", nil, {}, function(onSelected)
        if not onSelected then return end
        local closestPlayer, dist = ESX.Game.GetClosestPlayer()
        if closestPlayer == -1 or dist > 3.0 then
            ESX.ShowNotification("Aucun joueur proche")
            return
        end
        TriggerServerEvent("bcso:virerpoli", GetPlayerServerId(closestPlayer))
        ESX.ShowNotification("Joueur viré")
        SetTimeout(300, GetBcsoEmployees)
    end)

    zUI.Button("Liste des employés", nil, {}, function() end, listMenu)
end)

-- ⚠️ Boucle propre sur bcsoEmployees
zUI.SetItems(listMenu, function()
    if type(bcsoEmployees) ~= 'table' or #bcsoEmployees == 0 then
        zUI.Separator("Chargement/Liste vide…")
        return
    end

    for i, emp in ipairs(bcsoEmployees) do
        local name = emp.name or emp.firstname and emp.lastname and (emp.firstname .. " " .. emp.lastname) or ("Employé #" .. i)
        local grade =
            emp.grade_label or
            (emp.job and (emp.job.grade_label or emp.job.grade_name)) or
            emp.grade or "?"

        zUI.Button(("%s [%s]"):format(name, grade), nil, {}, function(onSelected)
            if onSelected then
                ESX.ShowNotification(("Employé: %s | Grade: %s"):format(name, grade))
            end
        end)
    end
end)

-- === FONCTIONS ===
function RefreshMoney()
    local data = ESX.PlayerData or ESX.GetPlayerData()
    if data and data.job and data.job.name == "bcso" and (data.job.grade_name == "boss" or (data.job.grade or 0) >= (ConfigBcso.Boss.BcsoBoss.bossMenu.requiredGrade or 0)) then
        ESX.TriggerServerCallback("bcso:getSocietyMoney", function(money)
            local m = tonumber(money or 0) or 0
            societybcso = ESX.Math.GroupDigits(m)

            -- Forcer un refresh visuel si le menu est ouvert
            if zUI.IsVisible(bossMenubcso) then
                zUI.SetVisible(bossMenubcso, false)
                Wait(0)
                zUI.SetVisible(bossMenubcso, true)
            end
        end, "bcso")
    else
        societybcso = "Accès refusé"
    end
end

function GetBcsoEmployees()
    ESX.TriggerServerCallback("getBcsoEmployees", function(employees)
        bcsoEmployees = type(employees) == "table" and employees or {}
    end)
end

-- === OX_TARGET ===
exports.ox_target:addBoxZone({
    coords = ConfigBcso.Boss.BcsoBoss.coords,
    size = ConfigBcso.Boss.BcsoBoss.size,
    drawSprite = true,

    -- ✅ laisse ox_target filtrer job/grade avec le mapping ci-dessus
    groups = ConfigBcso.Boss.BcsoBoss.society,

    options = {
        {
            name = ConfigBcso.Boss.BcsoBoss.bossMenu.name,
            icon = ConfigBcso.Boss.BcsoBoss.bossMenu.icon,
            label = ConfigBcso.Boss.BcsoBoss.bossMenu.label,
            distance = ConfigBcso.Boss.BcsoBoss.bossMenu.distance,

            -- (optionnel) double sécurité côté client
            canInteract = function()
                local d = ESX.PlayerData or ESX.GetPlayerData()
                if not d or not d.job then return false end
                if d.job.name ~= (ConfigBcso.JobRequired or 'bcso') then return false end
                return (d.job.grade or 0) >= (ConfigBcso.Boss.BcsoBoss.bossMenu.requiredGrade or 0)
            end,

            onSelect = function()
                bossbcso()  -- (dans bossbcso, tu récupères le solde avant d’ouvrir)
            end
        }
    }
})


-- remplace ta fonction bossbcso() par ceci :
function bossbcso()
    -- Récupère le solde avant d'ouvrir le menu
    ESX.TriggerServerCallback("bcso:getSocietyMoney", function(money)
        local m = tonumber(money or 0) or 0
        societybcso = ESX.Math.GroupDigits(m)

        -- charge aussi la liste employés (asynchrone) puis ouvre
        GetBcsoEmployees()
        zUI.SetVisible(bossMenubcso, true)
    end, "bcso")
end


-- (Optionnel) Poll léger pendant l’ouverture du menu
CreateThread(function()
    while true do
        if zUI.IsVisible(bossMenubcso) then
            RefreshMoney()
            Wait(1500)
        else
            Wait(600)
        end
    end
end)
