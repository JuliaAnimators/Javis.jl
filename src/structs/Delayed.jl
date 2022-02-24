"""
    DelayedPosition(obj, position, called)

This struct is used in place of a `Point` as a hook that will let you access the 
position of an object at the starting frame of an `Action`. One should not need to call
this directly, rather check [`delayed_pos`](@ref).
"""
mutable struct DelayedPosition <: Luxor.AbstractPoint
    obj::AbstractObject
    position::Point
    called::Bool
end

import Base: +, -

-(dp::DelayedPosition) = DelayedPosition(dp.obj, -get_position(dp), dp.called)

function +(dp::DelayedPosition, p::Point)
    DelayedPosition(dp.obj, get_position(dp) + p, dp.called)
end

+(p::Point, dp::DelayedPosition) = +(dp, p)

function -(dp::DelayedPosition, p::Point)
    return DelayedPosition(dp.obj, get_position(dp) - p, dp.called)
end

function -(p::Point, dp::DelayedPosition)
    return DelayedPosition(dp.obj, p - get_position(dp), dp.called)
end

function translate(pos::DelayedPosition)
    return translate(get_position(pos))
end


import Luxor: distance

distance(dp1::DelayedPosition, dp2::DelayedPosition) =
    distance(get_position(dp1), get_position(dp2))

function distance(dp::DelayedPosition, p::Point)
    return distance(get_position(dp), p)
end

distance(p::Point, dp::DelayedPosition) = distance(dp, p)

Base.:/(dp::DelayedPosition, k::Number) = get_position(dp) / k
