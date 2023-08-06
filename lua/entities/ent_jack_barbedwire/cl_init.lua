include( "shared.lua" )

ENT.trueMadeProgress = 0

function ENT:Draw()
    self:DrawModel()
end

language.Add( "ent_jack_barbedwire", "J.I. Barbed Wire" )

local _IsValid = IsValid

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
    if not _IsValid( self.Wires1 ) then
        self.Wires1 = ClientsideModel( "models/bf1/barbed_wire_destroyed02.mdl" )
        self.Wires1:SetPos( self:GetPos() )
        self.Wires1:SetAngles( self:GetForward():Angle() )
        self.Wires1:SetParent( self )

    end

    if not _IsValid( self.Wires2 ) then
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

-- actual ent is invis
function ENT:Draw()
end

function ENT:Think()
    -- according to wiki, barb models will remove themselves sometimes
    -- invisible damage dealers, not good!
    self:DoBarbedWires()

    local integrityLatest = self:GetNW2Int( "structuralIntegrity" )

    local growDuration = self.growDuration

    local timeToFullyMade = CurTime() - self.FullyMadeTime
    timeToFullyMade = math.Clamp( timeToFullyMade, -growDuration, 0 )
    local timeToFullyMadeReversed = ( timeToFullyMade + growDuration )

    local madeProgress = math.abs( timeToFullyMadeReversed ) / growDuration
    local trueMadeProgress = self.trueMadeProgress

    -- spawning in...
    if trueMadeProgress < 1 then
        self.trueMadeProgress = madeProgress
        -- looks dumb when it appears from nothing, so make it at least start with some size
        local progressRescaled = math.Clamp( madeProgress + .3, .3, 1 )
        self:DoScaling( finalBarbScale * progressRescaled )

        self:EmitSound( "ChainLink.ImpactSoft" )

        self:SetNextClientThink( CurTime() + 1 + math.Rand( -.1, .1 ) )

    -- need to update
    elseif integrityLatest ~= self.StructuralIntegrity then
        self.StructuralIntegrity = integrityLatest

        -- as wires take damage, make them flatter
        local scale = integrityLatest / self.MaxStructuralIntegrity
        self:DoScaling( finalBarbScale * Vector( 1, 1, scale ) )
        self:SetNextClientThink( CurTime() + 1 )

    -- nothin changed
    else
        self:SetNextClientThink( CurTime() + 3 )
        return true

    end
end

local mat = surface.GetTextureID( "sprites/mat_jack_cutwire" )

local tooFarToCut = 100^2
local maxSpeedCanCut = 100^2

local function ShouldDrawNotification( ply )
    local eyeTr = ply:GetEyeTrace()
    if not IsValid( eyeTr.Entity ) then return end

    if eyeTr.Entity:GetClass() ~= "ent_jack_barbedwire" then return end
    if eyeTr.HitPos:DistToSqr( ply:GetShootPos() ) > tooFarToCut then return end
    if ply:GetVelocity():LengthSqr() > maxSpeedCanCut then return end

    ply.JackaCutWireNotification = 100

end


local function DrawNotification()
    local ply = LocalPlayer()

    ShouldDrawNotification( ply )

    if not ply.JackaCutWireNotification then return end
    if ply.JackaCutWireNotification <= 0 then return end

    local w = ScrW()
    local h = ScrH()
    local opacity = math.Clamp( ply.JackaCutWireNotification ^ 1.5, 0, 255 )
    surface.SetDrawColor( 255, 255, 255, opacity )
    surface.SetTexture( mat )
    surface.DrawTexturedRect( w * .3, h * .4, 200, 200 )

    surface.SetFont( "Trebuchet24" )
    surface.SetTextPos( w * .3 + 20, h * .4 + 200 )
    local Col = math.sin( CurTime() * 5 ) * 127 + 127
    surface.SetTextColor( Col, Col, Col, opacity )
    surface.DrawText( "\" USE \" to cut." )

    ply.JackaCutWireNotification = ply.JackaCutWireNotification - 0.75

end

hook.Add( "RenderScreenspaceEffects", "JackaCutWireNote", DrawNotification )