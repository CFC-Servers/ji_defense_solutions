ENT.Type = "anim"
ENT.PrintName = "Barbed Wire"
ENT.Author = "Jackarunda"
ENT.Category = "J.I. Defense Solutions"
ENT.Spawnable = false

ENT.growDuration = 3
ENT.MaxStructuralIntegrity = 200
ENT.StructuralIntegrity = ENT.MaxStructuralIntegrity

hook.Add( "PhysgunPickup", "JID_CannotPickup_BarbedWire", function( _, pickedUp )
    if pickedUp:GetClass() == "ent_jack_barbedwire" then return false end

end )

function ENT:CanTool( tooler, _, toolname )
    if not IsValid( tooler ) then return end
    if not toolname or not isstring( toolname ) then return false end
    if string.find( toolname, "remove" ) then return true end

    tooler:PrintMessage( HUD_PRINTTALK, "You can only use \"removing\" tools on me." )

    return false

end

cleanup.Register( "Barbed Wire" )
