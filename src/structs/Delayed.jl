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
