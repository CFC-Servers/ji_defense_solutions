AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:Initialize()
    self:SetModel( "models/props_junk/PropaneCanister001a.mdl" )
    self:SetColor( Color( 200, 200, 200 ) )
    self:SetMaterial( "models/mat_jack_aidfuel_propane" )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:DrawShadow( true )
    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
        phys:SetMass( 35 )
    end

    self.StructuralIntegrity = 50
    self.Asploded = false
end

function ENT:PhysicsCollide( data )
    if data.Speed > 80 and data.DeltaTime > 0.2 then
        self:EmitSound( "Canister.ImpactHard" )
        self:EmitSound( "Wade.StepRight" )
        self:EmitSound( "Wade.StepLeft" )
    end
end

function ENT:OnTakeDamage( dmginfo )
    self:TakePhysicsDamage( dmginfo )
    self.StructuralIntegrity = self.StructuralIntegrity - dmginfo:GetDamage()

    if self.StructuralIntegrity <= 0 then
        self:Break()
    end
end

function ENT:Break()
    if self.Broken then return end
    self.Broken = true
    self.DieTime = CurTime() + math.Rand( 3, 5 )
    self.ThrustingSound = CreateSound( self, "PhysicsCannister.ThrusterLoop" )
    self.ThrustingSound:Play()

end

function ENT:Think()
    if self.Broken then
        if self.DieTime < CurTime() then
            self.ThrustingSound:Stop()
            self:Explode()
            return

        end
        local phys = self:GetPhysicsObject()
        if not IsValid( phys ) then return end
        phys:ApplyForceCenter( self:GetUp() * phys:GetMass() * 200 )

    end
end

function ENT:OnRemove()
    if not self.ThrustingSound then return end
    if not self.ThrustingSound:IsPlaying() then return end
    self.ThrustingSound:Stop()

end

function ENT:Explode()
    if self.Exploded then return end
    self.Exploded = true
    -- tiny explosion
    local explode = ents.Create( "env_explosion" )
    explode:SetPos( self:WorldSpaceCenter() )
    explode:SetOwner( self )
    explode:Spawn()
    explode:Activate()
    explode:SetKeyValue( "iMagnitude", "20" )
    explode:Fire( "Explode", 0, 0 )

    if IsValid( self.JackaGenerator ) then
        self.JackaGenerator:Fire( "Ignite", 15 )
    end

    self:Remove()
end
