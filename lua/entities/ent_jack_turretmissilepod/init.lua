AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 16
    local ent = ents.Create( "ent_jack_turretmissilepod" )
    ent:SetPos( SpawnPos )
    ent:SetNWEntity( "Owner", ply )
    ent:Spawn()
    ent:Activate()
    local effectdata = EffectData()
    effectdata:SetEntity( ent )
    util.Effect( "propspawn", effectdata )

    return ent
end

function ENT:Initialize()
    self:SetModel( "models/weapons/w_rocket_jauncher.mdl" )
    self:SetMaterial( "models/weapons/w_Rocket_jauncher/w_rpg_sheet_missile" )

    if self.Empty then
        self:SetMaterial( "models/weapons/w_Rocket_jauncher/w_rpg_sheet_burnt" )
        self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
    end

    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:DrawShadow( true )
    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
        phys:SetMass( 70 )
    end

    self:SetUseType( SIMPLE_USE )
end

function ENT:PhysicsCollide( data )
    if data.Speed > 80 and data.DeltaTime > 0.2 then
        self:EmitSound( "DryWall.ImpactHard" )
    end
end

function ENT:OnTakeDamage( dmginfo )
    self:TakePhysicsDamage( dmginfo )
end

function ENT:Use( activator )
    if not self.Empty then
        activator:PickupObject( self )
    end
end
