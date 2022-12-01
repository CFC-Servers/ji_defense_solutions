AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
ENT.Base = "ent_jack_turret_base"

ENT.TrackRate = .275
ENT.MaxRange = 4500
ENT.FireRate = 1
ENT.BulletDamage = 20
ENT.ScanRate = 0.75
ENT.ShotSpread = .0055
ENT.RoundInChamber = false
ENT.MaxBatteryCharge = 3000
ENT.ShellEffect = "RifleShellEject"
ENT.BulletsPerShot = 1
ENT.TurretSkin = "models/mat_jack_rifleturret"
ENT.ShootSoundPitch = 105
ENT.NearShotNoise = "snd_jack_turretshoot_close.mp3"
ENT.FarShotNoise = "snd_jack_turretshoot_far.mp3"
ENT.AmmoType = "5.56x45mm"
ENT.MuzzEff = "muzzleflash_smg"
ENT.BarrelSizeMod = Vector( 1, 1, 2.25 )
ENT.Autoloading = true
ENT.MechanicsSizeMod = 1

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 16
    local ent = ents.Create( "ent_jack_turret_dmr" )
    ent:SetPos( SpawnPos )
    ent:SetNWEntity( "Owner", ply )

    ent:Spawn()
    ent:Activate()
    local effectdata = EffectData()
    effectdata:SetEntity( ent )
    util.Effect( "propspawn", effectdata )

    return ent
end
