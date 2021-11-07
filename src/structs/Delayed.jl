"""
    DelayedPosition(obj, position, called)

This struct is used in place of a `Point` as a hook that will let you access the 
position of an object at the starting frame of an `Action`. One should not need to call
this directly, rather check [`delayed_pos`](@ref).
"""
mutable struct DelayedPosition
    obj::AbstractObject
    position::Point
    called::Bool
end

import Base: +, -

function +(dp::DelayedPosition, p::Point)
    DelayedPosition(dp.obj, dp.position + p, dp.called)
end

+(p::Point, dp::DelayedPosition) = +(dp, p)

function -(dp::DelayedPosition, p::Point)
    return DelayedPosition(dp.obj, dp.position - p, dp.called)
end

function -(p::Point, dp::DelayedPosition)
    return DelayedPosition(dp.obj, p - dp.position, dp.called)
end
