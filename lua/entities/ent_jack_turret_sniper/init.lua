AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
ENT.Base = "ent_jack_turret_base"

ENT.TrackRate = .15
ENT.MaxRange = 6000
ENT.FireRate = .15
ENT.BulletDamage = 50
ENT.ScanRate = 1.5
ENT.ShotSpread = .002
ENT.RoundInChamber = false
ENT.MaxBatteryCharge = 500
ENT.ShellEffect = "RifleShellEject"
ENT.BulletsPerShot = 1
ENT.TurretSkin = "models/mat_jack_sniperturret"
ENT.ShootSoundPitch = 80
ENT.NearShotNoise = "snd_jack_turretshoot_close.mp3"
ENT.FarShotNoise = "snd_jack_turretshoot_far.mp3"
ENT.AmmoType = "7.62x51mm"
ENT.MuzzEff = "muzzleflash_sr25"
ENT.BarrelSizeMod = Vector( 1, 1, 3 )
ENT.Autoloading = false
ENT.CycleSound = "snd_jack_sniperturretcycle.mp3"
ENT.MechanicsSizeMod = 1.5

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 16
    local ent = ents.Create( "ent_jack_turret_sniper" )
    ent:SetPos( SpawnPos )
    ent:SetNWEntity( "Owner", ply )

    ent:Spawn()
    ent:Activate()
    local effectdata = EffectData()
    effectdata:SetEntity( ent )
    util.Effect( "propspawn", effectdata )

    return ent
end
