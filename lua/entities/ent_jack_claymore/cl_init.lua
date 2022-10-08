include( "shared.lua" )
local mat = surface.GetTextureID( "sprites/mat_jack_clacker" )
language.Add( "ent_jack_claymore", "M18 Claymore" )

net.Receive( "JID_ClaymoreNotify", function()
    LocalPlayer().JackaClaymoreNotification = 300
end )

local function DrawNotification()
    local ply = LocalPlayer()

    if not ply.JackaClaymoreNotification and ply.JackaClaymoreNotification <= 0 then return end

    local w = ScrW()
    local h = ScrH()
    local opacity = math.Clamp( ply.JackaClaymoreNotification ^ 1.5, 0, 255 )
    surface.SetDrawColor( 255, 255, 255, opacity )
    surface.SetTexture( mat )
    surface.DrawTexturedRect( w * .3, h * .4, 200, 200 )
    surface.SetFont( "Trebuchet24" )
    surface.SetTextPos( w * .3 + 20, h * .4 + 200 )
    local Col = math.sin( CurTime() * 5 ) * 127 + 127
    surface.SetTextColor( Col, Col, Col, opacity )
    surface.DrawText( "NumPad Zero" )
    ply.JackaClaymoreNotification = ply.JackaClaymoreNotification - 1.5
end

hook.Add( "RenderScreenspaceEffects", "JackaClaymoreDetNote", DrawNotification )
