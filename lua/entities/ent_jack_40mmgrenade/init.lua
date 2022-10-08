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
    if data.Speed > 80 and data.DeltaTime > 0.2 then
        self:Detonate()
    end
end

function ENT:OnTakeDamage( dmginfo )
    self:TakePhysicsDamage( dmginfo )
end

function ENT:Detonate()
    if self.Exploding then return end
    self.Exploding = true
    local pos = self:GetPos()

    util.ScreenShake( pos, 99999, 99999, 1, 750 )

    local explode = ents.Create( "env_explosion" )
    explode:SetPos( self:GetPos() )
    explode:SetOwner( self:GetNWEntity( "Owner" ) )
    explode:Spawn()
    explode:Activate()
    explode:SetKeyValue( "iMagnitude", "190" )
    explode:Fire( "Explode", 0, 0 )

    for _ = 0, 30 do
        local Trayuss = util.QuickTrace( pos, VectorRand() * 200, { self } )

        if Trayuss.Hit then
            util.Decal( "FadingScorch", Trayuss.HitPos + Trayuss.HitNormal, Trayuss.HitPos - Trayuss.HitNormal )
        end
    end

    self:Remove()
end
