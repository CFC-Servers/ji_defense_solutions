AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
ENT.Base = "ent_jack_turret_base"

ENT.TrackRate = .23
ENT.MaxRange = 2700
ENT.FireRate = 11.5
ENT.BulletDamage = 20
ENT.ScanRate = 2
ENT.ShotSpread = .01
ENT.RoundInChamber = false
ENT.MaxBatteryCharge = 2000
ENT.IdleDrainMul = 2
ENT.ShellEffect = "RifleShellEject"
ENT.BulletsPerShot = 1
ENT.TurretSkin = "models/mat_jack_sniperturret"
ENT.ShootSoundPitch = 83
ENT.NearShotNoise = "snd_jack_turretshoot_close.mp3"
ENT.FarShotNoise = "snd_jack_turretshoot_far.mp3"
ENT.AmmoType = "5.56x45mm"
ENT.MuzzEff = "muzzleflash_sr25"
ENT.Automatic = true
ENT.BarrelSizeMod = Vector( 1.5, 1.5, 3.5 )
ENT.Autoloading = true
ENT.MechanicsSizeMod = 2.2
ENT.TracerEffect = "StriderTracer"

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 5
    local ent = ents.Create( "ent_jack_turret_mg" )
    ent:SetPos( SpawnPos )
    ent:SetNWEntity( "Owner", ply )

    ent:Spawn()
    ent:Activate()
    local effectdata = EffectData()
    effectdata:SetEntity( ent )
    util.Effect( "propspawn", effectdata )

    return ent
end

function ENT:AdditionalShootFX()
    util.ScreenShake( self:GetPos(), 2, 20, 0.25, 700 )
end