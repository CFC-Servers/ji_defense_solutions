--gernaaaayud
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
ENT.MotorPower = 0

function ENT:Initialize()
    self:SetModel( "models/hawx/weapons/agm-65 maverick.mdl" )
    self:SetMaterial( "models/mat_jack_sidewinderaam" )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetCollisionGroup( COLLISION_GROUP_NONE )
    self:SetUseType( SIMPLE_USE )
    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
        phys:SetMass( 15 )
        --phys:EnableGravity(false)
        phys:EnableDrag( false )
    end

    self:Fire( "enableshadow", "", 0 )
    self.Exploded = false
    self.ExplosiveMul = 0.5
    self.MotorFired = false
    self.Engaged = false
    self:SetModelScale( .25, 0 )
    self:SetColor( Color( 10, 15, 20 ) )
    util.PrecacheSound( "snd_jack_missilemotorfire.mp3" )
    self.InitialAng = self:GetAngles()

    timer.Simple( .15, function()
        if IsValid( self ) then
            self:FireMotor()
        end
    end )

    local Settins = physenv.GetPerformanceSettings()

    if Settins.MaxVelocity < 3000 then
        Settins.MaxVelocity = 3000
        physenv.SetPerformanceSettings( Settins )
    end
    --if not(self.InitialVel)then self.InitialVel=Vector(0,0,0) end
end

function ENT:FireMotor()
    if self.MotorFired then return end
    self.MotorFired = true
    sound.Play( "snd_jack_missilemotorfire.mp3", self:GetPos(), 85, 110 )
    sound.Play( "snd_jack_missilemotorfire.mp3", self:GetPos() + Vector( 0, 0, 1 ), 88, 110 )
    self:SetDTBool( 0, true )
    self.Engaged = true
end

function ENT:PhysicsCollide( data )
    if data.Speed > 80 and data.DeltaTime > .2 then
        self:Detonate()
    end
end

function ENT:OnTakeDamage( dmginfo )
    self:TakePhysicsDamage( dmginfo )
end

function ENT:Think()
    if self.Exploded then return end

    if not self.Engaged then
        self:GetPhysicsObject():EnableGravity( false )
        self:SetAngles( self.InitialAng )
        self:GetPhysicsObject():SetVelocity( self.InitialVel )
    end

    if self.MotorFired then
        local Flew = EffectData()
        Flew:SetOrigin( self:GetPos() - self:GetRight() * 20 )
        Flew:SetNormal( -self:GetRight() )
        Flew:SetScale( 5 )
        util.Effect( "eff_jack_rocketthrust", Flew )
        local Phys = self:GetPhysicsObject()
        Phys:EnableGravity( false )
        Phys:ApplyForceCenter( self:GetRight() * self.MotorPower )
        self.MotorPower = self.MotorPower + 1500

        if self.MotorPower >= 160000 then
            self.MotorPower = 160000
        end
    end

    self:NextThink( CurTime() + .025 )

    return true
end

function ENT:Detonate()
    if self.Exploding then return end
    self.Exploding = true
    local SelfPos = self:GetPos()
    local Pos = SelfPos

    if true then
        --[[-  EFFECTS  -]]
        util.ScreenShake( SelfPos, 99999, 99999, 1, 750 )
        local Boom = EffectData()
        Boom:SetOrigin( SelfPos )
        Boom:SetScale( 2.25 )
        util.Effect( "eff_jack_genericboom", Boom, true, true )

        --ParticleEffect("100lb_air",SelfPos,self:GetAngles())
        for key, thing in pairs( ents.FindInSphere( SelfPos, 500 ) ) do
            if thing:IsNPC() and self:Visible( thing ) then
                if table.HasValue( { "npc_strider", "npc_combinegunship", "npc_helicopter", "npc_turret_floor", "npc_turret_ground", "npc_turret_ceiling" }, thing:GetClass() ) then
                    thing:SetHealth( 1 )
                    thing:Fire( "selfdestruct", "", .5 )
                end
            end
        end

        util.BlastDamage( self, self, SelfPos, 600, 400 )
        self:EmitSound( "snd_jack_fragsplodeclose.mp3", 80, 100 )
        sound.Play( "snd_jack_fragsplodeclose.mp3", SelfPos + Vector( 0, 0, 1 ), 75, 80 )
        sound.Play( "snd_jack_fragsplodefar.mp3", SelfPos + Vector( 0, 0, 2 ), 100, 80 )

        for i = 0, 40 do
            local Trayuss = util.QuickTrace( SelfPos, VectorRand() * 200, { self } )

            if Trayuss.Hit then
                util.Decal( "Scorch", Trayuss.HitPos + Trayuss.HitNormal, Trayuss.HitPos - Trayuss.HitNormal )
            end
        end

        for key, obj in pairs( ents.FindInSphere( SelfPos, 250 ) ) do
            if IsValid( obj:GetPhysicsObject() ) then
                if obj:Visible( self ) and not obj.JackyArmoredPanel then
                    if obj:GetPhysicsObject():GetMass() < 800 then
                        constraint.RemoveAll( obj )
                    end
                end
            end
        end

        self:Remove()
    end
end
