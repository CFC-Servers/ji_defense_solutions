AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
ENT.PlugPosition = Vector( 0, 0, 0 )

local fuelsEntsTable = {
    ["ent_jack_aidfuel_gasoline"] = true,
    ["ent_jack_aidfuel_kerosene"] = true,
    ["ent_jack_aidfuel_propane"] = true,
}

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 16
    local ent = ents.Create( "ent_jack_generator" )
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
    self:SetModel( "models/props_outland/generator_static01a.mdl" )
    self:SetMaterial( "models/props_silo/generator_jtatic01.mdl" )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:DrawShadow( true )
    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
        phys:SetMass( 750 )
    end

    self:SetUseType( SIMPLE_USE )
    self.Remaining = 0
    self.NextUseTime = 0
    self.NextSoundTime = 0
    self.IsRunning = false
    self.Dependents = {}
    self.Connections = {}
    self.FuelTank = nil
    self.NextWorkTime = 0
    self:SetDTBool( 0, self.IsRunning )
    self:SetColor( Color( 150, 150, 150 ) )
end

function ENT:PhysicsCollide( data )
    if data.Speed > 80 and data.DeltaTime > 0.2 then
        self:EmitSound( "SolidMetal.ImpactHard" )
    end

    if data.HitEntity:IsWorld() then return end
    if data.HitEntity.Generator == self then return end
    if data.HitEntity:GetClass() ~= "ent_jack_powernode" and not data.HitEntity.ExternalCharge and not data.HitEntity.HasBattery then return end
    if table.HasValue( self.Dependents, data.HitEntity ) then return end

    table.insert( self.Dependents, data.HitEntity )

    if data.HitEntity:GetClass() == "ent_jack_powernode" then
        data.HitEntity.Generator = self
    end

    timer.Simple( 0.01, function()
        if not IsValid( self ) or not IsValid( data.HitEntity ) then return end
        if data.HitEntity.PlugPosition then
            local Cable = constraint.Rope( self, data.HitEntity, 0, 0, Vector( 0, 0, 0 ), data.HitEntity.PlugPosition, 1, 499, 1500, 2, "cable/cable2", false )
            self.Connections[data.HitEntity] = Cable

            if data.HitEntity:GetClass() == "ent_jack_powernode" then
                data.HitEntity.GeneratorConn = Cable
            end
        elseif self.IsRunning then
            if data.HitEntity.BatteryCharge < data.HitEntity.BatteryMaxCharge then
                data.HitEntity:ExternalCharge( 1000 )
                local effectdata = EffectData()
                effectdata:SetOrigin( data.HitEntity:GetPos() )
                effectdata:SetNormal( VectorRand() )
                effectdata:SetMagnitude( 1 ) --amount and shoot hardness
                effectdata:SetScale( 1 ) --length of strands
                effectdata:SetRadius( 1 ) --thickness of strands
                util.Effect( "Sparks", effectdata, true, true )
                data.HitEntity:EmitSound( "snd_jack_niceding.mp3" )
                self.Remaining = self.Remaining - 1
            end
        end
    end )
end

function ENT:OnTakeDamage( dmginfo )
    self:TakePhysicsDamage( dmginfo )
end

function ENT:Use( activator )
    if activator:IsPlayer() then
        if self.NextUseTime > CurTime() then return end

        if not self.IsRunning then
            self:Start()
        elseif self.IsRunning then
            self:ShutOff()
            self.NextUseTime = CurTime() + 10
        end
    end
end

function ENT:Start()
    if self.Remaining > 0 then
        self:EmitSound( "snd_jack_genstart.mp3" )
        self.IsRunning = true
        self:SetDTBool( 0, self.IsRunning )
        self.NextSoundTime = CurTime() + 8
        self.NextUseTime = CurTime() + 10
        self.NextWorkTime = CurTime() + 10
    else
        self:Refuel()
    end
end

function ENT:ShutOff()
    self:EmitSound( "snd_jack_genstop.mp3" )
    self.IsRunning = false
    self:SetDTBool( 0, self.IsRunning )
end

function ENT:Think()
    if not self.IsRunning then return end
    local time = CurTime()

    if not IsValid( self.FuelTank ) then
        self.FuelTank = nil
        self.Remaining = 0
    end

    if self.Remaining <= 0 then
        if IsValid( self.FuelTank ) then
            self.FuelTank:Remove()
        end

        self.FuelTank = nil
        self.Remaining = 0
        self:ShutOff()

        return
    end

    if self.NextWorkTime < time then
        self.NextWorkTime = time + 1

        for _, ent in pairs( self.Dependents ) do
            if IsValid( ent ) and IsValid( self.Connections[ent] ) and ent.HasBattery then
                ent:ExternalCharge( 100 )
            else
                if IsValid( self.Connections[ent] ) then
                    self.Connections[ent]:Remove()
                end

                if self.Connections[ent] then
                    self.Connections[ent] = nil
                end

                table.RemoveByValue( self.Dependents, ent )
            end
        end

        self.Remaining = self.Remaining - 1
    end

    if self.NextSoundTime < CurTime() then
        self.NextSoundTime = CurTime() + 3.5
        self:EmitSound( "snd_jack_genrun.mp3" )
    end

    if self:WaterLevel() > 0 then
        self:ShutOff()
    end

    self:GetPhysicsObject():ApplyForceCenter( VectorRand() * 1500 )
    self:NextThink( time + .1 )

    return true
end

function ENT:Refuel()
    for _, found in pairs( ents.FindInSphere( self:GetPos(), 125 ) ) do
        if fuelsEntsTable[found:GetClass()] and not found.Burning then
            self:FuelWith( found )
        end
    end
end

function ENT:FuelWith( ent )
    self.Remaining = 700

    self.FuelTank = ent
    ent:SetPos( self:GetPos() + self:GetUp() * 68 - self:GetForward() * 15 )

    local Ang = self:GetAngles()
    Ang:RotateAroundAxis( Ang:Right(), -90 )
    ent:SetAngles( Ang )
    ent:SetParent( self )
    ent:SetNotSolid( true )

    self:EmitSound( "snd_jack_metallicload.mp3" )
end
