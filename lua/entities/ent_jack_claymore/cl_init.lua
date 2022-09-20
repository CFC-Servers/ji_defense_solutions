include('shared.lua')
local Mat=surface.GetTextureID("sprites/mat_jack_clacker")
language.Add("ent_jack_claymore","M18 Claymore")
local function NotifyReceive(data)
	data:ReadEntity().JackaClaymoreNotification=300
end
usermessage.Hook("JackaClaymoreNotify",NotifyReceive)
local function DrawNotification()
	local Ply=LocalPlayer()
	if((Ply.JackaClaymoreNotification)and(Ply.JackaClaymoreNotification>0))then
		local W=ScrW()
		local H=ScrH()
		local Opacity=math.Clamp(Ply.JackaClaymoreNotification^1.5,0,255)
		surface.SetDrawColor(255,255,255,Opacity)
		surface.SetTexture(Mat)
		surface.DrawTexturedRect(W*.3,H*.4,200,200)
		surface.SetFont("Trebuchet24")
		surface.SetTextPos(W*.3+20,H*.4+200)
		local Col=((math.sin(CurTime()*5))*127)+127
		surface.SetTextColor(Col,Col,Col,Opacity)
		surface.DrawText("NumPad Zero")
		Ply.JackaClaymoreNotification=Ply.JackaClaymoreNotification-1.5
	end
end
hook.Add("RenderScreenspaceEffects","JackaClaymoreDetNote",DrawNotification)