AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
ENT.Base = "ent_jack_turret_base"

ENT.TrackRate = 2
ENT.MaxRange = 1750
ENT.FireRate = 3
ENT.BulletDamage = 8
ENT.ScanRate = 1.5
ENT.ShotSpread = .020
ENT.RoundInChamber = false
ENT.IdleDrainMul = 0.5
ENT.ShellEffect = "ShellEject"
ENT.BulletsPerShot = 1
ENT.TurretSkin = "models/mat_jack_plinkerturret"
ENT.ShootSoundPitch = 125
ENT.NearShotNoise = "snd_jack_turretshootshort_close.mp3"
ENT.FarShotNoise = "snd_jack_turretshootshort_far.mp3"
ENT.AmmoType = ".22 Long Rifle"
ENT.MuzzEff = "muzzleflash_pistol"
ENT.BarrelSizeMod = Vector( .8, .8, .8 )
ENT.Autoloading = true
ENT.MechanicsSizeMod = .75

ENT.MaxStructuralIntegrity = 150
ENT.StructuralIntegrity = 150

ENT.SpawnsWithBattery = true
ENT.SpawnsWithAmmo = true
ENT.SpawnInClunk = false

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 5
    local ent = ents.Create( "ent_jack_turret_plinker" )
    ent:SetPos( SpawnPos )
    ent:SetNWEntity( "Owner", ply )

    ent:Spawn()
    ent:Activate()
    local effectdata = EffectData()
    effectdata:SetEntity( ent )
    util.Effect( "propspawn", effectdata )

    return ent
end
