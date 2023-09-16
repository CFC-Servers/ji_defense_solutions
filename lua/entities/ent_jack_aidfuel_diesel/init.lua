AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:Initialize()
    self:SetModel( "models/props_lab/harddrive02.mdl" )
    self:SetColor( Color( 31, 31, 31 ) )
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
end

function ENT:OnTakeDamage( dmginfo )
    self:TakePhysicsDamage( dmginfo )
    self.StructuralIntegrity = self.StructuralIntegrity - dmginfo:GetDamage()

    if self.StructuralIntegrity <= 0 then
        self:Remove()
    end
end