local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
LumiBar.Data = {}
local Data = LumiBar.Data

-- Representative Icons for Expansions
Data.ExpansionIcons = {
    ["Midnight"] = 6307823,
    ["The War Within"] = 5764215,
    ["Dragonflight"] = 4640486,
    ["Shadowlands"] = 3536181,
    ["BfA"] = 1869493,
    ["Legion"] = 1397630,
    ["Warlords"] = 1041239,
    ["Cataclysm"] = 461859,
    ["WotLK"] = 236415,
    ["Pandaria"] = 646378,
    ["SEASON"] = 463447, -- Mythic+ Seasonal Icon
}

-- Mapping of Portal Spell IDs to clean Dungeon Names
Data.PortalNames = {
    -- Midnight Season 1
    [1254572] = "Magisters' Terrace",
    [1254400] = "Windrunner Spire",
    [1254563] = "Nexus-Point Xenas",
    [1254559] = "Maisara Caverns",
    [471665]  = "Seat of the Triumvirate",
    [393273]  = "Algeth'ar Academy",
    [1254557] = "Skyreach",
    [1254555] = "Pit of Saron",

    -- The War Within
    [445417] = "Ara-Kara, City of Echoes",
    [445416] = "City of Threads",
    [445414] = "The Dawnbreaker",
    [445269] = "The Stonevault",
    [445443] = "The Rookery",
    [445440] = "Cinderbrew Meadery",
    [467546] = "Cinderbrew Meadery",
    [445441] = "Darkflame Cleft",
    [445444] = "Priory of the Sacred Flame",
    [1216786] = "Operation: Floodgate",
    [1237215] = "Eco-Dome Al'dani",

    -- Dragonflight
    [393256] = "Ruby Life Pools",
    [393262] = "Nokhud Offensive",
    [393267] = "Brackenhide Hollow",
    [393279] = "Azure Vault",
    [393283] = "Halls of Infusion",
    [393276] = "Neltharus",
    [393223] = "Uldaman: Legacy of Tyr",
    [424197] = "Dawn of the Infinite",

    -- Shadowlands
    [354464] = "Mists of Tirna Scithe",
    [354462] = "Necrotic Wake",
    [354463] = "Plaguefall",
    [354467] = "Theater of Pain",
    [354468] = "De Other Side",
    [354469] = "Sanguine Depths",
    [354465] = "Halls of Atonement",
    [354466] = "Spires of Ascension",
    [367416] = "Tazavesh",

    -- BfA
    [410071] = "Freehold",
    [410074] = "Underrot",
    [424167] = "Waycrest Manor",
    [424187] = "Atal'Dazar",
    [464256] = "Siege of Boralus",
    [445418] = "Siege of Boralus",
    [373274] = "Mechagon",

    -- Legion
    [410078] = "Neltharion's Lair",
    [424153] = "Black Rook Hold",
    [424163] = "Darkheart Thicket",
    [393764] = "Halls of Valor",
    [393766] = "Court of Stars",
    [373262] = "Karazhan",

    -- Warlords
    [159895] = "Bloodmaul Slag Mines",
    [159896] = "Iron Docks",
    [159897] = "Auchindoun",
    [159898] = "Skyreach",
    [159899] = "Shadowmoon Burial Grounds",
    [159900] = "Grimrail Depot",
    [159901] = "The Everbloom",
    [159902] = "Upper Blackrock Spire",

    -- Pandaria
    [131204] = "Temple of the Jade Serpent",
    [131205] = "Stormstout Brewery",
    [131206] = "Shado-Pan Monastery",
    [131222] = "Mogu'shan Palace",
    [131225] = "Gate of the Setting Sun",
    [131228] = "Siege of Niuzao Temple",
    [131229] = "Scarlet Monastery",
    [131231] = "Scarlet Halls",
    [131232] = "Scholomance",
}

-- Comprehensive Database
Data.HearthstoneData = {
    -- Items/Toys
    [6948]   = { type = "item", hearthstone = true },
    [110560] = { type = "toy",  hearthstone = false, label = "GARR" },
    [140192] = { type = "toy",  hearthstone = false, label = "DALA" },
    [253629] = { type = "toy",  hearthstone = true,  label = "ARCAN" },
    [54452]  = { type = "toy",  hearthstone = true },
    [64488]  = { type = "toy",  hearthstone = true },
    [142542] = { type = "toy",  hearthstone = true },
    [162973] = { type = "toy",  hearthstone = true },
    [163045] = { type = "toy",  hearthstone = true },
    [163211] = { type = "toy",  hearthstone = true }, -- Headless Horseman's
    [165670] = { type = "toy",  hearthstone = true }, -- Lunar Elder's
    [165802] = { type = "toy",  hearthstone = true }, -- Noble Gardener's
    [166333] = { type = "toy",  hearthstone = true }, -- Noble Gardener's (alt)
    [166746] = { type = "toy",  hearthstone = true }, -- Brewfest
    [166747] = { type = "toy",  hearthstone = true }, -- Fire Eater's
    [172179] = { type = "toy",  hearthstone = true }, -- Eternal Traveler's
    [188952] = { type = "toy",  hearthstone = true },
    [190196] = { type = "toy",  hearthstone = true }, -- Enlightened
    [193588] = { type = "toy",  hearthstone = true }, -- Timewalker's
    [208704] = { type = "toy",  hearthstone = true }, -- Deepdweller's Earthen
    [209035] = { type = "toy",  hearthstone = true }, -- Hearthstone of the Flame
    [212337] = { type = "toy",  hearthstone = true },
    [254102] = { type = "toy",  hearthstone = false, label = "QUEL" },
    
    -- Class Spells
    [556]    = { type = "spell", hearthstone = true, class = "SHAMAN" },
    [193753] = { type = "spell", hearthstone = false, class = "DRUID" },
    [50977]  = { type = "spell", hearthstone = false, class = "DEATHKNIGHT" },
    [126892] = { type = "spell", hearthstone = false, class = "MONK" },
}

-- Mages
Data.MageSpells = {
    3561, 3567, 3562, 3563, 3565, 3566, 32271, 32272, 33690, 35715, 49359, 49358, 53140, 120145, 132621, 132627, 176242, 176248, 193759, 224869, 281403, 281404, 344587, 395277, 446540, 1259190,
    10059, 11417, 11416, 11418, 11419, 11420, 32266, 32267, 33691, 35717, 49360, 49361, 53142, 120146, 132620, 132626, 176244, 176246, 224871, 281400, 281402, 344597, 395289, 446534, 1259194
}

-- Expansion Groups
Data.DungeonPortals = {
    ["Midnight"] = { 1254572, 1254400, 1254563, 1254559 },
    ["The War Within"] = { 445417, 445416, 445414, 445269, 445443, 445440, 445441, 445444, 1216786, 1237215 },
    ["Dragonflight"] = { 393256, 393262, 393267, 393279, 393283, 393276, 393223, 424197, 393273 },
    ["Shadowlands"] = { 354464, 354462, 354463, 354467, 354468, 354469, 354465, 354466, 367416 },
    ["BfA"] = { 410071, 410074, 424167, 424187, 464256, 445418, 373274 },
    ["Legion"] = { 410078, 424153, 424163, 393764, 393766, 373262, 471665 },
    ["Warlords"] = { 159895, 159896, 159897, 159898, 159899, 159900, 159901, 159902 },
    ["Cataclysm"] = { 445443, 410080 },
    ["WotLK"] = { 467823, 1254555 }
}

-- Midnight Season 1 Rotation
Data.SeasonPortals = {
    1254572, 1254400, 1254563, 1254559, -- Midnight 4
    471665, -- Seat of the Triumvirate (Legion)
    393273, -- Algeth'ar Academy (Dragonflight)
    1254557, -- Skyreach (Warlords)
    1254555, -- Pit of Saron (WotLK)
}

-- Repair Mounts
Data.RepairMounts = {
    [2237] = "Grizzly Hills Packmaster",
    [2254] = "Trader's Gilded Brutosaur",
    [460]  = "Grand Expedition Yak",
    [280]  = "Traveler's Tundra Mammoth (Alliance)",
    [284]  = "Traveler's Tundra Mammoth (Horde)",
    [1039] = "Mighty Caravan Brutosaur",
}
