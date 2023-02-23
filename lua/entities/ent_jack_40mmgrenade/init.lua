include( "shared.lua" )

function ENT:Initialize()
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

    self:Fire( "enableshadow", "", 0 )
    self.Exploded = false
    self.ExplosiveMul = 0.5
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
    local effect = EffectData()
    effect:SetOrigin( self:GetPos() )
    effect:SetNormal( self:GetForward() )
    effect:SetScale( 0.8 )
    util.Effect( "eff_jack_rocketthrust", effect, true, true )
    self:NextThink( CurTime() + 0.01 )
    return true
end

local vecUp = Vector( 0,0,1 )

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

    util.BlastDamage( self, attacker, pos, owner.BulletDamage, owner.BulletDamage )

    local plooie = EffectData()
    plooie:SetOrigin( self:GetPos() )
    plooie:SetScale( .75 )
    plooie:SetRadius( 2 )
    plooie:SetNormal( vecUp )
    util.Effect( "eff_jack_minesplode", plooie, true, true )

    self:Remove()
end
