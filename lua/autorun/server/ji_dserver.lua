local IsValid = IsValid
local RENDERMODE_TRANSALPHA = RENDERMODE_TRANSALPHA

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

function JID.CanTarget( ent, isBlind )
    if not IsValid( ent ) then return false end
    -- if checker cant see why are we checking this?
    if not isBlind and ent:GetRenderMode() == RENDERMODE_TRANSALPHA then return false end

    local canTarget = hook.Run( "JIDCanTarget", ent )
    if canTarget == false then return false end

    if not CFCPvp then return true end

    local owner = ent:GetCreator()
    if ent:IsPlayer() and ent:IsInBuild() then return false end
    if owner and owner:IsPlayer() and owner:IsInBuild() then return false end

    if IsValid( owner ) and owner:IsPlayer() and owner:IsInBuild() then return false end

    return true
end

function JID.CanBeUsed( ply, ent )
    if not IsValid( ent ) then return false end
    if not IsValid( ply ) then return false end

    local canBeUsed = hook.Run( "JIDCanBeUsed", ent )
    if canBeUsed == false then return false end

    if not CFCPvp then return true end

    local owner = ent:GetCreator()
    if IsValid( owner ) and owner:IsPlayer() then
        if owner:IsInBuild() and owner ~= ply then return false end
        if owner:IsInPvp() and ply:IsInBuild() then return false end
    end

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

function JID.CanConstrain( ent, toConstrain )
    if not IsValid( ent ) then return end
    if not IsValid( toConstrain ) then return end

    local entOwner = CPPI and ent:CPPIGetOwner() or ent:GetOwner()
    if not IsValid( entOwner ) then return end
    print( toConstrain:CPPICanTool( entOwner ), ent:CPPIGetOwner(), ent:GetOwner() )
    if CPPI and not toConstrain:CPPICanTool( entOwner ) then return end

    local toConstrainOwner = CPPI and toConstrain:CPPIGetOwner() or toConstrain:GetOwner()
    if not IsValid( toConstrainOwner ) then return end
    if CPPI and not ent:CPPICanTool( toConstrainOwner ) then return end

    if CPPI then return true end -- CPPI exists and hasn't blocked, so allow
    if entOwner == toConstrainOwner then return true end -- CPPI doesn't exist, directly compare owners
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
