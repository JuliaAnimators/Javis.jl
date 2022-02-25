"""
    compute_frames!(elements::Vector{UA}; parent=nothing)
        where UA<:Union{AbstractObject,AbstractAction}

Set elem.frames.frames to the computed frames for each elem in elements.
"""
function compute_frames!(
    elements::Vector{UA};
    parent = nothing,
    parent_counter = 0,
) where {UA<:Union{AbstractObject,AbstractAction}}
    available_subframes = typemin(Int):typemax(Int)
    if parent !== nothing
        last_frames = get_frames(parent)
        available_subframes = 1:length(get_frames(parent))
    else
        last_frames = nothing
    end
    is_first = true
    counter = 1
    for elem in elements
        # update (CURRENT/PREVIOUS)_(OBJECT/ACTION) and CURRENT_OBJECT_ACTION_TYPE
        if elem isa Object
            set_current_object(elem)
            empty!(CURRENT_ACTION)
        elseif elem isa Action
            set_current_action(elem)
        end
        set_current_action_type(elem)

        if last_frames === nothing && get_frames(elem) === nothing
            throw(ArgumentError("Frames need to be defined explicitly in the initial
                Object/Background or Action."))
        end
        if get_frames(elem) === nothing
            set_frames!(parent, elem, last_frames; is_first = is_first)
        end
        last_frames = get_frames(elem)
        if !(get_frames(elem) ⊆ available_subframes)
            @warn(
                "Action defined outside the frame range of the parent object.
          Action #$counter for Object #$parent_counter is defined for frames
          $(get_frames(elem)) but Object #$parent_counter exists only for $(available_subframes).
          (Info: Background is counted as Object #1)"
            )
        end
        is_first = false
        counter += 1
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
    # does interpolate between `to` and `from` and assumes we are at `from` already
    from = get_position(trans.from)
    to = get_position(trans.to)
    return t * (to - from)
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

function get_polypoint_at(points, t; pdist = polydistances(points))
    if t ≈ 0
        return points[1]
    end
    ind, surplus = nearestindex(pdist, t * pdist[end])

    nextind = mod1(ind + 1, length(points))
    overshootpoint = between(
        points[ind],
        points[nextind],
        surplus / distance(points[ind], points[nextind]),
    )
    return overshootpoint
end

"""
    set_previous_object(object::Object)

Set the `object` as `PREVIOUS_OBJECT`
"""
function set_previous_object(object::Object)
    if isempty(PREVIOUS_OBJECT)
        push!(PREVIOUS_OBJECT, object)
    else
        PREVIOUS_OBJECT[1] = object
    end
end

"""
    set_previous_action(action::Action)

Set the `action` as `PREVIOUS_ACTION`
"""
function set_previous_action(action::Action)
    if isempty(PREVIOUS_ACTION)
        push!(PREVIOUS_ACTION, action)
    else
        PREVIOUS_ACTION[1] = action
    end
end

"""
    set_current_object(object::Object)

Set the `object` as `CURRENT_OBJECT` and update `PREVIOUS_OBJECT`/`PREVIOUS_ACTION`
"""
function set_current_object(object::Object)
    update_previous_object_or_action()

    if isempty(CURRENT_OBJECT)
        push!(CURRENT_OBJECT, object)
    else
        CURRENT_OBJECT[1] = object
    end
end

"""
    set_current_action(action::Action)

Set the `action` as `CURRENT_ACTION` and update `PREVIOUS_OBJECT`/`PREVIOUS_ACTION`
"""
function set_current_action(action::Action)
    update_previous_object_or_action()

    if isempty(CURRENT_ACTION)
        push!(CURRENT_ACTION, action)
    else
        CURRENT_ACTION[1] = action
    end
end

"""
    update_previous_object_or_action() 

Update the `PREVIOUS_OBJECT` or `PREVIOUS_ACTION` depending on whether the 
last element was an object or an action. This is still saved in `CURRENT_OBJECT_ACTION_TYPE`.
"""
function update_previous_object_or_action()
    if !isempty(CURRENT_OBJECT_ACTION_TYPE)
        if CURRENT_OBJECT_ACTION_TYPE[1] == :Object
            !isempty(CURRENT_OBJECT) && set_previous_object(CURRENT_OBJECT[1])
        else
            !isempty(CURRENT_ACTION) && set_previous_action(CURRENT_ACTION[1])
        end
    end
end

"""
    set_current_action_type(t)

Set `CURRENT_OBJECT_ACTION_TYPE` to `:Object` or `:Action` depending 
on the type of `t`.
"""
function set_current_action_type(t)
    type = :Object
    if t isa AbstractAction
        type = :Action
    end
    if isempty(CURRENT_OBJECT_ACTION_TYPE)
        push!(CURRENT_OBJECT_ACTION_TYPE, type)
    else
        CURRENT_OBJECT_ACTION_TYPE[1] = type
    end
end

"""
    empty_CURRENT_constants()

empty all `CURRENT_` constants like `CURRENT_OBJECT`
"""
function empty_CURRENT_constants()
    empty!(CURRENT_VIDEO)
    empty!(CURRENT_OBJECT)
    empty!(CURRENT_ACTION)
    empty!(PREVIOUS_OBJECT)
    empty!(PREVIOUS_ACTION)
    empty!(CURRENT_OBJECT_ACTION_TYPE)
end

"""
    interpolateable(x::AbstractVector)

Return the vector in a datatype that is interpolateable. 
Currently only implemented is to change from `<:Integer` to `float`
"""
interpolateable(x::AbstractVector) = x
interpolateable(x::AbstractVector{<:Integer}) = float.(x)



"""
    _get_range(sizemargin, sizefrom)

For even `sizemargin` returns a range with values from `sizemargin ÷ 2 + 1` to `sizefrom - sizemargin ÷ 2`.
For odd `sizemargin` the left range value is increased by one.
"""
function _get_range(sizemargin, sizefrom)
    return if sizemargin == 0
        1:sizefrom
    elseif iseven(sizemargin)
        (sizemargin ÷ 2 + 1):(sizefrom - sizemargin ÷ 2)
    else
        (sizemargin ÷ 2 + 2):(sizefrom - sizemargin ÷ 2)
    end
end

"""
    crop(im, heightto, widthto)

Crops an imagematrix to size `(heightto, widthto)` around the center of the image.
"""
function crop(im, heightto, widthto)
    heightfrom, widthfrom = size(im)
    heightmargin, widthmargin = (heightfrom - heightto), (widthfrom - widthto)
    heightrange = _get_range(heightmargin, heightfrom)
    widthrange = _get_range(widthmargin, widthfrom)
    cropped_im = im[heightrange, widthrange]
    return cropped_im
end

"""
    _apply_and_reshape(func, im, template, args...)

Applies function `func` to imagematrix `im`. Afterwards reshapes the output 
cropping it or padding it to the size of `template`.
All the `args` are passed to func after `im` as arguments.
"""
function _apply_and_reshape(func, im, template, args...)
    newim = func(im, args...)
    template_size = size(template)
    if any(size(newim) .> template_size)
        newim = crop(newim, template_size...)
    end
    if any(size(newim) .< template_size)
        newim, _ = paddedviews(mean(im), newim, template)
    end
    return newim
end

"""
    default_postprocess(frame_image, frame, frames)

Returns its first argument. Used as effectless default for keywords
argument `postprocess_frame` in render function.
"""
function default_postprocess(frame_image, frame, frames)
    frame_image
end

"""
    _rescale_if_needed(frame_image, rescale_factor)

Converts `frame_image` values to RGB and if `rescale_factor` 
in `render` is different from 1.0 rescales the images matrix for 
faster rendering.
"""
function _convert_and_rescale_if_needed(frame_image, rescale_factor)
    frame_image = convert.(RGB, frame_image)
    return if !isone(rescale_factor)
        new_size = trunc.(Int, size(frame_image) .* rescale_factor)
        imresize(frame_image, new_size)
    else
        frame_image
    end
end

"""
    _postprocess(args...;kwargs...)

This function is used to perform the postprocessing inside the render function.
It does mainly two things:
 - Adds a memoization with checks for the frames to render. The keyword argument 
frames_memory, stores those imagematrices associated to frames that will reappear later
in the frames processing, so that when those will have to be rendered they can be taken 
from here instead, whereas those that do not reappear are discarded. (the check is performed
after each frame on those predent in the frames_memory)

 - Applies `postprocess_frame` as provided to `render` on each frame.
"""
function _postprocess(
    video,
    objects,
    frame;
    layers,
    frames_memory,
    postprocess_frame,
    frame_template,
    filecounter,
    frames,
    rescale_factor,
)
    # Memoized frame_image
    frame_image = if haskey(frames_memory, frame)
        frames_memory[frame]
    else
        frame_image = if frame == first(frames)
            frame_template
        else
            frame_image = _convert_and_rescale_if_needed(
                get_javis_frame(video, objects, frame; layers = layers),
                rescale_factor,
            )
        end
    end

    # Memoization container updating with cleaning
    if !(frame in frames[(filecounter + 1):end]) && haskey(frames_memory, frame)
        delete!(frames_memory, frame)
    elseif (frame in frames[(filecounter + 1):end]) && !haskey(frames_memory, frame)
        frames_memory[frame] = frame_image
    end

    return _apply_and_reshape(
        postprocess_frame,
        frame_image,
        frame_template,
        filecounter,
        frames,
    )
end
