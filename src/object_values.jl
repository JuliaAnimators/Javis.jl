"""
    get_value(s::Symbol)

Get access to the value that got saved in `s` by a previous object.
If you want to access a position or angle check out [`get_position`](@ref)
and [`get_angle`](@ref).

# Returns
- `Any`: the value stored by a previous object.
"""
function get_value(s::Symbol)
    is_internal = first(string(s)) == '_'
    if is_internal
        internal_sym = Symbol(string(s)[2:end])
        if hasfield(ObjectSetting, internal_sym)
            return getfield(get_current_setting(), internal_sym)
        end
    end

    error("The internal symbol $s is not defined.")
end

function get_value(obj::AbstractObject)
    return obj.result[1]
end

"""
    val(x)

`val` is just a short-hand for [`get_value`](@ref)
"""
val(x) = get_value(x)

get_position(p::Point) = p
get_position(t::Transformation) = t.p

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

get_position(s::Symbol) = get_position(val(s))

"""
    pos(x)

`pos` is just a short-hand for [`get_position`](@ref)
"""
pos(x) = get_position(x)

# As it is just the number tuple -> return it
get_scale(x::Tuple{<:Number,<:Number}) = x

# If just the number -> return it as a tuple
get_scale(x::Number) = (x, x)

"""
    get_scale(obj::AbstractObject)

Get access to the scaling that got saved in a previous object.

# Returns
- `Scaling`: the scale stored by a previous object.
"""
function get_scale(obj::AbstractObject)
    return get_scale(obj.result[1])
end

get_scale(s::Symbol) = get_scale(val(s))

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

get_angle(s::Symbol) = get_angle(val(s))

"""
    ang(x)

`ang` is just a short-hand for [`get_angle`](@ref)
"""
ang(x) = get_angle(x)
