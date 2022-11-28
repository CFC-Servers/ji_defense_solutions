AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
ENT.Base = "ent_jack_turret_base"

ENT.TrackRate = 2.25
ENT.MaxRange = 1125
ENT.FireRate = 2
ENT.BulletDamage = 40
ENT.ScanRate = 3
ENT.ShotSpread = .035
ENT.RoundsOnBelt = 0
ENT.RoundInChamber = false
ENT.MaxBatteryCharge = 3000
ENT.ShellEffect = "ShellEject"
ENT.BulletsPerShot = 1
ENT.TurretSkin = "models/mat_jack_pistolturret"
ENT.ShootSoundPitch = 110
ENT.NearShotNoise = "snd_jack_turretshootshort_close.mp3"
ENT.FarShotNoise = "snd_jack_turretshootshort_far.mp3"
ENT.AmmoType = "9x19mm"
ENT.MuzzEff = "muzzleflash_pistol"
ENT.BarrelSizeMod = Vector( .9, .9, .9 )
ENT.Autoloading = true
ENT.MechanicsSizeMod = 1

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 16
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
