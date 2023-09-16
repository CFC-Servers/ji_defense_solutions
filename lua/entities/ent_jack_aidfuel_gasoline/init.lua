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

    self.StructuralIntegrity = 100
    self.Asploded = false
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
    self.StructuralIntegrity = self.StructuralIntegrity - dmginfo:GetDamage()

    if self.StructuralIntegrity <= 0 then
        self:Asplode()
    end
end

function ENT:Asplode()
    if self.Asploded then return end
    self.Asploded = true
    local SelfPos = self:LocalToWorld( self:OBBCenter() )
    local Poof = EffectData()
    Poof:SetOrigin( SelfPos )
    Poof:SetScale( 1 )
    util.Effect( "eff_jack_gasolineburst", Poof, true, true )

    -- tiny explosion
    local explode = ents.Create( "env_explosion" )
    explode:SetPos( self:WorldSpaceCenter() )
    explode:SetOwner( self )
    explode:Spawn()
    explode:Activate()
    explode:SetKeyValue( "iMagnitude", "20" )
    explode:Fire( "Explode", 0, 0 )

    sound.Play( "snd_jack_firebomb.mp3", SelfPos, 85, 130 )
    sound.Play( "snd_jack_gasolineburn.mp3", SelfPos, 80, 100 )
    if IsValid( self.JackaGenerator ) then
        self.JackaGenerator:Fire( "Ignite", 15 )
    end

    self:Remove()
end
