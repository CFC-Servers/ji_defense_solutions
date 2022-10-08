--box
--By Jackarunda
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')
function ENT:SpawnFunction(ply,tr)
	local SpawnPos=tr.HitPos + tr.HitNormal*16
	local ent=ents.Create("ent_jack_ifftag")
	ent:SetPos(SpawnPos)
	ent:Spawn()
	ent:Activate()
	local effectdata=EffectData()
	effectdata:SetEntity(ent)
	util.Effect("propspawn",effectdata)
	return ent
end
function ENT:Initialize()
	self:SetModel("models/Items/AR2_Grenade.mdl")
	self:SetMaterial("models/mat_jack_scratchedmetal")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)	
	self:SetSolid(SOLID_VPHYSICS)
	self:DrawShadow(true)
	self:SetColor(Color(128,128,128,255))
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
		phys:SetMass(10)
	end
end
function ENT:PhysicsCollide(data, physobj)
	if((data.Speed>80)and(data.DeltaTime>0.2))then
		self:EmitSound("DryWall.ImpactHard")
	end
end
function ENT:OnTakeDamage(dmginfo)
	self:TakePhysicsDamage(dmginfo)
end
function ENT:Use(activator,caller)
	local Tagged=activator:GetNetworkedInt("JackyIFFTag")
	if((Tagged)and(Tagged!=0))then
		activator:PrintMessage(HUD_PRINTCENTER,"You have an IFF tag equipped already.")
	else
		JID.genericUseEffect(activator)
		activator:SetNetworkedInt("JackyIFFTag",math.random(1,100000))
		activator:PrintMessage(HUD_PRINTCENTER,"IFF tag equipped.")
		activator:EmitSound("snd_jack_tinyequip.mp3",75,100)
		self:Remove()
	end
end
function ENT:Think()
	--pfahahaha
end
function ENT:OnRemove()
	--aw fuck you
end
local function Death(ply)
	ply:SetNetworkedInt("JackyIFFTag",0)
end
hook.Add("DoPlayerDeath","JackyIFFTagRemoval",Death)