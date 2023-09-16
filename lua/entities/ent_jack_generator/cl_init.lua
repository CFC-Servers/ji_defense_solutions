include( "shared.lua" )

function ENT:Initialize()
    self.RotateAngle = 0
    self.RotSpeed = 0
    self.Blowing = false

    self.Engine1 = ClientsideModel( "models/props_silo/fanoff.mdl" )
    self.Engine1:SetPos( self:GetPos() )
    self.Engine1:SetParent( self )
    self.Engine1:SetNoDraw( true )
    self.Engine1:SetModelScale( .75, 0 )

    self.Engine2 = ClientsideModel( "models/props_silo/fanoff.mdl" )
    self.Engine2:SetPos( self:GetPos() )
    self.Engine2:SetParent( self )
    self.Engine2:SetNoDraw( true )
    self.Engine2:SetModelScale( .75, 0 )

    self.Engine3 = ClientsideModel( "models/props_silo/fanoff.mdl" )
    self.Engine3:SetPos( self:GetPos() )
    self.Engine3:SetParent( self )
    self.Engine3:SetNoDraw( true )
    self.Engine3:SetModelScale( .75, 0 )

    self.Engine4 = ClientsideModel( "models/props_silo/fanoff.mdl" )
    self.Engine4:SetPos( self:GetPos() )
    self.Engine4:SetParent( self )
    self.Engine4:SetNoDraw( true )
    self.Engine4:SetModelScale( .75, 0 )

    self.Turbine = ClientsideModel( "models/props_silo/fanhousing.mdl" )
    self.Turbine:SetPos( self:GetPos() )
    self.Turbine:SetParent( self )
    self.Turbine:SetNoDraw( true )
    self.Turbine:SetModelScale( .75, 0 )
    self.Turbine:SetMaterial( "models/props_silo/jan" )
end

function ENT:Draw()
    local Ang = self:GetAngles()
    local Pos = self:GetPos()
    local Up = self:GetUp()
    local Forward = self:GetForward()
    local Ang2 = self:GetAngles()

    local selfTbl = self:GetTable()

    Ang:RotateAroundAxis( Ang:Forward(), selfTbl.RotateAngle )
    selfTbl.RotateAngle = selfTbl.RotateAngle + selfTbl.RotSpeed

    if selfTbl.RotateAngle > 360 then
        selfTbl.RotateAngle = 0
    end

    if self:GetDTBool( 0 ) then
        selfTbl.RotSpeed = selfTbl.RotSpeed + .035
    else
        selfTbl.RotSpeed = selfTbl.RotSpeed - .035
    end

    if selfTbl.RotSpeed > 42 then
        selfTbl.RotSpeed = 42
    end

    if selfTbl.RotSpeed < 0 then
        selfTbl.RotSpeed = 0
    end

    if selfTbl.RotSpeed > 30 then
        if not selfTbl.Blowing then
            selfTbl.Blowing = true
            selfTbl.Engine1:SetModel( "models/props_silo/fan.mdl" )
            selfTbl.Engine2:SetModel( "models/props_silo/fan.mdl" )
            selfTbl.Engine3:SetModel( "models/props_silo/fan.mdl" )
            selfTbl.Engine4:SetModel( "models/props_silo/fan.mdl" )
        end
    else
        if selfTbl.Blowing then
            selfTbl.Blowing = false
            selfTbl.Engine1:SetModel( "models/props_silo/fanoff.mdl" )
            selfTbl.Engine2:SetModel( "models/props_silo/fanoff.mdl" )
            selfTbl.Engine3:SetModel( "models/props_silo/fanoff.mdl" )
            selfTbl.Engine4:SetModel( "models/props_silo/fanoff.mdl" )
        end
    end

    selfTbl.Engine1:SetRenderOrigin( Pos + Forward * 70 + Up * 55 )
    Ang:RotateAroundAxis( Ang:Right(), 90 )
    selfTbl.Engine1:SetRenderAngles( Ang )
    selfTbl.Engine1:DrawModel()
    selfTbl.Engine2:SetRenderOrigin( Pos + Forward * 70 + Up * 55 )

    Ang:RotateAroundAxis( Ang:Up(), 15 )
    selfTbl.Engine2:SetRenderAngles( Ang )
    selfTbl.Engine3:SetRenderOrigin( Pos + Forward * 70 + Up * 55 )

    Ang:RotateAroundAxis( Ang:Up(), 15 )
    selfTbl.Engine3:SetRenderAngles( Ang )
    selfTbl.Engine4:SetRenderOrigin( Pos + Forward * 70 + Up * 55 )

    Ang:RotateAroundAxis( Ang:Up(), 15 )
    selfTbl.Engine4:SetRenderAngles( Ang )

    local R, G, B = render.GetColorModulation()
    render.SetColorModulation( .2, .2, .2 )
    selfTbl.Engine1:DrawModel()
    selfTbl.Engine2:DrawModel()
    selfTbl.Engine3:DrawModel()
    selfTbl.Engine4:DrawModel()

    render.SetColorModulation( R, G, B )
    selfTbl.Turbine:SetRenderOrigin( Pos + Forward * 65 + Up * 55 )
    Ang2:RotateAroundAxis( Ang2:Right(), -90 )
    selfTbl.Turbine:SetRenderAngles( Ang2 )
    selfTbl.Turbine:DrawModel()
    self:DrawModel()
end

language.Add( "ent_jack_generator", "Gas Turbine Generator" )
