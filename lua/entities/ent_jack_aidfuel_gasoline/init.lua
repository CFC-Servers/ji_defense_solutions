AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 16
    local ent = ents.Create( "ent_jack_aidfuel_gasoline" )
    ent:SetPos( SpawnPos )
    ent:SetNWEntity( "Owenur", ply )
    ent:Spawn()
    ent:Activate()
    local effectdata = EffectData()
    effectdata:SetEntity( ent )
    util.Effect( "propspawn", effectdata )

    return ent
end

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

    for _, found in pairs( ents.FindInSphere( SelfPos, 150 ) ) do
        if IsValid( found:GetPhysicsObject() ) and self:Visible( found ) then
            found:Ignite( 15 )
        end
    end

    for _ = 0, 15 do
        local Tr = util.QuickTrace( SelfPos, VectorRand() * math.Rand( 200, 300 ), { self } )

        if Tr.Hit then
            util.Decal( "Scorch", Tr.HitPos + Tr.HitNormal, Tr.HitPos - Tr.HitNormal )
            local OhLawdyJeezusItsaFaar = ents.Create( "env_fire" )
            OhLawdyJeezusItsaFaar:SetKeyValue( "health", tostring( math.random( 10, 15 ) ) )
            OhLawdyJeezusItsaFaar:SetKeyValue( "firesize", tostring( math.random( 30, 120 ) ) )
            OhLawdyJeezusItsaFaar:SetKeyValue( "fireattack", "1" )
            OhLawdyJeezusItsaFaar:SetKeyValue( "damagescale", "20" )
            OhLawdyJeezusItsaFaar:SetKeyValue( "spawnflags", "128" )
            OhLawdyJeezusItsaFaar:SetPos( Tr.HitPos )
            OhLawdyJeezusItsaFaar:Spawn()
            OhLawdyJeezusItsaFaar:Activate()
            OhLawdyJeezusItsaFaar:Fire( "StartFire", "", 0 )
        end
    end

    sound.Play( "snd_jack_firebomb.mp3", SelfPos, 85, 130 )
    sound.Play( "snd_jack_gasolineburn.mp3", SelfPos, 80, 100 )
    self:Remove()
end
