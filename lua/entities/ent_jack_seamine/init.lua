AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

local vec_up = Vector( 0, 0, 1 )

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

    self:EmitSound( "snd_jack_metallicclick.mp3", 75, math.random( 80, 90 ) )
    util.ScreenShake( self:GetPos(), 10, 20, 1, 500 )
    self:GetPhysicsObject():ApplyForceCenter( vec_up * 50000 ) --bounce!
    self:GetPhysicsObject():ApplyTorqueCenter( vec_up * 50000 ) --spin!

    timer.Simple( 0.5, function()
        if not IsValid( self ) then return end

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
            splad:SetScale( 10 )
            util.Effect( "eff_jack_waterboom", splad, true, true )
        else
            sound.Play( "BaseExplosionEffect.Sound", SelfPos )
            sound.Play( "weapons/explode4.wav", SelfPos, 100, 150 )
            sound.Play( "snd_jack_bigsplodeclose.mp3", SelfPos, 110, 100 )
            sound.Play( "snd_jack_bigsplodeclose.mp3", SelfPos, 110, 100 )
            sound.Play( "npc/env_headcrabcanister/explosion.wav", SelfPos, 110, 100 )
            sound.Play( "ambient/explosions/explode_2.wav", SelfPos, 110, 50 )
            self:EmitSound( "BaseExplosionEffect.Sound" )
            sound.Play( "weapons/explode3.wav", self:GetPos(), 100, 150 )
            local splad = EffectData()
            splad:SetOrigin( SelfPos )
            splad:SetScale( 10 )
            util.Effect( "eff_jack_genericboom", splad, true, true )
        end

        local damager = self.Armer
        if not IsValid( damager ) then
            damager = self:GetCreator()
        end
        if not IsValid( damager ) then
            damager = self
        end

        util.BlastDamage( self, damager, SelfPos, 3000, 20000 )
        util.ScreenShake( SelfPos, 99999, 99999, 1, 1000 )
        self:Remove()
    end )
end

function ENT:PhysicsCollide( data )
    if data.Speed > 300 and data.DeltaTime > 0.2 then
        self:EmitSound( "Canister.ImpactHard" )
        self:EmitSound( "EpicMetal.ImpactHard", 100, math.random( 70, 80 ), 1, CHAN_STATIC, SND_CHANGE_PITCH )
    elseif data.Speed > 25 and data.DeltaTime > 0.1 then
        self:EmitSound( "Canister.ImpactSoft" )
        self:EmitSound( "EpicMetal.ImpactSoft", 85, math.random( 70, 80 ), 1, CHAN_STATIC, SND_CHANGE_PITCH )
        if self.Armed then
            self:Detonate()
        end
    end
end

function ENT:OnTakeDamage( dmginfo )
    if self.Armed and ( dmginfo:GetDamage() > 300 or math.random( 1, 4 ) == 3 ) then
        self:Detonate()
    end

    self:TakePhysicsDamage( dmginfo )
end

function ENT:GravGunPunt()
    if self.Armed and math.random( 1, 40 ) == 1 then
        self:Detonate()
    end
    return true
end

function ENT:Use( activator )
    if not activator:IsPlayer() then return end
    if not JID.CanBeUsed( activator, self ) then return end
    if self.NextUseTime >= CurTime() then return end
    self.NextUseTime = CurTime() + .5

    if self.Armed then return end
    if self.Fuzed then return end

    self.Fuzed = true
    self:EmitSound( "snd_jack_pinpull.mp3", 65, 90 )
    self.Armer = activator

    timer.Simple( 3, function()
        if IsValid( self ) then
            self:EmitSound( "npc/metropolice/vo/shit.wav", 75, 90 )
            self.Armed = true
        end
    end )

    JID.genericUseEffect( activator )
end

function ENT:ShouldDoDamageConversion()
    -- ball busters are immune
    return false
end
