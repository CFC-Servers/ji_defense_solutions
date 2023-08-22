AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:SpawnFunction( _, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 5
    local ent = ents.Create( "ent_jack_landmine" )
    ent:SetAngles( Angle( 0, 0, 0 ) )
    ent:SetPos( SpawnPos )
    ent:Spawn()
    ent:Activate()
    local effectdata = EffectData()
    effectdata:SetEntity( ent )
    util.Effect( "propspawn", effectdata )

    return ent
end

function ENT:Initialize()
    self:SetModel( "models/props_pipes/pipe02_connector01.mdl" )
    self:SetMaterial( "models/mat_jack_monotone_abu" )
    self:SetColor( Color( 50, 50, 50 ) )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:DrawShadow( true )
    self.Exploded = false
    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
        phys:SetMass( 20 )
    end

    self:SetUseType( SIMPLE_USE )
    self.Armed = false
    self.NextBounceNoiseTime = 0
    self:SetAngles( Angle( 90, 0, 0 ) )
end

function ENT:Detonate()
    if self.Exploded then return end
    self.Exploded = true

    local SelfPos = self:LocalToWorld( self:OBBCenter() )
    local EffectType = 1
    local Traec = util.QuickTrace( self:GetPos(), Vector( 0, 0, -5 ), self )

    if Traec.Hit then
        if Traec.MatType == MAT_DIRT or Traec.MatType == MAT_SAND then
            EffectType = 1
        elseif Traec.MatType == MAT_CONCRETE or Traec.MatType == MAT_TILE then
            EffectType = 2
        elseif Traec.MatType == MAT_METAL or Traec.MatType == MAT_GRATE then
            EffectType = 3
        elseif Traec.MatType == MAT_WOOD then
            EffectType = 4
        end
    else
        EffectType = 5
    end

    local plooie = EffectData()
    plooie:SetOrigin( SelfPos )
    plooie:SetScale( .75 )
    plooie:SetRadius( EffectType )
    plooie:SetNormal( vector_up )
    util.Effect( "eff_jack_minesplode", plooie, true, true )

    for _, playa in pairs( ents.FindInSphere( SelfPos, 50 ) ) do
        local Clayus = playa:GetClass()

        if playa:IsPlayer() or playa:IsNPC() or Clayuss == "prop_vehicle_jeep" or Clayuss == "prop_vehicle_jeep" or Clayus == "prop_vehicle_airboat" then
            playa:SetVelocity( playa:GetVelocity() + vector_up * 300 )
        end
    end

    util.BlastDamage( self, self:GetCreator(), SelfPos, 120, math.Rand( 65, 85 ) )
    util.BlastDamage( self, self:GetCreator(), SelfPos + vector_up * 100, 70, math.Rand( 55, 75 ) )
    util.ScreenShake( SelfPos, 99999, 99999, 1.5, 500 )

    for _, object in pairs( ents.FindInSphere( SelfPos, 75 ) ) do
        if object ~= self and IsValid( object:GetPhysicsObject() ) then
            local PhysObj = object:GetPhysicsObject()
            PhysObj:ApplyForceCenter( vector_up * 10000 )
            PhysObj:AddAngleVelocity( VectorRand() * math.Rand( 500, 3000 ) )
        end
    end

    self:EmitSound( "BaseExplosionEffect.Sound" )
    self:EmitSound( "snd_jack_fragsplodeclose.mp3", 90, 100 )
    sound.Play( "snd_jack_debris" .. tostring( math.random( 1, 2 ) ) .. ".mp3", SelfPos, 80, 100 )

    if self then
        self:Remove()
    end
end

function ENT:StartTouch( ent )
    if self.Armed then
        if not JID.CanTarget( self, ent, true ) then return end
        self:Detonate( ent )

        util.Decal( "Scorch", self:GetPos(), Vector( 0, 0, -5 ) )
    else
        if self.NextBounceNoiseTime < CurTime() then
            self:EmitSound( "SolidMetal.ImpactSoft" )
            self.NextBounceNoiseTime = CurTime() + 0.4
        end
    end
end
-- Both end and start touch have to be used otherwise it causes a hard crash.
function ENT:EndTouch( ent )
    if self.Armed then
        if not JID.CanTarget( self, ent, true ) then return end
        self:Detonate( ent )

        util.Decal( "Scorch", self:GetPos(), Vector( 0, 0, -5 ) )
    end
end

function ENT:OnTakeDamage( dmginfo )
    if self then
        self:TakePhysicsDamage( dmginfo )
    end

    if self.Armed and math.random( 1, 15 ) == 3 then
        self:Detonate()
    end
end

function ENT:Use( activator )
    if not activator:IsPlayer() then return end
    if self.Armed then return end

    local traceResult = util.QuickTrace( activator:GetShootPos(), activator:GetAimVector() * 100, { activator, self } )

    if not traceResult.Hit or not IsValid( traceResult.Entity:GetPhysicsObject() ) then
        return activator:PickupObject( self )
    end

    self:SetAngles( traceResult.HitNormal:Angle() )
    self:SetPos( traceResult.HitPos + traceResult.HitNormal )

    local canConstrain = JID.CanConstrain( self, traceResult.Entity )

    if canConstrain then
        self:SetParent( traceResult.Entity )
    else
        local phys = self:GetPhysicsObject()
        phys:EnableMotion( false )
    end

    self:Arm()
    JID.genericUseEffect( activator )
end

function ENT:Arm()
    self.Armed = true
    self:EmitSound( "snd_jack_pinpull.mp3", 65, 100 )
    self:EmitSound( "snd_jack_pinpull.mp3", 65, 100 )
    self:SetDTBool( 0, true )
end
