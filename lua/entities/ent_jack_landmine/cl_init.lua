include( "shared.lua" )

function ENT:Initialize()
    self.Pin = ClientsideModel( "models/props_trainstation/mount_connection001a.mdl" )
    self.Pin:SetPos( self:GetPos() )
    self.Pin:SetParent( self )
    self.Pin:SetModelScale( .1, 0 )
    self.Pin:SetNoDraw( true )
end

function ENT:Draw()
    self:DrawModel()
    self.Pin:SetRenderOrigin( self:GetPos() + self:GetRight() * 7 - self:GetForward() * 1.1 )
    local Ang = self:GetAngles()
    Ang:RotateAroundAxis( Ang:Right(), 90 )
    Ang:RotateAroundAxis( Ang:Up(), 90 )
    Ang:RotateAroundAxis( Ang:Forward(), 180 )
    self.Pin:SetRenderAngles( Ang )

    local planted = self:GetDTBool( 0 )
    if not planted then
        self.Pin:DrawModel()
    end

    if planted and not self.ColorApplied then
        local start = self:GetPos() + Vector( 0, 10, 0 ) + self:GetForward() * 10
        local endpos = self:GetPos() + Vector( 0, 10, 0 ) - self:GetForward() * 100

        local color = render.GetSurfaceColor( start, endpos )
        self:SetColor( color:ToColor() )
        self.ColorApplied = true
    end
end

function ENT:OnRemove()
end

language.Add( "ent_jack_landmine", "Landmine" )
