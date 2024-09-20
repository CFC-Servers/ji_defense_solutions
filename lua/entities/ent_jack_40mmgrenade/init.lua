include( "shared.lua" )
local nadeSmokeTrailColor = Color( 255, 255, 255, 25 )
local smokeTrailLifetime = 5

local nadeTracerTrailColor = Color( 255, 255, 255 )
local nadeTracerLifetime = 0.05

function ENT:Initialize()
    self.ExplosiveMul = 0.5
    self.HardKillTime = CurTime() + 30
    self.NextEffect = 0

    self:SetModel( "models/Items/AR2_Grenade.mdl" )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetCollisionGroup( COLLISION_GROUP_NONE )
    self:SetUseType( SIMPLE_USE )
    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
        phys:SetMass( 7 )
    end

    local startWidth = 25
    local endWidth = 75
    local res = 1 / ( startWidth + endWidth ) * 0.5
    self.SmokeTrail = util.SpriteTrail( self, 0, nadeSmokeTrailColor, true, startWidth, endWidth, smokeTrailLifetime, res, "trails/smoke" )
    -- stupid hack so the trail sticks around after the shell hits
    self.SmokeTrail:SetParent( nil )

    startWidth = 25
    endWidth = 0
    res = 1 / ( startWidth + endWidth ) * 0.5
    self.TracerTrail = util.SpriteTrail( self, 0, nadeTracerTrailColor, true, startWidth, endWidth, nadeTracerLifetime, res, "trails/laser" )
    -- stupid hack so the trail sticks around after the shell hits
    self.TracerTrail:SetParent( nil )

    self:Fire( "enableshadow", "", 0 )
end

function ENT:PhysicsCollide( data )
    if data.Speed > 80 and data.DeltaTime > 0.1 then
        self:Detonate()
    end
end

function ENT:OnTakeDamage( dmginfo )
    self:TakePhysicsDamage( dmginfo )
end

function ENT:Think()
    if self.HardKillTime < CurTime() then
        self:Remove()
        return
    end
    local myPos = self:GetPos()

    if self.NextEffect < CurTime() then
        self.NextEffect = CurTime() + 0.05
        local effect = EffectData()
        effect:SetOrigin( myPos )
        effect:SetNormal( self:GetForward() )
        effect:SetScale( 0.8 )
        util.Effect( "eff_jack_rocketthrust", effect, true )
    end

    local smokeTrail = self.SmokeTrail
    if IsValid( smokeTrail ) then
        smokeTrail:SetPos( myPos )
    end

    local tracerTrail = self.TracerTrail
    if IsValid( tracerTrail ) then
        tracerTrail:SetPos( myPos )
    end

    self:NextThink( CurTime() + 0.01 )
    return true
end

local vecUp = Vector( 0, 0, 1 )

function ENT:Detonate()
    if self.Exploding then return end
    self.Exploding = true
    local pos = self:GetPos()

    util.ScreenShake( pos, 200, 20, 1, 750 )
    util.ScreenShake( pos, 1, 20, 2, 2000 )
    local owner = self:GetNWEntity( "Owner" )
    local attacker = owner
    if IsValid( attacker ) then
        local creator = attacker:GetCreator()
        attacker = IsValid( creator ) and creator or attacker
    end

    if not IsValid( attacker ) then attacker = self end

    util.BlastDamage( self, attacker, pos, owner.BulletDamage or 0, owner.BulletDamage or 0 )

    local plooie = EffectData()
    plooie:SetOrigin( self:GetPos() )
    plooie:SetScale( .75 )
    plooie:SetRadius( 2 )
    plooie:SetNormal( vecUp )
    util.Effect( "eff_jack_minesplode", plooie, true, true )

    self:Remove()
end

function ENT:OnRemove()
    local smokeTrail = self.SmokeTrail
    if IsValid( smokeTrail ) then
        SafeRemoveEntityDelayed( smokeTrail, smokeTrailLifetime )
    end

    local tracerTrail = self.TracerTrail
    if IsValid( tracerTrail ) then
        SafeRemoveEntityDelayed( tracerTrail, nadeTracerLifetime )
    end
end
