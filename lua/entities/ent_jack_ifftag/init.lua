AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

ENT.activationTime = 0
ENT.nextAllowSameEnt = 0
ENT.StructuralIntegrity = 250
ENT.MaxStructuralIntegrity = ENT.StructuralIntegrity

ENT.Broken = nil

-- in front of the "screen" csideent
local screenPos = Vector( 10, -2.7, 4 )

function ENT:SpawnFunction( _, tr )
    local SpawnPos = tr.HitPos
    local ent = ents.Create( "ent_jack_ifftag" )
    ent:SetPos( SpawnPos )
    ent:SetAngles( tr.HitNormal:Angle():Forward():Angle() )
    ent:Spawn()
    ent:Activate()
    local effectdata = EffectData()
    effectdata:SetEntity( ent )
    util.Effect( "propspawn", effectdata )

    return ent
end

local gray = Color( 150, 150, 150 )

function ENT:Initialize()
    self:SetModel( "models/props_lab/powerbox02b.mdl" )
    self:SetMaterial( "models/mat_jack_dullscratchedmetal.vmt" )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
    self:DrawShadow( true )

    self:SetColor( gray )

    self:SetTrigger( true )
    self:UseTriggerBounds( true, 60 )

    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
        phys:EnableMotion( false )
    end

    local activationOffset = 6
    self.myIFFTagId = math.random( 1, 100000 )
    self.activationTime = CurTime() + activationOffset

    -- wake up sounds
    timer.Simple( 0, function()
        if not IsValid( self ) then return end
        self:EmitSound( "snd_jack_turretwhine.mp3", 75, 30, 1, CHAN_STATIC )
        self:EmitSound( "npc/turret_floor/deploy.wav", 75, 30, 1, CHAN_STATIC )

    end )

    -- finished booting sounds
    timer.Simple( activationOffset, function()
        if not IsValid( self ) then return end

        if self.Broken then return end

        self:FlashScreen( .15 )

        self:EmitSound( "snd_jack_uisuccess.mp3", 75, 100, 1, CHAN_STATIC )
        self:EmitSound( "ambient/machines/combine_terminal_idle2.wav", 75, 120, 1, CHAN_STATIC )

    end )
end

function ENT:Think()
    if self.Broken then
        if math.random( 1, 8 ) == 7 then
            self:MiniSpark( .5 )
            self:EmitSound( "snd_jack_turretfizzle.mp3", 70, 130 )

        else
            local effectdata = EffectData()
            effectdata:SetOrigin( self:ChassisPos() )
            effectdata:SetScale( .4 )
            util.Effect( "eff_jack_tinyturretburn", effectdata, true, true )

        end
        return

    end
    if self.activationTime > CurTime() then return end
    if math.random( 1, 15 ) == 1 then
        self:FlashScreen( .025 )

    end
end

function ENT:PhysicsCollide( data )
    -- fragile!
    if data.Speed > 80 and data.DeltaTime > .2 then
        self:EmitSound( "SolidMetal.ImpactHard" )
        self:EmitSound( "Computer.ImpactHard" )
        local damageInfo = DamageInfo()

        local damage = data.Speed / 5
        if self:IsPlayerHolding() then
            damage = damage * .25

        end

        damageInfo:SetDamage( damage )
        damageInfo:SetDamageType( DMG_CLUB )
        damageInfo:SetInflictor( data.HitEntity )
        damageInfo:SetAttacker( self )

        self:TakeDamageInfo( damageInfo )

    end
end

function ENT:OnTakeDamage( dmginfo )
    self:TakePhysicsDamage( dmginfo )

    -- if we're already broken, it shouldnt look like we're breaking further
    if self.Broken then return end

    -- dont proppush me! 
    if IsValid( dmginfo:GetInflictor() ) and dmginfo:GetInflictor():IsPlayerHolding() and dmginfo:GetInflictor() ~= self then return end

    if dmginfo:IsDamageType( DMG_BUCKSHOT ) or dmginfo:IsDamageType( DMG_BULLET ) or dmginfo:IsDamageType( DMG_CLUB ) or dmginfo:IsExplosionDamage() then
        local damage = dmginfo:GetDamage()

        if dmginfo:IsExplosionDamage() then
            -- explosions are too easy to hit this with! do less damage
            damage = damage / 4

        end

        self.StructuralIntegrity = self.StructuralIntegrity - damage


        if self.StructuralIntegrity <= 0 then
            self:EmitSound( "snd_jack_turretbreak.mp3", 100, 120 )
            for _ = 1, 6 do
                self:MiniSpark( 1 )
                self.Broken = true

            end
        else
            self:EmitSound( "Computer.BulletImpact" )
            self:MiniSpark( math.Clamp( damage / 20, .1, 1 ) )

        end
    end
end

function ENT:StartTouch( toucher )
    if self.Broken then return end
    self:Taggify( toucher )

end

function ENT:Use( activator )
    if self.StructuralIntegrity <= 0 and JID.CanBeUsed( activator, self ) then
        local kit = self:FindRepairKit()
        if not IsValid( kit ) then return end

        self:Fix( kit )

        return

    end
    if self.Broken then return end
    self:Taggify( activator )
end

function ENT:Taggify( ent )
    if not ent:IsPlayer() then return end
    -- dont spam check the same thing!
    if self.nextAllowSameEnt > CurTime() and self.lastTaggifiedEnt == ent then return end

    self.lastTaggifiedEnt = ent

    local entsNearestToMe = ent:NearestPoint( self:GetPos() )
    local notGivingThruWallsTr = {
        start = self:NearestPoint( entsNearestToMe ),
        endpos = entsNearestToMe,
        filter = { self, ent }

    }
    local wallsResult = util.TraceLine( notGivingThruWallsTr )
    if wallsResult.Hit then
        self.nextAllowSameEnt = CurTime() + .8
        return

    end

    if self.activationTime > CurTime() then
        ent:PrintMessage( HUD_PRINTCENTER, "IFF implanter booting up..." )
        self:EmitSound( "buttons/button16.wav", 85, 150 )
        self.nextAllowSameEnt = CurTime() + .1
        return

    end

    if not JID.CanBeUsed( ent, self ) then
        self.nextAllowSameEnt = CurTime() + .8
        self:EmitSound( "buttons/button16.wav", 85, 150 )
        return

    end

    local Tagged = ent:GetNWInt( "JackyIFFTag" )

    if Tagged and Tagged == self.myIFFTagId then
        self:EmitSound( "buttons/button16.wav", 85, 100, .6 )
        self.nextAllowSameEnt = CurTime() + .4

        self:FlashScreen( .15 )

    else
        ent:SetNWInt( "JackyIFFTag", self.myIFFTagId )
        ent:PrintMessage( HUD_PRINTCENTER, "IFF tag implanted." )
        self.nextAllowSameEnt = CurTime() + .4

        self:EmitSound( "npc/roller/blade_in.wav", 70, 200, .6 )
        ent:EmitSound( "snd_jack_tinyequip.mp3", 85, 100 )
        self:SetNW2Vector( "implantedpos", entsNearestToMe )
        self:SetNW2Float( "implantedtime", CurTime() )

        JID.genericUseEffect( ent )
        self:FlashScreen( .15 )

    end
end

function ENT:FindRepairKit()
    for _, potential in pairs( ents.FindInSphere( self:GetPos(), 150 ) ) do
        if potential:GetClass() == "ent_jack_turretrepairkit" then return potential end

    end

    return nil
end

function ENT:Fix( kit )
    self.StructuralIntegrity = self.MaxStructuralIntegrity
    self:EmitSound( "snd_jack_turretrepair.mp3", 70, 150 )

    timer.Simple( 2, function()
        if IsValid( self ) then
            self.Broken = false
            self:RemoveAllDecals()

        end
    end )

    kit:Empty()

end

function ENT:FlashScreen( scale )
    local Flash = EffectData()
    Flash:SetOrigin( self:LocalToWorld( screenPos ) )
    Flash:SetScale( scale )
    util.Effect( "eff_jack_cyanflash", Flash, true, true )

end

function ENT:MiniSpark( scale )
    local effectdata = EffectData()
    effectdata:SetOrigin( self:ChassisPos() )
    effectdata:SetNormal( VectorRand() )
    effectdata:SetMagnitude( 3 * scale ) --amount and shoot hardness
    effectdata:SetScale( 1 * scale ) --length of strands
    effectdata:SetRadius( 3 * scale ) --thickness of strands
    util.Effect( "Sparks", effectdata, true, true )

end

function ENT:ChassisPos()
    return self:GetPos() + self:GetUp() * math.random( -5, 5 )

end

local function Death( ply )
    ply:SetNWInt( "JackyIFFTag", 0 )

end

hook.Add( "DoPlayerDeath", "JackyIFFTagRemoval", Death )

