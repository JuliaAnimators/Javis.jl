"""
    compute_frames!(elements::Vector{UA}; last_frames=nothing)
        where UA<:Union{AbstractObject,AbstractAction}

Set elem.frames.frames to the computed frames for each elem in elements.
"""
function compute_frames!(
    elements::Vector{UA};
    last_frames = nothing,
) where {UA<:Union{AbstractObject,AbstractAction}}
    for elem in elements
        if last_frames === nothing && get_frames(elem) === nothing
            throw(ArgumentError("Frames need to be defined explicitly in the initial
                Object/BackgroundObject or Action."))
        end
        if get_frames(elem) === nothing
            set_frames!(elem, last_frames)
        end
        last_frames = get_frames(elem)
    end
end

"""
    get_current_setting()

Return the current setting of the current object
"""
function get_current_setting()
    object = CURRENT_OBJECT[1]
    return object.current_setting
end

"""
    get_interpolation(frames::UnitRange, frame)

Return a value between 0 and 1 which represents the relative `frame` inside `frames`.
"""
function get_interpolation(frames::UnitRange, frame)
    frame == last(frames) && return 1.0
    t = (frame - first(frames)) / (length(frames) - 1)
    # makes sense to only allow 0 ≤ t ≤ 1
    t = min(1.0, t)
end

"""
    get_interpolation(action::AbstractAction, frame)

Return the value of the `action.anim` Animation based on the relative frame given by
`get_interpolation(get_frames(action), frame)`
"""
function get_interpolation(action::AbstractAction, frame)
    t = get_interpolation(get_frames(action), frame)
    if !(action.anim.frames[end].t ≈ 1)
        @warn "Animations should be defined from 0.0 to 1.0"
    end
    return interpolation_to_transition_val(at(action.anim, t), action.transition)
end


"""
    interpolation_to_transition_val(interpolation_val, Transition)

Returns the transition value for the given `interpolation_val`.
If the interpolation value is already of the correct form it just gets returned.
Otherwise the Transition function like `get_position` is called and the interpolated value
is calculated.
"""
interpolation_to_transition_val(t, ::Nothing) = t
interpolation_to_transition_val(t::Point, trans::Translation) = t
interpolation_to_transition_val(t::Float64, trans::Rotation) = t
interpolation_to_transition_val(t::Scale, trans::Scaling) = t

function interpolation_to_transition_val(t, trans::Translation)
    if !(t isa Number)
        println(t)
        println(typeof(t))
    end
    from = get_position(trans.from)
    to = get_position(trans.to)
    return from + t * (to - from)
end

function interpolation_to_transition_val(t, trans::Scaling)
    from = get_scale(trans.from)
    to = get_scale(trans.to)
    return from + t * (to - from)
end

function isapprox_discrete(val; atol = 1e-4)
    return isapprox(val, round(val); atol = atol)
end

function polywh(polygon::Vector{Vector{Point}})
    T = typeof(polygon[1][1].x)
    min_x = typemax(T)
    min_y = typemax(T)
    max_x = typemin(T)
    max_y = typemin(T)
    for poly in polygon
        for p in poly
            min_x = min(min_x, p.x)
            min_y = min(min_y, p.y)
            max_x = max(max_x, p.x)
            max_y = max(max_y, p.y)
        end
    end
    return max_x - min_x, max_y - min_y
end
