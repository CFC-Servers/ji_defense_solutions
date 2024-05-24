AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
ENT.Base = "ent_jack_turret_base"

ENT.TrackRate = 3
ENT.MaxRange = 900
ENT.FireRate = 1.5
ENT.BulletDamage = 14
ENT.ScanRate = 3
ENT.ShotSpread = .072
ENT.RoundInChamber = false
ENT.IdleDrainMul = 2
ENT.ShellEffect = "ShotgunShellEject"
ENT.BulletsPerShot = 12
ENT.TurretSkin = "models/mat_jack_shottyturret"
ENT.ShootSoundPitch = 90
ENT.NearShotNoise = "snd_jack_turretshootshot_close.mp3"
ENT.FarShotNoise = "snd_jack_turretshootshot_far.mp3"
ENT.AmmoType = "12GAshotshell"
ENT.MuzzEff = "muzzleflash_M3"
ENT.BarrelSizeMod = Vector( 2, 2, 1 )
ENT.Autoloading = false
ENT.CycleSound = "snd_jack_shottyturretcycle.mp3"
ENT.MechanicsSizeMod = 1.9

ENT.MaxStructuralIntegrity = 600
ENT.StructuralIntegrity = 600

ENT.PropThicknessToDisengageSqr = 100^2

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 5
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

function ENT:AdditionalShootFX()
    util.ScreenShake( self:GetPos(), 4, 20, 0.25, 700 )
end