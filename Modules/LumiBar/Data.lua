local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
LumiBar.Data = {}
local Data = LumiBar.Data

-- Representative Icons for Expansions
Data.ExpansionIcons = {
    ["Midnight"] = 132320,         -- Silvermoon City Crest
    ["The War Within"] = 423329,
    ["Dragonflight"] = 4640486,
    ["Shadowlands"] = 3536181,
    ["BfA"] = 1869493,
    ["Legion"] = 1397630,
    ["Warlords"] = 1041239,
    ["Cataclysm"] = 461859,
    ["WotLK"] = 236415,
    ["Pandaria"] = 646378,
    ["SEASON"] = 463447,
}

-- Mapping of Portal Spell IDs to clean Dungeon Names
Data.PortalNames = {
    -- Midnight Season 1
    [1254572] = "Magisters' Terrace",
    [1254400] = "Windrunner Spire",
    [1254563] = "Nexus-Point Xenas",
    [1254559] = "Maisara Caverns",
    [1254551] = "Seat of the Triumvirate",
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
    [393222] = "Uldaman: Legacy of Tyr",
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
    [467555] = "The MOTHERLODE!!",
    [467553] = "The MOTHERLODE!!",

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

-- Comprehensive Database (Retail Only)
Data.HearthstoneData = {
    -- Standard Items
    [6948]   = { type = "item", hearthstone = true }, -- Hearthstone
    [110560] = { type = "toy",  hearthstone = false, label = "GARR" }, -- Garrison Hearthstone
    [140192] = { type = "toy",  hearthstone = false, label = "DALA" }, -- Dalaran Hearthstone
    [141605] = { type = "item", hearthstone = false, label = "FMW" }, -- Flight Master's Whistle

    -- Class Teleports
    [556]    = { type = "spell", hearthstone = true,  class = "SHAMAN" }, -- Astral Recall
    [18960]  = { type = "spell", hearthstone = false, class = "DRUID" }, -- Teleport: Moonglade
    [50977]  = { type = "spell", hearthstone = false, class = "DEATHKNIGHT" }, -- Death Gate
    [126892] = { type = "spell", hearthstone = false, class = "MONK" }, -- Zen Pligrimage
    [193753] = { type = "spell", hearthstone = false, class = "DRUID" }, -- Dreamwalk

    -- Racial Teleports/Items
    [168862]  = { type = "item", hearthstone = false, label = "FMW" }, -- G.E.A.R. Tracking Beacon
    [265225]  = { type = "spell", hearthstone = false, label = "MOLE" }, -- Mole Machine
    [312372]  = { type = "spell", hearthstone = false, label = "CAMP" }, -- Return to Camp
    [1238686] = { type = "spell", hearthstone = false, label = "ROOT" }, -- Rootwalking

    -- Alternate Hearthstones
    [54452]  = { type = "toy", hearthstone = true }, -- Ethereal Portal
    [64488]  = { type = "toy", hearthstone = true }, -- The Innkeeper's Daughter
    [93672]  = { type = "toy", hearthstone = true }, -- Dark Portal (Retail)
    [142542] = { type = "toy", hearthstone = true }, -- Tome of Town Portal
    [162973] = { type = "toy", hearthstone = true }, -- Greatfather Winter's Hearthstone
    [163045] = { type = "toy", hearthstone = true }, -- Headless Horseman's Hearthstone
    [165669] = { type = "toy", hearthstone = true }, -- Lunar Elder's Hearthstone
    [165670] = { type = "toy", hearthstone = true }, -- Peddlefeet's Lovely Hearthstone
    [165802] = { type = "toy", hearthstone = true }, -- Noble Gardener's Hearthstone
    [166746] = { type = "toy", hearthstone = true }, -- Fire Eater's Hearthstone
    [166747] = { type = "toy", hearthstone = true }, -- Brewfest Reveler's Hearthstone
    [168907] = { type = "toy", hearthstone = true }, -- Holographic Digitalization Hearthstone
    [172179] = { type = "toy", hearthstone = true }, -- Eternal Traveler's Hearthstone
    [180290] = { type = "toy", hearthstone = true, covenant = true }, -- Night Fae Hearthstone
    [182773] = { type = "toy", hearthstone = true, covenant = true }, -- Necrolord Hearthstone
    [183716] = { type = "toy", hearthstone = true, covenant = true }, -- Venthyr Sinstone
    [184353] = { type = "toy", hearthstone = true, covenant = true }, -- Kyrian Hearthstone
    [188952] = { type = "toy", hearthstone = true }, -- Dominated Hearthstone
    [190237] = { type = "toy", hearthstone = true }, -- Broker Translocation Matrix
    [193588] = { type = "toy", hearthstone = true }, -- Timewalker's Hearthstone
    [200630] = { type = "toy", hearthstone = true }, -- Ohn'ir Windsage's Hearthstone
    [206195] = { type = "toy", hearthstone = true }, -- Path of the Naaru
    [208704] = { type = "toy", hearthstone = true }, -- Deepdweller's Earthen Hearthstone
    [209035] = { type = "toy", hearthstone = true }, -- Hearthstone of the Flame
    [190196] = { type = "toy", hearthstone = true }, -- Enlightened Hearthstone
    [212337] = { type = "toy", hearthstone = true }, -- Stone of the Hearth
    [228940] = { type = "toy", hearthstone = true }, -- Notorious Thread's Hearthstone
    [236687] = { type = "toy", hearthstone = true }, -- Explosive Hearthstone
    [246565] = { type = "toy", hearthstone = true }, -- Cosmic Hearthstone
    [245970] = { type = "toy", hearthstone = true }, -- P.O.S.T. Master's Express Hearthstone
    [263489] = { type = "toy", hearthstone = true }, -- Naaru's Enfold
    [235016] = { type = "toy", hearthstone = true }, -- Redeployment Module
    [257736] = { type = "toy", hearthstone = true }, -- Lightcalled Hearthstone

    -- Engineering Items/Toys
    [18984]  = { type = "toy",  hearthstone = false, label = "EVR" }, -- Dimensional Ripper - Everlook
    [18986]  = { type = "toy",  hearthstone = false, label = "GAD" }, -- Ultrasafe Transporter: Gadgetzan
    [30542]  = { type = "toy",  hearthstone = false, label = "A52" }, -- Dimensional Ripper - Area 52
    [30544]  = { type = "toy",  hearthstone = false, label = "TOSH" }, -- Ultrasafe Transporter: Toshley's Station
    [48933]  = { type = "toy",  hearthstone = false, label = "WotLK" }, -- Wormhole Generator: Northrend
    [87215]  = { type = "toy",  hearthstone = false, label = "MOP" }, -- Wormhole Generator: Pandaria
    [112059] = { type = "toy",  hearthstone = false, label = "WOD" }, -- Wormhole Centrifuge
    [132517] = { type = "item", hearthstone = false, label = "DALA" }, -- Intra-Dalaran Wormhole Generator
    [151652] = { type = "toy",  hearthstone = false, label = "ARG" }, -- Wormhole Generator: Argus
    [168807] = { type = "toy",  hearthstone = false, label = "KT" }, -- Wormhole Generator: Kul Tiras
    [168808] = { type = "toy",  hearthstone = false, label = "ZAN" }, -- Wormhole Generator: Zandalar
    [172924] = { type = "toy",  hearthstone = false, label = "SL" }, -- Wormhole Generator: Shadowlands
    [198156] = { type = "toy",  hearthstone = false, label = "DF" }, -- Wyrmhole Generator: Dragon Isles
    [221966] = { type = "toy",  hearthstone = false, label = "TWW" }, -- Wormhole Generator: Khaz Algar
    [248485] = { type = "toy",  hearthstone = false, label = "MID" }, -- Wormhole Generator: Quel'Thalas

    -- Teleportation Equipment
    [22589]  = { type = "item", hearthstone = false, label = "KZ" }, -- Atiesh, Greatstaff of the Guardian
    [28585]  = { type = "item", hearthstone = false, label = "HOME" }, -- Ruby Slippers
    [32757]  = { type = "item", hearthstone = false, label = "KAR" }, -- Blessed Medallion of Karabor
    [44935]  = { type = "item", hearthstone = false, label = "DALA" }, -- Ring of the Kirin Tor
    [45690]  = { type = "item", hearthstone = false, label = "DALA" }, -- Inscribed Ring of the Kirin Tor
    [46874]  = { type = "item", hearthstone = false, label = "ICC" }, -- Argent Crusader's Tabard
    [48956]  = { type = "item", hearthstone = false, label = "DALA" }, -- Etched Ring of the Kirin Tor
    [51559]  = { type = "item", hearthstone = false, label = "DALA" }, -- Runed of the Kirin Tor
    [50287]  = { type = "item", hearthstone = false, label = "BOTY" }, -- Boots of the Bay
    [63206]  = { type = "item", hearthstone = false, label = "SW" }, -- Wrap of Unity (Alliance)
    [63207]  = { type = "item", hearthstone = false, label = "ORG" }, -- Wrap of Unity (Horde)
    [63352]  = { type = "item", hearthstone = false, label = "SW" }, -- Shroud of Cooperation (Alliance)
    [63353]  = { type = "item", hearthstone = false, label = "ORG" }, -- Shroud of Cooperation (Horde)
    [63378]  = { type = "item", hearthstone = false, label = "TBR" }, -- Hellscream's Reach Tabard
    [63379]  = { type = "item", hearthstone = false, label = "TBR" }, -- Baradin's Wardens Tabard
    [65274]  = { type = "item", hearthstone = false, label = "ORG" }, -- Cloak of Coordination (Horde)
    [65360]  = { type = "item", hearthstone = false, label = "SW" }, -- Cloak of Coordination (Alliance)
    [139599] = { type = "item", hearthstone = false, label = "DALA" }, -- Empowered Ring of the Kirin Tor
    [142469] = { type = "item", hearthstone = false, label = "KZ" }, -- Violet Seal of the Grand Magus
    [144391] = { type = "item", hearthstone = false, label = "BRAWL" }, -- Pugilist's Powerful Punching Ring (Alliance)
    [144392] = { type = "item", hearthstone = false, label = "BRAWL" }, -- Pugilist's Powerful Punching Ring (Horde)
    [166559] = { type = "item", hearthstone = false, label = "DAZ" }, -- Commander's Signet of Battle
    [166560] = { type = "item", hearthstone = false, label = "BOR" }, -- Captain's Signet of Command
    [193000] = { type = "item", hearthstone = false, label = "RAND" }, -- Ring-Bound Hourglass
    [243056] = { type = "toy",  hearthstone = false, label = "DORN" }, -- Delver's Mana-Bound Ethergate
    [230850] = { type = "toy",  hearthstone = false, label = "DLVE" }, -- Delve-O-Bot 7001
    [205255] = { type = "toy",  hearthstone = false, label = "ZARL" }, -- Niffen Diggin' Mitts
    [253629] = { type = "toy",  hearthstone = false, label = "ARC" }, -- Personal Key to the Arcantina

    -- Mythic+ Teleports (Categorized Metadata)
    [1254555] = { type = "spell", hearthstone = false, mythic = true, season = "mid1", label = "POS" },
    [410080]  = { type = "spell", hearthstone = false, mythic = true, season = "df2",  label = "VP" },
    [424142]  = { type = "spell", hearthstone = false, mythic = true, season = "df3",  label = "TotT" },
    [445424]  = { type = "spell", hearthstone = false, mythic = true, season = "tww1", label = "GB" },
    [131204]  = { type = "spell", hearthstone = false, mythic = true, season = "df1",  label = "TJS" },
    [131205]  = { type = "spell", hearthstone = false, mythic = true, season = "mop",  label = "SB" },
    [131206]  = { type = "spell", hearthstone = false, mythic = true, season = "mop",  label = "SPM" },
    [131222]  = { type = "spell", hearthstone = false, mythic = true, season = "mop",  label = "MSP" },
    [131225]  = { type = "spell", hearthstone = false, mythic = true, season = "mop",  label = "GSS" },
    [131228]  = { type = "spell", hearthstone = false, mythic = true, season = "mop",  label = "SON" },
    [131229]  = { type = "spell", hearthstone = false, mythic = true, season = "mop",  label = "SM" },
    [131231]  = { type = "spell", hearthstone = false, mythic = true, season = "mop",  label = "SH" },
    [131232]  = { type = "spell", hearthstone = false, mythic = true, season = "mop",  label = "SCH" },
    [159895]  = { type = "spell", hearthstone = false, mythic = true, season = "wod",  label = "BSM" },
    [159896]  = { type = "spell", hearthstone = false, mythic = true, season = "wod",  label = "ID" },
    [159897]  = { type = "spell", hearthstone = false, mythic = true, season = "wod",  label = "AUCH" },
    [159898]  = { type = "spell", hearthstone = false, mythic = true, season = "wod",  label = "SKY" },
    [159899]  = { type = "spell", hearthstone = false, mythic = true, season = "df1",  label = "SBG" },
    [159900]  = { type = "spell", hearthstone = false, mythic = true, season = "sl4",  label = "GD" },
    [159901]  = { type = "spell", hearthstone = false, mythic = true, season = "df3",  label = "EB" },
    [159902]  = { type = "spell", hearthstone = false, mythic = true, season = "wod",  label = "UBS" },
    [1254557] = { type = "spell", hearthstone = false, mythic = true, season = "mid1", label = "SKY" },
    [410078]  = { type = "spell", hearthstone = false, mythic = true, season = "df",   label = "NL" },
    [424153]  = { type = "spell", hearthstone = false, mythic = true, season = "df3",  label = "BRH" },
    [424163]  = { type = "spell", hearthstone = false, mythic = true, season = "df3",  label = "DHT" },
    [393764]  = { type = "spell", hearthstone = false, mythic = true, season = "df",   label = "HOV" },
    [393766]  = { type = "spell", hearthstone = false, mythic = true, season = "df",   label = "COS" },
    [1254551] = { type = "spell", hearthstone = false, mythic = true, season = "mid1", label = "SotV" },
    [424167]  = { type = "spell", hearthstone = false, mythic = true, season = "df3",  label = "WM" },
    [424187]  = { type = "spell", hearthstone = false, mythic = true, season = "df3",  label = "AD" },
    [410074]  = { type = "spell", hearthstone = false, mythic = true, season = "df",   label = "UNDR" },
    [410071]  = { type = "spell", hearthstone = false, mythic = true, season = "df",   label = "FH" },
    [467555]  = { type = "spell", hearthstone = false, mythic = true, season = "tww2", label = "ML" },
    [467553]  = { type = "spell", hearthstone = false, mythic = true, season = "tww2", label = "ML" },
    [464256]  = { type = "spell", hearthstone = false, mythic = true, season = "tww1", label = "SIEGE" },
    [445418]  = { type = "spell", hearthstone = false, mythic = true, season = "tww1", label = "SIEGE" },
    [354462]  = { type = "spell", hearthstone = false, mythic = true, season = "tww1", label = "NW" },
    [354463]  = { type = "spell", hearthstone = false, mythic = true, season = "sl",   label = "PF" },
    [354464]  = { type = "spell", hearthstone = false, mythic = true, season = "tww1", label = "MISTS" },
    [354465]  = { type = "spell", hearthstone = false, mythic = true, season = "tww3", label = "HOA" },
    [354466]  = { type = "spell", hearthstone = false, mythic = true, season = "sl",   label = "SOA" },
    [354467]  = { type = "spell", hearthstone = false, mythic = true, season = "tww2", label = "TOP" },
    [354468]  = { type = "spell", hearthstone = false, mythic = true, season = "sl",   label = "DOS" },
    [354469]  = { type = "spell", hearthstone = false, mythic = true, season = "sl",   label = "SD" },
    [367416]  = { type = "spell", hearthstone = false, mythic = true, season = "tww3", label = "TVM" },
    [373274]  = { type = "spell", hearthstone = false, mythic = true, season = "tww2", label = "WORK" },
    [393222]  = { type = "spell", hearthstone = false, mythic = true, season = "df4",  label = "ULD" },
    [393256]  = { type = "spell", hearthstone = false, mythic = true, season = "df4",  label = "RLP" },
    [393262]  = { type = "spell", hearthstone = false, mythic = true, season = "df4",  label = "NO" },
    [393267]  = { type = "spell", hearthstone = false, mythic = true, season = "df4",  label = "BH" },
    [393273]  = { type = "spell", hearthstone = false, mythic = true, season = "mid1", label = "AA" },
    [393276]  = { type = "spell", hearthstone = false, mythic = true, season = "df4",  label = "NELT" },
    [393279]  = { type = "spell", hearthstone = false, mythic = true, season = "df4",  label = "AV" },
    [393283]  = { type = "spell", hearthstone = false, mythic = true, season = "df4",  label = "HOI" },
    [424197]  = { type = "spell", hearthstone = false, mythic = true, season = "df3",  label = "DOI" },
    [445417]  = { type = "spell", hearthstone = false, mythic = true, season = "tww3", label = "ARAK" },
    [445416]  = { type = "spell", hearthstone = false, mythic = true, season = "tww1", label = "COT" },
    [445414]  = { type = "spell", hearthstone = false, mythic = true, season = "tww3", label = "DAWN" },
    [445443]  = { type = "spell", hearthstone = false, mythic = true, season = "tww2", label = "ROOK" },
    [445269]  = { type = "spell", hearthstone = false, mythic = true, season = "tww1", label = "SV" },
    [445440]  = { type = "spell", hearthstone = false, mythic = true, season = "tww2", label = "BREW" },
    [467546]  = { type = "spell", hearthstone = false, mythic = true, season = "tww2", label = "BREW" },
    [445441]  = { type = "spell", hearthstone = false, mythic = true, season = "tww2", label = "DFC" },
    [445444]  = { type = "spell", hearthstone = false, mythic = true, season = "tww3", label = "PSF" },
    [1216786] = { type = "spell", hearthstone = false, mythic = true, season = "tww3", label = "FLOOD" },
    [1237215] = { type = "spell", hearthstone = false, mythic = true, season = "tww3", label = "EDA" },
    [1254572] = { type = "spell", hearthstone = false, mythic = true, season = "mid1", label = "MT" },
    [1254400] = { type = "spell", hearthstone = false, mythic = true, season = "mid1", label = "WS" },
    [1254563] = { type = "spell", hearthstone = false, mythic = true, season = "mid1", label = "NPX" },
    [1254559] = { type = "spell", hearthstone = false, mythic = true, season = "mid1", label = "MC" },

    -- Raid Teleports
    [432254]  = { type = "spell", hearthstone = false, raid = true, expansion = "df",  label = "VotI" },
    [432257]  = { type = "spell", hearthstone = false, raid = true, expansion = "df",  label = "ABER" },
    [432258]  = { type = "spell", hearthstone = false, raid = true, expansion = "df",  label = "AMIR" },
    [1226482] = { type = "spell", hearthstone = false, raid = true, expansion = "tww", label = "UNDER" },
    [1239155] = { type = "spell", hearthstone = false, raid = true, expansion = "tww", label = "MANA" },

    -- Other
    [37863]   = { type = "item",  hearthstone = false, label = "BRD" }, -- Direbrew's Remote
    [43824]   = { type = "toy",   hearthstone = false, label = "DALA" }, -- The Schools of Arcane Magic - Mastery
    [52251]   = { type = "item",  hearthstone = false, label = "DALA" }, -- Jaina's Locket
    [58487]   = { type = "item",  hearthstone = false, label = "DHLM" }, -- Potion of Deepholm
    [64457]   = { type = "item",  hearthstone = false, label = "RAND" }, -- The Last Relic of Argus
    [95567]   = { type = "toy",   hearthstone = false, label = "IOT" }, -- Kirin Tor Beacon
    [95568]   = { type = "toy",   hearthstone = false, label = "IOT" }, -- Sunreaver Beacon
    [103678]  = { type = "item",  hearthstone = false, label = "TIML" }, -- Time-Lost Artifact
    [118662]  = { type = "item",  hearthstone = false, label = "BLAD" }, -- Bladespire Relic
    [118663]  = { type = "item",  hearthstone = false, label = "KAR" }, -- Relic of Karabor
    [128353]  = { type = "item",  hearthstone = false, label = "SHIP" }, -- Admiral's Compass
    [129276]  = { type = "item",  hearthstone = false, label = "AZ" }, -- Beginner's Guide to Dimensional Rifting
    [129929]  = { type = "item",  hearthstone = false, label = "SHFT" }, -- Ever-Shifting Mirror
    [140324]  = { type = "toy",   hearthstone = false, label = "SUR" }, -- Mobile Telemancy Beacon
    [140493]  = { type = "item",  hearthstone = false, label = "BI" }, -- Adepts's Guide to Dimensional Rifting
    [167075]  = { type = "item",  hearthstone = false, label = "MECH" }, -- Ultrasafe Transporter: Mechagon
    [211788]  = { type = "toy",   hearthstone = false, label = "GIL" }, -- Tess's Peacebloom
    [324547]  = { type = "spell", hearthstone = false, label = "NECR" }, -- Hearth Kidneystone
}

-- Mages
Data.MageSpells = {
    -- Teleports
    3561, 3567, 3562, 3563, 3565, 3566, 32271, 32272, 33690, 35715, 49359, 49358, 53140, 88342, 88344, 120145, 132621, 132627, 176242, 176248, 193759, 224869, 281403, 281404, 344587, 395277, 446540, 1259190,
    -- Portals
    10059, 11417, 11416, 11418, 11419, 11420, 32266, 32267, 33691, 35717, 49360, 49361, 53142, 88345, 88346, 120146, 132620, 132626, 176244, 176246, 224871, 281400, 281402, 344597, 395289, 446534, 1259194
}

-- Expansion Groups (Categorized for UI Menus)
Data.DungeonPortals = {
    ["Midnight"] = { 1254572, 1254400, 1254563, 1254559, 1254551 },
    ["The War Within"] = { 445417, 445416, 445414, 445269, 445443, 445440, 445441, 445444, 1216786, 1237215 },
    ["Dragonflight"] = { 393256, 393262, 393267, 393279, 393283, 393276, 393222, 424197, 393273 },
    ["Shadowlands"] = { 354464, 354462, 354463, 354467, 354468, 354469, 354465, 354466, 367416, 373274 },
    ["BfA"] = { 410071, 410074, 424167, 424187, 464256, 445418, 467555, 467553 },
    ["Legion"] = { 410078, 424153, 424163, 393764, 393766, 373262 },
    ["Warlords"] = { 159895, 159896, 159897, 159898, 159899, 159900, 159901, 159902, 1254557 },
    ["Cataclysm"] = { 410080, 424142, 445424 },
    ["WotLK"] = { 1254555 }
}

-- Midnight Season 1 Rotation
Data.SeasonPortals = {
    1254572, 1254400, 1254563, 1254559, -- Midnight 4
    1254551, -- Seat of the Triumvirate (Legion)
    393273, -- Algeth'ar Academy (Dragonflight)
    1254557, -- Skyreach (Warlords)
    1254555, -- Pit of Saron (WotLK)
}

-- Repair Mounts
Data.RepairMounts = {
    [2237] = "Grizzly Hills Packmaster",
    [460]  = "Grand Expedition Yak",
    [280]  = "Traveler's Tundra Mammoth (Alliance)",
    [284]  = "Traveler's Tundra Mammoth (Horde)",
    [1039] = "Mighty Caravan Brutosaur",
    [2265] = "Trader's Gilded Brutosaur",
}
