AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )


ENT.SpeedLimit = 110
ENT.SpeedLimitSqr = ENT.SpeedLimit^2
ENT.Mass = 30
ENT.ACF_DamageMult = 0

ENT.nextTouchThink = ENT.nextTouchThink or math.huge -- prevents it doing 1 tick of damage before initialize
ENT.nextDeconstruct = 0

function ENT:Initialize()
    self:SetModel( "models/hunter/plates/plate075x075.mdl" )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetCollisionGroup( COLLISION_GROUP_WORLD )
    self:DrawShadow( false )

    local phys = self:GetPhysicsObject()

    self:SetTrigger( true )
    self:UseTriggerBounds( true, 50 )

    if phys:IsValid() then
        phys:SetMaterial( "chainlink" )
        phys:EnableMotion( false )
        phys:SetMass( self.Mass )

    end

    self.nextTouchThink = CurTime() + self.growDuration

    self:SetNW2Int( "structuralIntegrity", self.StructuralIntegrity )

    self:SetUseType( CONTINUOUS_USE )

    timer.Simple( 0, function()
        if not IsValid( self ) then return end
        self:DropToFloor()
        -- needed to do this to make sure :React's angle changes were networked (i think?)
        self:SetPos( self:GetPos() + vector_up * 5 )

    end )
end

function ENT:Use( user )
    if self.nextDeconstruct > CurTime() then return end
    if not JID.CanBeUsed( user, self ) then return end
    -- have to stop and focus on this!
    if user:GetVelocity():LengthSqr() > 100 then return end
    self.nextDeconstruct = CurTime() + math.Rand( .25, .35 )
    self:TakeStructuralDamage( 50 )
    self:Damage( user, 1 )

end

local damagingMaterials = {
    ["flesh"] = true,
    ["player"] = true,
    ["$MATERIAL_INDEX_SHADOw"] = true, -- simfphys tire
    ["rubber"] = true,
    ["jeeptire"] = true,
    ["friction_00"] = true, -- also simfphys tire?

}

function ENT:TakeStructuralDamage( dmg, silent )
    if silent ~= true then
        self:React( dmg )

    end
    self.StructuralIntegrity = self.StructuralIntegrity + -dmg
    self:SetNW2Int( "structuralIntegrity", math.Round( self.StructuralIntegrity ) )

    if self.StructuralIntegrity < 0 then SafeRemoveEntity( self ) end

end

function ENT:React( scale )
    self:EmitSound( "physics/metal/metal_chainlink_impact_soft3.wav", 75, math.random( 120, 130 ) + -scale, .5 )

    self.originalAngles = self.originalAngles or self:GetAngles()
    self:SetAngles( self.originalAngles + AngleRand() * .03 )

end

function ENT:Touch( toucher )
    if self.nextTouchThink > CurTime() then return end
    self.nextTouchThink = CurTime() + .08

    if not JID.CanTarget( self, toucher ) then return end

    local obj = toucher:GetPhysicsObject()
    if not IsValid( obj ) then return end

    local vel = nil
    -- ply
    if not toucher:IsNPC() then
        vel = toucher:GetVelocity()

    else
        -- npc probably
        if toucher.GetIdealMoveSpeed then
            local moveSpeed = toucher:GetIdealMoveSpeed()
            vel = Vector( moveSpeed, moveSpeed, moveSpeed )

            --- npcs make everything easier....
            local justNormalVelocity = toucher:GetVelocity()

            -- getvelocity works on this, eg manhack, rollermine
            if vel:LengthSqr() < justNormalVelocity:LengthSqr() then
                vel = justNormalVelocity

            end

        else
            -- physics thing
            vel = toucher:GetVelocity()

        end
    end
    local speedSqr = vel:LengthSqr()
    local theirMass = obj:GetMass() or 100

    if speedSqr < self.SpeedLimitSqr then return end

    local speed = math.sqrt( speedSqr )

    local howMuchAboveLimit = self.SpeedLimit - speed
    howMuchAboveLimit = math.Clamp( howMuchAboveLimit, -50, 0 )
    howMuchAboveLimit = math.abs( howMuchAboveLimit )

    local objsMaterial = obj:GetMaterial()
    if howMuchAboveLimit < 0 then return end
    if damagingMaterials[ objsMaterial ] or toucher:IsNPC() then
        -- if thing is above limit, then 'punish' a bit extra
        local aboveLimitScaled = howMuchAboveLimit * 1.5

        self.nextTouchThink = CurTime() + .15
        local damage = aboveLimitScaled / 25

        self:Damage( toucher, damage )

        self:TakeStructuralDamage( .5 )

        if toucher:IsPlayer() or toucher:IsNPC() then
            toucher:SetVelocity( -vel:GetNormalized() * aboveLimitScaled * 2.5 )

        elseif IsValid( obj ) then
            obj:ApplyForceCenter( -vel:GetNormalized() * aboveLimitScaled * self.Mass )

        end
    elseif theirMass >= self.Mass then -- big prop!
        self.nextTouchThink = CurTime() + .15
        local structuralDamage = 0
        -- physics gun pickup makes mass MASSIVE
        if toucher:IsPlayerHolding() then
            structuralDamage = .5

        else
            structuralDamage = theirMass / self.Mass -- get a big number
            structuralDamage = math.Round( structuralDamage / 10 ) -- divide by magic num
            structuralDamage = math.max( structuralDamage + -5, 0 ) -- chop off the bottom, so smaller ish stuff does no damage

        end
        obj:ApplyForceCenter( ( -vel ):GetNormalized() * howMuchAboveLimit * self.Mass )
        self:TakeStructuralDamage( structuralDamage )

    end
end

function ENT:Damage( toDamage, damage )
    local dmgInfo = DamageInfo()
    dmgInfo:SetDamage( damage )
    dmgInfo:SetDamageForce( vector_origin )
    dmgInfo:SetDamageType( DMG_SLASH )
    dmgInfo:SetAttacker( JID.DetermineAttacker( self ) )
    dmgInfo:SetInflictor( self )

    toDamage:TakeDamageInfo( dmgInfo )
end

-- decay over time
function ENT:Think()
    self:TakeStructuralDamage( 1, true )
    local time = math.Rand( 14, 16 ) -- dont decay all at once
    self:NextThink( CurTime() + time )

    return true

end