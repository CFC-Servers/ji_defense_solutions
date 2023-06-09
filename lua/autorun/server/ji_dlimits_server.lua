local limits = {
    turrets = 4,
    mines = 10,
    ammo = 8,
    fuel = 2,

    ent_jack_powernode = 20,
    ent_jack_barbedwire = 25,
    ent_jack_claymore = 8, -- claymores are very dank to stack up inside vehicles and use as IEDS
    ent_jack_generator = 2,
    ent_jack_barbedwirekit = 6,
    ent_jack_turretrepairkit = 8,
    ent_jack_turretbattery = 8,
    ent_jack_ifftag = 2,
    ent_jack_paintcan = 4,

    ent_jack_seamine = 10000,

}

local limitTranslations = {
    ent_jack_teslasentry = "turrets",
    ent_jack_turret_grenade = "turrets",
    ent_jack_turret_mg = "turrets",
    ent_jack_turret_missile = "turrets",
    ent_jack_turret_pistol = "turrets",
    ent_jack_turret_plinker = "turrets",
    ent_jack_turret_rocket = "turrets",
    ent_jack_turret_shotty = "turrets",
    ent_jack_turret_smg = "turrets",
    ent_jack_turret_sniper = "turrets",

    ent_jack_boundingmine = "mines",
    ent_jack_landmine = "mines",

    ent_jack_turretammobox_9mm = "ammo",
    ent_jack_turretammobox_22 = "ammo",
    ent_jack_turretammobox_40mm = "ammo",
    ent_jack_turretammobox_556 = "ammo",
    ent_jack_turretammobox_762 = "ammo",
    ent_jack_turretammobox_shot = "ammo",

    ent_jack_aidfuel_gasoline = "fuel",
    ent_jack_aidfuel_kerosene = "fuel",
    ent_jack_aidfuel_propane = "fuel",

}

local function getLimitName( class )
    local name = class
    if limitTranslations[ name ] then
        name = limitTranslations[ name ]

    end

    return "jacka_" .. name, name
end

local function isLimited( class )
    local name = class
    if limitTranslations[ name ] then
        name = limitTranslations[ name ]

    end

    if limits[ name ] then return true end

end


for name, limit in pairs( limits ) do
    local limitName, cleanName = getLimitName( name )
    CreateConVar( "sbox_max" .. limitName, tostring( limit ) )

    if CLIENT then
        language.Add( "sboxlimit_" .. limitName, "You've hit the " .. cleanName .. " limit!" )
    end
end

if not SERVER then return end

local function playerCanSpawn( ply, class )
    if not isLimited( class ) then return end
    local limitName = getLimitName( class )

    local canSpawn = ply:CheckLimit( limitName )
    if not canSpawn then return false end
end

local function playerSpawnedEnt( ply, ent )
    local class = ent:GetClass()

    if not isLimited( class ) then return end
    local limitName = getLimitName( class )

    ply:AddCount( limitName, ent )
end

function JID.IsOverLimit( ply, class )
    return playerCanSpawn( ply, class )

end

function JID.RegisterEntSpawn( ply, ent )
    playerSpawnedEnt( ply, ent )

end

hook.Remove( "PlayerSpawnSENT", "JID_Limits_CanPlayerSpawn" )
hook.Add( "PlayerSpawnSENT", "JID_Limits_CanPlayerSpawn", playerCanSpawn )

hook.Remove( "PlayerSpawnedSENT", "JID_Limits_PlayerSpawnedEnt" )
hook.Add( "PlayerSpawnedSENT", "JID_Limits_PlayerSpawnedEnt", playerSpawnedEnt )