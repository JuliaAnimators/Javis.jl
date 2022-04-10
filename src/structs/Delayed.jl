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

import Base: +, -, *, /
import Luxor: distance

*(k::Number, dp::DelayedPosition) = DelayedPosition(dp.obj, k * get_position(dp), dp.called)
*(dp::DelayedPosition, k::Number) = *(k, dp)
/(dp::DelayedPosition, k::Number) = DelayedPosition(dp.obj, get_position(dp) / k, dp.called)
-(dp::DelayedPosition) = DelayedPosition(dp.obj, -get_position(dp), dp.called)
-(dp::DelayedPosition, p::Point) = DelayedPosition(dp.obj, get_position(dp) - p, dp.called)
-(p::Point, dp::DelayedPosition) = DelayedPosition(dp.obj, p - get_position(dp), dp.called)
+(dp::DelayedPosition, p::Point) = DelayedPosition(dp.obj, get_position(dp) + p, dp.called)
+(p::Point, dp::DelayedPosition) = +(dp, p)

translate(pos::DelayedPosition) = translate(get_position(pos))

function distance(p1::T1, p2::T2) where {T1<:Luxor.AbstractPoint,T2<:Luxor.AbstractPoint}
    return distance(get_position(p1), get_position(p2))
end
