AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

local HULL_TARGETING = {
    [0] = 0,
    [HULL_TINY] = -5,
    [HULL_TINY_CENTERED] = 0,
    [HULL_SMALL_CENTERED] = -5,
    [HULL_HUMAN] = 10,
    [HULL_WIDE_SHORT] = 20,
    [HULL_WIDE_HUMAN] = 15,
    [HULL_MEDIUM] = 0,
    [HULL_MEDIUM_TALL] = 35,
    [HULL_LARGE] = 30,
    [HULL_LARGE_CENTERED] = 30
}

local HULL_SIZE_TABLE = {
    [HULL_TINY] = { 0, 1000 },
    [HULL_TINY_CENTERED] = { 1000, 7000 },
    [HULL_SMALL_CENTERED] = { 7000, 15000 },
    [HULL_HUMAN] = { 15000, 50000 },
    [HULL_WIDE_SHORT] = { 50000, 70000 },
    [HULL_WIDE_HUMAN] = { 70000, 200000 },
    [HULL_MEDIUM] = { 200000, 700000 },
    [HULL_MEDIUM_TALL] = { 700000, 1000000 },
    [HULL_LARGE] = { 1000000, 1500000 },
    [HULL_LARGE_CENTERED] = { 1500000, 2000000 }
}

local SYNTHETIC_TABLE = {
    MAT_CONCRETE = true,
    MAT_GRATE = true,
    MAT_CLIP = true,
    MAT_PLASTIC = true,
    MAT_METAL = true,
    MAT_COMPUTER = true,
    MAT_TILE = true,
    MAT_WOOD = true,
    MAT_VENT = true,
    MAT_GLASS = true,
    MAT_DIRT = true,
    MAT_SAND = true
}

local ORGANIC_TABLE = {
    MAT_FLESH = true,
    MAT_ANTLION = true,
    MAT_BLOODYFLESH = true,
    MAT_FOLIAGE = true,
    MAT_SLOSH = true
}

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
ENT.NextAlrightFuckYouTime = 0
ENT.WillWarn = false
ENT.WillLight = false
ENT.StructuralIntegrity = 400
ENT.Broken = false
ENT.FiredAtCurrentTarget = false
ENT.NextClearCheckTime = 0
ENT.NextOverHeatWhineTime = 0
ENT.Heat = 0
ENT.IsLocked = false
ENT.LockPass = ""
ENT.MaxCharge = 3000
ENT.PlugPosition = Vector( 0, 0, 20 )

local function GetCenterMass( ent )
    local Pos = ent:LocalToWorld( ent:OBBCenter() )
    local Hull = 0

    if ent.GetHullType then
        Hull = ent:GetHullType()
    end

    local Add = Vector( 0, 0, 0 )

    if ent:IsNPC() or ent:IsPlayer() then
        Add = Vector( 0, 0, HULL_TARGETING[Hull] )
    end

    Pos = Pos + Add

    if ent:IsPlayer() and ent:Crouching() then
        Pos = Pos - Vector( 0, 0, 20 )
    end

    return Pos
end

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

local function IsSynthetic( ent )
    local mat = ent:GetMaterialType()

    if ORGANIC_TABLE[mat] then
        return false
    elseif SYNTHETIC_TABLE[mat] then
        return true
    end
    return false
end

function ENT:ExternalCharge( amt )
    self.BatteryCharge = self.BatteryCharge + amt

    if self.BatteryCharge > self.MaxCharge then
        self.BatteryCharge = self.MaxCharge
    end

    self:SetDTInt( 2, math.Round( self.BatteryCharge / self.MaxCharge * 100 ) )
end

function ENT:WillTargetThisSize( siz )
    for _, grp in pairs( self.TargetingGroup ) do
        if siz > HULL_SIZE_TABLE[grp][1] and siz <= HULL_SIZE_TABLE[grp][2] then return true end
    end

    return false
end

function ENT:Initialize()
    self:SetAngles( Angle( 0, 0, 0 ) )
    self:SetModel( "models/combine_turrets/floor_turret.mdl" )
    self:SetMaterial( "models/mat_jack_turret" )
    self:SetColor( Color( 50, 50, 50 ) )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetUseType( SIMPLE_USE )
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
    self:ManipulateBoneScale( 1, Vector( self.MechanicsSizeMod, 1, 1 ) )

    if self.AmmoType == "AAmissile" or self.AmmoType == "ATrocket" then
        self:ManipulateBoneScale( 4, Vector( .01, .01, .01 ) )
    end

    self:SetNWInt( "JackIndex", self:EntIndex() )
    self:SetDTBool( 0, self.HasAmmoBox )
    self:SetDTInt( 3, 0 )
    self.IFFTags = {}
end

function ENT:GetShootPos()
    return self:GetPos() + self:GetUp() * 55 + self:GetForward() * 5
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

    if dmginfo:IsDamageType( DMG_BUCKSHOT ) or dmginfo:IsDamageType( DMG_BULLET ) or dmginfo:IsDamageType( DMG_BLAST ) or dmginfo:IsDamageType( DMG_CLUB ) then
        self.StructuralIntegrity = self.StructuralIntegrity - dmginfo:GetDamage()

        if self.StructuralIntegrity <= 0 then
            self:Break()
        else
            if self:GetDTInt( 0 ) == TS_IDLING then
                self:Notice()
            end
        end
    end
end

function ENT:Use( activator )
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

    if not self.MenuOpen then
        local Tag = activator:GetNWInt( "JackyIFFTag" )
        self:EmitSound( "snd_jack_uisuccess.mp3", 65, 100 )
        self.MenuOpen = true

        umsg.Start( "JackaTurretOpenMenu", activator )
        umsg.Entity( self )
        umsg.Short( self.BatteryCharge )
        umsg.Short( self.RoundsOnBelt )
        umsg.Bool( table.HasValue( self.TargetingGroup, HULL_TINY ) )
        umsg.Bool( table.HasValue( self.TargetingGroup, HULL_TINY_CENTERED ) )
        umsg.Bool( table.HasValue( self.TargetingGroup, HULL_SMALL_CENTERED ) )
        umsg.Bool( table.HasValue( self.TargetingGroup, HULL_HUMAN ) )
        umsg.Bool( table.HasValue( self.TargetingGroup, HULL_WIDE_SHORT ) )
        umsg.Bool( table.HasValue( self.TargetingGroup, HULL_WIDE_HUMAN ) )
        umsg.Bool( table.HasValue( self.TargetingGroup, HULL_MEDIUM ) )
        umsg.Bool( table.HasValue( self.TargetingGroup, HULL_MEDIUM_TALL ) )
        umsg.Bool( table.HasValue( self.TargetingGroup, HULL_LARGE ) )
        umsg.Bool( table.HasValue( self.TargetingGroup, HULL_LARGE_CENTERED ) )
        umsg.Bool( self.TargetSynthetics )
        umsg.Bool( table.HasValue( self.IFFTags, Tag ) )
        umsg.Bool( self.WillWarn )
        umsg.Bool( self.TargetOrganics )
        umsg.Bool( self.WillLight )
        umsg.End()
    end
end

function ENT:Think()
    self.Heat = self.Heat - .01

    if self.Heat < 0 then
        self.Heat = 0
    elseif self.Heat >= 50 then
        if math.random( 1, 5 ) == 1 then
            local PosAng = self:GetAttachment( 1 )
            local Sss = EffectData()
            Sss:SetOrigin( PosAng.Pos + PosAng.Ang:Forward() * math.random( -7, 7 ) )
            Sss:SetScale( self.Heat / 50 )
            util.Effect( "eff_jack_gunoverheat", Sss, true, true )
        end
    end

    if self.Broken then
        self.BatteryCharge = 0
        self:SetDTInt( 2, 0 )

        if math.random( 1, 8 ) == 7 then
            local effectdata = EffectData()
            effectdata:SetOrigin( self:GetPos() + self:GetUp() * math.random( 30, 55 ) )
            effectdata:SetNormal( VectorRand() )
            effectdata:SetMagnitude( 3 ) --amount and shoot hardness
            effectdata:SetScale( 1 ) --length of strands
            effectdata:SetRadius( 3 ) --thickness of strands
            util.Effect( "Sparks", effectdata, true, true )
            self:EmitSound( "snd_jack_turretfizzle.mp3", 70, 100 )
        else
            local effectdata = EffectData()
            effectdata:SetOrigin( self:GetShootPos() )
            effectdata:SetScale( 1 )
            util.Effect( "eff_jack_tinyturretburn", effectdata, true, true )
        end

        return
    end

    local State = self:GetDTInt( 0 )
    if State == TS_NOTHING then return end
    if self.MenuOpen then return end
    local SelfPos = self:GetShootPos()
    local Time = CurTime()
    local WeAreClear = self:ClearHead()
    self:SetDTInt( 4, self.RoundsOnBelt )

    if self.BatteryCharge <= 0 then
        self:HardShutDown()

        return
    elseif self.BatteryCharge < self.MaxCharge * .2 then
        if self.NextBatteryAlertTime < Time then
            self:Whine()
            self.NextBatteryAlertTime = Time + 4.75
        end
    end

    if State ~= TS_WHINING and not WeAreClear then
        self:SetDTInt( 0, TS_WHINING )
        state = TS_WHINING
    end

    if State == TS_IDLING then
        if self.NextWatchTime < Time then
            for _, potential in pairs( ents.FindInSphere( SelfPos, self.MaxTrackRange ) ) do
                if GetEntityVolume( potential ) > 0 and self:MotionCheck( potential ) and self:CanSee( potential ) then
                    local TrueVec = ( SelfPos - potential:GetPos() ):GetNormalized()
                    local LookVec = self:GetForward()
                    local DotProduct = LookVec:Dot( TrueVec )
                    local ApproachAngle = -math.deg( math.asin( DotProduct ) ) + 90

                    if ApproachAngle > 90 then
                        self:Notice()
                    end
                end
            end
            self.BatteryCharge = self.BatteryCharge - .0025
            self.NextWatchTime = self.NextWatchTime + .1
        end
    elseif State == TS_WATCHING then
        if self.NextScanTime < Time then
            self.CurrentTarget = self:ScanForTarget()
            self.NextScanTime = Time + 1 / self.ScanRate

            if IsValid( self.CurrentTarget ) then
                self:Alert( self.CurrentTarget )
            end
        elseif self.NextGoSilentTime < Time then
            self:StandDown()
        end

        self.BatteryCharge = self.BatteryCharge - .05
    elseif State == TS_CONCENTRATING then
        if self.NextScanTime < Time then
            self.CurrentTarget = self:ScanForTarget()
            self.NextScanTime = Time + ( 1 / self.ScanRate ) / 4

            if IsValid( self.CurrentTarget ) then
                self:Alert( self.CurrentTarget )
            end
        elseif self.NextGoSilentTime < Time then
            self:StandDown()
        end

        self.BatteryCharge = self.BatteryCharge - .025
    elseif State == TS_TRACKING then
        if not IsValid( self.CurrentTarget ) then
            self:SetDTInt( 0, TS_CONCENTRATING )
            self.NextGoSilentTime = Time + 2
        else
            if self:CanSee( self.CurrentTarget ) then
                local TargPos = GetCenterMass( self.CurrentTarget )
                local Ang = ( TargPos - SelfPos ):GetNormalized():Angle()
                local TargAng = self:WorldToLocalAngles( Ang )
                local ProperSweep = TargAng.y
                local ProperSwing = TargAng.p

                if TargAng.y > -90 and TargAng.y < 90 and TargAng.p > -90 and TargAng.p < 90 then
                    self.GoalSweep = ProperSweep
                    self.GoalSwing = ProperSwing
                else
                    self.CurrentTarget = self:ScanForTarget()
                end

                if self.NextScanTime < Time then
                    self.CurrentTarget = self:ScanForTarget()

                    if not IsValid( self.CurrentTarget ) then
                        self:StandDown()
                    end

                    self.NextScanTime = Time + 1 / self.ScanRate * 2
                end

                if self.CurrentSweep < self.GoalSweep + 2 and self.CurrentSweep > self.GoalSweep - 2 and self.CurrentSwing < self.GoalSwing + 2 and self.CurrentSwing > self.GoalSwing - 2 then
                    if self.NextShotTime < Time then
                        self:FireShot()
                        self.NextShotTime = Time + 1 / self.FireRate * math.Rand( .9, 1.1 )
                    end
                end
            else
                self:HoldFire()
            end
        end
    elseif State == TS_WHINING then
        if WeAreClear then
            self:SetDTInt( 0, TS_IDLING )
            self.GoalSweep = 0
            self.GoalSwing = 0
        else
            if self.NextWhineTime < Time then
                self:Whine()
                self.NextWhineTime = Time + .85

                if math.random( 1, 5 ) == 4 then
                    self:HardShutDown()
                end
            end
        end
    elseif State == TS_ASLEEPING then
        if self.CurrentSweep <= 2 and self.CurrentSwing <= 2 then
            self:StandBy()
        else
            if self.NextScanTime < Time then
                self:SetDTInt( 0, TS_WATCHING )
                self.NextScanTime = Time + 1 / self.TrackRate * 1.5
            end
        end
    end

    self:SetDTInt( 2, math.Round( self.BatteryCharge / self.MaxCharge * 100 ) )
    self:Traverse()
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

        for i = 0, 20 do
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

local function IsBetterCanidate( turret, ent, shootPos, turretPos, closestCanidate )
    if turret == ent then return end
    if ent:IsWorld() then return end
    if not turret:CanSee( ent ) then return end

    local size = GetEntityVolume( ent )
    if size <= 0 then return end
    if not turret:WillTargetThisSize( size ) then return end

    local synthetic = IsSynthetic( ent )

    if not ( synthetic and turret.TargetSynthetics or not synthethic and turret.TargetOrganics ) then return end

    local targetPos = ent:GetPos()
    local ang = ( targetPos - shootPos ):GetNormalized():Angle()

    local distance = ( targetPos - turretPos ):Length()
    if distance > closestCanidate then return end

    local targetAngle = turret:WorldToLocalAngles( ang )

    if targetAngle.y <= -90 then return end
    if targetAngle.y >= 90 then return end
    if targetAngle.p <= -90 then return end
    if targetAngle.p >= 90 then return end


    if synthetic and turret:MotionCheck( ent ) then
        return ent, distance
    end

    if ent:IsPlayer() then
        local tag = ent:GetNWInt( "JackyIFFTag" )

        if tag and tag ~= 0 then
            if table.HasValue( turret.IFFTags, tag ) then
                if math.random( 1, 3 ) == 2 then
                    turret:FriendlyAlert()
                end
            else
                return ent, distance
            end
        else
            return ent, distance
        end
    end

    return ent, distance
end

function ENT:ScanForTarget()
    local shootPos = self:GetShootPos()
    local closestCanidate = self.MaxTrackRange
    local turretPos = self:GetPos()
    local bestTarget = nil

    for _, potential in pairs( ents.FindInSphere( turretPos, self.MaxTrackRange ) ) do
        local betterCanidate, canidateDistance = IsBetterCanidate( self, potential, shootPos, turretPos, closestCanidate )
        if betterCanidate then
            bestTarget = betterCanidate
            closestCanidate = canidateDistance
        end
    end

    self.BatteryCharge = self.BatteryCharge - self.MaxTrackRange / 2000

    if bestTarget then
        if bestTarget == self.CurrentTarget and self.FiredAtCurrentTarget and not self:MotionCheck( bestTarget ) then
            return nil
        elseif bestTarget ~= self.CurrentTarget then
            self.FiredAtCurrentTarget = false
        end
    end

    return bestTarget
end

function ENT:MotionCheck( ent )
    local velocity = ent:GetVelocity()
    local turretPhys = self:GetPhysicsObject()
    local relativeSpeed = ( turretPhys:GetVelocity() - velocity ):Length()

    return relativeSpeed > 20
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
    self:EmitSound( "snd_jack_turretdetect.mp3", 90, 100 )
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

        self.NextAlrightFuckYouTime = CurTime() + 5
        self.BatteryCharge = self.BatteryCharge - .5 * self.MechanicsSizeMod

        if self.WillLight then
            self.flashlight = ents.Create( "env_projectedtexture" )
            self.flashlight:SetParent( self )
            -- The local positions are the offsets from parent..
            self.flashlight:SetLocalPos( Vector( 0, 0, 50 ) )
            self.flashlight:SetLocalAngles( Angle( 0, 0, 0 ) )
            -- Looks like only one flashlight can have shadows enabled!
            self.flashlight:SetKeyValue( "enableshadows", 1 )
            self.flashlight:SetKeyValue( "farz", 1500 )
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

function ENT:Traverse()
    local PowerDrain = .2 * self.TrackRate * self.MechanicsSizeMod ^ 1.5

    if self.CurrentSweep > self.GoalSweep + 2 then
        self.CurrentSweep = self.CurrentSweep - self.TrackRate
        self:EmitSound( "snd_jack_turretservo.mp3", 66, 90 )
        self.BatteryCharge = self.BatteryCharge - PowerDrain
    elseif self.CurrentSweep < self.GoalSweep - 2 then
        self.CurrentSweep = self.CurrentSweep + self.TrackRate
        self:EmitSound( "snd_jack_turretservo.mp3", 66, 90 )
        self.BatteryCharge = self.BatteryCharge - PowerDrain
    end

    if self.CurrentSwing > self.GoalSwing + 2 then
        self.CurrentSwing = self.CurrentSwing - self.TrackRate * .6667
        self:EmitSound( "snd_jack_turretservo.mp3", 66, 110 )
        self.BatteryCharge = self.BatteryCharge - PowerDrain
    elseif self.CurrentSwing < self.GoalSwing - 2 then
        self.CurrentSwing = self.CurrentSwing + self.TrackRate * .6667
        self:EmitSound( "snd_jack_turretservo.mp3", 66, 110 )
        self.BatteryCharge = self.BatteryCharge - PowerDrain
    end

    if self:GetNWFloat( "CurrentSweep" ) ~= self.CurrentSweep then
        self:SetNWFloat( "CurrentSweep", self.CurrentSweep )
    end

    if self:GetNWFloat( "CurrentSwing" ) ~= self.CurrentSwing then
        self:SetNWFloat( "CurrentSwing", self.CurrentSwing )
    end

    if IsValid( self.flashlight ) then
        self.flashlight:SetLocalAngles( self:WorldToLocalAngles( self:GetAttachment( 1 ).Ang ) )
    end
end

function ENT:FireShot()
    self:StandBy()

    local Time = CurTime()
    self.BatteryCharge = self.BatteryCharge - .1

    if self.WillWarn and self.NextAlrightFuckYouTime >= Time then
        if self.NextWarnTime < Time then
            self:HostileAlert()
            self.NextWarnTime = Time + 1
        end

        return
    end

    if self.RoundInChamber then
        if self.Heat >= 95 then
            if self.NextOverHeatWhineTime < Time then
                self.NextOverHeatWhineTime = Time + .5
                self:Whine()
            end

            return
        end

        local PosAng = self:GetAttachment( 1 )
        local muzzleFlash = EffectData()
        muzzleFlash:SetStart( PosAng.Pos + PosAng.Ang:Forward() * self.BarrelSizeMod.z * 4 )
        muzzleFlash:SetAngles( PosAng.Ang )
        muzzleFlash:SetFlags( 1 )
        util.Effect( "MuzzleFlash", muzzleFlash, true, true )
        self:SetNWVector( "BarrelSizeMod", Vector( self.BarrelSizeMod.x, self.BarrelSizeMod.y, self.BarrelSizeMod.z * .75 ) )

        timer.Simple( .1, function()
            if IsValid( self ) then
                self:SetNWVector( "BarrelSizeMod", self.BarrelSizeMod )
            end
        end )

        local SelfPos = self:GetShootPos()
        local TargPos = GetCenterMass( self.CurrentTarget )

        local Dir = ( TargPos - SelfPos ):GetNormalized()
        local Spred = self.ShotSpread
        local Phys = self.CurrentTarget:GetPhysicsObject()

        if IsValid( Phys ) then
            local RelSpeed = ( Phys:GetVelocity() - self:GetPhysicsObject():GetVelocity() ):Length()

            if self:GetClass() ~= "ent_jack_turret_shotty" then
                Spred = Spred + RelSpeed / 100000
            end
        end

        local Bellit = {
            Attacker = self,
            Damage = self.ShotPower,
            Force = self.ShotPower / 60,
            Num = self.ProjectilesPerShot,
            Tracer = 0,
            Dir = Dir,
            Spread = Vector( Spred, Spred, Spred ),
            Src = SelfPos
        }

        self:FireBullets( Bellit )
        self.FiredAtCurrentTarget = true
        self.RoundInChamber = false
        self.Heat = self.Heat + ( self.ShotPower * self.ProjectilesPerShot ) / 150

        for _ = 0, 1 do
            self:EmitSound( self.NearShotNoise, 75, self.ShotPitch )
            self:EmitSound( self.FarShotNoise, 90, self.ShotPitch - 10 )
            sound.Play( self.NearShotNoise, SelfPos, 75, self.ShotPitch )
            sound.Play( self.FarShotNoise, SelfPos + Vector( 0, 0, 1 ), 90, self.ShotPitch - 10 )

            if self:GetClass() ~= "ent_jack_turret_plinker" then
                sound.Play( self.NearShotNoise, SelfPos, 75, self.ShotPitch )
                sound.Play( self.FarShotNoise, SelfPos + Vector( 0, 0, 1 ), 110, self.ShotPitch - 10 )
            else
                Scayul = .5
            end

            if self.AmmoType == "7.62x51mm" or self.AmmoType == ".338 Lapua Magnum" then
                sound.Play( self.NearShotNoise, SelfPos + Vector( 0, 0, 1 ), 75, self.ShotPitch + 10 )

                if self:GetClass() ~= "ent_jack_turret_mg" then
                    sound.Play( self.FarShotNoise, SelfPos + Vector( 0, 0, 2 ), 100, self.ShotPitch )
                end

                Scayul = 1.5
            end

            if self.AmmoType == ".338 Lapua Magnum" then
                sound.Play( self.NearShotNoise, SelfPos + Vector( 0, 0, 3 ), 75, self.ShotPitch + 10 )
                sound.Play( self.FarShotNoise, SelfPos + Vector( 0, 0, 4 ), 100, self.ShotPitch + 5 )
                Scayul = 2.5
            end
        end

        if self.RoundsOnBelt > 0 then
            if self.Autoloading then
                self.RoundsOnBelt = self.RoundsOnBelt - 1
                self.RoundInChamber = true
                local effectdata = EffectData()
                effectdata:SetOrigin( SelfPos )
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
                        effectdata:SetOrigin( SelfPos )
                        effectdata:SetAngles( Dir:Angle():Right():Angle() )
                        effectdata:SetEntity( self )
                        util.Effect( self.ShellEffect, effectdata, true, true )
                    end
                end )
            end
        end

        self:GetPhysicsObject():ApplyForceOffset( -Dir * self.ShotPower * 6 * self.ProjectilesPerShot, SelfPos + self:GetUp() * 30 )
    else
        self:EmitSound( "snd_jack_turretclick.mp3", 70, 110 )

        if self.NextWhineTime < CurTime() then
            self:Whine()
            self.NextWhineTime = CurTime() + 2.25
        end
    end
end

function ENT:Whine()
    self:EmitSound( "snd_jack_turretwhine.mp3", 80, 100 )
    self.BatteryCharge = self.BatteryCharge - .05
end

function ENT:StandBy()
    self:SetDTInt( 0, TS_IDLING )

    if self.WeaponOut then
        self:ResetSequence( 0 )

        if not ( self.AmmoType == "AAmissile" or self.AmmoType == "ATrocket" ) then
            self:EmitSound( "snd_jack_turretasleep.mp3", 70, 100 )
        end

        self.WeaponOut = false
        self.BatteryCharge = self.BatteryCharge - .5 * self.MechanicsSizeMod
        SafeRemoveEntity( self.flashlight )
        self:SetDTBool( 3, false )
    end
end

function ENT:CanSee( ent )
    local traceTable = {
        start = self:GetShootPos(),
        endpos = ent:WorldSpaceCenter(),
        filter = { self, ent },
        mask = MASK_SHOT
    }

    local traceResult = util.TraceLine( traceTable )

    return not traceResult.Hit
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
    self.BatteryCharge = self.MaxCharge
    self:SetDTInt( 2, math.Round( self.BatteryCharge / self.MaxCharge * 100 ) )
    SafeRemoveEntity( box )
    self:SetDTBool( 3, false )
    self:EmitSound( "snd_jack_turretbatteryload.mp3" )
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
    if not self.Broken then
        self:EmitSound( "snd_jack_turretbreak.mp3" )
        self.Broken = true
        self:SetDTInt( 0, TS_NOTHING )
        self.IsLocked = false
        self.LockPass = ""
        self.CurrentTarget = nil

        SafeRemoveEntity( self.flashlight )
        self:SetDTBool( 3, false )
    end
end

function ENT:Fix( kit )
    self.StructuralIntegrity = 400
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

hook.Add( "PlayerSay", "JackaSentryChat", SentryChat )

local function CloseOn( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )
    turret:EmitSound( "snd_jack_uiselect.mp3", 65, 100 )
    turret.MenuOpen = false

    if turret:GetDTInt( 0 ) == TS_NOTHING and turret.StartUp then
        turret:StartUp()
        JID.genericUseEffect( args[1] )
    end
end

concommand.Add( "JackaTurretCloseMenu_On", CloseOn )

local function CloseOff( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )
    turret:EmitSound( "snd_jack_uiselect.mp3", 65, 100 )
    turret.MenuOpen = false

    if turret:GetDTInt( 0 ) ~= TS_NOTHING then
        turret:HardShutDown()
        JID.genericUseEffect( args[1] )
    end
end

concommand.Add( "JackaTurretCloseMenu_Off", CloseOff )

local function CloseCancel( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )
    turret:EmitSound( "snd_jack_uiselect.mp3", 65, 100 )
    turret.MenuOpen = false
end

concommand.Add( "JackaTurretCloseMenu_Cancel", CloseCancel )

local function Ammo( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )

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

        if turret.RoundsOnBelt <= 0 then
            if not turret.HasAmmoBox then
                local Box = turret:FindAmmo()

                if IsValid( Box ) then
                    turret:RefillAmmo( Box )
                    JID.genericUseEffect( args[1] )
                else
                    args[1]:PrintMessage( HUD_PRINTCENTER, "No ammunition present." )
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

concommand.Add( "JackaTurretAmmo", Ammo )

local function TargetingGroup( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )
    local Check = tobool( args[3][3] )
    local Num = tonumber( args[3][2] )

    if Check then
        table.ForceInsert( turret.TargetingGroup, Num )
    else
        table.remove( turret.TargetingGroup, table.KeyFromValue( turret.TargetingGroup, Num ) )
    end

    turret:EmitSound( "snd_jack_uiselect.mp3", 65, 100 )
end

concommand.Add( "JackaTurretTargetingChange", TargetingGroup )

local function TargetingGroupType( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )
    local Check = tobool( args[3][3] )
    local Type = args[3][2]
    turret[Type] = Check
    turret:EmitSound( "snd_jack_uiselect.mp3", 65, 100 )
end

concommand.Add( "JackaTurretTargetingTypeChange", TargetingGroupType )

local function IFFTag( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )
    local ply = args[1]
    turret:EmitSound( "snd_jack_uiselect.mp3", 65, 100 )
    turret.MenuOpen = false
    local Tag = ply:GetNWInt( "JackyIFFTag" )

    if Tag and Tag ~= 0 then
        if not table.HasValue( turret.IFFTags, Tag ) then
            if Tag ~= 0 then
                table.ForceInsert( turret.IFFTags, Tag )
            end

            ply:PrintMessage( HUD_PRINTTALK, "Personal IFF tag ID recorded." )
        else
            table.remove( turret.IFFTags, table.KeyFromValue( turret.IFFTags, Tag ) )
            ply:PrintMessage( HUD_PRINTTALK, "Personal IFF tag ID forgotten." )
        end
    else
        ply:PrintMessage( HUD_PRINTCENTER, "You don't have an IFF tag equipped." )
    end
end

concommand.Add( "JackaTurretIFF", IFFTag )

local function Warn( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )
    local Check = tobool( args[3][2] )
    turret.WillWarn = Check
    turret:EmitSound( "snd_jack_uiselect.mp3", 65, 100 )
end

concommand.Add( "JackaTurretWarn", Warn )

local function Light( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )
    local Check = tobool( args[3][2] )
    turret.WillLight = Check
    turret:EmitSound( "snd_jack_uiselect.mp3", 65, 100 )
end

concommand.Add( "JackaTurretLight", Light )

local function Battery( ... )
    local args = { ... }

    local turret = Entity( tonumber( args[3][1] ) )

    if not turret.BatteryCharge then
        turret.BatteryCharge = 0
    end

    if turret.BatteryCharge <= 0 then
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

concommand.Add( "JackaTurretBattery", Battery )

local function Upright( ... )
    local args = { ... }

    local ply = args[1]
    local turret = Entity( tonumber( args[3][1] ) )
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

concommand.Add( "JackaTurretUpright", Upright )
