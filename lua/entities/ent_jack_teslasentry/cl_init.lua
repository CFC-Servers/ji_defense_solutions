include( "shared.lua" )
ENT.UpAmount = 0
language.Add( "ent_jack_teslasentry", "Tesla Sentry" )

function ENT:Initialize()
    self.PoleOne = ClientsideModel( "models/props_c17/canister01a.mdl" )
    self.PoleOne:SetPos( self:GetPos() )
    self.PoleOne:SetParent( self )
    self.PoleOne:SetNoDraw( true )
    self.PoleOne:SetMaterial( "phoenix_storms/metalfloor_2-3" )

    self.PoleTwo = ClientsideModel( "models/props_junk/propane_tank001a.mdl" )
    self.PoleTwo:SetPos( self:GetPos() )
    self.PoleTwo:SetParent( self )
    self.PoleTwo:SetNoDraw( true )
    self.PoleTwo:SetMaterial( "phoenix_storms/metalfloor_2-3" )

    self.Dissipator = ClientsideModel( "models/holograms/hq_torus_thick.mdl" )
    self.Dissipator:SetPos( self:GetPos() )
    self.Dissipator:SetParent( self )
    self.Dissipator:SetNoDraw( true )
    self.Dissipator:SetModelScale( 1.5, 0 )
    self.Dissipator:SetMaterial( "debug/env_cubemap_model" )
    self.Dissipator:DrawShadow( true )

    self.BatOne = ClientsideModel( "models/Items/car_battery01.mdl" )
    self.BatOne:SetPos( self:GetPos() )
    self.BatOne:SetParent( self )
    self.BatOne:SetNoDraw( true )

    self.BatTwo = ClientsideModel( "models/Items/car_battery01.mdl" )
    self.BatTwo:SetPos( self:GetPos() )
    self.BatTwo:SetParent( self )
    self.BatTwo:SetNoDraw( true )
end

function ENT:Draw()
    local selfTbl = self:GetTable()
    local OrigR, OrigG, OrigB = render.GetColorModulation()
    selfTbl.UpAmount = self:GetDTFloat( 0 )

    local Pos = self:GetPos()
    local Up = self:GetUp()
    local Right = self:GetRight()
    local AngOne = self:GetAngles()
    local AngTwo = self:GetAngles()
    local AngThree = self:GetAngles()
    local AngFour = self:GetAngles()
    local AngFive = self:GetAngles()

    selfTbl.PoleOne:SetRenderOrigin( Pos + Up * ( 1 + selfTbl.UpAmount ) + Right * 5 )
    selfTbl.PoleOne:SetRenderAngles( AngOne )
    selfTbl.PoleTwo:SetRenderOrigin( Pos + Up * ( 10 + selfTbl.UpAmount * 1.7 ) + Right * 5 )
    selfTbl.PoleTwo:SetRenderAngles( AngTwo )
    selfTbl.Dissipator:SetRenderOrigin( Pos + Up * ( 25 + selfTbl.UpAmount * 1.7 ) + Right * 5 )
    selfTbl.Dissipator:SetRenderAngles( AngThree )

    selfTbl.BatOne:SetRenderOrigin( Pos + Up * 5 + Right * 20 )
    AngFour:RotateAroundAxis( AngFour:Right(), -90 )
    AngFour:RotateAroundAxis( AngFour:Forward(), 90 )
    AngFour:RotateAroundAxis( AngFour:Right(), 180 )
    selfTbl.BatOne:SetRenderAngles( AngFour )

    selfTbl.BatTwo:SetRenderOrigin( Pos + Up * 5 - Right * 11 )
    AngFive:RotateAroundAxis( AngFour:Right(), -90 )
    AngFive:RotateAroundAxis( AngFive:Up(), 90 )
    selfTbl.BatTwo:SetRenderAngles( AngFive )

    render.SetColorModulation( OrigR / 2, OrigG / 2, OrigB / 2 )
    selfTbl.PoleOne:DrawModel()
    selfTbl.PoleTwo:DrawModel()
    render.SetColorModulation( OrigR, OrigG, OrigB )

    if self:GetDTBool( 1 ) then
        selfTbl.BatOne:DrawModel()
    end

    if self:GetDTBool( 2 ) then
        selfTbl.BatTwo:DrawModel()
    end

    selfTbl.Dissipator:DrawModel()
    self:DrawModel()
end

function ENT:OnRemove()
end

local function OpenMenu( data )
    local Tab = {}
    Tab.Self = data:ReadEntity()
    Tab.Batt = data:ReadShort()
    Tab.CapCharge = data:ReadShort()
    Tab.Self:OpenTheMenu( Tab )
end

usermessage.Hook( "JackaTeslaTurretOpenMenu", OpenMenu )

function ENT:OpenTheMenu( tab )
    local DermaPanel = vgui.Create( "DFrame" )
    DermaPanel:SetPos( 40, 80 )
    DermaPanel:SetSize( 300, 100 )
    DermaPanel:SetTitle( "Jackarunda Industries" )
    DermaPanel:SetVisible( true )
    DermaPanel:SetDraggable( true )
    DermaPanel:ShowCloseButton( false )
    DermaPanel:MakePopup()
    DermaPanel:SetKeyboardInputEnabled( false )

    DermaPanel:Center()
    DermaPanel:SetKeyboardInputEnabled( false )

    local MainPanel = vgui.Create( "DPanel", DermaPanel )
    MainPanel:SetPos( 5, 25 )
    MainPanel:SetSize( 290, 68 )

    MainPanel.Paint = function()
        surface.SetDrawColor( 0, 20, 40, 255 )
        surface.DrawRect( 0, 0, MainPanel:GetWide(), MainPanel:GetTall() + 3 )
    end

    local battlabel = vgui.Create( "DLabel", MainPanel )
    battlabel:SetPos( 120, 0 )
    battlabel:SetSize( 150, 20 )
    battlabel:SetText( "Power: " .. tostring( math.Round( tab.Batt / 6000 * 100 ) ) .. "%" )
    local SecondPanel = vgui.Create( "DPanel", MainPanel )
    SecondPanel:SetPos( 10, 20 )
    SecondPanel:SetSize( 270, 17 )

    SecondPanel.Paint = function()
        surface.SetDrawColor( 0, 128, 128, 255 )
        surface.DrawRect( 0, 0, 270, 17 )
    end

    local capselect = vgui.Create( "DNumSlider", SecondPanel )
    capselect:SetPos( 10, -8 )
    capselect:SetWide( 280 )
    capselect:SetText( "Capacitor Firing Charge" )
    capselect:SetMin( 10 )
    capselect:SetMax( 150 )
    capselect:SetDecimals( 0 )
    capselect:SetValue( tab.CapCharge )

    capselect.ValueChanged = function( _, value )
        RunConsoleCommand( "JackaTeslaTurretSetCap", tostring( self:GetNWInt( "JackIndex" ) ), tostring( value ) )
    end

    local battbutton = vgui.Create( "Button", MainPanel )
    battbutton:SetSize( 80, 20 )
    battbutton:SetPos( 10, 43 )
    battbutton:SetText( "Electricity" )
    battbutton:SetVisible( true )

    battbutton.DoClick = function()
        DermaPanel:Close()
        RunConsoleCommand( "JackaTeslaTurretBattery", tostring( self:GetNWInt( "JackIndex" ) ) )
    end

    local exitbutton = vgui.Create( "Button", MainPanel )
    exitbutton:SetSize( 80, 20 )
    exitbutton:SetPos( 106, 43 )
    exitbutton:SetText( "Exit" )
    exitbutton:SetVisible( true )

    exitbutton.DoClick = function()
        DermaPanel:Close()
        RunConsoleCommand( "JackaTeslaTurretCloseMenu_Cancel", tostring( self:GetNWInt( "JackIndex" ) ) )
    end

    local powerbutton = vgui.Create( "Button", MainPanel )
    powerbutton:SetSize( 80, 20 )
    powerbutton:SetPos( 200, 43 )
    powerbutton:SetText( "Activate" )
    powerbutton:SetVisible( true )

    powerbutton.DoClick = function()
        DermaPanel:Close()
        RunConsoleCommand( "JackaTeslaTurretCloseMenu_On", tostring( self:GetNWInt( "JackIndex" ) ) )
    end
end
