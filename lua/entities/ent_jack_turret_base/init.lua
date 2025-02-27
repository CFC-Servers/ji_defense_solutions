AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

local TARGET_TABLE = {
    ["npc_helicopter"] = 700000,
    ["npc_strider"] = 800000,
    ["npc_combinegunship"] = 900000
}

local TS_NOTHING = 0
local TS_IDLING = 1
local TS_WATCHING = 2
local TS_CONCENTRATING = 3
local TS_AWAKENING = 4
local TS_TRACKING = 5
local TS_ASLEEPING = 6
local TS_WHINING = 7

local BOXES = {
    ["9x19mm"] = "ent_jack_turretammobox_9mm",
    ["12GAshotshell"] = "ent_jack_turretammobox_shot",
    ["7.62x51mm"] = "ent_jack_turretammobox_762",
    ["5.56x45mm"] = "ent_jack_turretammobox_556",
    [".338 Lapua Magnum"] = "ent_jack_turretammobox_338",
    [".22 Long Rifle"] = "ent_jack_turretammobox_22",
    ["40x53mm Grenade"] = "ent_jack_turretammobox_40mm",
    ["AAmissile"] = "ent_jack_turretmissilepod",
    ["ATrocket"] = "ent_jack_turretrocketpod"
}

ENT.IsJackaTurret = true

ENT.CurrentTarget = nil
ENT.HasAmmoBox = false
ENT.HasBattery = false
ENT.BatteryCharge = 0
ENT.GoalSweep = 0
ENT.GoalSwing = 0
ENT.CurrentSweep = 0
ENT.CurrentSwing = 0
ENT.NextScanTime = 0
ENT.NextShotTime = 0
ENT.NextWhineTime = 0
ENT.NextWatchTime = 0
ENT.NextGoSilentTime = 0
ENT.WeaponOut = false
ENT.NextBatteryAlertTime = 0
ENT.MenuOpen = false
ENT.NextFriendlyTime = 0
ENT.NextWarnTime = 0
ENT.RoundsOnBelt = 0
ENT.NextWarnTime = 0
ENT.WillWarn = false
ENT.WillLight = false
ENT.WillLightOverride = nil
ENT.MaxStructuralIntegrity = 400
ENT.StructuralIntegrity = 400
ENT.Broken = false
ENT.FiredAtCurrentTarget = false
ENT.NextClearCheckTime = 0
ENT.NextOverHeatWhineTime = 0
ENT.Heat = 0
ENT.IsLocked = false
ENT.LockPass = ""
ENT.MaxBatteryCharge = 3000
ENT.IdleDrainMul = 1
ENT.GroundCheckTime = 0
ENT.GroundLastWhine = 0
ENT.IsOnValidGround = true
ENT.PlugPosition = Vector( 0, 0, 20 )
ENT.TracerEffect = "Tracer"
ENT.MechanicsSizeMod = 1

-- if already acquired target is greater than this far behind something, lose em.
ENT.PropThicknessToDisengageSqr = nil

-- distance to find targets behind props, different var so turret can opress prop shields, without having wallhacks for new targets
-- also good for vehicles
ENT.PropThicknessToEngageSqr = nil

ENT.SpawnsWithBattery = false
ENT.SpawnsWithAmmo = false
ENT.SpawnInClunk = true

local function GetEntityVolume( ent )
    local phys = ent:GetPhysicsObject()
    local class = ent:GetClass()
    if ent:IsPlayer() then return 45000 end

    if not IsValid( phys ) then
        if TARGET_TABLE[class] ~= nil then
            return TARGET_TABLE[class]
        end
        return 0
    end

    local volume = phys:GetVolume()

    if volume then
        local model = ent:GetModel()
        if model and string.find( model, "/gibs/" ) then
            return 0
        end

        return volume
    else
        return 0
    end
end

function ENT:ExternalCharge( amt )
    self.BatteryCharge = self.BatteryCharge + amt

    if self.BatteryCharge > self.MaxBatteryCharge then
        self.BatteryCharge = self.MaxBatteryCharge
    end

    self:SetDTInt( 2, math.Round( self.BatteryCharge / self.MaxBatteryCharge * 100 ) )
end

local spawnAng = Angle( 0, 0, 0 )

function ENT:Initialize()
    local owner = self:GetNWEntity( "Owner", nil )
    if IsValid( owner ) then
        spawnAng.y = owner:EyeAngles().y

    end

    self:SetAngles( spawnAng )
    self:SetModel( "models/combine_turrets/floor_turret.mdl" )
    self:SetMaterial( "models/mat_jack_turret" )
    self:SetColor( Color( 50, 50, 50 ) )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetUseType( SIMPLE_USE )
    self:AddFlags( FL_OBJECT ) -- allow npcs to target the turret
    self:DrawShadow( true )
    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
        phys:SetMass( 200 )
    end

    self:SetDTInt( 0, TS_NOTHING )
    self:ResetSequence( 0 )
    self:ManipulateBoneScale( 0, Vector( 1.5, 1.1, 1 ) )
    self:SetNWVector( "BarrelSizeMod", self.BarrelSizeMod )

    self:SetNWFloat( "MechanicsSizeMod", self.MechanicsSizeMod )
    self:ManipulateBoneScale( 1, Vector( self.MechanicsSizeMod, 1, 1 ) )

    if self.AmmoType == "AAmissile" or self.AmmoType == "ATrocket" then
        self:ManipulateBoneScale( 4, Vector( .01, .01, .01 ) )
    end

    self:SetNWInt( "JackIndex", self:EntIndex() )
    self:SetDTBool( 0, self.HasAmmoBox )
    self:SetDTInt( 3, 0 )
    self.IFFTags = {}

    timer.Simple( 0, function()
        if not IsValid( self ) then return end
        if self.SpawnInClunk then -- used by "heavy" turrets
            self:EmitSound( "Canister.ImpactHard" )
        end
        if self.SpawnsWithBattery then
            self:RefillPower()
        end
        if self.SpawnsWithAmmo then
            local box = ents.Create( BOXES[self.AmmoType] )
            if not IsValid( box ) then return end
            box:SetPos( self:GetPos() )
            box:Spawn()
            self:RefillAmmo( box )
        end
    end )
end

function ENT:GetShootPos()
    return self:GetBonePosition( 4 )
end

function ENT:GetTargetPos( ent )
    return ent:WorldSpaceCenter()
end

function ENT:TargetIsInvalidOrDead()
    if not IsValid( self.CurrentTarget ) then return true end
    if self.CurrentTarget:GetMaxHealth() > 0 and self.CurrentTarget:Health() <= 0 then return true end
end

function ENT:PhysicsCollide( data )
    if data.Speed > 80 and data.DeltaTime > 0.2 and IsValid( self ) then
        self:EmitSound( "Canister.ImpactHard" )
    end

    if data.Speed > 750 then
        self.StructuralIntegrity = self.StructuralIntegrity - data.Speed / 50

        if self.StructuralIntegrity <= 0 then
            self:Break()
        end
    end

    if data.Speed < 20 and self:GetDTInt( 0 ) == TS_IDLING then
        self:Notice()
    end
end

function ENT:OnTakeDamage( dmginfo )
    self:TakePhysicsDamage( dmginfo )

    -- if we're already broken, it shouldnt look like we're breaking further
    if self.Broken then return end

    -- dont proppush turrets pls! 
    if IsValid( dmginfo:GetInflictor() ) and dmginfo:GetInflictor():IsPlayerHolding() then return end

    local damageTaken = nil

    if dmginfo:IsDamageType( DMG_BUCKSHOT ) or dmginfo:IsDamageType( DMG_BULLET ) or dmginfo:IsDamageType( DMG_BLAST ) or dmginfo:IsDamageType( DMG_CLUB ) then
        damageTaken = dmginfo:GetDamage()
    else
        damageTaken = dmginfo:GetDamage() / 10
    end
    if damageTaken then
        self.StructuralIntegrity = self.StructuralIntegrity - damageTaken

        if self.StructuralIntegrity <= 0 then
            self:Break()
        else
            self:MiniSpark( math.Clamp( damageTaken / 50, 0.2, 1 ) )

            local pitch = math.random( 110, 120 ) + ( -damageTaken / 4 )

            self:EmitSound( "Computer.BulletImpact" )
            self:EmitSound( "physics/metal/metal_canister_impact_hard" .. math.random( 1, 3 ) .. ".wav", 75, pitch, 1, CHAN_STATIC )
            if self:GetDTInt( 0 ) == TS_IDLING then
                self:Notice()
            end
        end
    end
end

function ENT:Use( activator )
    if not activator:IsPlayer() then return end
    if not JID.CanBeUsed( activator, self ) then return end
    if self.StructuralIntegrity <= 0 then
        local Kit = self:FindRepairKit()

        if IsValid( Kit ) then
            self:Fix( Kit )
            JID.genericUseEffect( activator )
        end
    end

    if self.Broken then return end

    if activator == self.CurrentTarget then
        self:EmitSound( "snd_jack_denied.mp3", 75, 100 )
        return
    end

    if self.IsLocked then
        self:EmitSound( "snd_jack_denied.mp3", 75, 100 )
        return
    end

    local nextMenuOpen = self.NextMenuOpen or 0

    if not self.MenuOpen and nextMenuOpen < CurTime() then
        local Tag = activator:GetNWInt( "JackyIFFTag" )
        self:EmitSound( "snd_jack_uisuccess.mp3", 65, 100 )
        self.MenuOpen = true

        umsg.Start( "JackaTurretOpenMenu", activator )
        umsg.Entity( self )
        umsg.Short( self.BatteryCharge )
        umsg.Short( self.RoundsOnBelt )
        umsg.Bool( table.HasValue( self.IFFTags, Tag ) )
        umsg.Bool( self.WillWarn )
        umsg.Bool( self.WillLight )
        umsg.End()
    end
end

function ENT:Think()
    local selfTbl = self:GetTable()
    selfTbl.Heat = selfTbl.Heat - .01

    if selfTbl.Heat < 0 then
        selfTbl.Heat = 0
    elseif selfTbl.Heat >= 50 then
        if math.random( 1, 5 ) == 1 then
            local PosAng = self:GetAttachment( 1 )
            local effect = EffectData()
            effect:SetOrigin( PosAng.Pos + PosAng.Ang:Forward() * math.random( -7, 7 ) )
            effect:SetScale( selfTbl.Heat / 50 )
            util.Effect( "eff_jack_gunoverheat", effect, true, true )
        end
    end

    if selfTbl.Broken then
        selfTbl.BatteryCharge = 0
        self:SetDTInt( 2, 0 )

        local rand = math.random( 1, 8 )

        if rand >= 8 then
            self:MiniSpark( 1 )
            self:EmitSound( "snd_jack_turretfizzle.mp3", 70, 100 )
        elseif rand < 4 then
            local effectdata = EffectData()
            effectdata:SetOrigin( self:GetShootPos() )
            effectdata:SetScale( 1 )
            util.Effect( "eff_jack_tinyturretburn", effectdata, true )
        end

        return
    end

    local State = self:GetDTInt( 0 )
    if State == TS_NOTHING then return end
    if selfTbl.MenuOpen then return end
    local SelfPos = self:GetShootPos()
    local Time = CurTime()
    local WeAreClear = self:ClearHead()
    self:SetDTInt( 4, selfTbl.RoundsOnBelt )

    if selfTbl.GroundCheckTime < Time then
        selfTbl.GroundCheckTime = Time + 3
        local traceData = {
            start = self:GetPos(),
            endpos = -self:GetUp() * 50 + self:GetPos(),
            filter = self
        }

        local trace = util.TraceLine( traceData )
        if not trace.Hit then
            selfTbl.IsOnValidGround = false
        else
            selfTbl.IsOnValidGround = true
        end
    end

    if selfTbl.BatteryCharge <= 0 then
        self:HardShutDown()

        return
    elseif selfTbl.BatteryCharge < selfTbl.MaxBatteryCharge * .2 then
        if selfTbl.NextBatteryAlertTime < Time then
            self:Whine()
            selfTbl.NextBatteryAlertTime = Time + 4.75
        end
    end

    if State ~= TS_WHINING and ( not WeAreClear or not selfTbl.IsOnValidGround ) then
        self:SetDTInt( 0, TS_WHINING )
    end

    if State == TS_IDLING then
        if selfTbl.NextWatchTime < Time then
            local possibleTarget = self:ScanForTarget()
            if possibleTarget then
                self:Notice()
            end
            selfTbl.BatteryCharge = selfTbl.BatteryCharge - ( .0010 * selfTbl.IdleDrainMul )
            selfTbl.NextWatchTime = Time + 1 / ( selfTbl.ScanRate * 1.5 )
        end
    elseif State == TS_WATCHING then
        if selfTbl.NextScanTime < Time then
            selfTbl.CurrentTarget = self:ScanForTarget()
            selfTbl.NextScanTime = Time + 1 / selfTbl.ScanRate

            if IsValid( selfTbl.CurrentTarget ) then
                self:Alert( selfTbl.CurrentTarget )
            end
        elseif selfTbl.NextGoSilentTime < Time then
            self:StandDown()
        end

        selfTbl.BatteryCharge = selfTbl.BatteryCharge - ( .05  * selfTbl.IdleDrainMul )
    elseif State == TS_CONCENTRATING then
        if selfTbl.NextScanTime < Time then
            selfTbl.CurrentTarget = self:ScanForTarget()
            selfTbl.NextScanTime = Time + ( 1 / selfTbl.ScanRate ) / 4

            if IsValid( selfTbl.CurrentTarget ) then
                self:Alert( selfTbl.CurrentTarget )
            end
        elseif selfTbl.NextGoSilentTime < Time then
            self:StandDown()
        end

        selfTbl.BatteryCharge = selfTbl.BatteryCharge - ( .025 * selfTbl.IdleDrainMul )
    elseif State == TS_TRACKING then
        if not IsValid( selfTbl.CurrentTarget ) then
            self:SetDTInt( 0, TS_CONCENTRATING )
            selfTbl.NextGoSilentTime = Time + 2
        else
            if self:CanSee( selfTbl.CurrentTarget, selfTbl.PropThicknessToDisengageSqr ) then
                local TargPos = self:GetTargetPos( selfTbl.CurrentTarget )
                local Ang = ( TargPos - SelfPos ):GetNormalized():Angle()
                local TargAng = self:WorldToLocalAngles( Ang )
                local ProperSweep = TargAng.y
                local ProperSwing = TargAng.p

                if TargAng.y > -90 and TargAng.y < 90 and TargAng.p > -90 and TargAng.p < 90 then
                    selfTbl.GoalSweep = ProperSweep
                    selfTbl.GoalSwing = ProperSwing
                else
                    selfTbl.CurrentTarget = self:ScanForTarget()
                end

                -- switch targets instantly if our current one just died
                if selfTbl.NextScanTime < Time or self:TargetIsInvalidOrDead() then
                    selfTbl.CurrentTarget = self:ScanForTarget()

                    if not IsValid( selfTbl.CurrentTarget ) then
                        self:StandDown()
                    end

                    selfTbl.NextScanTime = Time + 1 / selfTbl.ScanRate * 2
                end

                if selfTbl.NextShotTime < Time and selfTbl.CurrentSweep < selfTbl.GoalSweep + 2 and selfTbl.CurrentSweep > selfTbl.GoalSweep - 2 and selfTbl.CurrentSwing < selfTbl.GoalSwing + 2 and selfTbl.CurrentSwing > selfTbl.GoalSwing - 2 then
                    self:FireShot()
                    selfTbl.NextShotTime = Time + 1 / selfTbl.FireRate * math.Rand( .9, 1.1 )
                end
            else
                self:HoldFire()
            end
        end
        selfTbl.BatteryCharge = selfTbl.BatteryCharge - ( .05 * selfTbl.IdleDrainMul )
    elseif State == TS_WHINING then
        if WeAreClear and selfTbl.IsOnValidGround then
            self:SetDTInt( 0, TS_IDLING )
            selfTbl.GoalSweep = 0
            selfTbl.GoalSwing = 0
        else
            if selfTbl.NextWhineTime < Time then
                self:Whine()
                selfTbl.NextWhineTime = Time + .85

                if math.random( 1, 5 ) == 4 then
                    self:HardShutDown()
                end
            end
        end
    elseif State == TS_ASLEEPING then
        if selfTbl.CurrentSweep <= 2 and selfTbl.CurrentSwing <= 2 then
            self:StandBy()
        else
            if selfTbl.NextScanTime < Time then
                self:SetDTInt( 0, TS_WATCHING )
                selfTbl.NextScanTime = Time + 1 / selfTbl.TrackRate * 1.5
            end
        end
    end

    self:SetDTInt( 2, math.Round( selfTbl.BatteryCharge / selfTbl.MaxBatteryCharge * 100 ) )
    self:Traverse( selfTbl )
    self:NextThink( CurTime() + .02 )

    return true
end

function ENT:OnRemove()
    SafeRemoveEntity( self.flashlight )
    self:SetDTBool( 3, false )
end

function ENT:ClearHead()
    if math.random( 1, 10 ) == 5 then
        local Hits = 0

        for _ = 0, 20 do
            local Tr = util.QuickTrace( self:GetShootPos(), VectorRand() * 30, { self } )

            if Tr.Hit and not ( Tr.Entity:IsPlayer() or Tr.Entity:IsNPC() ) then
                Hits = Hits + 1
            end
        end

        return Hits < 7
    else
        return true
    end
end

local function IsBetterCanidate( turret, ent, shootPos, turretPos, closestCanidate, allowableThinnessSqr )
    if turret == ent then return end
    if ent:IsWorld() then return end
    if not turret:CanTarget( ent ) then return end
    if not turret:CanSee( ent, allowableThinnessSqr ) then return end

    local size = GetEntityVolume( ent )
    if size <= 0 then return end

    local targetPos = ent:GetPos()
    local ang = ( targetPos - shootPos ):GetNormalized():Angle()

    local distance = ( targetPos - turretPos ):Length()
    if distance > closestCanidate then return end

    local targetAngle = turret:WorldToLocalAngles( ang )

    if targetAngle.y <= -90 then return end
    if targetAngle.y >= 90 then return end
    if targetAngle.p <= -90 then return end
    if targetAngle.p >= 90 then return end

    if ent:IsPlayer() then
        local tag = ent:GetNWInt( "JackyIFFTag" )

        if tag and tag ~= 0 and table.HasValue( turret.IFFTags, tag ) then
            if math.random( 1, 5 ) == 2 then
                turret:FriendlyAlert()
            end
            return
        end
    end

    return ent, distance
end

function ENT:CanTarget( ent )
    if not JID.CanTarget( self, ent ) then return false end
    if not JID.IsTargetVisibile( ent ) then return false end
    if ent:GetClass() == "cfc_shaped_charge" then return true end
    if ent:IsPlayer() and ent:Alive() and not ent:HasGodMode() then return true end
    if ent:IsNPC() and ent:Health() > 0 then return true end
    if ent:IsNextBot() then return true end
    if ent:IsVehicle() and JID.CanTarget( ent:GetDriver() ) then return true end
    return false
end

function ENT:ScanForTarget()
    local oldTarget = self.CurrentTarget
    local shootPos = self:GetShootPos()
    local closestCanidate = self.MaxRange
    local turretPos = self:GetPos()
    local bestTarget = nil
    local thicknessToEngageSqr = self.PropThicknessToEngageSqr
    local thicknessToDisegnageSqr = self.PropThicknessToDisengageSqr

    for _, potential in pairs( ents.FindInSphere( turretPos, self.MaxRange ) ) do

        local thinnessSqr = thicknessToEngageSqr

        if potential == oldTarget then
            thinnessSqr = thicknessToDisegnageSqr
        end

        local betterCanidate, canidateDistance = IsBetterCanidate( self, potential, shootPos, turretPos, closestCanidate, thinnessSqr )
        if betterCanidate then
            bestTarget = betterCanidate
            closestCanidate = canidateDistance
        end
    end

    self.BatteryCharge = self.BatteryCharge - self.MaxRange / 2000

    if bestTarget then
        JID.EnrageNPC( self, bestTarget )

        if bestTarget == self.CurrentTarget then
            return bestTarget
        end
        if bestTarget == self.CurrentTarget and self.FiredAtCurrentTarget then
            return nil
        elseif bestTarget ~= self.CurrentTarget then
            self.FiredAtCurrentTarget = false
        end
    end
    return bestTarget
end

function ENT:FriendlyAlert()
    if self.NextFriendlyTime >= CurTime() then return end
    self.NextFriendlyTime = CurTime() + 1
    local Flash = EffectData()
    Flash:SetOrigin( self:GetShootPos() )
    Flash:SetScale( .7 )
    util.Effect( "eff_jack_cyanflash", Flash, true, true )
    self:EmitSound( "snd_jack_turrethi.mp3", 80, 100 )
    self.BatteryCharge = self.BatteryCharge - .5
end

function ENT:HostileAlert()
    local Flash = EffectData()
    Flash:SetOrigin( self:GetShootPos() )
    Flash:SetScale( 1.3 )
    util.Effect( "eff_jack_redflash", Flash, true, true )
    self:EmitSound( "snd_jack_turretwarn.mp3", 80, 100 )
    sound.Play( "snd_jack_turretwarn.mp3", self:GetPos(), 80, 100 )
    self.BatteryCharge = self.BatteryCharge - .5
end

function ENT:HoldFire()
    self:SetDTInt( 0, TS_CONCENTRATING )
    self.NextGoSilentTime = CurTime() + 10
    self.CurrentTarget = nil
end

function ENT:StandDown()
    self.GoalSweep = 0
    self.GoalSwing = 0
    self.CurrentTarget = nil
    self:SetDTInt( 0, TS_ASLEEPING )
end

function ENT:Notice()
    if self:GetDTInt( 0 ) == TS_WHINING then return end
    self:SetDTInt( 0, TS_WATCHING )
    self.NextGoSilentTime = CurTime() + 5
    self.NextScanTime = CurTime() + 1 / self.ScanRate
    self:EmitSound( "snd_jack_turretdetect.mp3", 105, 100 )
    self.BatteryCharge = self.BatteryCharge - .25
end

function ENT:Alert( targ )
    if not self.WeaponOut then
        self:SetDTInt( 0, TS_AWAKENING )
        self:ResetSequence( 4 )
        self.WeaponOut = true

        if not ( self.AmmoType == "AAmissile" or self.AmmoType == "ATrocket" ) then
            self:EmitSound( "snd_jack_turretawaken.mp3", 70, 100 )
        end

        timer.Simple( .4 / self.TrackRate, function()
            if IsValid( self ) and IsValid( self.CurrentTarget ) then
                self:SetDTInt( 0, TS_TRACKING )
            elseif IsValid( self ) then
                self:StandBy()
            end
        end )

        self.NextWarnTime = CurTime() + 5
        self.BatteryCharge = self.BatteryCharge - .5 * self.MechanicsSizeMod

        if self.WillLight then
            self.flashlight = ents.Create( "env_projectedtexture" )
            self.flashlight:SetParent( self )
            -- The local positions are the offsets from parent..
            self.flashlight:SetLocalPos( Vector( 0, 0, 50 ) )
            self.flashlight:SetLocalAngles( Angle( 0, 0, 0 ) )
            -- Looks like only one flashlight can have shadows enabled!
            self.flashlight:SetKeyValue( "enableshadows", 0 )
            self.flashlight:SetKeyValue( "farz", 800 )
            self.flashlight:SetKeyValue( "nearz", 30 )
            self.flashlight:SetKeyValue( "lightfov", 30 )
            self.flashlight:SetKeyValue( "lightcolor", "4080 4080 4080 255" )
            self.flashlight:Spawn()
            self.flashlight:Input( "SpotlightTexture", NULL, NULL, "effects/flashlight001" )
            self:SetDTBool( 3, true )
        end
    else
        self.BatteryCharge = self.BatteryCharge - .1
        self:SetDTInt( 0, TS_TRACKING )

        if targ then
            self.CurrentTarget = targ
        end
    end
end

function ENT:Traverse( selfTbl )
    local PowerDrain = .2 * selfTbl.TrackRate * selfTbl.MechanicsSizeMod ^ 1.5

    if selfTbl.CurrentSweep > selfTbl.GoalSweep + 2 then
        selfTbl.CurrentSweep = selfTbl.CurrentSweep - selfTbl.TrackRate
        self:EmitSound( "snd_jack_turretservo.mp3", 66, 90 )
        selfTbl.BatteryCharge = selfTbl.BatteryCharge - PowerDrain
    elseif selfTbl.CurrentSweep < selfTbl.GoalSweep - 2 then
        selfTbl.CurrentSweep = selfTbl.CurrentSweep + selfTbl.TrackRate
        self:EmitSound( "snd_jack_turretservo.mp3", 66, 90 )
        selfTbl.BatteryCharge = selfTbl.BatteryCharge - PowerDrain
    end

    if selfTbl.CurrentSwing > selfTbl.GoalSwing + 2 then
        selfTbl.CurrentSwing = selfTbl.CurrentSwing - selfTbl.TrackRate * .6667
        self:EmitSound( "snd_jack_turretservo.mp3", 66, 110 )
        selfTbl.BatteryCharge = selfTbl.BatteryCharge - PowerDrain
    elseif selfTbl.CurrentSwing < selfTbl.GoalSwing - 2 then
        selfTbl.CurrentSwing = selfTbl.CurrentSwing + selfTbl.TrackRate * .6667
        self:EmitSound( "snd_jack_turretservo.mp3", 66, 110 )
        selfTbl.BatteryCharge = selfTbl.BatteryCharge - PowerDrain
    end

    if self:GetNWFloat( "CurrentSweep" ) ~= selfTbl.CurrentSweep then
        self:SetNWFloat( "CurrentSweep", selfTbl.CurrentSweep )
    end

    if self:GetNWFloat( "CurrentSwing" ) ~= selfTbl.CurrentSwing then
        self:SetNWFloat( "CurrentSwing", selfTbl.CurrentSwing )
    end

    if IsValid( selfTbl.flashlight ) then
        selfTbl.flashlight:SetLocalAngles( Angle( selfTbl.CurrentSwing, selfTbl.CurrentSweep, 0 ) )
    end
end

-- use this to add extra flash when turrets fire, no need to overwrite fireshot
function ENT:AdditionalShootFX()
end

function ENT:FireShot()
    self.CurrentTarget = IsValid( self.CurrentTarget ) and self.CurrentTarget or self:ScanForTarget()
    if not IsValid( self.CurrentTarget ) then return self:StandBy() end

    local Time = CurTime()
    self.BatteryCharge = self.BatteryCharge - .1

    if self.WillWarn and self.NextWarnTime >= Time then
        if ( self.NextWarnBark or 0 ) < Time then
            self:HostileAlert()
            self.NextWarnBark = Time + 1
        end

        return
    end

    if not self.RoundInChamber then
        self:EmitSound( "snd_jack_turretclick.mp3", 70, 110 )

        if self.NextWhineTime < CurTime() then
            self:Whine()
            self.NextWhineTime = CurTime() + 2.25
        end
        return
    end

    if self.Heat >= 95 then
        if self.NextOverHeatWhineTime < Time then
            self.NextOverHeatWhineTime = Time + .5
            self:Whine()
        end

        return
    end

    local fakeDPS = self.BulletDamage * ( self.BulletsPerShot / 2 )
    local additionalScale = math.Clamp( fakeDPS / 8, 0, 3 )

    local sweepAng = Angle( self.CurrentSwing, self.CurrentSweep, 0 )
    sweepAng = self:LocalToWorldAngles( sweepAng )
    local up = sweepAng:Up()
    local forward = sweepAng:Forward()
    local right = sweepAng:Right()

    local ShootPos = self:GetBonePosition( 1 ) -- turret pivot bone

    ShootPos = ShootPos + -right * 4
    ShootPos = ShootPos + up * 22

    local muzzleEffect = EffectData()
    muzzleEffect:SetOrigin( ShootPos + forward * self.BarrelSizeMod.z * 5 )
    muzzleEffect:SetAngles( sweepAng )
    muzzleEffect:SetScale( 0.5 + additionalScale )
    util.Effect( "MuzzleEffect", muzzleEffect, true, true )

    local fakeRecoilTime = .1
    self.returnFakeRecoil = CurTime() + fakeRecoilTime
    self:SetNWVector( "BarrelSizeMod", Vector( self.BarrelSizeMod.x, self.BarrelSizeMod.y, self.BarrelSizeMod.z * .75 ) )

    timer.Simple( fakeRecoilTime, function()
        if not IsValid( self ) then return end
        local returnFakeRecoil = self.returnFakeRecoil or 0
        if returnFakeRecoil > CurTime() then return end
        self:SetNWVector( "BarrelSizeMod", self.BarrelSizeMod )
    end )

    self:AdditionalShootFX()

    local TargPos = self:GetTargetPos( self.CurrentTarget )

    local Dir = ( TargPos - ShootPos ):GetNormalized()
    local spread
    if self:IsPlayerHolding() then
        spread = self.ShotSpread * 10
    else
        spread = self.ShotSpread
    end

    local Phys = self.CurrentTarget:GetPhysicsObject()

    if IsValid( Phys ) then
        local RelSpeed = ( Phys:GetVelocity() - self:GetPhysicsObject():GetVelocity() ):Length()

        if self:GetClass() ~= "ent_jack_turret_shotty" then
            spread = spread + RelSpeed / 100000
        end
    end

    -- manually build spread to avoid weird bug where all shots land in the top right for no apparent reason
    local Rand = VectorRand( -1, 1 )
     -- z is behind/in front, just makes the turrets biast towards shooting in the center
    Rand.z = 0
    Rand:Normalize()

    local SpreadVec = Rand * spread

    local bulletData = {
        Attacker = self:GetCreator(),
        Damage = self.BulletDamage,
        Force = self.BulletDamage / 60,
        Num = self.BulletsPerShot,
        Tracer = 0,
        Dir = Dir,
        Spread = SpreadVec,
        Src = ShootPos,
        Callback = function( _, trace )
            local TracerEffect = EffectData()
            TracerEffect:SetStart( ShootPos )
            TracerEffect:SetOrigin( trace.HitPos )
            TracerEffect:SetFlags( 1 )
            TracerEffect:SetScale( self.MaxRange * 8 )
            util.Effect( self.TracerEffect, TracerEffect )
        end
    }

    self:FireBullets( bulletData )
    self.FiredAtCurrentTarget = true
    self.RoundInChamber = false
    self.Heat = self.Heat + ( self.BulletDamage * self.BulletsPerShot ) / 150

    local filterBroader = RecipientFilter()
    filterBroader:AddPVS( self:GetPos() )

    local rangeLevelOffset = self.MaxRange / 300

    self:EmitSound( self.NearShotNoise, 70 + rangeLevelOffset, self.ShootSoundPitch, 1, CHAN_WEAPON )
    self:EmitSound( self.FarShotNoise, 90 + rangeLevelOffset, self.ShootSoundPitch - 10, 1, CHAN_WEAPON, 0, 0, filterBroader ) -- semi-global sound so players know where they're getting shot from


    sound.Play( self.NearShotNoise, ShootPos, 65 + rangeLevelOffset, self.ShootSoundPitch ) -- play extra sounds to make it feel punchier.
    sound.Play( self.FarShotNoise, ShootPos + Vector( 0, 0, 1 ), 85 + rangeLevelOffset, self.ShootSoundPitch - 10 )

    if self.RoundsOnBelt > 0 then
        if self.Autoloading then
            self.RoundsOnBelt = self.RoundsOnBelt - 1
            self.RoundInChamber = true
            local effectdata = EffectData()
            effectdata:SetOrigin( ShootPos )
            effectdata:SetAngles( Dir:Angle():Right():Angle() )
            effectdata:SetEntity( self )
            util.Effect( self.ShellEffect, effectdata, true, true )
        else
            timer.Simple( 1 / self.FireRate * .25, function()
                if IsValid( self ) then
                    self:EmitSound( self.CycleSound, 68, 100 )
                end
            end )

            timer.Simple( 1 / self.FireRate * .35, function()
                if IsValid( self ) then
                    self.RoundsOnBelt = self.RoundsOnBelt - 1
                    self.RoundInChamber = true
                    local effectdata = EffectData()
                    effectdata:SetOrigin( ShootPos )
                    effectdata:SetAngles( Dir:Angle():Right():Angle() )
                    effectdata:SetEntity( self )
                    util.Effect( self.ShellEffect, effectdata, true, true )
                end
            end )
        end
    end

    self:GetPhysicsObject():ApplyForceOffset( -Dir * self.BulletDamage * 6 * self.BulletsPerShot, ShootPos + self:GetUp() * 30 )
end

function ENT:Whine()
    self:EmitSound( "snd_jack_turretwhine.mp3", 80, 100 )
    self.BatteryCharge = self.BatteryCharge - .05
end

function ENT:StandBy()
    self:SetDTInt( 0, TS_IDLING )

    if not self.WeaponOut then return end
    self:ResetSequence( 0 )

    if not ( self.AmmoType == "AAmissile" or self.AmmoType == "ATrocket" ) then
        self:EmitSound( "snd_jack_turretasleep.mp3", 70, 100 )
    end

    self.WeaponOut = false
    self.BatteryCharge = self.BatteryCharge - .5 * self.MechanicsSizeMod
    SafeRemoveEntity( self.flashlight )
    self:SetDTBool( 3, false )
end

function ENT:CanSee( ent, allowableThinnessSqr )
    local worldSpaceCenter = ent:WorldSpaceCenter()

    local traceTable = {
        start = self:GetShootPos(),
        endpos = worldSpaceCenter,
        filter = { self, ent },
        mask = MASK_SHOT
    }

    local traceResult = util.TraceLine( traceTable )

    -- return true if target is directly visibile, or behind a thin thing
    -- common strategy to defeat turrets is to use prop shields, this should make it interesting
    if not traceResult.Hit then return true end

    if not allowableThinnessSqr then return false end
    if traceResult.HitWorld then return false end
    return traceResult.HitPos:DistToSqr( worldSpaceCenter ) < allowableThinnessSqr
end

function ENT:HardShutDown()
    self:EmitSound( "snd_jack_turretshutdown.mp3", 80, 100 )
    self:SetDTInt( 0, TS_NOTHING )
    self:GetPhysicsObject():SetDamping( 0, 0 )
    self.CurrentTarget = nil

    SafeRemoveEntity( self.flashlight )
    self:SetDTBool( 3, false )
end

function ENT:StartUp()
    if not self.HasBattery then return end
    if self.BatteryCharge <= 0 then return end
    self:EmitSound( "snd_jack_turretstartup.mp3", 80, 100 )
    self:GetPhysicsObject():SetDamping( 0, 10 )

    if self.AmmoType == "AAmissile" then
        self.MissileLocked = false
    end

    self:Notice()
end

function ENT:FindAmmo()
    for _, potential in pairs( ents.FindInSphere( self:GetPos(), 100 ) ) do
        if potential:GetClass() == BOXES[self.AmmoType] and not potential.Empty then
            return potential
        end
    end

    return nil
end

function ENT:DetachAmmoBox()
    self.RoundsOnBelt = 0
    self.HasAmmoBox = false
    self:SetDTBool( 0, self.HasAmmoBox )

    local Box = ents.Create( BOXES[self.AmmoType] )
    Box.AmmoType = self.AmmoType
    Box.Empty = true
    Box:SetPos( self:GetPos() - self:GetRight() * 10 + self:GetUp() * 30 )
    Box:SetAngles( self:GetRight():Angle() )
    Box:Spawn()
    Box:Activate()

    self:EmitSound( "snd_jack_turretammounload.mp3" )
    SafeRemoveEntityDelayed( Box, 30 )
end

function ENT:RefillAmmo( box )
    self.HasAmmoBox = true
    self:SetDTBool( 0, self.HasAmmoBox )

    if self.RoundInChamber then
        self.RoundsOnBelt = box.NumberOfRounds
    else
        self.RoundInChamber = true
        self.RoundsOnBelt = box.NumberOfRounds - 1
    end

    self:EmitSound( "snd_jack_turretammoload.mp3" )
    SafeRemoveEntity( box )

end

function ENT:RefillPower( box )
    self.HasBattery = true
    self:SetDTBool( 1, self.HasBattery )
    self.BatteryCharge = self.MaxBatteryCharge
    self:SetDTInt( 2, math.Round( self.BatteryCharge / self.MaxBatteryCharge * 100 ) )

    self:SetDTBool( 3, false )
    self:EmitSound( "snd_jack_turretbatteryload.mp3" )

    if not IsValid( box ) then return end
    SafeRemoveEntity( box )
end

function ENT:DetachBattery()
    self.BatteryCharge = 0
    self.HasBattery = false
    self:SetDTBool( 1, self.HasBattery )

    local Box = ents.Create( "ent_jack_turretbattery" )
    Box.Dead = true
    Box:SetPos( self:GetPos() + self:GetRight() * 10 + self:GetUp() * 10 )
    Box:SetAngles( self:GetForward():Angle() )
    Box:Spawn()
    Box:Activate()

    self:EmitSound( "snd_jack_turretbatteryunload.mp3" )
end

function ENT:FindBattery()
    for _, potential in pairs( ents.FindInSphere( self:GetPos(), 100 ) ) do
        if potential:GetClass() == "ent_jack_turretbattery" and not potential.Dead then
            return potential
        end
    end

    return nil
end

function ENT:Break()
    if self.Broken then return end
    self:EmitSound( "snd_jack_turretbreak.mp3" )
    self.Broken = true
    self:SetDTInt( 0, TS_NOTHING )
    self.IsLocked = false
    self.LockPass = ""
    self.CurrentTarget = nil

    -- ppl expect explosions when stuff breaks
    local effectdata = EffectData()
    effectdata:SetOrigin( self:ChassisPos() )
    effectdata:SetMagnitude( 0.2 ) --length of strands
    effectdata:SetScale( 0.2 )
    util.Effect( "Explosion", effectdata, true, true )

    self:AddFlags( FL_NOTARGET )

    SafeRemoveEntity( self.flashlight )
    self:SetDTBool( 3, false )

end

function ENT:Fix( kit )
    self.StructuralIntegrity = self.MaxStructuralIntegrity
    self:EmitSound( "snd_jack_turretrepair.mp3", 70, 100 )

    timer.Simple( 3.25, function()
        if not IsValid( self ) then return end
        self.Broken = false
        self:RemoveAllDecals()
        self:RemoveFlags( FL_NOTARGET )

    end )

    kit:Empty()

end

function ENT:ShouldDoDamageConversion() -- only take real damage when our JI health runs out
    return self.Broken

end

function ENT:FindRepairKit()
    for _, potential in pairs( ents.FindInSphere( self:GetPos(), 100 ) ) do
        if potential:GetClass() == "ent_jack_turretrepairkit" then return potential end
    end

    return nil
end

local function SentryChat( ply, txt )
    local Found = false

    if string.sub( txt, 1, 12 ) == "sentry lock " then
        for _, sent in pairs( ents.FindInSphere( ply:GetPos(), 150 ) ) do
            if string.find( sent:GetClass(), "ent_jack_turret_" ) then
                local Pass = string.Split( txt, " " )[3]

                if Pass and not sent.IsLocked and sent.BatteryCharge > 0 then
                    Found = true
                    sent.IsLocked = true
                    sent.LockPass = Pass
                    ply:PrintMessage( HUD_PRINTTALK, "Sentry " .. tostring( sent:EntIndex() ) .. " locked with password " .. Pass )
                end
            end
        end
    elseif string.sub( txt, 1, 14 ) == "sentry unlock " then
        for _, sent in pairs( ents.FindInSphere( ply:GetPos(), 150 ) ) do
            if string.find( sent:GetClass(), "ent_jack_turret_" ) then
                local Pass = string.Split( txt, " " )[3]

                if Pass and sent.IsLocked and Pass == sent.LockPass and sent.BatteryCharge > 0 then
                    Found = true
                    sent.IsLocked = false
                    sent.LockPass = ""
                    ply:PrintMessage( HUD_PRINTTALK, "Sentry " .. tostring( sent:EntIndex() ) .. " unlocked" )
                    sent:EmitSound( "snd_jack_granted.mp3", 75, 100 )
                end
            end
        end
    end

    if Found then return "" end
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
    return self:GetPos() + self:GetUp() * math.random( 30, 55 )

end

local _IsValid = IsValid

local function IsAValidJackaTurret( ent )
    if not _IsValid( ent ) then return end
    if not ent.IsJackaTurret then return end
    return true

end

hook.Add( "PlayerSay", "JackaSentryChat", SentryChat )

local function closeOn( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )
    if not IsAValidJackaTurret( turret ) then return end

    turret:EmitSound( "snd_jack_uiselect.mp3", 65, 100 )
    turret.MenuOpen = false

    if turret:GetDTInt( 0 ) == TS_NOTHING and turret.StartUp then
        turret:StartUp()
        JID.genericUseEffect( args[1] )
    end
end

concommand.Add( "JackaTurretCloseMenu_On", closeOn )

local function closeOff( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )
    if not IsAValidJackaTurret( turret ) then return end

    turret:EmitSound( "snd_jack_uiselect.mp3", 65, 100 )
    turret.MenuOpen = false

    if turret:GetDTInt( 0 ) ~= TS_NOTHING then
        turret:HardShutDown()
        JID.genericUseEffect( args[1] )
    end
end

concommand.Add( "JackaTurretCloseMenu_Off", closeOff )

local function closeCancel( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )
    if not IsAValidJackaTurret( turret ) then return end

    turret:EmitSound( "snd_jack_uiselect.mp3", 65, 100 )
    turret.MenuOpen = false
    turret.NextMenuOpen = CurTime() + 0.1
end

concommand.Add( "JackaTurretCloseMenu_Cancel", closeCancel )

local function addAmmo( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )
    if not IsAValidJackaTurret( turret ) then return end

    if turret.AmmoType == "AAmissile" or turret.AmmoType == "ATrocket" then
        if not turret.RoundInChamber then
            if not turret.HasAmmoBox then
                local Tube = turret:FindAmmo()

                if IsValid( Tube ) then
                    turret:RefillAmmo( Tube )
                else
                    args[1]:PrintMessage( HUD_PRINTCENTER, "No munition present." )
                end
            else
                turret:DetachAmmoBox()
                JID.genericUseEffect( args[1] )
            end
        else
            args[1]:PrintMessage( HUD_PRINTCENTER, "Current tube not empty." )
        end
    else
        if not turret.RoundsOnBelt then
            turret.RoundsOnBelt = 0
        end

        if turret.RoundsOnBelt <= 5 then
            if not turret.HasAmmoBox then
                local Box = turret:FindAmmo()

                if IsValid( Box ) then
                    turret:RefillAmmo( Box )
                    JID.genericUseEffect( args[1] )
                else
                    args[1]:PrintMessage( HUD_PRINTCENTER, "No ammunition present. Requires " .. turret.AmmoType .. "." )
                end
            else
                turret:DetachAmmoBox()
                JID.genericUseEffect( args[1] )
            end
        else
            args[1]:PrintMessage( HUD_PRINTCENTER, "Current box not empty." )
        end
    end

    turret.MenuOpen = false
end

concommand.Add( "JackaTurretAmmo", addAmmo )

local function IFFTag( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )
    if not IsAValidJackaTurret( turret ) then return end

    local ply = args[1]
    turret:EmitSound( "snd_jack_uiselect.mp3", 65, 100 )
    turret.MenuOpen = false
    local Tag = ply:GetNWInt( "JackyIFFTag" )

    if Tag and Tag ~= 0 then
        if not table.HasValue( turret.IFFTags, Tag ) then
            if Tag ~= 0 then
                table.ForceInsert( turret.IFFTags, Tag )
            end

            ply:PrintMessage( HUD_PRINTTALK, "IFF tag ID recorded." )
        else
            table.remove( turret.IFFTags, table.KeyFromValue( turret.IFFTags, Tag ) )
            ply:PrintMessage( HUD_PRINTTALK, "IFF tag ID forgotten." )
        end
    else
        ply:PrintMessage( HUD_PRINTCENTER, "You don't have an IFF tag implanted." )
    end
end

concommand.Add( "JackaTurretIFF", IFFTag )

local function warn( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )
    if not IsAValidJackaTurret( turret ) then return end

    local Check = tobool( args[3][2] )
    turret.WillWarn = Check
    turret:EmitSound( "snd_jack_uiselect.mp3", 65, 100 )
end

concommand.Add( "JackaTurretWarn", warn )

local function light( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )
    if not IsAValidJackaTurret( turret ) then return end

    local Check = tobool( args[3][2] )
    turret.WillLight = turret.WillLightOverride or Check
    turret:EmitSound( "snd_jack_uiselect.mp3", 65, 100 )
end

concommand.Add( "JackaTurretLight", light )

local function addBattery( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )
    if not IsAValidJackaTurret( turret ) then return end

    if not turret.BatteryCharge then
        turret.BatteryCharge = 0
    end

    if turret.BatteryCharge <= turret.MaxBatteryCharge * 0.25 then
        if not turret.HasBattery then
            local Box = turret:FindBattery()

            if IsValid( Box ) then
                turret:RefillPower( Box )
                JID.genericUseEffect( args[1] )
            else
                args[1]:PrintMessage( HUD_PRINTCENTER, "No battery present." )
            end
        else
            turret:DetachBattery()
            JID.genericUseEffect( args[1] )
        end
    else
        args[1]:PrintMessage( HUD_PRINTCENTER, "Current battery not dead." )
    end

    turret.MenuOpen = false
end

concommand.Add( "JackaTurretBattery", addBattery )

local function upright( ... )
    local args = { ... }

    local ply = args[1]
    local turret = Entity( tonumber( args[3][1] ) )
    if not IsAValidJackaTurret( turret ) then return end

    local AimVec = ply:GetAimVector()

    local Trace = util.QuickTrace( ply:GetShootPos(), AimVec * 150, { turret, ply } )

    if Trace.Hit then
        turret:SetPos( Trace.HitPos + Trace.HitNormal * 3 )

        local Ang = AimVec:Angle()
        local AngDiff = AimVec:AngleEx( Trace.HitNormal )
        Ang:RotateAroundAxis( Ang:Right(), AngDiff.p )
        turret:SetAngles( Ang )
        turret:EmitSound( "weapons/iceaxe/iceaxe_swing1.wav", 70, 80 )
        JID.genericUseEffect( ply )
        turret:GetPhysicsObject():ApplyForceCenter( VectorRand() )
    end

    turret.MenuOpen = false
end

concommand.Add( "JackaTurretUpright", upright )
