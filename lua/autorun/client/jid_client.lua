local iconColor = Color( 255, 255, 255, 255 )
killicon.Add( "ent_jack_turret_amateriel", "vgui/hud/jid_turret_killicon", iconColor )
killicon.Add( "ent_jack_turret_grenade", "vgui/hud/jid_turret_killicon", iconColor )
killicon.Add( "ent_jack_turret_mg", "vgui/hud/jid_turret_killicon", iconColor )
killicon.Add( "ent_jack_turret_dmr", "vgui/hud/jid_turret_killicon", iconColor )
killicon.Add( "ent_jack_turret_pistol", "vgui/hud/jid_turret_killicon", iconColor )
killicon.Add( "ent_jack_turret_plinker", "vgui/hud/jid_turret_killicon", iconColor )
killicon.Add( "ent_jack_turret_rifle", "vgui/hud/jid_turret_killicon", iconColor )
killicon.Add( "ent_jack_turret_shotty", "vgui/hud/jid_turret_killicon", iconColor )
killicon.Add( "ent_jack_turret_sniper", "vgui/hud/jid_turret_killicon", iconColor )
killicon.Add( "ent_jack_turret_smg", "vgui/hud/jid_turret_killicon", iconColor )
killicon.Add( "ent_jack_40mmgrenade", "vgui/hud/jid_turret_killicon", iconColor )

killicon.Add( "ent_jack_claymore", "vgui/hud/jid_claymore_killicon", iconColor )
killicon.Add( "ent_jack_seamine", "vgui/hud/jid_seamine_killicon", iconColor )
killicon.Add( "ent_jack_landmine", "vgui/hud/jid_landmine_killicon", iconColor )
killicon.Add( "ent_jack_boundingmine", "vgui/hud/jid_boundingmine_killicon", iconColor )
killicon.Add( "ent_jack_teslasentry", "vgui/hud/jid_teslasentry_killicon", iconColor )

local function ShutDownPanel( panel, cmd )
    if not panel then return end
    panel:Close()
    if not cmd then return end
    LocalPlayer():ConCommand( cmd )
end

function JID.MakeEasyClose( panel, cmd )
    local clientsMenuKey = input.LookupBinding( "+menu" )
    if clientsMenuKey then
        clientsMenuKey = input.GetKeyCode( clientsMenuKey )
    end

    local clientsUseKey = input.LookupBinding( "+use" )
    if clientsUseKey then
        clientsUseKey = input.GetKeyCode( clientsUseKey )
    end

    panel.nextDeleteThink = CurTime() + 0.25

    function panel:Think()
        -- bail if they open any menu, or press use
        if self.nextDeleteThink > CurTime() then return end
        if input.IsKeyDown( KEY_ESCAPE ) then ShutDownPanel( self, cmd ) return end
        if input.IsKeyDown( clientsMenuKey ) or input.IsKeyDown( clientsUseKey ) then ShutDownPanel( self, cmd ) return end
        if not input.IsMouseDown( MOUSE_LEFT ) and not input.IsMouseDown( MOUSE_RIGHT ) then return end

        -- close when clicking off menu
        local myX, myY = self:GetPos()
        local myWidth, myHeight = self:GetSize()
        local mouseX, mouseY = input.GetCursorPos()

        if mouseX < myX or mouseX > myX + myWidth then ShutDownPanel( self, cmd ) return end
        if mouseY < myY or mouseY > myY + myHeight then ShutDownPanel( self, cmd ) return end
    end
end
