include( "shared.lua" )

function ENT:Initialize()
    self.Nice = ClientsideModel( "models/XQM/cylinderx1.mdl" )
    self.Nice:SetMaterial( "models/mat_jack_scratchedmetal" )
    self.Nice:SetPos( self:GetPos() )
    self.Nice:SetParent( self )
    self.Nice:SetNoDraw( true )
    self.Nice:SetModelScale( .5, 0 )

    self.Fuze = ClientsideModel( "models/props_phx/construct/metal_dome360.mdl" )
    self.Fuze:SetMaterial( "models/mat_jack_scratchedmetal" )
    self.Fuze:SetPos( self:GetPos() )
    self.Fuze:SetParent( self )
    self.Fuze:SetNoDraw( true )
    self.Fuze:SetModelScale( .04, 0 )

    self.Prongs = ClientsideModel( "models/Mechanics/robotics/stand.mdl" )
    self.Prongs:SetMaterial( "models/mat_jack_scratchedmetal" )
    self.Prongs:SetPos( self:GetPos() )
    self.Prongs:SetParent( self )
    self.Prongs:SetNoDraw( true )
    self.Prongs:SetModelScale( .03, 0 )

    self.Prong = ClientsideModel( "models/props_junk/harpoon002a.mdl" )
    self.Prong:SetMaterial( "models/mat_jack_scratchedmetal" )
    self.Prong:SetPos( self:GetPos() )
    self.Prong:SetParent( self )
    self.Prong:SetNoDraw( true )
    self.Prong:SetModelScale( .075, 0 )
end

function ENT:Draw()
    local R, G, B = render.GetColorModulation()
    local Pos = self:GetPos()
    local Ang1 = self:GetAngles()
    local Ang2 = self:GetAngles()
    local Ang3 = self:GetAngles()
    local Ang4 = self:GetAngles()
    local Up = self:GetUp()

    Ang1:RotateAroundAxis( Ang1:Right(), 90 )
    self.Nice:SetRenderAngles( Ang1 )
    self.Nice:SetRenderOrigin( Pos + Up * 4 )
    render.SetColorModulation( 1, 1, 1 )
    self.Nice:DrawModel()

    render.SetColorModulation( R, G, B )
    self.Fuze:SetRenderAngles( Ang2 )
    self.Fuze:SetRenderOrigin( Pos + Up * 7.25 )
    self.Fuze:DrawModel()

    Ang3:RotateAroundAxis( Ang3:Right(), 180 )
    self.Prongs:SetRenderAngles( Ang3 )
    self.Prongs:SetRenderOrigin( Pos + Up * 8.75 )
    self.Prongs:DrawModel()

    Ang4:RotateAroundAxis( Ang4:Right(), -90 )
    self.Prong:SetRenderAngles( Ang4 )
    self.Prong:SetRenderOrigin( Pos + Up * 6.5 )
    self.Prong:DrawModel()
end

language.Add( "ent_jack_boundingmine", "Bounding Mine" )
