local math = math
local VectorRand = VectorRand

function EFFECT:Init( data )
    local SelfPos = data:GetOrigin()
    local Scayul = data:GetScale()

    if self:WaterLevel() == 3 then
        local Splach = EffectData()
        Splach:SetOrigin( SelfPos )
        Splach:SetNormal( Vector( 0, 0, 1 ) )
        Splach:SetScale( 5 )
        util.Effect( "WaterSplash", Splach )

        return
    end

    local Emitter = ParticleEmitter( SelfPos )

    local Particle1 = Emitter:Add( "particles/flamelet" .. tostring( math.random( 1, 5 ) ), SelfPos + VectorRand() * math.Rand( 0, 1 ) )

    if Particle1 then
        Particle1:SetVelocity( VectorRand() * math.Rand( 0, 10 ) )
        Particle1:SetLifeTime( 0 )
        Particle1:SetDieTime( math.Rand( .1, .4 ) )
        local shadevariation = math.Rand( -10, 10 )
        Particle1:SetColor( math.Clamp( 255 + shadevariation + math.Rand( -5, 5 ), 0, 255 ), math.Clamp( 255 + shadevariation + math.Rand( -5, 5 ), 0, 255 ), math.Clamp( 255 + shadevariation + math.Rand( -5, 5 ), 0, 255 ) )
        Particle1:SetStartAlpha( math.Rand( 200, 255 ) )
        Particle1:SetEndAlpha( 0 )
        Particle1:SetStartSize( math.Rand( 3, 6 ) * Scayul )
        Particle1:SetEndSize( 0 )
        Particle1:SetRoll( math.Rand( -360, 360 ) )
        Particle1:SetRollDelta( math.Rand( -5, 5 ) )
        Particle1:SetAirResistance( 10 )
        Particle1:SetGravity( Vector( 0, 0, 1000 ) )
        Particle1:SetCollide( false )
        Particle1:SetLighting( false )
    end

    local Particle2 = Emitter:Add( "sprites/mat_jack_smoke" .. tostring( math.random( 1, 3 ) ), SelfPos + VectorRand() * math.Rand( 0, 3 ) )

    if Particle2 then
        Particle2:SetVelocity( Vector( 0, 0, 0 ) )
        Particle2:SetLifeTime( 0 )
        Particle2:SetDieTime( math.Rand( .5, 2 ) )
        local shadevariation = math.Rand( -10, 10 )
        Particle2:SetColor( math.Clamp( 255 + shadevariation + math.Rand( -5, 5 ), 0, 255 ), math.Clamp( 255 + shadevariation + math.Rand( -5, 5 ), 0, 255 ), math.Clamp( 255 + shadevariation + math.Rand( -5, 5 ), 0, 255 ) )
        Particle2:SetStartAlpha( math.Rand( 50, 100 ) )
        Particle2:SetEndAlpha( 0 )
        Particle2:SetStartSize( math.Rand( 0, 1 ) * Scayul )
        Particle2:SetEndSize( math.Rand( 10, 30 ) * Scayul )
        Particle2:SetRoll( math.Rand( -360, 360 ) )
        Particle2:SetRollDelta( math.Rand( -5, 5 ) )
        Particle2:SetAirResistance( 500 )
        Particle2:SetGravity( Vector( 0, 0, 400 ) + VectorRand() * math.Rand( 0, 300 ) )
        Particle2:SetCollide( false )
        Particle2:SetLighting( true )
    end

    Emitter:Finish()
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
end
