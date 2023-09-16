include( "shared.lua" )

function ENT:Initialize()
    self.Prettiness = ClientsideModel( "models/props_junk/propane_tank001a.mdl" )
    self.Prettiness:SetPos( self:GetPos() )
    self.Prettiness:SetParent( self )
    self.Prettiness:SetNoDraw( true )
    local Matricks = Matrix()
    Matricks:Scale( Vector( 1.8, 1.8, .275 ) )
    self.Prettiness:EnableMatrix( "RenderMultiply", Matricks )
    self.Prettiness:SetMaterial( "models/mat_jack_aidfuel_kerosene" )
end

function ENT:Draw()
    self.Prettiness:SetRenderOrigin( self:GetPos() + self:GetUp() * 5 )
    local Ang = self:GetAngles()
    Ang:RotateAroundAxis( Ang:Up(), 90 )
    self.Prettiness:SetRenderAngles( Ang )
    self.Prettiness:DrawModel()
end

language.Add( "ent_jack_aidfuel_kerosene", "Kerosene Canister" )
