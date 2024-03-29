AddCSLuaFile( 'cl_init.lua' )
AddCSLuaFile( 'shared.lua' )
include( "shared.lua" )
ENT.Base = "ent_jack_turretammobox_base"
ENT.AmmoType = "5.56x45mm"
ENT.NumberOfRounds = 550

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 16
    local ent = ents.Create( "ent_jack_turretammobox_556" )
    ent:SetPos( SpawnPos )
    ent:SetNWEntity( "Owner", ply )
    ent:Spawn()
    ent:Activate()
    local effectdata = EffectData()
    effectdata:SetEntity( ent )
    util.Effect( "propspawn", effectdata )

    return ent
end