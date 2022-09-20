--LayundMahn
--By Jackarunda

AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')
function ENT:SpawnFunction(ply, tr)
	local SpawnPos=tr.HitPos+tr.HitNormal*20
	local ent=ents.Create("ent_jack_landmine_med")
	ent:SetAngles(Angle(0,0,0))
	ent:SetPos(SpawnPos)
	ent:Spawn()
	ent:Activate()
	local effectdata=EffectData()
	effectdata:SetEntity(ent)
	util.Effect("propspawn",effectdata)
	return ent
end
function ENT:Initialize()
	self.Entity:SetModel("models/props_pipes/pipe02_connector01.mdl")
	self.Entity:SetMaterial("models/mat_jack_monotone_abu")
	self.Entity:SetColor(Color(50,50,50))
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)	
	self.Entity:SetSolid(SOLID_VPHYSICS)
	self.Entity:DrawShadow(true)
	self.Exploded=false
	local phys = self.Entity:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
		phys:SetMass(20)
	end
	self:SetUseType(SIMPLE_USE)
	self.Armed=false
	self.NextBounceNoiseTime=0
	self:SetAngles(Angle(90,0,0))
end
function ENT:Detonate(toucher)
	if(self.Exploded)then return end
	self.Exploded=true
	local SelfPos=self:LocalToWorld(self:OBBCenter())
	--[[
	for key,found in pairs(ents.FindInSphere(SelfPos,50))do
		if(IsValid(found:GetPhysicsObject()))then
			if(found:GetPhysicsObject():GetMass()<1000)then
				constraint.RemoveAll(found)
				found:Fire("enablemotion",0,0)
			end
		end
	end
	--]]
	local EffectType=1
	local Traec=util.QuickTrace(self:GetPos(),Vector(0,0,-5),self.Entity)
	if(Traec.Hit)then
		if((Traec.MatType==MAT_DIRT)or(Traec.MatType==MAT_SAND))then
			EffectType=1
		elseif((Traec.MatType==MAT_CONCRETE)or(Traec.MatType==MAT_TILE))then
			EffectType=2
		elseif((Traec.MatType==MAT_METAL)or(Traec.MatType==MAT_GRATE))then
			EffectType=3
		elseif(Traec.MatType==MAT_WOOD)then
			EffectType=4
		end
	else
		EffectType=5
	end
	local plooie=EffectData()
	plooie:SetOrigin(SelfPos)
	plooie:SetScale(.75)
	plooie:SetRadius(EffectType)
	plooie:SetNormal(vector_up)
	--util.Effect("eff_jack_minesplode_l",plooie,true,true)
	util.Effect("eff_jack_minesplode",plooie,true,true)
	--ParticleEffect("50lb_main",SelfPos,vector_up:Angle())
	for key,playa in pairs(ents.FindInSphere(SelfPos,50))do
		local Clayus=playa:GetClass()
		if((playa:IsPlayer())or(playa:IsNPC())or(Clayuss=="prop_vehicle_jeep")or(Clayuss=="prop_vehicle_jeep")or(Clayus=="prop_vehicle_airboat"))then
			playa:SetVelocity(playa:GetVelocity()+vector_up*300)
		end
	end
	util.BlastDamage(self,self,SelfPos,120,math.Rand(65,85))
	util.BlastDamage(self,self,SelfPos+vector_up*100,70,math.Rand(55,75))
	util.ScreenShake(SelfPos,99999,99999,1.5,500)
	for key,object in pairs(ents.FindInSphere(SelfPos,75))do
		local Clayuss=object:GetClass()
		if not(Clayuss=="ent_jack_landmine_med")then
			if(IsValid(object:GetPhysicsObject()))then
				local PhysObj=object:GetPhysicsObject()
				PhysObj:ApplyForceCenter(vector_up*10000)
				PhysObj:AddAngleVelocity(VectorRand()*math.Rand(500,3000))
			end
		end
	end
	self.Entity:EmitSound("BaseExplosionEffect.Sound")
	self:EmitSound("snd_jack_fragsplodeclose.mp3",90,100)
	sound.Play("snd_jack_debris"..tostring(math.random(1,2))..".mp3",SelfPos,80,100)
	if(self)then self:Remove() end
end
function ENT:PhysicsCollide(data, physobj)
	if(data.HitEntity:IsWorld())then self:StartTouch(data.HitEntity) end
end
function ENT:StartTouch(ent)
	if(self.Armed)then
		self:Detonate(ent)
		local Tr=util.QuickTrace(self:GetPos(),Vector(0,0,-5),self.Entity)
		if(Tr.Hit)then
			util.Decal("Scorch",Tr.HitPos+Tr.HitNormal,Tr.HitPos-Tr.HitNormal)
		end
	else
		if(self.NextBounceNoiseTime<CurTime())then
			self.Entity:EmitSound("SolidMetal.ImpactSoft")
			self.NextBounceNoiseTime=CurTime()+0.4
		end
	end
end
function ENT:EndTouch(ent)
	if(self.Armed)then
		self:Detonate(ent)
		local Tr=util.QuickTrace(self:GetPos(),Vector(0,0,-5),self.Entity)
		if(Tr.Hit)then
			util.Decal("Scorch",Tr.HitPos+Tr.HitNormal,Tr.HitPos-Tr.HitNormal)
		end
	end
end
function ENT:OnTakeDamage(dmginfo)
	if(self)then self:TakePhysicsDamage(dmginfo) end
	if(self.Armed)then
		if(math.random(1,15)==3)then
			self:Detonate()
		end
	end
end
function ENT:Use(activator, caller)
	if not(self.Armed)then
		self:Arm()
		JackaGenericUseEffect(activator)
	end
end
function ENT:Arm()
	self.Armed=true
	self:EmitSound("snd_jack_pinpull.mp3",65,100)
	self:EmitSound("snd_jack_pinpull.mp3",65,100)
	self:SetDTBool(0,true)
end
