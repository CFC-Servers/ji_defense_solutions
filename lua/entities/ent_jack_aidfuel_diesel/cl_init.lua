include( "shared.lua" )
language.Add( "env_fire", "Fire" )

function ENT:Initialize()
    self.Prettiness = ClientsideModel( "models/props_junk/gascan001a.mdl" )
    self.Prettiness:SetPos( self:GetPos() )
    self.Prettiness:SetParent( self )
    self.Prettiness:SetNoDraw( true )
    local Matricks = Matrix()
    Matricks:Scale( Vector( 1, .9, .65 ) )
    self.Prettiness:EnableMatrix( "RenderMultiply", Matricks )
    self.Prettiness:SetMaterial( "models/mat_jack_aidfuel_diesel" )
end

function ENT:Draw()
    self.Prettiness:SetRenderOrigin( self:GetPos() )
    local Ang = self:GetAngles()
    Ang:RotateAroundAxis( Ang:Up(), 90 )
    self.Prettiness:SetRenderAngles( Ang )

    self.Prettiness:DrawModel()
end

language.Add( "ent_jack_aidfuel_diesel", "Diesel Fuel Can" )
