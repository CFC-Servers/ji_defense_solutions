//local Shit=Material("models/entities/mat_jack_apersbomb")
include('shared.lua')
ENT.Base="ent_jack_turretammobox_base"

function ENT:Draw()
	self.Entity:DrawModel()
end

language.Add("ent_jack_ammobox_40mm","40x53mm Grenade AmmoBox")