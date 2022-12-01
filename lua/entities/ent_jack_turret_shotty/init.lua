AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
ENT.Base = "ent_jack_turret_base"

ENT.TrackRate = 2
ENT.MaxRange = 900
ENT.FireRate = .8
ENT.BulletDamage = 22
ENT.ScanRate = 4
ENT.ShotSpread = .06
ENT.RoundInChamber = false
ENT.MaxBatteryCharge = 500
ENT.ShellEffect = "ShotgunShellEject"
ENT.BulletsPerShot = 10
ENT.TurretSkin = "models/mat_jack_shottyturret"
ENT.ShootSoundPitch = 100
ENT.NearShotNoise = "snd_jack_turretshootshot_close.mp3"
ENT.FarShotNoise = "snd_jack_turretshootshot_far.mp3"
ENT.AmmoType = "12GAshotshell"
ENT.MuzzEff = "muzzleflash_M3"
ENT.BarrelSizeMod = Vector( 2, 2, 1 )
ENT.Autoloading = false
ENT.CycleSound = "snd_jack_shottyturretcycle.mp3"
ENT.MechanicsSizeMod = 1.5

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 16
    local ent = ents.Create( "ent_jack_turret_shotty" )
    ent:SetPos( SpawnPos )
    ent:SetNWEntity( "Owner", ply )

    ent:Spawn()
    ent:Activate()
    local effectdata = EffectData()
    effectdata:SetEntity( ent )
    util.Effect( "propspawn", effectdata )

    return ent
end
