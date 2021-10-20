"""
    get_value(obj::AbstractObject)

Returns the value saved by `obj`
"""
function get_value(obj::AbstractObject)
    return obj.result[1]
end

"""
    val(x)

`val` is just a short-hand for [`get_value`](@ref)
"""
val(x) = get_value(x)

get_position(p::Point) = p
get_position(t::Transformation) = t.point

"""
    get_delayed_position(obj::Object)

In principle this is similar to [`get_position`](@ref) however, unlike that 
one it gets evaluated the first time is called after the rendering has started.
"""
function get_delayed_position(obj::Object)
    DelayedPosition(obj, nothing, false)
end

"""
    get_position(obj::Object)

Get access to the position that got saved in a previous object.

# Returns
- `Point`: the point stored by a previous object.

# Throws
- If the function of Object didn't return a Point or Transformation
"""
function get_position(obj::Object)
    return get_position(obj.result[1])
end

function get_position(p::DelayedPosition)
    if STARTED_RENDERING[1] && !p.called
        p.called = true
        p.position = get_position(p.obj)
    end
    return p.position
end

"""
    pos(x)

`pos` is just a short-hand for [`get_position`](@ref)
"""
pos(x) = get_position(x)

"""
    delayed_pos(x)

`delayed_pos` is just a short-hand for [`get_delayed_position`](@ref)
"""
delayed_pos(x) = get_delayed_position(x)

# As it is just the number tuple -> return it
get_scale(x::Tuple{<:Number,<:Number}) = Scale(x...)

# If just the number -> return it as a tuple
get_scale(x::Number) = Scale(x, x)

get_scale(s::Scale) = s
get_scale(t::Transformation) = Scale(t.scale.x, t.scale.y)

function get_scale(s::Symbol)
    @assert s == :current_scale
    cs = get_current_setting()
    return cs.current_scale
end

"""
    get_scale(obj::AbstractObject)

Get access to the scaling that got saved in a previous object.

# Returns
- `Scaling`: the scale stored by a previous object.
"""
function get_scale(obj::AbstractObject)
    return get_scale(obj.result[1])
end

"""
    scl(x)

`scl` is just a short-hand for [`get_scale`](@ref)
"""
scl(x) = get_scale(x)

get_angle(x::Number) = x
get_angle(t::Transformation) = t.angle


"""
    get_angle(obj::AbstractObject)

Get access to the angle that got saved in a previous object.

# Returns
- `Float64`: the angle stored by a previous object i.e via `return Transformation(p, angle)`
"""
function get_angle(obj::AbstractObject)
    return get_angle(obj.result[1])
end

"""
    ang(x)

`ang` is just a short-hand for [`get_angle`](@ref)
"""
ang(x) = get_angle(x)
