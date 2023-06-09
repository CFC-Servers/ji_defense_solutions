AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
ENT.Base = "ent_jack_turret_base"

ENT.TrackRate = 1.4
ENT.MaxRange = 1750
ENT.FireRate = 12
ENT.BulletDamage = 10
ENT.ScanRate = 2.25
ENT.ShotSpread = .038
ENT.IdleDrainMul = 2
ENT.ShellEffect = "ShellEject"
ENT.BulletsPerShot = 1
ENT.TurretSkin = "models/mat_jack_pistolturret"
ENT.ShootSoundPitch = 110
ENT.NearShotNoise = "snd_jack_turretshootshort_close.mp3"
ENT.FarShotNoise = "snd_jack_turretshootshort_far.mp3"
ENT.AmmoType = "9x19mm"
ENT.MuzzEff = "muzzleflash_pistol"
ENT.Automatic = true
ENT.BarrelSizeMod = Vector( 1, 1, 1 )
ENT.Autoloading = true
ENT.MechanicsSizeMod = 1

ENT.PropThicknessToEngageSqr = 50^2
ENT.PropThicknessToDisengageSqr = 100^2

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 5
    local ent = ents.Create( "ent_jack_turret_smg" )
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
    util.ScreenShake( self:GetPos(), 1, 20, 0.25, 700 )
end