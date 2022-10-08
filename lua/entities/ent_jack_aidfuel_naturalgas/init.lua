--box
--By Jackarunda
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')
function ENT:SpawnFunction(ply,tr)
	local SpawnPos=tr.HitPos + tr.HitNormal*16
	local ent=ents.Create("ent_jack_aidfuel_naturalgas")
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
	self:SetModel("models/props_junk/plasticbucket001a.mdl")
	self:SetColor(Color(175,50,50))
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)	
	self:SetSolid(SOLID_VPHYSICS)
	self:DrawShadow(true)
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
		phys:SetMass(45)
	end
	self.StructuralIntegrity=100
	self.Fired=false
	self.FuelLeft=100
end
function ENT:PhysicsCollide(data, physobj)
	if(data.Speed>500)then
		self:EmitSound("Canister.ImpactHard")
		sound.Play("Canister.ImpactHard",data.HitPos,75,100)
		sound.Play("Canister.ImpactHard",data.HitPos,75,100)
		sound.Play("Canister.ImpactHard",data.HitPos,75,100)
		sound.Play("Canister.ImpactHard",data.HitPos,75,100)
		sound.Play("Canister.ImpactHard",data.HitPos,75,100)
		sound.Play("Canister.ImpactHard",data.HitPos,75,100)
		sound.Play("Canister.ImpactHard",data.HitPos,75,100)
		sound.Play("SolidMetal.ImpactHard",data.HitPos,75,100)
	end
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
	if(self.FuelLeft<=0)then return end
	if(self.Fired)then return end
	self.Fired=true
	local SelfPos=self:GetPos()
	self:EmitSound("SolidMetal.BulletImpact")
	self:EmitSound("SolidMetal.BulletImpact")
	self:EmitSound("SolidMetal.BulletImpact")
	self:EmitSound("SolidMetal.BulletImpact")
	self:EmitSound("SolidMetal.BulletImpact")
	self:EmitSound("SolidMetal.BulletImpact")
	self:EmitSound("SolidMetal.BulletImpact")
	self:EmitSound("SolidMetal.BulletImpact")
end
function ENT:Use(activator,caller)
	--nope
end
function ENT:Think()
	if(self.Fired)then
		local SelfPos=self:GetPos()
		local Up=self:GetUp()
		local Eff=EffectData()
		Eff:SetOrigin(SelfPos+Up*20)
		Eff:SetScale(1)
		Eff:SetNormal(Up)
		util.Effect("eff_jack_rocketthrust",Eff,true,true)
		self:GetPhysicsObject():ApplyForceCenter(-Up*3000)
		self:GetPhysicsObject():AddAngleVelocity(-self:GetPhysicsObject():GetAngleVelocity()/10)
		self:EmitSound("snd_jack_thrustburn.mp3",75,100)
		self.FuelLeft=self.FuelLeft-.75
		if(self.FuelLeft<=0)then
			self.Fired=false
			SafeRemoveEntityDelayed(self,10)
		end
	end
	self:NextThink(CurTime()+.02)
	return true
end
function ENT:OnRemove()
	--aw fuck you
end