ConfigBcso = {}
-- Metez le webhook de votre salon disocrd configure pour le job ems 
-- ✅ Valeurs par défaut si non définies
ConfigBcso.JobBcso = "bcso"  -- Nom du job si besoin
ConfigBcso.CommandeMenu = "bcsomenu"  -- Commande pour ouvrir le menu
ConfigBcso.ToucheMenu = "F6"  -- Touche d'accès rapide
ConfigBcso.themes = "default"

ConfigBcso.Notifications = {
    ox_lib = false,         -- true pour utiliser ox_lib
    vms_notifyv2 = false,   -- true pour utiliser vms_notifyv2
    esx_notify = true       -- true pour utiliser ESX notifications natives
}

-- 📌 Webhook Discord
ConfigBcso.WebhookURL = ""

-- 📌 Nom affiché dans Discord
ConfigBcso.WebhookName = "📅 RDV bcso"

-- 📌 Poste de bcso (interaction)
-- config.lua
ConfigBcso.BcsoStation = vec3(-447.639556, 6013.648438, 31.706176)
-- (vector3(...) marche aussi)


ConfigBcso.BcsoStations = {

	bcso = {

		Blip = {
			Coords  = vec3(-447.639556, 6013.648438, 31.706176),
			Sprite  = 60,
			Display = 4,
			Scale   = 0.5,
			Colour  = 5,
            Name    = "~g~Entreprise~s~ | BCSO"
		},
    }
}

--CriminalRecords

configuration = configuration or {}
configuration.casierBcso = {
    { pos = vector3(1851.513916,3691.647949,34.048328), size = vector3(1.8, 1.2, 2.0), heading = 0.0, label = "Ordinateur MRPD", debug = false },
    -- ajoute d'autres points si besoin...
    webhook = {
        ["createCasier"] = "",
        ["supprCasier"] = "", 
        ["addMotif"] = "", 
        ["supprMotif"] = "",
        ["editMotif"] = ""
    },
}

ConfigBcso.amende = {
    ["amende"] = {
        -- 🚦 Infractions routières légères
        {label = 'Usage abusif du klaxon', price = 100},
        {label = 'Franchir une ligne continue', price = 150},
        {label = 'Circulation à contresens', price = 250},
        {label = 'Demi-tour non autorisé', price = 200},
        {label = 'Circulation hors-route', price = 250},
        {label = 'Non-respect des distances de sécurité', price = 180},
        {label = 'Arrêt dangereux / interdit', price = 150},
        {label = 'Stationnement gênant / interdit', price = 100},

        -- 🚥 Priorités & feux
        {label = 'Non respect de la priorité à droite', price = 200},
        {label = 'Non-respect à un véhicule prioritaire', price = 300},
        {label = 'Non-respect d\'un stop', price = 250},
        {label = 'Non-respect d\'un feu rouge', price = 350},
        {label = 'Dépassement dangereux', price = 300},

        -- 🚗 Véhicule & permis
        {label = 'Véhicule non en état', price = 250},
        {label = 'Conduite sans permis', price = 1500},
        {label = 'Délit de fuite', price = 2000},


        -- 🚀 Excès de vitesse en ville
        {label = 'Ville - Excès de vitesse < 10 km/h', price = 100},
        {label = 'Ville - Excès de vitesse 10-20 km/h', price = 250},
        {label = 'Ville - Excès de vitesse 20-40 km/h', price = 600},
        {label = 'Ville - Excès de vitesse > 40 km/h', price = 1500},

        -- 🛣️ Excès de vitesse sur autoroute
        {label = 'Autoroute - Excès de vitesse < 10 km/h', price = 80},
        {label = 'Autoroute - Excès de vitesse 10-20 km/h', price = 200},
        {label = 'Autoroute - Excès de vitesse 20-40 km/h', price = 500},
        {label = 'Autoroute - Excès de vitesse > 40 km/h', price = 1200},
        {label = 'Autoroute - Excès de vitesse > 60 km/h', price = 2500},


        -- ⚖️ Divers
        {label = 'Entrave de la circulation', price = 400},
        {label = 'Dégradation de la voie publique', price = 600},
        {label = 'Trouble à l\'ordre publique', price = 800},
        {label = 'Entrave opération de bcso', price = 1500},
        {label = 'Insulte envers / entre civils', price = 200},
        {label = 'Outrage à agent de bcso', price = 800},
        {label = 'Menace verbale ou intimidation envers civil', price = 500},
        {label = 'Menace verbale ou intimidation envers policier', price = 1200},
        {label = 'Manifestation illégale', price = 1000},
        {label = 'Tentative de corruption', price = 5000},

        -- 🔫 Armes
        {label = 'Arme blanche sortie en ville', price = 1000},
        {label = 'Arme léthale sortie en ville', price = 2500},
        {label = 'Port d\'arme non autorisé (défaut de license)', price = 2000},
        {label = 'Port d\'arme illégal', price = 5000},

        -- 🚔 Criminalité
        {label = 'Pris en flag lockpick', price = 1500},
        {label = 'Vol de voiture', price = 2500},
        {label = 'Vente de drogue', price = 5000},
        {label = 'Fabrication de drogue', price = 8000},
        {label = 'Possession de drogue', price = 2500},
        {label = 'Prise d\'otage civil', price = 10000},
        {label = 'Prise d\'otage agent de l\'état', price = 15000},
        {label = 'Braquage particulier', price = 5000},
        {label = 'Braquage magasin', price = 10000},
        {label = 'Braquage de banque', price = 25000},

        -- 🔪 Violence
        {label = 'Tir sur civil', price = 7500},
        {label = 'Tir sur agent de l\'état', price = 10000},
        {label = 'Tentative de meurtre sur civil', price = 15000},
        {label = 'Tentative de meurtre sur agent de l\'état', price = 20000},
        {label = 'Meurtre sur civil', price = 25000},
        {label = 'Meurtre sur agent de l\'état', price = 30000},

        -- 💰 Fraude
        {label = 'Escroquerie à l\'entreprise', price = 4000},
    }
}


-- 📋 Props
ConfigBcso.Objects = {
    { label = "Sac",      model = "prop_big_bag_01" },
    { label = "Plot",     model = "prop_roadcone02a" },
    { label = "Barrière", model = "prop_barrier_work05" },
    { label = "Herse",    model = "p_ld_stinger_s" },
    { label = "Caisse",   model = "prop_boxpile_07d" },
}

-- 🧰 Liste des objets placés (stocke des NetIDs)
object = object or {}

-- Alias si ton ancien config utilise "weapon_rifle"
ConfigBcso.WeaponAliases = {
    weapon_rifle = 'weapon_carbinerifle'
}

-- Mappage arme → type de munition
ConfigBcso.AmmoTypeByWeapon = {
    weapon_pistol         = 'ammo-9',
    weapon_combatpistol   = 'ammo-9',
    weapon_smg            = 'ammo-9',
    weapon_carbinerifle   = 'ammo-rifle',
    weapon_assaultrifle   = 'ammo-rifle',
    weapon_pumpshotgun    = 'ammo-shotgun',
    weapon_assaultshotgun = 'ammo-shotgun',
}

-- Marque l’équipement donné par l’armurerie
function ConfigBcso.BuildAmmoMetadata(src)
    return { issued = true } -- ajoute dept='LSPD' si tu veux
end
function ConfigBcso.BuildWeaponMetadata(src)
    return { issued = true }
end

-- Équipements par grade (⚠️ remplace weapon_rifle par weapon_carbinerifle)
ConfigBcso.EquipmentByGrade = {
    [0] = {
        label = "Recrue",
        items = {
            { name = 'weapon_flashlight', count = 1, metadata = { issued = true } },
            { name = 'weapon_stungun',    count = 1, metadata = { issued = true } },
            { name = 'weapon_nightstick', count = 1, metadata = { issued = true } },
        }
    },
    [1] = {
        label = "Officier",
        items = {
            { name = 'weapon_pistol',     count = 1, metadata = { issued = true } },
            { name = 'weapon_stungun',    count = 1, metadata = { issued = true } },
            { name = 'weapon_nightstick', count = 1, metadata = { issued = true } },
            { name = 'weapon_flashlight', count = 1, metadata = { issued = true } },
            { name = 'ammo-9',            count = 42, metadata = { issued = true } },
        }
    },
    [2] = {
        label = "Sergent",
        items = {
            { name = 'weapon_pistol',       count = 1, metadata = { issued = true } },
            { name = 'weapon_flashlight',   count = 1, metadata = { issued = true } },
            { name = 'weapon_nightstick',   count = 1, metadata = { issued = true } },
            { name = 'weapon_stungun',      count = 1, metadata = { issued = true } },
            { name = 'ammo-9',              count = 100, metadata = { issued = true } },
            { name = 'weapon_carbinerifle', count = 1, metadata = { issued = true } },
        }
    },
    [3] = {
        label = "Lieutenant",
        items = {
            { name = 'weapon_pistol',         count = 1, metadata = { issued = true } },
            { name = 'weapon_flashlight',     count = 1, metadata = { issued = true } },
            { name = 'weapon_nightstick',     count = 1, metadata = { issued = true } },
            { name = 'weapon_stungun',        count = 1, metadata = { issued = true } },
            { name = 'ammo-9',                count = 120, metadata = { issued = true } },
            { name = 'weapon_carbinerifle',   count = 1, metadata = { issued = true } },
            { name = 'weapon_assaultshotgun', count = 1, metadata = { issued = true } },
        }
    },
    [4] = {
        label = "Boss",
        items = {
            { name = 'weapon_pistol',         count = 1, metadata = { issued = true } },
            { name = 'weapon_flashlight',     count = 1, metadata = { issued = true } },
            { name = 'weapon_nightstick',     count = 1, metadata = { issued = true } },
            { name = 'ammo-9',                count = 120, metadata = { issued = true } },
            { name = 'weapon_carbinerifle',   count = 1, metadata = { issued = true } },
            { name = 'weapon_assaultshotgun', count = 1, metadata = { issued = true } },
        }
    }
}

-- Armes à retirer (on cible d’abord les armes de service via metadata)
ConfigBcso.WeaponsToRemove = {
    { item = 'weapon_nightstick',     metadata = { issued = true } },
    { item = 'weapon_stungun',        metadata = { issued = true } },
    { item = 'weapon_pistol',         metadata = { issued = true } },
    { item = 'weapon_carbinerifle',   metadata = { issued = true } },
    { item = 'weapon_pumpshotgun',    metadata = { issued = true } },
    { item = 'weapon_smg',            metadata = { issued = true } },
    { item = 'weapon_flashlight',     metadata = { issued = true } },
    { item = 'weapon_assaultshotgun', metadata = { issued = true } },
    { item = 'weapon_assaultrifle',   metadata = { issued = true } }, -- si tu l’utilises
}

-- Munitions à retirer (priorité : piles issued → piles neutres)
ConfigBcso.AmmoToRemove = {
    { item = 'ammo-9',      count = 120, filters = { { issued = true }, {} } },
    { item = 'ammo-rifle',  count = 120, filters = { { issued = true }, {} } },
    { item = 'ammo-shotgun',count = 40,  filters = { { issued = true }, {} } },
}


-- Événements associés à l'armurerie
ConfigBcso.ArmoryEvent = 'armorybcso:giveEquipment' -- L'événement pour donner l'équipement
ConfigBcso.RemoveItemEvent = 'RemoveItem' -- L'événement pour retirer les armes et munitions
-- Configuration des jobs requis pour accéder à l'armurerie
ConfigBcso.JobRequired = 'bcso'  -- Par exemple, seulement les policiers peuvent accéder
-- Zone de l'armurerie (coordonnées et autres paramètres)
ConfigBcso.Armurerie = {
    coords = vector3(-436.974335,5988.625488,31.889095),  -- Exemple de coordonnées pour l'armurerie
    size = vector3(1, 1, 2),
    rotation = 0,
    Armory = {
        name = 'armurerie_bcso',
        icon = 'fa-solid fa-gun',
        label = 'Ouvrir l\'Armurerie',
        distance = 2.0
    }
}
--############################
--########### Boss ##########
--############################
ConfigBcso.JobRequired = 'bcso' -- pour rester cohérent dans tout le script

ConfigBcso.Boss = {
    BcsoBoss = {
        coords = vector3(-433.143097,6003.796875,31.662149),
        size   = vector3(2.0, 2.0, 2.0),

        -- 🔐 Accès ox_target: job + grade mini
        -- (ox_target check natif; tu peux garder ton canInteract en plus)
        society = { ['bcso'] = 4 },  -- <= important: mapping job -> grade min

        bossMenu = {
            name          = "open_bossmenu",
            icon          = 'fa-solid fa-building',
            label         = "Menu patron bcso",
            requiredGrade = 4,        -- garde la même valeur que ci-dessus
            distance      = 2.5
        }
    }
}

-- === Déclaration des stashes (IDs uniques) ===
ConfigBcso.Stashes = {
    Principal = {
        id     = 'bcso_principal',           -- ⚠️ ID unique
        label  = 'Coffre Principal - bcso',
        slots  = 150,
        weight = 100000,
        owner  = false
    },
    Saisies = {
        id     = 'bcso_saisies',             -- ⚠️ ID unique différent
        label  = 'Coffre Saisies - bcso',
        slots  = 250,
        weight = 150000,
        owner  = false
    }
}

-- === Zones d’interaction ===
ConfigBcso.Coffre = {
    BcsoCoffre = {
        coords      = vec3(-438.081451,6011.793457,31.529881),
        size        = vec3(1, 1, 1),
        rotation    = 0.0,
        label       = "Ouvrir le coffre (Principal)",
        icon        = "fas fa-box-open",
        jobRequired = 'bcso',
        stashId     = ConfigBcso.Stashes.Principal.id, -- OK
        distance    = 2.0
    },
}

ConfigBcso.Saisies = {
    BcsoSaisies = {
        coords      = vec3(-442.492615,5986.956055,31.500053),
        size        = vec3(1, 1, 1),
        rotation    = 0.0,
        label       = "Ouvrir le coffre de Saisies",
        icon        = "fas fa-box-open",
        jobRequired = 'bcso',
        stashId     = ConfigBcso.Stashes.Saisies.id,   -- ✅ Corrigé : pointer vers le stash Saisies
        distance    = 2.0
    },
}

-- Coffres fixes existants (Principal / Saisies)
ConfigBcso.Stashes = ConfigBcso.Stashes or {
    Principal = { id = 'bcso_principal', label = 'Coffre Principal - bcso', slots = 150, weight = 100000, owner = false },
    Saisies   = { id = 'bcso_saisies',   label = 'Coffre Saisies - bcso',   slots = 250, weight = 150000, owner = false },
}

-- Paramètres du système Evidence dynamique
ConfigBcso.Evidence = {
    job       = 'bcso',
    minGrade  = 0,            -- grade minimum (0 = tous les policiers)
    slots     = 80,
    weight    = 60000,
    webhook   = "",           -- URL Discord (optionnel). Laisse vide pour désactiver
    persistFile = "evidence.json",  -- nom du fichier persistant dans la ressource
    zone = {                  -- Une zone unique “Salle des preuves”
        coords   = vec3(-440.328217,5996.301758,32.368587),
        size     = vec3(1,1,1),
        rotation = 0.0,
        distance = 2.0,
        icon     = "fas fa-box-archive",
        labelCreate = "Créer un coffre de saisie",
        labelBrowse = "Ouvrir les coffres de saisies"
    }
}

-- Tenues disponibles dans le vestiaire
--Vestiaire 
ConfigBcso.VestiaireCoords = vector3(-436.974335,5988.625488,31.889095) -- Coordonnées du vestiaire
ConfigBcso.JobRequired = "bcso"  -- Job requis pour accéder au vestiaire
BcsoCloak = {
    clothes = {
        specials = {
            [0] = {
                label = "Tenue Civil",
                minimum_grade = 0,
                variations = { male = {}, female = {} },
                onEquip = function()
                    if not ESX then
                        ESX = exports["es_extended"]:getSharedObject()
                        if not ESX then return end
                    end
                    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                        TriggerEvent('skinchanger:loadSkin', skin)
                        SetPedArmour(PlayerPedId(), 0)
                    end)
                    SetPedArmour(PlayerPedId(), 0)
                end
            },
        },

        grades = {
            -- Classe A (Recrue) : chemise manches courtes, sans gilet
            [0] = {
                label = "Tenue Recruit",
                minimum_grade = 0,
                variations = {
                    male = {
                        tshirt_1 = 58,  tshirt_2 = 2,   -- undershirt beige clair
                        torso_1  = 55,  torso_2  = 2,   -- chemise tan
                        decals_1 = 0,   decals_2 = 0,
                        arms     = 41,                 -- manches courtes
                        pants_1  = 35,  pants_2  = 5,   -- pantalon vert olive
                        shoes_1  = 25,  shoes_2  = 0,   -- bottes noires
                        bproof_1 = 0,   bproof_2 = 0,   -- pas de gilet
                        helmet_1 = -1,  helmet_2 = 0,
                        chain_1  = 0,   chain_2  = 0,
                        mask_1   = 0,   mask_2   = 0,
                        bags_1   = 0,   bags_2   = 0,
                        ears_1   = -1,  ears_2   = 0,
                        glasses_1 = 0,  glasses_2 = 0
                    },
                    female = {
                        tshirt_1 = 35,  tshirt_2 = 2,
                        torso_1  = 48,  torso_2  = 2,
                        decals_1 = 0,   decals_2 = 0,
                        arms     = 44,
                        pants_1  = 34,  pants_2  = 5,
                        shoes_1  = 27,  shoes_2  = 0,
                        bproof_1 = 0,   bproof_2 = 0,
                        helmet_1 = -1,  helmet_2 = 0,
                        chain_1  = 0,   chain_2  = 0,
                        mask_1   = 0,   mask_2   = 0,
                        bags_1   = 0,   bags_2   = 0,
                        ears_1   = -1,  ears_2   = 0,
                        glasses_1 = 5,  glasses_2 = 0
                    }
                },
                onEquip = function() end
            },

            -- Classe B (Officer) : chemise manches longues + gilet BCSO
            [1] = {
                label = "Tenue Officer",
                minimum_grade = 1,
                variations = {
                    male = {
                        tshirt_1 = 58,  tshirt_2 = 2,
                        torso_1  = 55,  torso_2  = 2,
                        decals_1 = 0,   decals_2 = 0,
                        arms     = 1,                 -- manches longues
                        pants_1  = 35,  pants_2  = 5,
                        shoes_1  = 25,  shoes_2  = 0,
                        bproof_1 = 13,  bproof_2 = 5,  -- gilet “sheriff”
                        helmet_1 = -1,  helmet_2 = 0,
                        chain_1  = 0,   chain_2  = 0,
                        mask_1   = 0,   mask_2   = 0,
                        bags_1   = 0,   bags_2   = 0,
                        ears_1   = -1,  ears_2   = 0,
                        glasses_1 = 0,  glasses_2 = 0
                    },
                    female = {
                        tshirt_1 = 35,  tshirt_2 = 2,
                        torso_1  = 48,  torso_2  = 2,
                        decals_1 = 0,   decals_2 = 0,
                        arms     = 3,
                        pants_1  = 34,  pants_2  = 5,
                        shoes_1  = 27,  shoes_2  = 0,
                        bproof_1 = 13,  bproof_2 = 5,
                        helmet_1 = -1,  helmet_2 = 0,
                        chain_1  = 0,   chain_2  = 0,
                        mask_1   = 0,   mask_2   = 0,
                        bags_1   = 0,   bags_2   = 0,
                        ears_1   = -1,  ears_2   = 0,
                        glasses_1 = 5,  glasses_2 = 0
                    }
                },
                onEquip = function() end
            },

            -- Sergeant : + insigne (si texture), gants, radio
            [2] = {
                label = "Tenue Sergeant",
                minimum_grade = 2,
                variations = {
                    male = {
                        tshirt_1 = 58,  tshirt_2 = 2,
                        torso_1  = 55,  torso_2  = 2,
                        decals_1 = 7,   decals_2 = 2,  -- essaye 6/7/8 selon packs
                        arms     = 1,
                        pants_1  = 35,  pants_2  = 5,
                        shoes_1  = 25,  shoes_2  = 0,
                        bproof_1 = 13,  bproof_2 = 5,
                        helmet_1 = -1,  helmet_2 = 0,
                        chain_1  = 0,   chain_2  = 0,
                        mask_1   = 0,   mask_2   = 0,
                        bags_1   = 0,   bags_2   = 0,
                        ears_1   = -1,  ears_2   = 0,
                        glasses_1 = 0,  glasses_2 = 0
                    },
                    female = {
                        tshirt_1 = 35,  tshirt_2 = 2,
                        torso_1  = 48,  torso_2  = 2,
                        decals_1 = 7,   decals_2 = 2,
                        arms     = 3,
                        pants_1  = 34,  pants_2  = 5,
                        shoes_1  = 27,  shoes_2 = 0,
                        bproof_1 = 13,  bproof_2 = 5,
                        helmet_1 = -1,  helmet_2 = 0,
                        chain_1  = 0,   chain_2 = 0,
                        mask_1   = 0,   mask_2  = 0,
                        bags_1   = 0,   bags_2  = 0,
                        ears_1   = -1,  ears_2  = 0,
                        glasses_1 = 5,  glasses_2 = 0
                    }
                },
                onEquip = function() end
            },

            -- Lieutenant : chapeau “campaign hat” + gilet
            [3] = {
                label = "Tenue Lieutenant",
                minimum_grade = 3,
                variations = {
                    male = {
                        tshirt_1 = 58,  tshirt_2 = 2,
                        torso_1  = 55,  torso_2  = 2,
                        decals_1 = 8,   decals_2 = 2,
                        arms     = 1,
                        pants_1  = 35,  pants_2  = 5,
                        shoes_1  = 25,  shoes_2  = 0,
                        bproof_1 = 13,  bproof_2 = 5,
                        helmet_1 = 58,  helmet_2 = 3,  -- campaign hat (ajuste la texture)
                        chain_1  = 0,   chain_2 = 0,
                        mask_1   = 0,   mask_2  = 0,
                        bags_1   = 0,   bags_2  = 0,
                        ears_1   = -1,  ears_2  = 0,
                        glasses_1 = 0,  glasses_2 = 0
                    },
                    female = {
                        tshirt_1 = 35,  tshirt_2 = 2,
                        torso_1  = 48,  torso_2  = 2,
                        decals_1 = 8,   decals_2 = 2,
                        arms     = 3,
                        pants_1  = 34,  pants_2  = 5,
                        shoes_1  = 27,  shoes_2  = 0,
                        bproof_1 = 13,  bproof_2 = 5,
                        helmet_1 = 58,  helmet_2 = 3,
                        chain_1  = 0,   chain_2 = 0,
                        mask_1   = 0,   mask_2  = 0,
                        bags_1   = 0,   bags_2  = 0,
                        ears_1   = -1,  ears_2  = 0,
                        glasses_1 = 5,  glasses_2 = 0
                    }
                },
                onEquip = function() end
            },

            -- Sheriff/Boss : tenue propre + chapeau, textures plus “gold”
            [4] = {
                label = "Tenue Boss",
                minimum_grade = 4,
                variations = {
                    male = {
                        tshirt_1 = 58,  tshirt_2 = 1,
                        torso_1  = 55,  torso_2  = 1,
                        decals_1 = 10,  decals_2 = 1,  -- insigne supérieur (à ajuster)
                        arms     = 1,
                        pants_1  = 35,  pants_2  = 3,  -- vert plus foncé
                        shoes_1  = 25,  shoes_2  = 0,
                        bproof_1 = 13,  bproof_2 = 4,  -- variante de gilet
                        helmet_1 = 58,  helmet_2 = 1,
                        chain_1  = 0,   chain_2 = 0,
                        mask_1   = 0,   mask_2  = 0,
                        bags_1   = 0,   bags_2  = 0,
                        ears_1   = -1,  ears_2  = 0,
                        glasses_1 = 0,  glasses_2 = 0
                    },
                    female = {
                        tshirt_1 = 35,  tshirt_2 = 1,
                        torso_1  = 48,  torso_2  = 1,
                        decals_1 = 10,  decals_2 = 1,
                        arms     = 3,
                        pants_1  = 34,  pants_2  = 3,
                        shoes_1  = 27,  shoes_2  = 0,
                        bproof_1 = 13,  bproof_2 = 4,
                        helmet_1 = 58,  helmet_2 = 1,
                        chain_1  = 0,   chain_2 = 0,
                        mask_1   = 0,   mask_2  = 0,
                        bags_1   = 0,   bags_2  = 0,
                        ears_1   = -1,  ears_2  = 0,
                        glasses_1 = 5,  glasses_2 = 0
                    }
                },
                onEquip = function() end
            },
        },
    }
}


--############################
--########### Garage #########
--############################
ConfigBcso.posbcso = {
    spawnBcsoVehicle = {
        position =  vector4(-466.945068, 6015.283692, 30.947998, 317.480316)  -- Position de spawn du véhicule avec heading
    }
}

ConfigBcso.GarageBCSO = {
    BcsoGarage = {
        coords = vector3(-458.055908,6011.852051,31.869719), -- Coordonnées du garage
        size = vector3(3.0, 3.0, 3.0),
        garageMenuBCSO = {
            name = "bcso_garage",
            icon = "fa-solid fa-car",
            label = "Ouvrir le Garage bcso",
            distance = 2.0
        }
    }
}
ConfigBcso.Ranger = {
    BcsoRanger = {
        coords = vector3(-462.369232, 6009.758300, 30.947998),  -- Exemple de coordonnées du garage
        size = vector3(3.0, 3.0, 3.0),  -- Taille de la zone d'interaction
        distance = 5.0,  -- Distance à partir de laquelle le joueur peut interagir
        key = 38,  -- Touche E pour ranger (38 correspond à la touche E)
    },
}


ConfigBcso.AuthorizedBcsoVehicles = {
    {
        label = "Declasse Sheriff Cruiser",
        model = "sheriff",
        image = "https://wiki.rage.mp/images/thumb/6/68/Sheriff.png/164px-Sheriff.png"
    },
    {
        label = "Declasse Sheriff SUV",
        model = "sheriff2",
        image = "https://wiki.rage.mp/images/thumb/c/c4/Sheriff2.png/164px-Sheriff2.png"
    }
}

--############################
--########### ped #########
--############################
ConfigBcso.NPCs = {
    -- {
    --     model = "mp_s_m_armoured_01",
    --     coords =  vector4(1844.610962, 3691.964844, 34.250610, 300.472442),
    --     freeze = true,
    --     invincible = true,
    --     text = "👋 Ouvrir l\'Armurerie"
    -- },
    {
        model = "mp_s_m_armoured_01",
        coords =  vector4(-457.819764, 6011.934082, 31.487182, 130.393708),
        freeze = true,
        invincible = true,
        text = "👋 Ouvrir le Garage bcso"
    },

}
