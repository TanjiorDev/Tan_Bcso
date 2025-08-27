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

local bossMenu       = zUI.CreateMenu("MENU BCSO","INTERACTIONS", "Intéractions BCSO :", ConfigBcso.themes)
local employeesMenu  = zUI.CreateSubMenu(bossMenu,"MENU BCSO","INTERACTIONS", "Intéractions BCSO :", ConfigBcso.themes)
local listMenu       = zUI.CreateSubMenu(employeesMenu,"MENU BCSO","INTERACTIONS", "Intéractions BCSO :", ConfigBcso.themes)

local societybcso  = "Chargement..."
local bcsoEmployees = {}

-- === MENUS ===
zUI.SetItems(bossMenu, function()
    zUI.Separator("Gestion de l'entreprise")
    zUI.Separator(("Coffre : %s $"):format(societybcso or "Chargement..."))

    -- Retrait
    zUI.Button("Retirer de l'argent", nil, {}, function(onSelected)
        if not onSelected then return end
            local playerPed = PlayerPedId()

            -- ❄️ Geler le joueur
            FreezeEntityPosition(playerPed, true)
            SetEntityInvincible(playerPed, true)

            -- ✅ Bloquer seulement les mouvements (conserve la caméra + ox_target)
            SetPlayerControl(PlayerId(), false, 2) -- 2 = désactive déplacement/sprint/saut, pas la caméra

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
            Wait(300)
            RefreshMoney()
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

            -- ✅ Bloquer seulement les mouvements (conserve la caméra + ox_target)
            SetPlayerControl(PlayerId(), false, 2) -- 2 = désactive déplacement/sprint/saut, pas la caméra

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
            Wait(300)
            RefreshMoney()
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
        TriggerServerEvent("tanjiro:Recruter", GetPlayerServerId(closestPlayer))
        ESX.ShowNotification("Joueur recruté")
        Wait(300)
        GetBcsoEmployees()
    end)

    zUI.Button("Promouvoir (Chef d'équipe)", nil, {}, function(onSelected)
        if not onSelected then return end
        local closestPlayer, dist = ESX.Game.GetClosestPlayer()
        if closestPlayer == -1 or dist > 3.0 then
            ESX.ShowNotification("Aucun joueur proche")
            return
        end
        TriggerServerEvent("tanjiro:chiefpoli", GetPlayerServerId(closestPlayer))
        ESX.ShowNotification("Joueur promu")
        Wait(300)
        GetBcsoEmployees()
    end)

    zUI.Button("Virer un employé", nil, {}, function(onSelected)
        if not onSelected then return end
        local closestPlayer, dist = ESX.Game.GetClosestPlayer()
        if closestPlayer == -1 or dist > 3.0 then
            ESX.ShowNotification("Aucun joueur proche")
            return
        end
        TriggerServerEvent("tanjiro:virerpoli", GetPlayerServerId(closestPlayer))
        ESX.ShowNotification("Joueur viré")
        Wait(300)
        GetBcsoEmployees()
    end)

    zUI.Button("Liste des employés", nil, {}, function() end, listMenu)
end)

-- ⚠️ Ici on boucle correctement sur bcsoEmployees
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
    if ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name == "bcso" and ESX.PlayerData.job.grade_name == "boss" then
        ESX.TriggerServerCallback("bcso:getSocietyMoney", function(money)
            -- money peut être nil si la société n’existe pas encore côté serveur
            local m = tonumber(money or 0) or 0
            societybcso = ESX.Math.GroupDigits(m)
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
    groups = ConfigBcso.Boss.BcsoBoss.society,
    options = {
        {
            name = ConfigBcso.Boss.BcsoBoss.bossMenu.name,
            icon = ConfigBcso.Boss.BcsoBoss.bossMenu.icon,
            label = ConfigBcso.Boss.BcsoBoss.bossMenu.label,
            distance = ConfigBcso.Boss.BcsoBoss.bossMenu.distance,
            canInteract = function()
                local data = ESX.PlayerData or ESX.GetPlayerData()
                if not data or not data.job then return false end
                local okJob = (data.job.name == (ConfigBcso.JobRequired or "bcso"))
                local okGrade = (data.job.grade or 0) >= (ConfigBcso.Boss.BcsoBoss.bossMenu.requiredGrade or 0)
                return okJob and okGrade
            end,
            onSelect = function()
                bossbcso()
            end
        }
    }
})

function bossbcso()
    RefreshMoney()
    GetBcsoEmployees()
    zUI.SetVisible(bossMenu, not zUI.IsVisible(bossMenu))
end
