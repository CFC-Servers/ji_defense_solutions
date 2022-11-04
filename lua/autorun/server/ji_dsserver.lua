local IsValid = IsValid
local RENDERMODE_TRANSALPHA = RENDERMODE_TRANSALPHA

local limits = {
    ent_jack_generator = 1,
    ent_jack_turretammobox_22 = 2,
    ent_jack_turretammobox_338 = 2,
    ent_jack_turretammobox_50 = 2,
    ent_jack_turretammobox_shot = 2,
    ent_jack_turretammobox_40mm = 2,
    ent_jack_turretammobox_556 = 2,
    ent_jack_turretammobox_762 = 2,
    ent_jack_turretammobox_9mm = 2,
    ent_jack_turret_amateriel = 1,
    ent_jack_turretbattery = 3,
    ent_jack_boundingmine = 2,
    ent_jack_aidfuel_gasoline = 2,
    ent_jack_aidfuel_kerosene = 2,
    ent_jack_aidfuel_propane = 2,
    ent_jack_claymore = 1,
    ent_jack_powernode = 4,
    ent_jack_turret_grenade = 1,
    ent_jack_ifftag = 2,
    ent_jack_landmine = 2,
    ent_jack_turret_mg = 2,
    ent_jack_turret_dmr = 1,
    ent_jack_paintcan = 2,
    ent_jack_turret_pistol = 2,
    ent_jack_turret_plinker = 2,
    ent_jack_turret_rifle = 2,
    ent_jack_turret_shotty = 2,
    ent_jack_turret_sniper = 1,
    ent_jack_turret_smg = 2,
    ent_jack_teslasentry = 1,
    ent_jack_turretrepairkit = 3,
}

for class, limit in pairs( limits ) do
    CreateConVar( "sbox_max" .. class, limit, FCVAR_ARCHIVE )
end


local function CmdDet( ... )
    local args = { ... }
    local ply = args[1]
    ply:ConCommand( "jacky_claymore_det" )
end
concommand.Add( "jacky_remote_det", CmdDet )

function JID.genericUseEffect( ply )
    if ply:IsPlayer() then
        local Wep = ply:GetActiveWeapon()
        if IsValid( Wep ) then Wep:SendWeaponAnim( ACT_VM_DRAW ) end
        ply:ViewPunch( Angle( 1, 0, 0 ) )
        ply:SetAnimation( PLAYER_ATTACK1 )
    end
end

function JID.CanTarget( ent )
    if not IsValid( ent ) then return false end
    if ent:GetRenderMode() == RENDERMODE_TRANSALPHA then return false end

    if CFCPvp then
        if ent:IsPlayer() and ent:IsInBuild() then return false end

        local owner = ent:CPPIGetOwner() or ent:GetOwner()
        if IsValid( owner ) and owner:IsPlayer() and owner:IsInBuild() then return false end
    end

    local canTarget = hook.Run( "JIDCanTarget", ent )
    if canTarget == false then return false end

    return true
end

function JID.CanBeUsed( ply, ent )
    if not IsValid( ent ) then return false end
    if not IsValid( ply ) then return false end

    if CFCPvp then
        local owner = ent:CPPIGetOwner() or ent:GetOwner()
        if IsValid( owner ) and owner:IsPlayer() then
            if owner:IsInBuild() and owner ~= ply then return false end
            if owner:IsInPVP() and ply:IsInBuild() then return false end
        end
    end

    local canBeUsed = hook.Run( "JIDCanBeUsed", ent )
    if canBeUsed == false then return false end

    return true
end

function JID.DetermineAttacker( ent )
    local creator = ent:GetCreator()
    if IsValid( creator ) then return creator end

    local owner = ent:GetOwner()
    if IsValid( owner ) then return owner end

    local entOwner = ent.Owner
    if IsValid( entOwner ) then return entOwner end

    return ent
end

local toolsToBlock = {
    ["material"] = true,
    ["colour"] = true
}

hook.Add( "CanTool", "JID_PreventToolgun", function( _, tr, tool )
    if not toolsToBlock[tool] then return end
    if not IsValid( tr.Entity ) then return end
    local class = tr.Entity:GetClass()
    if string.StartWith( class, "ent_jack_" ) then return false end
end )
