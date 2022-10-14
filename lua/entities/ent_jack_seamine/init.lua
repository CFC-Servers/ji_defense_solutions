AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 32
    local ent = ents.Create( "ent_jack_seamine" )
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
    local Ang = self:GetAngles()

    Ang:RotateAroundAxis( Ang:Right(), 180 )
    self:SetAngles( Ang )
    self:SetModel( "models/magnet/submine/submine.mdl" )
    self:SetMaterial( "models/mat_jack_dullscratchedmetal" )
    self:SetColor( Color( 160, 170, 175 ) )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:DrawShadow( true )
    self.Exploded = false
    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
        phys:SetMass( 220 )
        phys:SetMaterial( "wood" )
        phys:SetDamping( .2, .2 )
    end

    self.NextUseTime = CurTime()
    self:SetUseType( SIMPLE_USE )
end

function ENT:Detonate()
    if self.Exploded then return end
    self.Exploded = true
    local SelfPos = self:LocalToWorld( self:OBBCenter() )

    if self:WaterLevel() > 0 then
        sound.Play( "ambient/water/water_splash" .. math.random( 1, 3 ) .. ".wav", SelfPos, 100, 100 )
        sound.Play( "ambient/water/water_splash" .. math.random( 1, 3 ) .. ".wav", SelfPos, 100, 99 )
        sound.Play( "ambient/water/water_splash" .. math.random( 1, 3 ) .. ".wav", SelfPos, 100, 90 )
        sound.Play( "ambient/water/water_splash" .. math.random( 1, 3 ) .. ".wav", SelfPos, 110, 80 )
        sound.Play( "ambient/water/water_splash" .. math.random( 1, 3 ) .. ".wav", SelfPos, 120, 70 )
        sound.Play( "ambient/water/water_splash" .. math.random( 1, 3 ) .. ".wav", SelfPos, 120, 60 )
        sound.Play( "ambient/water/water_splash" .. math.random( 1, 3 ) .. ".wav", SelfPos, 130, 50 )
        sound.Play( "ambient/water/water_splash" .. math.random( 1, 3 ) .. ".wav", SelfPos, 140, 40 )
        local splad = EffectData()
        splad:SetOrigin( SelfPos )
        splad:SetScale( 4 )
        util.Effect( "eff_jack_waterboom", splad, true, true )
    else
        sound.Play( "BaseExplosionEffect.Sound", SelfPos )
        sound.Play( "weapons/explode4.wav", SelfPos, 100, 150 )
        sound.Play( "snd_jack_bigsplodeclose.mp3", SelfPos, 110, 100 )
        sound.Play( "snd_jack_bigsplodeclose.mp3", SelfPos, 110, 100 )
        self:EmitSound( "BaseExplosionEffect.Sound" )
        sound.Play( "weapons/explode3.wav", self:GetPos(), 100, 150 )
        local splad = EffectData()
        splad:SetOrigin( SelfPos )
        splad:SetScale( 4 )
        util.Effect( "eff_jack_genericboom", splad, true, true )
    end

    util.BlastDamage( self, self:GetCreator(), SelfPos, 1000, 500 )
    util.ScreenShake( SelfPos, 99999, 99999, 1, 1000 )
    self:Remove()
end

function ENT:PhysicsCollide( data )
    if data.Speed > 80 and data.DeltaTime > 0.2 then
        self:EmitSound( "Canister.ImpactHard" )
    end

    if data.Speed > 5 and self.Armed then
        self:Detonate()
    end
end

function ENT:OnTakeDamage( dmginfo )
    if self.Armed and math.random( 1, 8 ) == 3 then
        self:Detonate()
    end

    self:TakePhysicsDamage( dmginfo )
end

function ENT:GravGunPunt()
    if self.Armed and math.random( 1, 100 ) == 1 then
        self:Detonate()
    end
    return true
end

function ENT:Use( activator )
    if not activator:IsPlayer() then return end
    if self.NextUseTime >= CurTime() then return end
    self.NextUseTime = CurTime() + .5

    if self.Armed then return end
    if self.Fuzed then return end

    self.Fuzed = true
    self:EmitSound( "snd_jack_pinpull.mp3", 65, 90 )

    timer.Simple( 3, function()
        if IsValid( self ) then
            self:EmitSound( "npc/metropolice/vo/shit.wav", 65, 90 )
            self.Armed = true
        end
    end )

    JID.genericUseEffect( activator )
end
