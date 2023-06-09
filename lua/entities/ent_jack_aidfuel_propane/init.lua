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

    self.StructuralIntegrity = 100
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
end
