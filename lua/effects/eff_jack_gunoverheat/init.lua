function EFFECT:Init( data )
    local pos = data:GetOrigin()
    local scale = data:GetScale()
    local numParticles = 5 * scale
    local emitter = ParticleEmitter( data:GetOrigin() )

    for _ = 0, numParticles do
        if math.random( 1, 2 ) == 2 then
            local rollparticle = emitter:Add( "sprites/heatwave", pos + VectorRand() * math.Rand( 0, 3 ) * scale )

            if rollparticle then
                rollparticle:SetVelocity( VectorRand() * math.Rand( 0, 100 ) * scale )
                rollparticle:SetLifeTime( 0 )
                local life = math.Rand( 0.2, 0.4 ) * scale
                rollparticle:SetDieTime( life )
                rollparticle:SetColor( 255, 255, 255 )
                rollparticle:SetStartAlpha( 255 )
                rollparticle:SetEndAlpha( 0 )
                rollparticle:SetStartSize( 1 * scale )
                rollparticle:SetEndSize( 3 * scale )
                rollparticle:SetRoll( math.Rand( -360, 360 ) )
                rollparticle:SetRollDelta( math.Rand( -0.61, 0.61 ) * 5 )
                rollparticle:SetAirResistance( 2000 )
                rollparticle:SetGravity( Vector( 0, 0, 500 ) )
                rollparticle:SetCollide( false )
                rollparticle:SetLighting( false )
            end
        else
            local rollparticle = emitter:Add( "particle/smokestack", pos + VectorRand() * math.Rand( 0, 1 ) * scale )

            if rollparticle then
                rollparticle:SetVelocity( VectorRand() * math.Rand( 0, 10 ) * scale )
                rollparticle:SetLifeTime( 0 )
                local life = math.Rand( 0.125, 1 ) * scale ^ 0.25
                rollparticle:SetDieTime( life )
                rollparticle:SetColor( 0, 0, 0 )
                rollparticle:SetStartAlpha( math.Rand( 1, 20 ) )
                rollparticle:SetEndAlpha( 0 )
                rollparticle:SetStartSize( 1 * scale )
                rollparticle:SetEndSize( 5 * scale )
                rollparticle:SetRoll( math.Rand( -360, 360 ) )
                rollparticle:SetRollDelta( math.Rand( -0.61, 0.61 ) * 5 )
                rollparticle:SetAirResistance( 2000 )
                rollparticle:SetGravity( Vector( 0, 0, 2000 ) )
                rollparticle:SetCollide( false )
                rollparticle:SetLighting( true )
            end
        end
    end

    emitter:Finish()
end

function EFFECT:Think()
    return false
end
