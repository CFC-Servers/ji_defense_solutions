AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:Initialize()
    self:SetModel( "models/props_lab/harddrive02.mdl" )
    self:SetColor( Color( 175, 50, 50 ) )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:DrawShadow( true )
    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
        phys:SetMass( 35 )
    end
end

function ENT:PhysicsCollide( data )
    if data.Speed > 80 and data.DeltaTime > 0.2 then
        self:EmitSound( "Wade.StepRight" )
        self:EmitSound( "Wade.StepLeft" )
        self:EmitSound( "Metal_Box.ImpactHard" )
    end
end

function ENT:OnTakeDamage( dmginfo )
    self:TakePhysicsDamage( dmginfo )
end
