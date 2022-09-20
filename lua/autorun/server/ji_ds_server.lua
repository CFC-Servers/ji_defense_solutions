hook.Add( "PlayerDisconnected", "JackaPlyDisconn", Disconn )
local function CmdDet( ... )
    local args = { ... }
    local ply = args[1]
    ply:ConCommand( "jacky_claymore_det" )
end
concommand.Add( "jacky_remote_det", CmdDet )

function JackaGenericUseEffect( ply )
    if ply:IsPlayer() then
        local Wep = ply:GetActiveWeapon()
        if IsValid( Wep ) then Wep:SendWeaponAnim( ACT_VM_DRAW ) end
        ply:ViewPunch( Angle( 1, 0, 0 ) )
        ply:SetAnimation( PLAYER_ATTACK1 )
    end
end
