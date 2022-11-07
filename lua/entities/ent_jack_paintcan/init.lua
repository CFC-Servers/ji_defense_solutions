AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:SpawnFunction( ply, tr )
    local SpawnPos = tr.HitPos + tr.HitNormal * 16
    local ent = ents.Create( "ent_jack_paintcan" )
    ent:SetPos( SpawnPos )
    ent:SetNWEntity( "Owner", ply )
    ent:Spawn()
    ent:Activate()
    local effectdata = EffectData()
    effectdata:SetEntity( ent )
    util.Effect( "propspawn", effectdata )

    return ent
end

function ENT:Initialize()
    self:SetModel( "models/props_phx/wheels/magnetic_small_base.mdl" )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:DrawShadow( true )
    self:SetUseType( SIMPLE_USE )
    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
        phys:SetMass( 10 )
    end

    self.MenuOpen = false
    self:SetNWInt( "JackIndex", self:EntIndex() )
end

function ENT:PhysicsCollide( data, physobj )
    if data.Speed > 80 and data.DeltaTime > 0.2 then
        self:EmitSound( "Computer.ImpactHard" )
    end
end

function ENT:OnTakeDamage( dmginfo )
    self:TakePhysicsDamage( dmginfo )
end

function ENT:Use( activator, caller )
    if not self.MenuOpen then
        self.MenuOpen = true
        umsg.Start( "JackaSprayPaintOpenMenu", activator )
        umsg.Entity( self )
        umsg.End()
    end
end

local function canPaint( ent, ply )
    if not IsValid( ent ) then return false end
    if ent:IsPlayer() then return false end
    if ent:CPPIGetOwner() ~= ply then return false end
    if ent:IsWorld() then return false end
    if ent:GetClass() == "ent_jack_paintcan" then return false end
    return true
end

function ENT:PaintObject( ply, col )
    local toPaint
    local distance = 100000

    for _, found in pairs( ents.FindInSphere( self:GetPos(), 100 ) ) do
        if found ~= self and canPaint( found, ply ) and found:GetColor() ~= col then
            local pos = found:GetPos()
            if pos:Distance( self:GetPos() ) < distance then
                distance = pos:Distance( self:GetPos() )
                toPaint = found
            end
        end
    end

    if not toPaint then return end

    if IsValid( toPaint ) then
        self:EmitSound( "snd_jack_spraypaint.mp3" )

        timer.Simple( .2, function()
            if not IsValid( toPaint ) then return end
            toPaint:SetColor( col )
        end )

        toPaint:EmitSound( "snd_jack_spraypaint.mp3" )
        local Poof = EffectData()
        Poof:SetOrigin( toPaint:LocalToWorld( toPaint:OBBCenter() ) )
        Poof:SetScale( 5 )
        Poof:SetStart( Vector( col.r, col.g, col.b ) )
        util.Effect( "eff_jack_spraypaint", Poof, true, true )
        self:Remove()
    end
end

local function MenuClosePaint( ... )
    local args = { ... }

    local ply = args[1]
    local self = Entity( tonumber( args[3][1] ) )
    local R = tonumber( args[3][2] )
    local G = tonumber( args[3][3] )
    local B = tonumber( args[3][4] )
    self.MenuOpen = false
    self:PaintObject( ply, Color( R, G, B ) )
end

concommand.Add( "JackaSprayPaintGo", MenuClosePaint )

local function MenuClose( ... )
    local args = { ... }

    local self = Entity( tonumber( args[3][1] ) )
    self.MenuOpen = false
end

concommand.Add( "JackaSprayPaintClose", MenuClose )
