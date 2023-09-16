AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:SpawnFunction( spawner, _ )

    local maxDist = 150
    local trStruc = {
        start = spawner:GetShootPos(),
        endpos = spawner:GetShootPos() + spawner:GetAimVector() * maxDist,
        filter = spawner

    }

    local tr = util.TraceLine( trStruc )

    local SpawnPos = tr.HitPos + tr.HitNormal * 10
    local ent = ents.Create( "ent_jack_barbedwirekit" )
    ent:SetAngles( Angle( 0, spawner:GetAimVector():Angle().y, 0 ) )
    ent:SetPos( SpawnPos )
    ent:Spawn()
    ent:Activate()
    local effectdata = EffectData()
    effectdata:SetEntity( ent )
    util.Effect( "propspawn", effectdata )

    ent:SetCreator( spawner )

    return ent
end

function ENT:Initialize()
    self:SetModel( "models/props_junk/cardboard_box001a.mdl" )
    self:SetMaterial( "models/mat_jack_barbedwirekit" )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:DrawShadow( true )
    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
        phys:SetMass( 30 )

    end

    self:SetUseType( SIMPLE_USE )

end

function ENT:PhysicsCollide( data, _ )
    if data.Speed > 80 and data.DeltaTime > .2 then
        self:EmitSound( "Cardboard.ImpactHard" )
        self:EmitSound( "ChainLink.ImpactHard" )
    end
end

function ENT:OnTakeDamage( dmginfo )
    self:TakePhysicsDamage( dmginfo )
    if not self:DoBarbedWire() then self:EmptyOut() end

end

function ENT:Use( user )
    if not JID.CanBeUsed( user, self ) then return end
    if not self:DoBarbedWire() then user:PickupObject( self ) end

end

local maxs = Vector( 30, 30, 1 )
local mins = -maxs

function ENT:DoBarbedWire()
    local toSpawnPositions = {}
    local myPos = self:GetPos()
    local right = self:GetRight()

    local trace1 = {
        start = self:GetPos(),
        endpos = myPos + right * 120,
        maxs = maxs,
        mins = mins,
        filter = { self, self:GetCreator() }

    }
    local trace2 = table.Copy( trace1 )

    -- we already have the table there!
    trace2.endpos = myPos + -right * 120

    toSpawnPositions[1] = self:GetPos()

    local result1 = util.TraceHull( trace1 )
    if result1.Fraction > .5 then
        toSpawnPositions[2] = result1.HitPos

    end
    local result2 = util.TraceHull( trace2 )
    if result2.Fraction > .5 then
        toSpawnPositions[3] = result2.HitPos

    end

    -- pairs because some indexes will be nil

    local potentialConflictors = ents.FindByClass( "ent_jack_barbedwire" )
    local minDistSqr = 68^2

    local barbs = {}
    local creator = self:GetCreator()

    for _, pos in pairs( toSpawnPositions ) do
        if pos then
            local bad = nil
            for _, conflictor in ipairs( potentialConflictors ) do
                if conflictor:GetPos():DistToSqr( pos ) < minDistSqr then bad = true break end
            end

            if JID.IsOverLimit( creator, "ent_jack_barbedwire" ) == false then bad = true break end

            if bad then continue end

            local barbed = ents.Create( "ent_jack_barbedwire" )
            barbed:SetPos( pos )
            local snappedYaw = ( math.random( 1, 4 ) * 90 ) - 180
            barbed:SetAngles( Angle( math.random( -5, 5 ), snappedYaw, math.random( -5, 5 ) ) )
            barbed:Spawn()

            JID.RegisterEntSpawn( creator, barbed )

            table.insert( barbs, barbed )
            barbed:SetCreator( creator )

        end
    end

    if #barbs <= 0 then return end

    undo.Create( "Barbed Wire" )
        for _, barbed in ipairs( barbs ) do
            undo.AddEntity( barbed )

        end
        undo.SetPlayer( creator )
    undo.Finish()

    for _, barbed in ipairs( barbs ) do
        cleanup.Add( creator, "Barbed Wire", barbed )

    end

    self:EmptyOut()

    return true

end

function ENT:EmptyOut()
    local Empty = ents.Create( "prop_ragdoll" )
    Empty:SetModel( "models/props_junk/cardboard_box001a_gib01.mdl" )
    Empty:SetMaterial( "models/mat_jack_barbedwirekit" )
    Empty:SetPos( self:GetPos() )
    Empty:SetAngles( self:GetAngles() )
    Empty:Spawn()
    Empty:Activate()
    Empty:SetCollisionGroup( COLLISION_GROUP_WEAPON )
    Empty:GetPhysicsObject():ApplyForceCenter( Vector( 0, 0, 1000 ) )
    Empty:GetPhysicsObject():AddAngleVelocity( VectorRand() * 1000 )

    SafeRemoveEntityDelayed( Empty, 10 )
    SafeRemoveEntity( self )

end