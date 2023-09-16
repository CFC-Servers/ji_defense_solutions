--SENTREH GOIN UP
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
ENT.StructuralIntegrity = 300
ENT.MaxStructuralIntegrity = ENT.StructuralIntegrity
ENT.Broken = false
ENT.HasBatteryOne = false
ENT.HasBatteryOne = false
ENT.HasBattery = false
ENT.PlugPosition = Vector( 0, 0, 0 )

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 50
    local ent = ents.Create( "ent_jack_teslasentry" )
    ent:SetPos( SpawnPos )
    ent:SetNWEntity( "Owner", ply )
    ent:Spawn()
    ent:Activate()
    local effectdata = EffectData()
    effectdata:SetEntity( ent )
    util.Effect( "propspawn", effectdata )

    return ent
end

function ENT:ExternalCharge( amt )
    self.BatteryCharge = self.BatteryCharge + amt

    if self.BatteryCharge >= self.BatteryMaxCharge then
        self.BatteryCharge = self.BatteryMaxCharge
        return false -- max battery!
    end
    return true
end

function ENT:Initialize()
    self:SetModel( "models/props_c17/substation_transformer01d.mdl" )
    self:SetMaterial( "models/mat_jack_teslasentry" )
    self:SetColor( Color( 50, 50, 50 ) )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
        phys:SetMass( 100 )
    end

    self:SetUseType( SIMPLE_USE )
    self:Fire( "enableshadow", "", 0 )
    self.UpAmount = 0
    self:SetDTFloat( 0, self.UpAmount )
    self.State = "Off"
    self.MenuOpen = false
    self.BatteryMaxCharge = 6000
    self.BatteryCharge = 0
    self.CapacitorCharge = 0
    self.CapacitorMaxCharge = 100 --maximum is 150, minimum is 10
    self.CapacitorChargeRate = 20 --maximum is 90, minimum is 10
    self.MaxEngagementRange = 600 -- range to engage
    self.NextAlertTime = 0
    self.NextWhineTime = 0
    self:SetDTBool( 1, self.HasBatteryOne )
    self:SetDTBool( 2, self.HasBatteryTwo )
    self:SetNWInt( "JackIndex", self:EntIndex() )
end

function ENT:PhysicsCollide( data, _ )

    -- getting turrets smashed by proppushers SUCKS!
    if IsValid( data.HitEntity ) and data.HitEntity:IsPlayerHolding() then return end

    if data.Speed > 80 and data.DeltaTime > 0.2 then
        self:EmitSound( "Canister.ImpactHard" )
    end

    if data.Speed > 750 then
        self.StructuralIntegrity = self.StructuralIntegrity - data.Speed / 10

        self:Whine()

        if self.StructuralIntegrity <= 0 then
            self:Break()
        end
    end
end

function ENT:Break()
    if not self.Broken then
        self:EmitSound( "snd_jack_turretbreak.mp3", 85, 100, 1, CHAN_STATIC )
        self.Broken = true
        self:Disengage()
        for _ = 1, 8 do
            self:MiniSpark( 1 )
        end
    end
end

function ENT:MiniSpark( scale )
    local effectdata = EffectData()
    effectdata:SetOrigin( self:GetPos() + self:GetUp() * math.random( -15, 15 ) )
    effectdata:SetNormal( VectorRand() )
    effectdata:SetMagnitude( 3 * scale ) --amount and shoot hardness
    effectdata:SetScale( 1 * scale ) --length of strands
    effectdata:SetRadius( 3 * scale ) --thickness of strands
    util.Effect( "Sparks", effectdata, true, true )

end

function ENT:OnTakeDamage( dmginfo )
    self:TakePhysicsDamage( dmginfo )

    -- if we're already broken, it shouldnt look like we're breaking further
    if self.Broken then return end

    -- dont proppush turrets pls! 
    if IsValid( dmginfo:GetInflictor() ) and dmginfo:GetInflictor():IsPlayerHolding() then return end

    if dmginfo:IsDamageType( DMG_SHOCK ) or dmginfo:IsDamageType( DMG_BUCKSHOT ) or dmginfo:IsDamageType( DMG_BULLET ) or dmginfo:IsDamageType( DMG_BLAST ) or dmginfo:IsDamageType( DMG_CLUB ) or dmginfo:IsDamageType( DMG_BURN ) then
        self.StructuralIntegrity = self.StructuralIntegrity - dmginfo:GetDamage()
        self:MiniSpark( math.Clamp( dmginfo:GetDamage() / 50, 0.2, 1 ) )
        self:EmitSound( "weapon.ImpactHard" )

        if self.StructuralIntegrity <= 0 then
            self:Break()
        end
    end
end

function ENT:Use( activator )
    if not JID.CanBeUsed( activator, self ) then return end
    if self.StructuralIntegrity <= 0 then
        local Kit = self:FindRepairKit()

        if IsValid( Kit ) then
            self:Fix( Kit )
            JID.genericUseEffect( activator )
        end
    end

    if self.Broken then return end
    if not ( self.State == "Off" ) then return end

    if not self.MenuOpen then
        self:EmitSound( "snd_jack_uisuccess.mp3", 65, 100 )
        self.MenuOpen = true
        umsg.Start( "JackaTeslaTurretOpenMenu", activator )
        umsg.Entity( self )
        umsg.Short( self.BatteryCharge )
        umsg.Short( self.CapacitorMaxCharge )
        umsg.End()
    end
end

function ENT:FindRepairKit()
    for _, potential in pairs( ents.FindInSphere( self:GetPos(), 100 ) ) do
        if potential:GetClass() == "ent_jack_turretrepairkit" then return potential end
    end

    return nil
end

function ENT:Fix( kit )
    self.StructuralIntegrity = self.MaxStructuralIntegrity
    self:EmitSound( "snd_jack_turretrepair.mp3", 70, 100 )

    timer.Simple( 3.25, function()
        if IsValid( self ) then
            self.Broken = false
            self:RemoveAllDecals()
        end
    end )

    kit:Empty()
end

function ENT:Engage()
    if not ( self.State == "Off" ) then return end
    if not ( self.HasBatteryOne and self.HasBatteryTwo and self.BatteryCharge > 0 ) then return end
    self:EmitSound( "snd_jack_turretstartup.mp3" )
    self.State = "Engaging"
end

function ENT:DetachBattery( IsExplosive )
    self.BatteryCharge = 0
    self.HasBatteryOne = false
    self.HasBatteryTwo = false
    self.HasBattery = false
    self:SetDTBool( 1, self.HasBatteryOne )
    self:SetDTBool( 2, self.HasBatteryTwo )
    local Box1 = ents.Create( "ent_jack_turretbattery" )
    Box1.Dead = true
    Box1:SetPos( self:GetPos() + self:GetRight() * 30 + self:GetUp() * 10 )
    Box1:SetAngles( self:GetForward():Angle() )
    Box1:Spawn()
    Box1:Activate()
    local Box2 = ents.Create( "ent_jack_turretbattery" )
    Box2.Dead = true
    Box2:SetPos( self:GetPos() - self:GetRight() * 30 + self:GetUp() * 10 )
    Box2:SetAngles( -self:GetForward():Angle() )
    Box2:Spawn()
    Box2:Activate()

    self:EmitSound( "snd_jack_turretbatteryunload.mp3" )

    timer.Simple( 0, function()
        if not IsExplosive then return end
        if IsValid( Box1 ) then
            local Box1Obj = Box1:GetPhysicsObject()
            if not Box1Obj:IsValid() then return end -- edge case!
            Box1Obj:ApplyForceCenter( VectorRand() * 50000 )
            Box1Obj:ApplyTorqueCenter( VectorRand() * 50000 )
            Box1:Ignite( 10, 10 )
        end
        if IsValid( Box2 ) then
            local Box2Obj = Box1:GetPhysicsObject()
            if not Box2Obj:IsValid() then return end
            Box2Obj:ApplyForceCenter( VectorRand() * 50000 )
            Box2Obj:ApplyTorqueCenter( VectorRand() * 50000 )
            Box2:Ignite( 10, 10 )
        end
    end )
end

function ENT:RefillPower( box )
    if not self.HasBatteryOne then
        self.HasBatteryOne = true
        self:SetDTBool( 1, self.HasBatteryOne )
        self.BatteryCharge = 3000
    elseif not self.HasBatteryTwo then
        self.HasBatteryTwo = true
        self:SetDTBool( 2, self.HasBatteryTwo )
        self.BatteryCharge = 6000
    end

    self.HasBattery = true
    self:SetDTInt( 2, math.Round( self.BatteryCharge / 6000 * 100 ) )
    SafeRemoveEntity( box )
    self:EmitSound( "snd_jack_turretbatteryload.mp3" )
end

function ENT:Disengage()
    if self.State ~= "Engaged" then return end
    self.State = "Disengaging"
    -- wasnt playing
    self:EmitSound( "snd_jack_turretshutdown.mp3", 80, 80, CHAN_STATIC )
end

function ENT:GetShootFromPos()
    return self:GetPos() + self:GetUp() * ( 30 + self.UpAmount * 1.6 )
end

local function ValidArcPossible( HitTrace, Destination )
    if not HitTrace.Hit then return nil end
    local MatType = HitTrace.MatType
    local HitEnt = HitTrace.Entity
    if not HitTrace.HitWorld and IsValid( HitEnt ) and MatType == MAT_METAL or MatType == MAT_GRATE then
        return true, HitEnt:NearestPoint( Destination ), HitEnt
    end
    return false
end

local function SparkEffect( SparkPos )
    local Sparks = EffectData()
    Sparks:SetOrigin( SparkPos )
    Sparks:SetMagnitude( 2 )
    Sparks:SetScale( 1 )
    Sparks:SetRadius( 6 )
    util.Effect( "Sparks", Sparks )
end

local function ExplEffect( ExplosionPos )
    local Explosion = EffectData()
    Explosion:SetOrigin( ExplosionPos )
    Explosion:SetScale( 1 )
    util.Effect( "eff_jack_minesplode", Explosion )
end

function ENT:FindBattery()
    for _, potential in pairs( ents.FindInSphere( self:GetPos(), 100 ) ) do
        if potential:GetClass() == "ent_jack_turretbattery" and not potential.Dead then
            return potential
        end
    end

    return nil
end

ENT.BlockedLinesOfCurrent = {}
local timeToBlock = 0.5

function ENT:LineOfCurrentIsBlocked( check )
    if self.BlockedLinesOfCurrent[ check:GetCreationID() ] == true then return true end

end
function ENT:FlagLineOfCurrentAsBlocked( theBlocked )
    local creationId = theBlocked:GetCreationID()
    self.BlockedLinesOfCurrent[ creationId ] = true
    timer.Simple( timeToBlock, function()
        if not IsValid( self ) then return end
        self.BlockedLinesOfCurrent[ creationId ] = nil

    end )
end

local DoesNotHaveHealthTable = {
    "npc_rollermine",
    "npc_turret_floor",
    "npc_turret_ceiling",
    "npc_turret_ground",
    "npc_grenade_frag",
    "rpg_missile",
    "crossbow_bolt",
    "hunter_flechette",
    "ent_jack_rocket",
    "prop_combine_ball",
    "grenade_ar2",
    "combine_mine",
    "npc_combinedropship",
    "hunter_flechette"
}

local SpecialTargetTable = { 
    "ent_jack_teslasentry",
    "sent_spawnpoint",
    "rpg_missile",
    "crossbow_bolt",
    "cfc_shaped_charge",
    "ent_ins2rpgrocket",
    "grenade_ar2",
    "npc_grenade_bugbait"
}

function ENT:FindTarget()
    self.BatteryCharge = self.BatteryCharge - .0125
    local NewTarg = nil
    local Closest = self.MaxEngagementRange^2

    local LineOfCurrentIsBlocked = self.LineOfCurrentIsBlocked

    for count, found in pairs( ents.FindInSphere( self:GetShootFromPos(), self.MaxEngagementRange ) ) do
        if count >= 100 then break end
        if found == self then continue end
        if found:IsPlayer() and found:HasGodMode() then continue end
        if found.JackaTeslaTurretIgnore then continue end
        if LineOfCurrentIsBlocked( self, found ) then continue end
        local Class = found:GetClass()
        local Phys = found:GetPhysicsObject()

        if table.HasValue( SpecialTargetTable, Class ) then

            local Dist = ( found:LocalToWorld( found:OBBCenter() ) - self:GetShootFromPos() ):LengthSqr()

            if Dist < Closest then
                NewTarg = found
                Closest = Dist
            end
        elseif IsValid( Phys ) then
            local Vel = Phys:GetVelocity() - self:GetPhysicsObject():GetVelocity()
            local Spd = Vel:Length()

            if Spd > 20 then
                local Dist = ( found:LocalToWorld( found:OBBCenter() ) - self:GetShootFromPos() ):LengthSqr()

                if Dist < Closest then
                    NewTarg = found
                    Closest = Dist
                end
            end
        end
    end

    return NewTarg
end

local HundredSquared = 100^2

function ENT:IsUnfair()

    local VelLengSqr = self:GetVelocity():LengthSqr()

    if not self:ClearHead() or VelLengSqr > HundredSquared or IsValid( self:GetParent() ) then return true end
    return nil
end

function ENT:Think()
    if self.MenuOpen then return end

    if self.Broken then
        self.BatteryCharge = 0

        if math.random( 1, 8 ) == 7 then
            self:MiniSpark( 1 )
            self:EmitSound( "snd_jack_turretfizzle.mp3", 70, 100 )
        else
            local effectdata = EffectData()
            effectdata:SetOrigin( self:GetShootFromPos() )
            effectdata:SetScale( 1 )
            util.Effect( "eff_jack_tinyturretburn", effectdata, true, true )
        end

        self:Disengage()

    end

    if self.State == "Disengaging" then
        self.UpAmount = self.UpAmount - .30

        if self.UpAmount <= 0 then
            self.UpAmount = 0
            self.State = "Off"
        else
            self:EmitSound( "snd_jack_turretservo.mp3", 70, 90 )
        end

        self:SetDTFloat( 0, self.UpAmount )
        self:NextThink( CurTime() + .05 )

        return true
    end

    if self.State == "Engaging" then
        self.UpAmount = self.UpAmount + .30

        if self.UpAmount >= 39 then
            self.UpAmount = 39
            self.State = "Engaged"
        else
            self:EmitSound( "snd_jack_turretservo.mp3", 70, 90 )
        end

        if self.NextAlertTime < CurTime() then
            self.NextAlertTime = CurTime() + 1
            self:HostileAlert()
        end

        self:SetDTFloat( 0, self.UpAmount )
        self:NextThink( CurTime() + .05 )

        return true
    end

    if self.Broken then return end

    self:SetDTInt( 2, math.Round( self.BatteryCharge / self.BatteryMaxCharge * 100 ) )

    if self.State == "Off" then return end

    if self.BatteryCharge < self.BatteryMaxCharge * 0.1 then
        self:Whine()

    end

    if self.CapacitorCharge <= 0 and self.BatteryCharge <= 0 then
        self:Disengage()

        return
    end

    if self:IsUnfair() then
        self:Whine()
        self:Disengage()

        return
    end

    if self.CapacitorCharge >= self.CapacitorMaxCharge or self.CapacitorCharge > 0 and self.BatteryCharge <= 0 then
        local Target = self:FindTarget()

        if IsValid( Target ) then
            -- has capacitor and valid target
            local Class = Target:GetClass()
            local nextFire = self.NextFire or 0

            if nextFire < CurTime() then

                self.NextFire = CurTime() + 0.1

                --this staggers the capacitor firings to make the sentries work together
                timer.Simple( math.Rand( 0, self.CapacitorMaxCharge / 1000 ), function()
                    if not IsValid( self ) then return end
                    if not IsValid( Target ) then return end
                    if not JID.CanTarget( self, Target ) then return end
                    if not JID.IsTargetVisibile( Target ) then return end
                    if ( not Target.Health and not Target:Health() <= 0 and not table.HasValue( DoesNotHaveHealthTable, Class ) ) or Target.JackyTeslaKilled then return end
                    if not self:LineOfCurrentBetween( self, Target ) then
                        -- find another target for a second
                        self:FlagLineOfCurrentAsBlocked( Target )
                        return
                    end
                    local DmgAmt = self.CapacitorCharge ^ 1.2 / 3
                    local Powa = self.CapacitorCharge
                    self.CapacitorCharge = 0
                    self:ZapTheShitOutOf( Target, DmgAmt, Powa )
                end )
            end
        else
            -- has capacitor charge but no battery charge
            self.Zapped = false
        end
    else
        -- battery has charge we can draw from
        self.Zapped = false
        self.CapacitorCharge = self.CapacitorCharge + 1
        local ChargeTaken = self.CapacitorChargeRate / 8
        self.BatteryCharge = self.BatteryCharge - ChargeTaken
        self:EmitSound( "snd_jack_chargecapacitor.mp3", 70 - self.CapacitorCharge / self.CapacitorMaxCharge * 20, 70 + self.CapacitorCharge / self.CapacitorMaxCharge * 90 )
    end

    self:NextThink( CurTime() + .015 )

    return true
end

function ENT:ClearHead()
    local Hits = 0

    for i = 0, 10 do
        local Tr = util.QuickTrace( self:GetShootFromPos(), VectorRand() * 15, { self } )

        if Tr.Hit then
            Hits = Hits + 1
        end
    end

    return Hits < 4 and self:WaterLevel() == 0
end

local batteryChargePerCBall = 750
local damagePerOverchargeCBall = 25

function ENT:AbsorbCombineBall( TheBall, Powa )
    local Class = TheBall:GetClass()

    if Class ~= "prop_combine_ball" then return end
    -- never absorb a single ball twice!
    if TheBall.AbsorbedByTeslaTurret then return end

    for _ = 1, 4 do
        local SparkPos = self:WorldSpaceCenter() + VectorRand() * math.Rand( 25, 75 )
        SparkEffect( SparkPos )

        local randomSparkId = math.random( 5, 9 )

        self:EmitSound( "ambient/energy/zap" .. tostring( randomSparkId ) .. "wav", 80, math.random( 80, 100 ), 1, CHAN_STATIC )

    end

    local BatteryAcceptedCharge = self:ExternalCharge( batteryChargePerCBall )

    self:ElectricalArcEffect( self, TheBall, 200 )

    if BatteryAcceptedCharge == true then
        self:EmitSound( "ambient/levels/labs/electric_explosion1.wav", 100, math.random( 110, 120 ), 1, CHAN_STATIC )


        for I = 1, 3 do
            timer.Simple( I * 1, function()
                if not IsValid( self ) then return end
                self:Whine()

            end )
        end

        for Index = 1, 2 do
            timer.Simple( Index * math.Rand( 0.1, 0.4 ), function()
                if not IsValid( self ) then return end
                self:ArcToGround( self, Powa / 8 )
            end )
        end
    else
        self:EmitSound( "ambient/levels/labs/electric_explosion1.wav", 100, math.random( 60, 70 ), 1, CHAN_STATIC )

        timer.Simple( 1, function()
            if not IsValid( self ) then return end
            if self.State ~= "Engaged" then return end

            self:HostileAlert()

        end )

        local Dmg = DamageInfo()
        Dmg:SetDamage( damagePerOverchargeCBall )
        Dmg:SetDamageType( DMG_BLAST )
        Dmg:SetAttacker( self )
        Dmg:SetInflictor( TheBall )

        if self.StructuralIntegrity < ( self.MaxStructuralIntegrity / 2 ) then
            Dmg:SetDamage( 1000 )
            self:DetachBattery( true )
            self:Break()
            for _ = 1, 2 do
                local ExplPos = self:WorldSpaceCenter() + VectorRand() * math.Rand( 25, 75 )
                ExplEffect( ExplPos )
            end
        end

        for Index = 1, 8 do
            timer.Simple( Index * math.Rand( 0.1, 0.4 ), function()
                if not IsValid( self ) then return end
                self:EmitSound( "LoudSpark" )
                self:ArcToGround( self, Powa / 2 )
            end )
        end

        self:TakeDamageInfo( Dmg )
    end

    TheBall.AbsorbedByTeslaTurret = true
    TheBall.JackaTeslaTurretIgnore = true
    TheBall:Fire( "Explode" )

    return true
end

function ENT:ZapTheShitOutOf( Target, DmgAmt, Powa )
    if self.Zapped then return end
    self.Zapped = true
    local ZapDamage = DamageInfo()
    ZapDamage:SetDamageType( DMG_SHOCK )
    ZapDamage:SetDamagePosition( self:GetShootFromPos() )
    local Phys = Target:GetPhysicsObject()

    if IsValid( Phys ) then
        ZapDamage:SetDamageForce( Target:GetUp() * Target:GetPhysicsObject():GetMass() ^ 0.6 * DmgAmt * 5 )
    else
        ZapDamage:SetDamageForce( Target:GetUp() * 50 * DmgAmt * 5 )
    end

    ZapDamage:SetDamage( DmgAmt )
    ZapDamage:SetInflictor( self )
    ZapDamage:SetAttacker( self:GetCreator() )

    local Class = Target:GetClass()

    if Powa >= 20 and math.Rand( 0, 1 ) > .25 then
        if Target:IsNPC() then
            Target:Fire( "sethealth", "2", 0 )
            Target:Fire( "respondtoexplodechirp", "", 0.5 )
            Target:Fire( "selfdestruct", "", 1 )
            Target:Fire( "disarm", " ", 0 )
            Target:Fire( "explode", "", 0 )
            Target:Fire( "gunoff", "", 0 )
            Target:Fire( "settimer", "0", 0 )
        end

        if table.HasValue( DoesNotHaveHealthTable, Class ) then
            Target.JackyTeslaKilled = true
        end
    end

    Target:TakeDamageInfo( ZapDamage )

    if table.HasValue( SpecialTargetTable, Target:GetClass() ) then
        Target:SetVelocity( VectorRand() * 100000 )
        local RpgDamage = DamageInfo()
        RpgDamage:SetDamageType( DMG_MISSILEDEFENSE )
        RpgDamage:SetAttacker( self )
        RpgDamage:SetInflictor( self )
        RpgDamage:SetDamage( 100 )

        Target:TakeDamageInfo( RpgDamage )

    end

    local Chance = DmgAmt / 100 * 0.1

    if math.Rand( 0, 1 ) < Chance then
        Target:Ignite( 5 )
    end

    self:ElectricalArcEffect( self, Target, Powa )
    self:ArcToGround( Target, Powa )

    if Class == "prop_combine_ball" then self:AbsorbCombineBall( Target, Powa ) end

end

function ENT:ElectricalArcEffect( Attacker, Victim, Powa )
    local VictimPos = Victim:LocalToWorld( Victim:OBBCenter() )
    local SelfPos = Attacker:GetShootFromPos()
    local ToVector = VictimPos - SelfPos
    local Dist = ToVector:Length()
    local WanderDirection = self:GetUp()
    local NumPoints = math.Clamp( math.ceil( 60 * Dist / 1000 ) + 1, 1, 60 )
    local PointTable = {}
    local NextFilterEnt
    PointTable[1] = SelfPos

    for i = 2, NumPoints do
        local NewPoint
        local WeCantGoThere = true
        local C_P_I_L = 0

        while WeCantGoThere do
            NewPoint = PointTable[i - 1] + WanderDirection * Dist / NumPoints
            local CheckTr = {}
            CheckTr.start = PointTable[i - 1]
            CheckTr.endpos = NewPoint

            CheckTr.filter = { Attacker, Victim, NextFilterEnt }

            local CheckTra = util.TraceLine( CheckTr )

            local ArcCompleted, ArcPos, ArcEnt = ValidArcPossible( CheckTra, VictimPos )

            if ArcCompleted == false then
                WanderDirection = ( WanderDirection + CheckTra.HitNormal * 0.5 ):GetNormalized()
            elseif ArcCompleted == true then
                WeCantGoThere = false
                NewPoint = ArcPos
                NextFilterEnt = ArcEnt

                ArcEnt:EmitSound( "ambient/energy/zap8.wav", 80, math.random( 80, 100 ) + C_P_I_L / 4 )

                SparkEffect( CheckTra.HitPos )
                SparkEffect( ArcPos )

            elseif not ArcCompleted then
                WeCantGoThere = false
            end

            C_P_I_L = C_P_I_L + 1

            if C_P_I_L >= 200 then
                break
            end
        end

        PointTable[i] = NewPoint
        WanderDirection = ( WanderDirection + VectorRand() * 0.35 + ( VictimPos - NewPoint ):GetNormalized() * 0.2 ):GetNormalized()
    end

    PointTable[NumPoints + 1] = VictimPos

    for key, point in pairs( PointTable ) do
        if not ( key == NumPoints + 1 ) then
            local Harg = EffectData()
            Harg:SetStart( point )
            Harg:SetOrigin( PointTable[key + 1] )
            Harg:SetScale( Powa / 50 )
            util.Effect( "eff_jack_plasmaarc", Harg )
        end
    end

    local Randim = math.Rand( 0.95, 1.05 )
    local SoundMod = math.Clamp( ( 50 - self.CapacitorMaxCharge ) / 50 * 30, -40, 40 )
    sound.Play( "snd_jack_zapang.mp3", SelfPos, 90 - SoundMod / 2, 110 * Randim + SoundMod )
    sound.Play( "snd_jack_zapang.mp3", VictimPos, 80 - SoundMod / 2, 111 * Randim + SoundMod )
    sound.Play( "snd_jack_smallthunder.mp3", SelfPos, 120, 100 )
end

function ENT:ArcToGround( Victim, Powa )
    if Victim:IsWorld() then return end
    local EndPosOffsetted = Vector( 0, 0, -30000 ) + ( VectorRand() * Vector( 30000, 30000, 0 ) )
    local Trayuss = util.QuickTrace( Victim:GetPos() + Vector( 0, 0, 5 ), EndPosOffsetted, Victim )

    if Trayuss.Hit then
        local NewStart = Victim:GetPos() + Vector( 0, 0, 5 )
        local ToVector = Trayuss.HitPos - NewStart
        local Dist = ToVector:Length()

        if Dist > 25 then
            local PointTableMax = 50
            local WanderDirection = Vector( 0, 0, 0.5 )
            local NumPoints = math.Clamp( math.ceil( 30 * Dist / 1000 ) + 1, 1, PointTableMax )
            local PointTable = {}
            local C_P_I_L = 0
            PointTable[1] = NewStart

            for i = 2, NumPoints do
                local NewPoint
                local WeCantGoThere = true
                C_P_I_L = 0

                while WeCantGoThere do
                    NewPoint = PointTable[i - 1] + WanderDirection * Dist / NumPoints
                    local CheckTr = {}
                    CheckTr.start = PointTable[i - 1]
                    CheckTr.endpos = NewPoint
                    CheckTr.filter = Victim
                    local CheckTra = util.TraceLine( CheckTr )

                    local EndingTooSoon = CheckTra.HitWorld and #PointTable < ( PointTableMax / 2 )

                    if CheckTra.Hit or EndingTooSoon then
                        WanderDirection = ( WanderDirection + CheckTra.HitNormal * 0.5 ):GetNormalized()
                    else
                        WeCantGoThere = false
                    end

                    C_P_I_L = C_P_I_L + 1

                    if C_P_I_L >= PointTableMax then
                        break
                    end
                end

                PointTable[i] = NewPoint
                WanderDirection = ( WanderDirection + VectorRand() * 0.3 + ( Trayuss.HitPos - NewPoint ):GetNormalized() * 0.2 ):GetNormalized()
            end

            PointTable[NumPoints + 1] = Trayuss.HitPos

            for key, point in pairs( PointTable ) do
                if not ( key == NumPoints + 1 ) and SERVER then
                    local Harg = EffectData()
                    Harg:SetStart( point )
                    Harg:SetOrigin( PointTable[key + 1] )
                    Harg:SetScale( Powa / 50 )
                    util.Effect( "eff_jack_plasmaarc", Harg, true, true )
                end
            end
        else
            if SERVER then
                local Harg = EffectData()
                Harg:SetStart( NewStart )
                Harg:SetOrigin( Trayuss.HitPos )
                Harg:SetScale( self.CapacitorCharge / 50 )
                util.Effect( "eff_jack_plasmaarc", Harg, true, true )
            end
        end

        local Randim = math.Rand( 0.95, 1.05 )
        local SoundMod = math.Clamp( ( 50 - self.CapacitorCharge ) / 50 * 30, -40, 40 )
        sound.Play( "snd_jack_zapang.mp3", Trayuss.HitPos, 80 - SoundMod / 2, 110 * Randim + SoundMod )

        if self.CapacitorCharge >= 50 then
            util.Decal( "Scorch", Trayuss.HitPos + Trayuss.HitNormal, Trayuss.HitPos - Trayuss.HitNormal )
        else
            util.Decal( "FadingScorch", Trayuss.HitPos + Trayuss.HitNormal, Trayuss.HitPos - Trayuss.HitNormal )
        end
    end
end

function ENT:HostileAlert()
    local Flash = EffectData()
    Flash:SetOrigin( self:GetShootFromPos() )
    Flash:SetScale( 2 )
    util.Effect( "eff_jack_redflash", Flash, true, true )
    self:EmitSound( "snd_jack_friendlylarm.mp3", 85, 95 )
    sound.Play( "snd_jack_friendlylarm.mp3", self:GetPos(), 80, 95 )
    self.BatteryCharge = self.BatteryCharge - .5
end

function ENT:LineOfCurrentBetween( Searcher, Searchee )
    local TracesDone = 0
    local TracesMax = 30
    local TraceData = {}
    local End = Searchee:LocalToWorld( Searchee:OBBCenter() ) + Vector( 0, 0, 5 )
    TraceData.start = Searcher:GetShootFromPos()
    TraceData.endpos = End

    TraceData.filter = { Searcher, Searchee }

    while TracesDone < TracesMax do
        TracesDone = TracesDone + 1

        local Trace = util.TraceLine( TraceData )

        local ArcCompleted, ArcPos, ArcEnt = ValidArcPossible( Trace, End )

        if ArcCompleted == true then
            TraceData.start = ArcPos
            table.insert( TraceData.filter, ArcEnt )
        elseif ArcCompleted == false then
            return false
        else
            return true
        end
    end
end

function ENT:Whine()
    if self.NextWhineTime > CurTime() then return end
    self.NextWhineTime = CurTime() + 0.95
    self:EmitSound( "snd_jack_turretwhine.mp3", 80, 80, 1, CHAN_STATIC )
    self.BatteryCharge = self.BatteryCharge - .05
end

local function Battery( ... )
    local args = { ... }

    local me = Entity( tonumber( args[3][1] ) )

    if not ( me.HasBatteryOne and me.HasBatteryTwo ) then
        local Box = me:FindBattery()

        if IsValid( Box ) then
            me:RefillPower( Box )
        else
            args[1]:PrintMessage( HUD_PRINTCENTER, "No battery present." )
        end
    elseif me.BatteryCharge <= 1 then
        me:DetachBattery()
    else
        args[1]:PrintMessage( HUD_PRINTCENTER, "Current batteries not dead." )
    end

    me.MenuOpen = false
end

concommand.Add( "JackaTeslaTurretBattery", Battery )

local function CloseCancel( ... )
    local args = { ... }

    local me = Entity( tonumber( args[3][1] ) )
    me:EmitSound( "snd_jack_uiselect.mp3", 65, 100 )
    me.MenuOpen = false
end

concommand.Add( "JackaTeslaTurretCloseMenu_Cancel", CloseCancel )

local function CloseOn( ... )
    local args = { ... }

    local me = Entity( tonumber( args[3][1] ) )
    me.MenuOpen = false

    if me.State ~= "Off" then return end

    if me:IsUnfair() then
        me:EmitSound( "snd_jack_uifail.mp3", 65, 100 )
        return
    end

    me:EmitSound( "snd_jack_uiselect.mp3", 65, 100 )
    me:Engage()
end

concommand.Add( "JackaTeslaTurretCloseMenu_On", CloseOn )

local function SetCap( ... )
    local args = { ... }

    local me = Entity( tonumber( args[3][1] ) )
    local Cap = tonumber( args[3][2] )
    me.CapacitorMaxCharge = Cap
end

concommand.Add( "JackaTeslaTurretSetCap", SetCap )
