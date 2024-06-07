AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
ENT.Base = "ent_jack_turret_base"

ENT.TrackRate = 1.75
ENT.MaxRange = 1750
ENT.FireRate = 2.5
ENT.BulletDamage = 12
ENT.ScanRate = 1.5
ENT.ShotSpread = .010
ENT.RoundInChamber = false
ENT.IdleDrainMul = 0.75
ENT.ShellEffect = "ShellEject"
ENT.BulletsPerShot = 1
ENT.TurretSkin = "models/mat_jack_pistolturret"
ENT.ShootSoundPitch = 110
ENT.NearShotNoise = "snd_jack_turretshootshort_close.mp3"
ENT.FarShotNoise = "snd_jack_turretshootshort_far.mp3"
ENT.AmmoType = "9x19mm"
ENT.MuzzEff = "muzzleflash_pistol"
ENT.Automatic = nil
ENT.BarrelSizeMod = Vector( 0.9, 0.9, 0.9 )
ENT.Autoloading = true
ENT.MechanicsSizeMod = 0.9

ENT.MaxStructuralIntegrity = 200
ENT.StructuralIntegrity = 200

ENT.SpawnsWithBattery = true
ENT.SpawnsWithAmmo = true
ENT.SpawnInClunk = false

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 5
    local ent = ents.Create( "ent_jack_turret_pistol" )
    ent:SetPos( SpawnPos )
    ent:SetNWEntity( "Owner", ply )

    ent:Spawn()
    ent:Activate()
    local effectdata = EffectData()
    effectdata:SetEntity( ent )
    util.Effect( "propspawn", effectdata )

    return ent
end
