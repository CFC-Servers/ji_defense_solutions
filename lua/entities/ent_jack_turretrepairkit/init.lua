--box
--By Jackarunda
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')
function ENT:SpawnFunction(ply,tr)
	local SpawnPos=tr.HitPos + tr.HitNormal*16
	local ent=ents.Create("ent_jack_turretrepairkit")
	ent:SetPos(SpawnPos)
	ent:SetNWEntity("Owenur",ply)
	ent:Spawn()
	ent:Activate()
	local effectdata=EffectData()
	effectdata:SetEntity(ent)
	util.Effect("propspawn",effectdata)
	return ent
end
function ENT:Initialize()
	self:SetModel("models/props_junk/cardboard_box003a.mdl")
	self:SetMaterial("models/mat_jack_turretrepairkit")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)	
	self:SetSolid(SOLID_VPHYSICS)
	self:DrawShadow(true)
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
		phys:SetMass(30)
	end
	self:SetUseType(SIMPLE_USE)
end
function ENT:PhysicsCollide(data, physobj)
	if((data.Speed>80)and(data.DeltaTime>0.2))then
		self:EmitSound("Cardboard.ImpactHard")
		self:EmitSound("Weapon.ImpactSoft")
	end
end
function ENT:OnTakeDamage(dmginfo)
	self:TakePhysicsDamage(dmginfo)
end
function ENT:Use(activator,caller)
	activator:PickupObject(self)
end
function ENT:Think()
	--pfahahaha
end
function ENT:OnRemove()
	--aw fuck you
end