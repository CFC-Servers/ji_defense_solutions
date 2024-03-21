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

function JID.CanTarget( ent, target )
    if not IsValid( target ) then return false end

    local canTarget = hook.Run( "JIDCanTarget", target )
    if canTarget == false then return false end

    if not CFCPvp then return true end

    local targetsOwner = target:GetCreator()
    if target:IsPlayer() and target:IsInBuild() then return false end
    if IsValid( targetsOwner ) and targetsOwner:IsPlayer() and targetsOwner:IsInBuild() then return false end

    local myOwner = ent:GetCreator()
    if IsValid( myOwner ) and myOwner:IsPlayer() and myOwner:IsInBuild() then return false end

    return true
end

function JID.IsTargetVisibile( target )
    if not IsValid( target ) then return false end
    if target:GetRenderMode() == RENDERMODE_TRANSALPHA then return false end

    return true
end

function JID.CanBeUsed( ply, ent )
    if not IsValid( ent ) then return false end
    if not IsValid( ply ) then return false end

    local canBeUsed = hook.Run( "JIDCanBeUsed", ent )
    if canBeUsed == false then return false end

    if not CFCPvp then return true end

    local owner = ent:GetCreator()
    if IsValid( owner ) and owner:IsPlayer() and owner.IsInBuild then
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

function JID.CanConstrain( ent, toConstrain, toolMode )
    if not IsValid( ent ) then return end
    if not IsValid( toConstrain ) then return end

    local entOwner = CPPI and ent:CPPIGetOwner() or ent:GetOwner()
    if not IsValid( entOwner ) then return end
    if CPPI and not toConstrain:CPPICanTool( entOwner, toolMode ) then return end

    local toConstrainOwner = CPPI and toConstrain:CPPIGetOwner() or toConstrain:GetOwner()
    if not IsValid( toConstrainOwner ) then return end
    if CPPI and not ent:CPPICanTool( toConstrainOwner, toolMode ) then return end

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
