include( "shared.lua" )

function ENT:Initialize()
    self.Can1 = ClientsideModel( "models/props_borealis/bluebarrel001.mdl" )
    self.Can1:SetPos( self:GetPos() )
    self.Can1:SetParent( self )
    self.Can1:SetNoDraw( true )
    self.Can1:SetModelScale( .1, 0 )
    self.Can1:SetMaterial( "models/mat_jack_spraypaintcan" )
    self.Can2 = ClientsideModel( "models/props_borealis/bluebarrel001.mdl" )
    self.Can2:SetPos( self:GetPos() )
    self.Can2:SetParent( self )
    self.Can2:SetNoDraw( true )
    self.Can2:SetModelScale( .1, 0 )
    self.Can2:SetMaterial( "models/mat_jack_spraypaintcan" )
    self.Can3 = ClientsideModel( "models/props_borealis/bluebarrel001.mdl" )
    self.Can3:SetPos( self:GetPos() )
    self.Can3:SetParent( self )
    self.Can3:SetNoDraw( true )
    self.Can3:SetModelScale( .1, 0 )
    self.Can3:SetMaterial( "models/mat_jack_spraypaintcan" )
    self.Can4 = ClientsideModel( "models/props_borealis/bluebarrel001.mdl" )
    self.Can4:SetPos( self:GetPos() )
    self.Can4:SetParent( self )
    self.Can4:SetNoDraw( true )
    self.Can4:SetModelScale( .1, 0 )
    self.Can4:SetMaterial( "models/mat_jack_spraypaintcan" )
    self.Can5 = ClientsideModel( "models/props_borealis/bluebarrel001.mdl" )
    self.Can5:SetPos( self:GetPos() )
    self.Can5:SetParent( self )
    self.Can5:SetNoDraw( true )
    self.Can5:SetModelScale( .1, 0 )
    self.Can5:SetMaterial( "models/mat_jack_spraypaintcan" )
    self.Tape = ClientsideModel( "models/props_vehicles/tire001b_truck.mdl" )
    self.Tape:SetPos( self:GetPos() )
    self.Tape:SetParent( self )
    self.Tape:SetNoDraw( true )
    self.Tape:SetModelScale( .1, 0 )
    self.Tape:SetMaterial( "models/debug/debugwhite" )
    --local Matricks=Matrix()
    --Matricks:Scale(Vector(.85,.85,.625))
    --self.Can1:EnableMatrix("RenderMultiply",Matricks)
end

function ENT:Draw()
    local Ang = self:GetAngles()
    local Up = self:GetUp()
    local Forward = self:GetForward()
    local Right = self:GetRight()
    local Pos = self:GetPos() + Up * 2

    local selfTbl = self:GetTable()

    selfTbl.Can1:SetRenderAngles( Ang )
    selfTbl.Can2:SetRenderAngles( Ang )
    selfTbl.Can3:SetRenderAngles( Ang )
    selfTbl.Can4:SetRenderAngles( Ang )
    selfTbl.Can5:SetRenderAngles( Ang )
    Ang:RotateAroundAxis( Ang:Right(), 90 )
    selfTbl.Tape:SetRenderAngles( Ang )
    selfTbl.Can1:SetRenderOrigin( Pos + Right * 2.75 )
    selfTbl.Can2:SetRenderOrigin( Pos - Right * 2.75 )
    selfTbl.Can3:SetRenderOrigin( Pos + Forward * 2.75 )
    selfTbl.Can4:SetRenderOrigin( Pos - Forward * 2.75 )
    selfTbl.Can5:SetRenderOrigin( Pos )
    selfTbl.Tape:SetRenderOrigin( Pos + Up * 3 )
    render.SetColorModulation( .05, .05, .05 )
    selfTbl.Can1:DrawModel()
    render.SetColorModulation( 1, .05, 1 )
    selfTbl.Can2:DrawModel()
    render.SetColorModulation( .05, 1, 1 )
    selfTbl.Can3:DrawModel()
    render.SetColorModulation( 1, 1, 1 )
    selfTbl.Can4:DrawModel()
    render.SetColorModulation( 1, 1, .05 )
    selfTbl.Can5:DrawModel()
    render.SetColorModulation( .9, .9, .825 )
    selfTbl.Tape:DrawModel()
end

local function OpenMenu( data )
    local Tab = {}
    Tab.Self = data:ReadEntity()
    Tab.Self:OpenTheMenu( Tab )
end

usermessage.Hook( "JackaSprayPaintOpenMenu", OpenMenu )

local myLastColor = CreateClientConVar( "JackaSprayPaintLastColor", "128 128 128", true, false )

function ENT:OpenTheMenu( tab )
    local DermaPanel = vgui.Create( "DFrame" )
    DermaPanel:SetPos( 40, 80 )
    DermaPanel:SetSize( 225, 300 )
    DermaPanel:SetTitle( "Choose Color" )
    DermaPanel:SetVisible( true )
    DermaPanel:SetDraggable( true )
    DermaPanel:ShowCloseButton( false )
    DermaPanel:MakePopup()
    DermaPanel:SetKeyboardInputEnabled( false )

    DermaPanel:Center()

    JID.MakeEasyClose( DermaPanel, "JackaSprayPaintClose " .. tostring( self:GetNWInt( "JackIndex" ) ) )

    local MainPanel = vgui.Create( "DPanel", DermaPanel )
    MainPanel:SetPos( 5, 25 )
    MainPanel:SetSize( 215, 270 )

    MainPanel.Paint = function()
        surface.SetDrawColor( 0, 20, 40, 255 )
        surface.DrawRect( 0, 0, MainPanel:GetWide(), MainPanel:GetTall() + 3 )
    end

    local Mixer = vgui.Create( "DColorMixer", MainPanel )
    Mixer:SetPos( 10, 10 )
    Mixer:SetSize( 200, 200 )
    Mixer:SetPalette( true )
    Mixer:SetAlphaBar( false )
    Mixer:SetWangs( true )

    local lastColorString = myLastColor:GetString()
    local lastColorDeconstructed = string.Explode( " ", lastColorString )
    local lastColor = Color( lastColorDeconstructed[1] or 128, lastColorDeconstructed[2] or 128, lastColorDeconstructed[3] or 128 )
    Mixer:SetColor( lastColor )

    Mixer.ValueChanged = function( _, Col )
        local colString = tostring( Col.r ) .. " " .. tostring( Col.g ) .. " " .. tostring( Col.b )
        RunConsoleCommand( "JackaSprayPaintLastColor", colString )
    end

    local ColorPanel = vgui.Create( "DPanel", DermaPanel )
    ColorPanel:SetPos( 170, 111 )
    ColorPanel:SetSize( 40, 50 )

    ColorPanel.Paint = function()
        if not IsValid( self ) then return end
        local PntCol = Mixer:GetColor()
        local LgtCol = render.GetLightColor( self:GetPos() )
        LgtCol = Color( math.Clamp( LgtCol.r * 4, 0, 1 ), math.Clamp( LgtCol.g * 4, 0, 1 ), math.Clamp( LgtCol.b * 4, 0, 1 ) )
        local ActCol = Color( PntCol.r * LgtCol.r, PntCol.g * LgtCol.g, PntCol.b * LgtCol.b )
        surface.SetDrawColor( ActCol )
        surface.DrawRect( 0, 0, ColorPanel:GetWide(), ColorPanel:GetTall() + 3 )
    end

    local gobutton = vgui.Create( "Button", MainPanel )
    gobutton:SetSize( 195, 40 )
    gobutton:SetPos( 10, 220 )
    gobutton:SetText( "Paint" )
    gobutton:SetVisible( true )

    gobutton.DoClick = function()
        DermaPanel:Close()
        local Col = Mixer:GetColor()
        RunConsoleCommand( "JackaSprayPaintGo", tostring( self:GetNWInt( "JackIndex" ) ), Col.r, Col.g, Col.b )
    end
end

language.Add( "ent_jack_aidfuel_paintcan", "Spray Paint" )
