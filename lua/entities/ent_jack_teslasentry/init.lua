--SENTREH GOIN UP
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
ENT.StructuralIntegrity = 300
ENT.Broken = false
ENT.HasBatteryOne = false
ENT.HasBatteryOne = false
ENT.HasBattery = false
ENT.PlugPosition = Vector( 0, 0, 0 )

local DoesNotHaveHealthTable = { "npc_rollermine", "npc_turret_floor", "npc_turret_ceiling", "npc_turret_ground", "npc_grenade_frag", "rpg_missile", "crossbow_bolt", "hunter_flechette", "ent_jack_rocket", "prop_combine_ball", "grenade_ar2", "combine_mine", "npc_combinedropship", "hunter_flechette" }

local SpecialTargetTable = { "rpg_missile", "crossbow_bolt", "cfc_shaped_charge", "ent_ins2rpgrocket" }

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
    end
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
    self.CapacitorChargeRate = 40 --maximum is 90, minimum is 10
    self.MaxEngagementRange = 600 -- range to engage
    self.NextAlertTime = 0
    self:SetDTBool( 1, self.HasBatteryOne )
    self:SetDTBool( 2, self.HasBatteryTwo )
    self:SetNWInt( "JackIndex", self:EntIndex() )
end

function ENT:PhysicsCollide( data, physobj )
    if data.Speed > 80 and data.DeltaTime > 0.2 then
        self:EmitSound( "Canister.ImpactHard" )
    end

    if data.Speed > 750 then
        self.StructuralIntegrity = self.StructuralIntegrity - data.Speed / 10

        if self.StructuralIntegrity <= 0 then
            self:Break()
        end
    end
end

function ENT:Break()
    if not self.Broken then
        self:EmitSound( "snd_jack_turretbreak.mp3" )
        self.Broken = true
        self:Disengage()
    end
end

function ENT:OnTakeDamage( dmginfo )
    self:TakePhysicsDamage( dmginfo )

    if dmginfo:IsDamageType( DMG_BUCKSHOT ) or dmginfo:IsDamageType( DMG_BULLET ) or dmginfo:IsDamageType( DMG_BLAST ) or dmginfo:IsDamageType( DMG_CLUB ) then
        self.StructuralIntegrity = self.StructuralIntegrity - dmginfo:GetDamage()

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
    self.StructuralIntegrity = 300
    self:EmitSound( "snd_jack_turretrepair.mp3", 70, 100 )

    timer.Simple( 3.25, function()
        if IsValid( self ) then
            self.Broken = false
            self:RemoveAllDecals()
        end
    end )

    local Empty = ents.Create( "prop_ragdoll" )
    Empty:SetModel( "models/props_junk/cardboard_box003a_gib01.mdl" )
    Empty:SetMaterial( "models/mat_jack_turretrepairkit" )
    Empty:SetPos( kit:GetPos() )
    Empty:SetAngles( kit:GetAngles() )
    Empty:Spawn()
    Empty:Activate()
    Empty:SetCollisionGroup( COLLISION_GROUP_WEAPON )
    Empty:GetPhysicsObject():ApplyForceCenter( Vector( 0, 0, 1000 ) )
    Empty:GetPhysicsObject():AddAngleVelocity( VectorRand() * 1000 )
    SafeRemoveEntityDelayed( Empty, 20 )
    SafeRemoveEntity( kit )
end

function ENT:Engage()
    if not ( self.State == "Off" ) then return end
    if not ( self.HasBatteryOne and self.HasBatteryTwo and self.BatteryCharge > 0 ) then return end
    self:EmitSound( "snd_jack_turretstartup.mp3" )
    self.State = "Engaging"
end

function ENT:DetachBattery()
    self.BatteryCharge = 0
    self.HasBatteryOne = false
    self.HasBatteryTwo = false
    self.HasBattery = false
    self:SetDTBool( 1, self.HasBatteryOne )
    self:SetDTBool( 2, self.HasBatteryTwo )
    local Box = ents.Create( "ent_jack_turretbattery" )
    Box.Dead = true
    Box:SetPos( self:GetPos() + self:GetRight() * 30 + self:GetUp() * 10 )
    Box:SetAngles( self:GetForward():Angle() )
    Box:Spawn()
    Box:Activate()
    Box = ents.Create( "ent_jack_turretbattery" )
    Box.Dead = true
    Box:SetPos( self:GetPos() - self:GetRight() * 30 + self:GetUp() * 10 )
    Box:SetAngles( -self:GetForward():Angle() )
    Box:Spawn()
    Box:Activate()
    self:EmitSound( "snd_jack_turretbatteryunload.mp3" )
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
    if not ( self.State == "Engaged" ) then return end
    self.State = "Disengaging"
    self:EmitSound( "snd_jack_turretshutdown.mp3" )
end

function ENT:GetPoz()
    return self:GetPos() + self:GetUp() * ( 30 + self.UpAmount * 1.6 )
end

function ValidArcPossible( HitTrace, Destination )
    if not HitTrace.Hit then return nil end
    local MatType = HitTrace.MatType
    local HitEnt = HitTrace.Entity
    if not HitTrace.HitWorld and IsValid( HitEnt ) and MatType == MAT_METAL or MatType == MAT_GRATE then
        return true, HitEnt:NearestPoint( Destination ), HitEnt
    end
    return false
end

function SparkEffect( SparkPos )
    local Sparks = EffectData()
    Sparks:SetOrigin( SparkPos )
    Sparks:SetMagnitude( 2 )
    Sparks:SetScale( 1 )
    Sparks:SetRadius( 6 )
    util.Effect( "Sparks", Sparks )
end

function ENT:FindBattery()
    for _, potential in pairs( ents.FindInSphere( self:GetPos(), 100 ) ) do
        if potential:GetClass() == "ent_jack_turretbattery" and not potential.Dead then
            return potential
        end
    end

    return nil
end

function ENT:FindTarget()
    self.BatteryCharge = self.BatteryCharge - .0125
    local NewTarg = nil
    local Closest = self.MaxEngagementRange

    for key, found in pairs( ents.FindInSphere( self:GetPoz(), self.MaxEngagementRange ) ) do
        if found:IsPlayer() and found:HasGodMode() then continue end
        local Class = found:GetClass()
        local Phys = found:GetPhysicsObject()
        local Class = found:GetClass()

        if table.HasValue( SpecialTargetTable, Class ) then
            local Vel = found:GetVelocity() - self:GetPhysicsObject():GetVelocity()
            local Spd = Vel:Length()

            local Dist = ( found:LocalToWorld( found:OBBCenter() ) - self:GetPoz() ):Length()

            if Dist < Closest then
                NewTarg = found
                Closest = Dist
            end
        elseif IsValid( Phys ) then
            local Vel = Phys:GetVelocity() - self:GetPhysicsObject():GetVelocity()
            local Spd = Vel:Length()

            if Spd > 20 then
                local Dist = ( found:LocalToWorld( found:OBBCenter() ) - self:GetPoz() ):Length()

                if Dist < Closest then
                    NewTarg = found
                    Closest = Dist
                end
            end
        end
    end

    return NewTarg
end

function ENT:Think()
    if self.MenuOpen then return end

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

    if self.Broken then
        self.BatteryCharge = 0

        if math.random( 1, 8 ) == 7 then
            local effectdata = EffectData()
            effectdata:SetOrigin( self:GetPos() + self:GetUp() * math.random( 30, 40 ) )
            effectdata:SetNormal( VectorRand() )
            effectdata:SetMagnitude( 3 ) --amount and shoot hardness
            effectdata:SetScale( 1 ) --length of strands
            effectdata:SetRadius( 3 ) --thickness of strands
            util.Effect( "Sparks", effectdata, true, true )
            self:EmitSound( "snd_jack_turretfizzle.mp3", 70, 100 )
        else
            local effectdata = EffectData()
            effectdata:SetOrigin( self:GetPoz() )
            effectdata:SetScale( 1 )
            util.Effect( "eff_jack_tinyturretburn", effectdata, true, true )
        end

        self:Disengage()

        return
    end

    self:SetDTInt( 2, math.Round( self.BatteryCharge / 6000 * 100 ) )
    if self.State == "Off" then return end

    if self.CapacitorCharge <= 0 and self.BatteryCharge <= 0 then
        self:Disengage()

        return
    end

    if not self:ClearHead() then
        self:Disengage()

        return
    end

    if self.CapacitorCharge >= self.CapacitorMaxCharge or self.CapacitorCharge > 0 and self.BatteryCharge <= 0 then
        local Target = self:FindTarget()

        if IsValid( Target ) then
            local Class = Target:GetClass()

            if not self.JaFired then
                self.JaFired = true

                --this staggers the capacitor firings to make the sentries work together
                timer.Simple( math.Rand( 0, self.CapacitorMaxCharge / 1000 ), function()
                    if not IsValid( self ) then return end
                    if not IsValid( Target ) or not JID.CanTarget( Target ) then return end
                    if ( not Target.Health and not Target:Health() <= 0 and not table.HasValue( DoesNotHaveHealthTable, Class ) ) or Target.JackyTeslaKilled then return end
                    if not self:LineOfCurrentBetween( self, Target ) then return end
                    local DmgAmt = self.CapacitorCharge ^ 1.2 / 3
                    local Powa = self.CapacitorCharge
                    self.CapacitorCharge = 0
                    self:ZapTheShitOutOf( Target, DmgAmt, Powa )
                    self:ElectricalArcEffect( self, Target, Powa )
                    self:ArcToGround( Target, Powa )
                end )
            end
        else
            self.Zapped = false
            self.JaFired = false
        end
    else
        self.Zapped = false
        self.JaFired = false
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
        local Tr = util.QuickTrace( self:GetPoz(), VectorRand() * 15, { self } )

        if Tr.Hit then
            Hits = Hits + 1
        end
    end

    return Hits < 4 and self:WaterLevel() == 0
end

function ENT:ZapTheShitOutOf( Target, DmgAmt, Powa )
    if self.Zapped then return end
    self.Zapped = true
    local Dayumege = DamageInfo()
    Dayumege:SetDamageType( DMG_SHOCK )
    Dayumege:SetDamagePosition( self:GetPoz() )
    local Phys = Target:GetPhysicsObject()

    if IsValid( Phys ) then
        Dayumege:SetDamageForce( Target:GetUp() * Target:GetPhysicsObject():GetMass() ^ 0.6 * DmgAmt * 5 )
    else
        Dayumege:SetDamageForce( Target:GetUp() * 50 * DmgAmt * 5 )
    end

    Dayumege:SetDamage( DmgAmt )
    Dayumege:SetInflictor( self )
    Dayumege:SetAttacker( self:GetCreator() )

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

        if table.HasValue( DoesNotHaveHealthTable, Target:GetClass() ) then
            Target.JackyTeslaKilled = true
        end
    end
    if table.HasValue( SpecialTargetTable, Target:GetClass() ) then
        Target:SetVelocity( VectorRand() * 100000 )
        Dayumege:SetDamageType( DMG_MISSILEDEFENSE )

    end

    Target.IsSpasmingFromElectrocution = true
    local Chance = DmgAmt / 100 * 0.1

    if math.Rand( 0, 1 ) < Chance then
        Target:Ignite( 5 )
    end

    timer.Simple( 0.1, function()
        if IsValid( target ) then
            Target.IsSpasmingFromElectrocution = false
        end
    end )

    local Pos = Target:GetPos()
    Target:TakeDamageInfo( Dayumege )

    timer.Simple( .05, function()
        umsg.Start( "JackysElectriTwitchClientSentry" )
        umsg.Vector( Pos )
        umsg.End()
    end )
end

function ENT:ElectricalArcEffect( Attacker, Victim, Powa )
    local VictimPos = Victim:LocalToWorld( Victim:OBBCenter() )
    local SelfPos = Attacker:GetPoz()
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
    local Trayuss = util.QuickTrace( Victim:GetPos() + Vector( 0, 0, 5 ), Vector( 0, 0, -30000 ), Victim )

    if Trayuss.Hit then
        local NewStart = Victim:GetPos() + Vector( 0, 0, 5 )
        ToVector = Trayuss.HitPos - NewStart
        local Dist = ToVector:Length()

        if Dist > 25 then
            WanderDirection = Vector( 0, 0, -1 )
            local NumPoints = math.Clamp( math.ceil( 30 * Dist / 1000 ) + 1, 1, 50 )
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

                    if CheckTra.Hit then
                        WanderDirection = ( WanderDirection + CheckTra.HitNormal * 0.5 ):GetNormalized()
                    else
                        WeCantGoThere = false
                    end

                    C_P_I_L = C_P_I_L + 1

                    if C_P_I_L >= 50 then
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
    Flash:SetOrigin( self:GetPoz() )
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
    TraceData.start = Searcher:GetPoz()
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

local function MakeSpasms( ent, ragdoll )
    if ent.IsSpasmingFromElectrocution then
        local r, g, b, a = ent:GetColor()
        ragdoll:SetColor( r, g, b, a )

        if ent:IsOnFire() then
            ragdoll:Ignite( 5 )
        end

        ragdoll.NextSpazTime = CurTime()
        local OriginalForce = ragdoll:GetPhysicsObject():GetMass() ^ 0.75 * 20
        local Force = OriginalForce

        timer.Create( "SpasmingOnEntity" .. ragdoll:EntIndex(), 0.01, 500, function()
            if not IsValid( ragdoll ) then
                timer.Remove( "SpasmingOnEntity" .. ragdoll:EntIndex() )

                return
            end

            if ragdoll.NextSpazTime < CurTime() then
                ragdoll:GetPhysicsObject():ApplyForceCenter( VectorRand() * Force )
                ragdoll:GetPhysicsObject():AddAngleVelocity( VectorRand() * Force )
                Force = Force - OriginalForce / 500
            end
        end )
    end
end

hook.Add( "CreateEntityRagdoll", "JackSpasmLectricSentreh", MakeSpasms )

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
    me:EmitSound( "snd_jack_uiselect.mp3", 65, 100 )
    me.MenuOpen = false

    if me.State == "Off" then
        me:Engage()
    end
end

concommand.Add( "JackaTeslaTurretCloseMenu_On", CloseOn )

local function SetCap( ... )
    local args = { ... }

    local me = Entity( tonumber( args[3][1] ) )
    local Cap = tonumber( args[3][2] )
    me.CapacitorMaxCharge = Cap
end

concommand.Add( "JackaTeslaTurretSetCap", SetCap )
