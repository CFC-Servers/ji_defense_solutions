--box
--By Jackarunda
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')
function ENT:SpawnFunction(ply,tr)
	local SpawnPos=tr.HitPos + tr.HitNormal*16
	local ent=ents.Create("ent_jack_aidfuel_propane")
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
	self:SetModel("models/props_junk/PropaneCanister001a.mdl")
	self:SetColor(Color(200,200,200))
	self:SetMaterial("models/mat_jack_aidfuel_propane")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)	
	self:SetSolid(SOLID_VPHYSICS)
	self:DrawShadow(true)
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
		phys:SetMass(35)
	end
	self.StructuralIntegrity=100
	self.Asploded=false
end
function ENT:PhysicsCollide(data, physobj)
	if((data.Speed>80)and(data.DeltaTime>0.2))then
		self:EmitSound("Canister.ImpactHard")
		self:EmitSound("Wade.StepRight")
		self:EmitSound("Wade.StepLeft")
	end
end
function ENT:OnTakeDamage(dmginfo)
	self:TakePhysicsDamage(dmginfo)
	self.StructuralIntegrity=self.StructuralIntegrity-dmginfo:GetDamage()
	if(self.StructuralIntegrity<=0)then
		self:Asplode()
	end
end
function ENT:Asplode()
	if(self.Asploded)then return end
	self.Asploded=true
	local SelfPos=self:LocalToWorld(self:OBBCenter())
	local explode=ents.Create("env_explosion")
	explode:SetPos(SelfPos)
	explode:SetOwner(self)
	explode:Spawn()
	explode:Activate()
	explode:SetKeyValue("iMagnitude","110")
	explode:Fire("Explode",0,0)
	self:Remove()
end
function ENT:Use(activator,caller)
	--nope
end
function ENT:Think()
	--pfahahaha
end
function ENT:OnRemove()
	--aw fuck you
end