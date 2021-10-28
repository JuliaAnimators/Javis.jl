mutable struct DelayedPosition
    obj::AbstractObject
    position::Union{Nothing,Point}
    called::Bool
end
