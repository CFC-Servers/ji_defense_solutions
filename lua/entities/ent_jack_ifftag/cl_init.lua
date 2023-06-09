include( "shared.lua" )

local implanterArmEmergePos = Vector( 6, 3, 4 )
local armsBeginPos = Vector( 15.11, 1.14, -6.26 )
local fullExtend = Vector( 2, 1, 1 )
local retracted = Vector( .5, 1, 1 )

local model1Offset = Vector( 2, -3, 0 )
local model1AngOffset = Angle( 0, 0, -90 )

local model2Offset = Vector( 8, 3, 4 )
local model2AngOffset = Angle( 0, -180, -90 )

local model3Offset = Vector( 4, -3, 20 )
local model3AngOffset = Angle( 0, 0, 0 )

local model4Offset = Vector( 5, 3, 4 )
local model4AngOffset = Angle( 0, -90, 0 )

local armMoveTime = .25

function ENT:RetractedAng()
    return ( ( self:GetForward() * 0.1 ) + ( self:GetUp() * 0.9 ) ):Angle()

end

function ENT:ArmEmergePos()
    return self:LocalToWorld( implanterArmEmergePos )

end
function ENT:ArmsBeginPos()
    return self.ImplantingArm:LocalToWorld( armsBeginPos * self.armsScale )

end

function ENT:Initialize()
    self.armMatrix = Matrix()
    self.ImplantingArm = ClientsideModel( "models/props_combine/combinecamera001.mdl" )

    self:DoScaling( retracted )
    self.ImplantingArm:SetParent( self )
    self:UpdateArm( self:RetractedAng() )

    self:CallOnRemove( "removemodels", function()
        self.ImplantingArm:Remove()
        SafeRemoveEntity( self.Model1 )
        SafeRemoveEntity( self.Model2 )
        SafeRemoveEntity( self.Model3 )
        SafeRemoveEntity( self.Model4 )

    end )

end

function ENT:UpdateArm( ang )

    self.ImplantingArm:SetAngles( ang )

    local worldEmergeFromPos = self:LocalToWorld( implanterArmEmergePos )
    local offsetToApplyWorld = LocalToWorld( armsBeginPos * self.armsScale, angle_zero, vector_origin, ang )
    local posToSetArmAt = worldEmergeFromPos + offsetToApplyWorld

    self.ImplantingArm:SetPos( posToSetArmAt )

    self:EmitSound( "snd_jack_turretservo.mp3", 70, 150 )

end

function ENT:DoScaling( scaleVec )
    self.armsScale = scaleVec
    self.armMatrix:SetScale( scaleVec )
    self.ImplantingArm:EnableMatrix( "RenderMultiply", self.armMatrix )

end

function ENT:Draw()
    self:DoDetails()
    local lastImplant = self:GetNW2Float( "implantedtime" )

    if lastImplant + armMoveTime > CurTime() then
        self.isDefinitelyRetracted = nil
        local implantedPos = self:GetNW2Vector( "implantedpos" )
        if implantedPos == vector_origin then return end

        local aimDir = ( implantedPos - self:ArmEmergePos() ):GetNormalized()
        local retractedDir = self:GetUp()

        local ratio = math.abs( ( lastImplant - CurTime() ) / armMoveTime )
        local ratioReversed = math.abs( ratio - 1 )

        local dirAsAng = ( ( aimDir * ratioReversed ) + ( retractedDir * ratio ) ):Angle()

        self:DoScaling( ( fullExtend * ratioReversed ) + ( retracted * ratio ) )
        self:UpdateArm( dirAsAng )

    elseif not self.isDefinitelyRetracted then
        self.isDefinitelyRetracted = true
        self:DoScaling( retracted )
        self:UpdateArm( self:RetractedAng() )

    end
    self:DrawModel()

end

language.Add( "ent_jack_ifftag", "J.I. IFF Tag Implanter" )

function ENT:DoDetails()
    if not IsValid( self.Model1 ) then
        self.Model1 = ClientsideModel( "models/props_lab/reciever01b.mdl" )
        self.Model1.vecOffset = model1Offset
        self.Model1.angOffset = model1AngOffset

        self.Model1:SetPos( self:LocalToWorld( self.Model1.vecOffset ) )
        self.Model1:SetAngles( self:LocalToWorldAngles( self.Model1.angOffset ) )
        self.Model1:SetParent( self )

    end

    if not IsValid( self.Model2 ) then
        self.Model2 = ClientsideModel( "models/props_lab/tpplug.mdl" )
        self.Model2.vecOffset = model2Offset
        self.Model2.angOffset = model2AngOffset

        self.Model2:SetModelScale( 1.25 )
        self.Model2:SetPos( self:LocalToWorld( self.Model2.vecOffset ) )
        self.Model2:SetAngles( self:LocalToWorldAngles( self.Model2.angOffset ) )
        self.Model2:SetParent( self )

    end

    if not IsValid( self.Model3 ) then
        self.Model3 = ClientsideModel( "models/props_rooftop/antenna03a.mdl" )
        self.Model3.vecOffset = model3Offset
        self.Model3.angOffset = model3AngOffset

        self.Model3:SetModelScale( 0.25 )
        self.Model3:SetPos( self:LocalToWorld( self.Model3.vecOffset ) )
        self.Model3:SetAngles( self:LocalToWorldAngles( self.Model3.angOffset ) )
        self.Model3:SetParent( self )

    end

    if not IsValid( self.Model4 ) then
        self.Model4 = ClientsideModel( "models/props_lab/rotato.mdl" )
        self.Model4.vecOffset = model4Offset
        self.Model4.angOffset = model4AngOffset

        self.Model4:SetModelScale( 0.75 )
        self.Model4:SetPos( self:LocalToWorld( self.Model4.vecOffset ) )
        self.Model4:SetAngles( self:LocalToWorldAngles( self.Model4.angOffset ) )
        self.Model4:SetParent( self )
        self.Model4:SetMaterial( "models/props_combine/combine_interface_disp" )

    end
    self.Models = { self.Model1, self.Model2, self.Model3, self.Model4 }

    -- reparent if we re-enter pvs
    for _, model in ipairs( self.Models ) do
        if model:GetParent() == self then continue end
        model:SetPos( self:LocalToWorld( model.vecOffset ) )
        model:SetAngles( self:LocalToWorldAngles( model.angOffset ) )
        model:SetParent( self )

    end

end