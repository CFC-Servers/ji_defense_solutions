AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
ENT.Base = "ent_jack_turret_base"

local HULL_TARGETING = {
    [HULL_TINY] = -5,
    [HULL_TINY_CENTERED] = 0,
    [HULL_SMALL_CENTERED] = -5,
    [HULL_HUMAN] = 10,
    [HULL_WIDE_SHORT] = 20,
    [HULL_WIDE_HUMAN] = 15,
    [HULL_MEDIUM] = 0,
    [HULL_MEDIUM_TALL] = 35,
    [HULL_LARGE] = 30,
    [HULL_LARGE_CENTERED] = 30
}


ENT.TrackRate = .2
ENT.MaxRange = 6000
ENT.FireRate = .2
ENT.BulletDamage = 200
ENT.ScanRate = .75
ENT.ShotSpread = .017
ENT.RoundsOnBelt = 0
ENT.RoundInChamber = false
ENT.MaxBatteryCharge = 3000
ENT.ShellEffect = "RifleShellEject"
ENT.BulletsPerShot = 1
ENT.TurretSkin = "models/mat_jack_grenadeturret"
ENT.ShootSoundPitch = 100
ENT.NearShotNoise = "snd_jack_turretshootgl_close.mp3"
ENT.FarShotNoise = "snd_jack_turretshootgl_far.mp3"
ENT.AmmoType = "40x53mm Grenade"
ENT.MuzzEff = "muzzleflash_m79"
ENT.BarrelSizeMod = Vector( 2.1, 2.1, 1 )
ENT.Autoloading = false
ENT.CycleSound = "snd_jack_glcycle.mp3"
ENT.MechanicsSizeMod = 2.1

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 16
    local ent = ents.Create( "ent_jack_turret_grenade" )
    ent:SetPos( SpawnPos )
    ent:SetNWEntity( "Owner", ply )

    ent:Spawn()
    ent:Activate()
    local effectdata = EffectData()
    effectdata:SetEntity( ent )
    util.Effect( "propspawn", effectdata )

    return ent
end

local function GetCenterMass( ent )
    local Pos = ent:LocalToWorld( ent:OBBCenter() )
    local Hull

    if not ent.GetHullType then
        Hull = HULL_HUMAN
    else
        Hull = ent:GetHullType()
    end

    local Add = Vector( 0, 0, HULL_TARGETING[Hull] )

    if string.find( ent:GetClass(), "vehicle", 1, false ) then
        Add = Vector( 0, 0, 0 )
    end

    Pos = Pos + Add

    if ent:IsPlayer() and ent:Crouching() then
        Pos = Pos - Vector( 0, 0, 20 )
    end

    return Pos
end

function ENT:FireShot()
    self:StandBy()

    local Time = CurTime()
    self.BatteryCharge = self.BatteryCharge - .1

    if self.WillWarn then
        if not ( self.NextWarnTime < CurTime() ) then
            if self.NextWarnTime < CurTime() then
                self:HostileAlert()
                self.NextWarnTime = CurTime() + 1
            end

            return
        end
    end

    if self.RoundInChamber then
        --self:ResetSequence(3) --prollem with this is the flash
        if self.Heat >= 95 then
            if self.NextOverHeatWhineTime < Time then
                self.NextOverHeatWhineTime = Time + .5
                self:Whine()
            end

            return
        end

        self:ManipulateBoneScale( 3, Vector( self.BarrelSizeMod.x, self.BarrelSizeMod.y, self.BarrelSizeMod.z * .75 ) )

        timer.Simple( .1, function()
            if IsValid( self ) then
                self:ManipulateBoneScale( 3, self.BarrelSizeMod )
            end
        end )

        local SelfPos = self:GetPos() + self:GetUp() * 55
        local TargPos

        if not IsValid( self.CurrentTarget ) then return end

        TargPos = GetCenterMass( self.CurrentTarget )

        local Dist = ( self:GetPos() - TargPos ):Length()

        if Dist <= 400 then
            self:HostileAlert()

            return
        end

        TargPos = TargPos + Vector( 0, 0, Dist / 60 )
        local Vec = TargPos - SelfPos
        local Dir = Vec:GetNormalized()
        local Spred = self.ShotSpread

        local Phys = self.CurrentTarget:GetPhysicsObject()

        if IsValid( Phys ) then
            local RelSpeed = ( Phys:GetVelocity() - self:GetPhysicsObject():GetVelocity() ):Length()
            Spred = Spred + RelSpeed / 100000
        end

        Dir = ( Dir + VectorRand() * Spred ):GetNormalized()
        --fire round
        local Grenade = ents.Create( "ent_jack_40mmgrenade" )
        Grenade.ParentLauncher = self
        self.MostRecentGrenade = Grenade
        Grenade:SetNWEntity( "Owner", self )
        Grenade:SetPos( SelfPos )
        local Ang = Dir:Angle()
        Grenade:SetAngles( Ang )
        Grenade.Type = "HE"
        Grenade:Spawn()
        Grenade:Activate()
        constraint.NoCollide( self, Grenade )
        Grenade:GetPhysicsObject():SetVelocity( self:GetPhysicsObject():GetVelocity() + Dir * 7500 ) --the Mk.19 throws its grenades typically at about 240mps
        self.FiredAtCurrentTarget = true
        self.RoundInChamber = false
        self.Heat = self.Heat + 5
        local Scayul = 1
        sound.Play( self.NearShotNoise, SelfPos, 70, self.ShootSoundPitch )
        sound.Play( self.FarShotNoise, SelfPos + Vector( 0, 0, 1 ), 90, self.ShootSoundPitch - 10 )
        sound.Play( self.NearShotNoise, SelfPos, 75, self.ShootSoundPitch )
        sound.Play( self.FarShotNoise, SelfPos + Vector( 0, 0, 2 ), 110, self.ShootSoundPitch - 10 )
        local PosAng = self:GetAttachment( 1 )
        local ThePos = PosAng.Pos + PosAng.Ang:Forward() * self.BarrelSizeMod.z * 5

        if math.random( 1, 2 ) == 1 then
            ParticleEffect( "muzzleflash_suppressed", ThePos, PosAng.Ang, self )
        else
            ParticleEffect( self.MuzzEff, ThePos, PosAng.Ang, self )
            local effectd = EffectData()
            effectd:SetStart( ThePos )
            effectd:SetNormal( PosAng.Ang:Forward() )
            effectd:SetScale( 1 )
            util.Effect( "eff_jack_turretmuzzlelight", effectd, true, true )
        end

        if self.RoundsOnBelt > 0 then
            timer.Simple( 1 / self.FireRate * .25, function()
                if IsValid( self ) then
                    self:EmitSound( self.CycleSound, 68, 100 )
                end
            end )

            timer.Simple( 1 / self.FireRate * .35, function()
                if IsValid( self ) then
                    self.RoundsOnBelt = self.RoundsOnBelt - 1
                    self.RoundInChamber = true
                    --shell effect
                    local Forward = self:GetForward()
                    local Up = self:GetUp()
                    local Right = self:GetRight()
                    local Shell = ents.Create( "prop_physics" )
                    Shell:SetModel( "models/hunter/plates/plate.mdl" )
                    Shell:SetPos( SelfPos + Right * 5 )
                    Shell:SetAngles( self:GetAngles() )
                    Shell:Spawn()
                    Shell:Activate()
                    constraint.NoCollide( self, Shell )
                    Shell:GetPhysicsObject():SetVelocity( self:GetPhysicsObject():GetVelocity() - Forward * 10 + Up * 30 + Right * 30 + VectorRand() * 10 )
                    Shell:GetPhysicsObject():AddAngleVelocity( VectorRand() * math.Rand( 10, 3000 ) )
                    Shell:GetPhysicsObject():SetMaterial( "metal_bouncy" )
                    Shell:GetPhysicsObject():SetDamping( 1, 5 )
                    Shell:SetNoDraw( true )
                    local Pert = ents.Create( "prop_dynamic" )
                    Pert:SetModel( "models/weapons/shell.mdl" )
                    Pert:SetPos( Shell:GetPos() )
                    Pert:SetAngles( Shell:GetAngles() )
                    Pert:SetParent( Shell )
                    Pert:Spawn()
                    Pert:Activate()
                    Pert:SetModelScale( 1.8, 0 )
                    Shell:SetCollisionGroup( COLLISION_GROUP_WEAPON )
                    SafeRemoveEntityDelayed( Shell, 30 )
                end
            end )
        end

        self:GetPhysicsObject():ApplyForceOffset( -Dir * self.BulletDamage * 6 * self.BulletsPerShot, SelfPos + self:GetUp() * 30 )
    else
        self:EmitSound( "snd_jack_turretclick.mp3", 70, 110 )

        if self.NextWhineTime < CurTime() then
            self:Whine()
            self.NextWhineTime = CurTime() + 2.25
        end
    end
end
