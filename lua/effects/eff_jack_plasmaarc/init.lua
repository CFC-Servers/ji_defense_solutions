function EFFECT:Init( data )
    self.StartPos = data:GetStart()
    self.EndPos = data:GetOrigin()
    self.Scayul = data:GetScale() ^ 0.5
    self.Delay = math.Clamp( 0.06 * data:GetScale(), 0.025, 0.06 )
    self.EndTime = CurTime() + self.Delay
    self:SetRenderBoundsWS( self.StartPos, self.EndPos )
end

function EFFECT:Think()
    if self.EndTime < CurTime() then
        return false
    else
        return true
    end
end

function EFFECT:Render()
    self:SetRenderBoundsWS( self.StartPos, self.EndPos )

    local Beamtwo = CreateMaterial( "xeno/beamgauss", "UnlitGeneric", {
        ["$basetexture"] = "sprites/spotlight",
        ["$additive"] = "1",
        ["$vertexcolor"] = "1",
        ["$vertexalpha"] = "1",
    } )

    render.SetMaterial( Beamtwo )
    render.DrawBeam( self.StartPos, self.EndPos, Lerp( ( self.EndTime - CurTime() ) / self.Delay, 0, 8 * self.Scayul ), 0, 0, Color( 100, 150, 255, 254 ) )
end
