include( "shared.lua" )

ENT.trueMadeProgress = 0

function ENT:Draw()
    self:DrawModel()
end

language.Add( "ent_jack_barbedwire", "J.I. Barbed Wire" )

local finalBarbScale = Vector( 3.5, 5.5, 3 )

function ENT:Initialize()
    self.WiresScaleMatrix = Matrix()
    self:DoBarbedWires()

    self:CallOnRemove( "deletemodels", function()
        SafeRemoveEntity( self.Wires1 )
        SafeRemoveEntity( self.Wires2 )

    end )

    self.FullyMadeTime = CurTime() + self.growDuration

end

function ENT:DoBarbedWires()
    if not IsValid( self.Wires1 ) then
        self.Wires1 = ClientsideModel( "models/bf1/barbed_wire_destroyed02.mdl" )
        self.Wires1:SetPos( self:GetPos() )
        self.Wires1:SetAngles( self:GetForward():Angle() )
        self.Wires1:SetParent( self )

    end

    if not IsValid( self.Wires2 ) then
        self.Wires2 = ClientsideModel( "models/bf1/barbed_wire_destroyed02.mdl" )
        self.Wires2:SetAngles( self:GetRight():Angle() )
        self.Wires2:SetPos( self:GetPos() )
        self.Wires2:SetParent( self )

    end
    self.Wires = { self.Wires1, self.Wires2 }

    -- reparent if we re-enter pvs
    for _, wire in ipairs( self.Wires ) do
        if wire:GetParent() == self then continue end
        wire:SetPos( self:GetPos() )
        wire:SetParent( self )

    end

end

function ENT:DoScaling( scale )
    self.WiresScaleMatrix:SetScale( scale )
    self.Wires1:EnableMatrix( "RenderMultiply", self.WiresScaleMatrix )
    self.Wires2:EnableMatrix( "RenderMultiply", self.WiresScaleMatrix )

end

-- draw nuthin!
function ENT:Draw()
end

function ENT:Think()

    -- according to wiki, barbs will remove themselves sometimes
    -- invisible damage dealers, not good!
    self:DoBarbedWires()

    local integrityLatest = self:GetNW2Int( "structuralIntegrity" )

    local growDuration = self.growDuration

    local timeToFullyMade = CurTime() - self.FullyMadeTime
    timeToFullyMade = math.Clamp( timeToFullyMade, -growDuration, 0 )
    local timeToFullyMadeReversed = ( timeToFullyMade + growDuration )

    local madeProgress = math.abs( timeToFullyMadeReversed ) / growDuration
    local trueMadeProgress = self.trueMadeProgress

    if trueMadeProgress < 1 then
        self.trueMadeProgress = madeProgress
        -- looks dumb when it appears from nothing, so make it at least start with some size
        local progressNeverZero = math.Clamp( madeProgress, .3, 1 )
        self:DoScaling( finalBarbScale * progressNeverZero )

        self:EmitSound( "ChainLink.ImpactSoft" )

        self:SetNextClientThink( CurTime() + 1 + math.Rand( -.1, .1 ) )

    elseif integrityLatest ~= self.StructuralIntegrity then
        self.StructuralIntegrity = integrityLatest

        -- as wires take damage, make them flatter
        local scale = integrityLatest / self.MaxStructuralIntegrity
        self:DoScaling( finalBarbScale * Vector( 1, 1, scale ) )
        self:SetNextClientThink( CurTime() + 1 )

    else
        self:SetNextClientThink( CurTime() + 3 )
        return true

    end
end