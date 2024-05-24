AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
ENT.Base = "ent_jack_turret_base"

ENT.TrackRate = .06
ENT.MaxRange = 6000
ENT.FireRate = .75
ENT.BulletDamage = 60
ENT.ScanRate = .60
ENT.ShotSpread = .003
ENT.RoundInChamber = false
ENT.IdleDrainMul = 6 -- annoying turret to fight, so takes lots of maintinance to keep running
ENT.ShellEffect = "RifleShellEject"
ENT.BulletsPerShot = 1
ENT.TurretSkin = "models/mat_jack_sniperturret"
ENT.ShootSoundPitch = 80
ENT.NearShotNoise = "snd_jack_turretshoot_close.mp3"
ENT.FarShotNoise = "snd_jack_turretshoot_far.mp3"
ENT.AmmoType = "7.62x51mm"
ENT.MuzzEff = "muzzleflash_sr25"
ENT.BarrelSizeMod = Vector( 1.5, 1.25, 4.5 )
ENT.Autoloading = true
ENT.CycleSound = "snd_jack_sniperturretcycle.mp3"
ENT.MechanicsSizeMod = 2.5
ENT.WillLight = true
ENT.WillLightOverride = true
ENT.TracerEffect = "StriderTracer"


ENT.MaxStructuralIntegrity = 400
ENT.StructuralIntegrity = 400

ENT.PropThicknessToDisengageSqr = 200^2

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 5
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

function ENT:AdditionalShootFX()
    util.ScreenShake( self:GetPos(), 4, 20, 0.25, 700 )
end