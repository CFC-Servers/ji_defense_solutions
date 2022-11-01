AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 20
    local ent = ents.Create( "ent_jack_boundingmine" )
    ent:SetAngles( Angle( 0, 0, 0 ) )
    ent:SetPos( SpawnPos )
    ent.Owner = ply
    ent:Spawn()
    ent:Activate()
    local effectdata = EffectData()
    effectdata:SetEntity( ent )
    util.Effect( "propspawn", effectdata )

    return ent
end

function ENT:Initialize()
    self:SetModel( "models/props_junk/glassjug01.mdl" )
    self:SetColor( Color( 153, 147, 111 ) )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:DrawShadow( true )
    self.Exploded = false
    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
        phys:SetMass( 50 )
        phys:SetMaterial( "metal" )
    end

    self:SetUseType( SIMPLE_USE )
    self.NextArmTime = CurTime() + 3
    self.NextBounceNoiseTime = CurTime()

    if not self.State then
        self.State = "Inactive"
    end
end

function ENT:Launch( toucher )
    self:DrawShadow( true )
    self.State = "Flying"

    local traceResult = util.QuickTrace( self:LocalToWorld( self:OBBCenter() ) + self:GetUp() * 20, -self:GetUp() * 40, { self, toucher } )

    if traceResult.Hit then
        timer.Simple( .1, function()
            util.Decal( "Scorch", traceResult.HitPos + traceResult.HitNormal, traceResult.HitPos - traceResult.HitNormal )
        end )
    end

    self:SetParent()
    local phys = self:GetPhysicsObject()
    if IsValid( phys ) then
        phys:EnableMotion( true )
    end

    if traceResult.Hit then
        self:SetPos( self:GetPos() + traceResult.HitNormal * 11 )
    end

    self:GetPhysicsObject():ApplyForceCenter( self:GetUp() * 16000 )
    local effect = EffectData()

    if traceResult.Hit then
        effect:SetOrigin( traceResult.HitPos )
        effect:SetNormal( traceResult.HitNormal )
    else
        effect:SetOrigin( self:GetPos() )
        effect:SetNormal( Vector( 0, 0, 1 ) )
    end

    effect:SetScale( 1 )
    util.Effect( "eff_jack_sminepop", effect, true, true )
    util.SpriteTrail( self, 0, Color( 50, 50, 50, 255 ), false, 8, 20, .5, 1 / ( 15 + 1 ) * 0.5, "trails/smoke.vmt" )
    self:EmitSound( "snd_jack_sminepop.mp3" )
    sound.Play( "snd_jack_sminepop.mp3", self:GetPos(), 120, 80 )

    timer.Simple( math.Rand( .4, .5 ), function()
        if IsValid( self ) then
            self:Detonate()
        end
    end )

    traceResult = util.QuickTrace( self:GetPos() + self:GetUp() * 20, self:GetUp() * 30, { self } )

    if traceResult.Hit and traceResult.Entity:IsPlayer() then
        timer.Simple( 0.5, function()
            if IsValid( traceResult.Entity ) and IsValid( self ) then
                local Bam = DamageInfo()
                Bam:SetDamage( 100 )
                Bam:SetDamageType( DMG_BLAST )
                Bam:SetDamageForce( self:GetUp() * 1000 )
                Bam:SetDamagePosition( traceResult.HitPos )
                Bam:SetAttacker( self )
                Bam:SetInflictor( self )
                traceResult.Entity:TakeDamageInfo( Bam )
            end
        end )
    end
end

function ENT:Detonate()
    if self.Exploded then return end
    self.Exploded = true
    local SelfPos = self:GetPos()
    sound.Play( "snd_jack_fragsplodeclose.mp3", SelfPos, 75, 100 )
    local effect = EffectData()
    effect:SetOrigin( SelfPos )
    effect:SetScale( 1 )
    effect:SetDamageType( DMG_BLAST )
    effect:SetNormal( Vector( 0, 0, 0 ) )

    util.Effect( "eff_jack_shrapnelburst", effect, true, true )
    util.BlastDamage( self, JID.DetermineAttacker( self ), SelfPos, 750, 150 )
    sound.Play( "snd_jack_fragsplodeclose.mp3", SelfPos, 75, 100 )
    util.ScreenShake( SelfPos, 99999, 99999, 1, 750 )

    for _ = 0, 70 do
        local Trayuss = util.QuickTrace( SelfPos, VectorRand() * 200 - self:GetUp() * 100, { self } )

        if Trayuss.Hit then
            util.Decal( "FadingScorch", Trayuss.HitPos + Trayuss.HitNormal, Trayuss.HitPos - Trayuss.HitNormal )
        end
    end

    self:Remove()
end

function ENT:PhysicsCollide( data )
    if data.Speed > 80 and data.DeltaTime > 0.2 and not data.HitEntity:IsPlayer() then
        self:EmitSound( "SolidMetal.ImpactHard" )
    end
end

function ENT:StartTouch( ent )
    if self.State ~= "Armed" then return end
    if JID.CanTarget( ent ) then return end

    self.State = "Preparing"
    self:EmitSound( "snd_jack_metallicclick.mp3", 60, 100 )

    timer.Simple( math.Rand( .75, 1.25 ), function()
        if IsValid( self ) then
            self:Launch( ent )
        end
    end )
end

function ENT:EndTouch( ent )
    if self.State == "Armed" then
        timer.Simple( math.Rand( 1, 2 ), function()
            if IsValid( self ) then
                self:Launch( ent )
            end
        end )

        self.State = "Preparing"
        self:EmitSound( "snd_jack_metallicclick.mp3", 60, 100 )
    end
end

function ENT:OnTakeDamage( dmginfo )
    if self then
        self:TakePhysicsDamage( dmginfo )

        if math.random( 1, 8 ) == 1 then
            self:StartTouch( dmginfo:GetAttacker() )
        end
    end
end

function ENT:Use( activator )
    if self.State ~= "Inactive" then return end
    if not activator:IsPlayer() then return end

    local traceResult = util.QuickTrace( activator:GetShootPos(), activator:GetAimVector() * 100, { activator, self } )

    if not traceResult.Hit or not IsValid( traceResult.Entity:GetPhysicsObject() ) then
        return activator:PickupObject( self )
    end

    local Ang = traceResult.HitNormal:Angle()
    Ang:RotateAroundAxis( Ang:Right(), -90 )
    local Pos = traceResult.HitPos - traceResult.HitNormal * 7.25
    self:SetAngles( Ang )
    self:SetPos( Pos )

    if traceResult.Entity == game.GetWorld() then
        local phys = self:GetPhysicsObject()
        phys:EnableMotion( false )
    else
        self:SetParent( traceResult.Entity )
    end

    local Fff = EffectData()
    Fff:SetOrigin( traceResult.HitPos )
    Fff:SetNormal( traceResult.HitNormal )
    Fff:SetScale( 1 )
    util.Effect( "eff_jack_sminebury", Fff, true, true )
    self:EmitSound( "snd_jack_pinpull.mp3" )
    activator:EmitSound( "Dirt.BulletImpact" )
    self.ShootDir = traceResult.HitNormal
    self:DrawShadow( false )
    self.State = "Armed"
    JID.genericUseEffect( activator )
end
