"""
    create_internal_transitions!(object::AbstractObject)

For every translation an internal translation is added to `object.internal_transitions`.
Same is true for all other transitions.
"""
function create_internal_transitions!(object::AbstractObject)
    for trans in object.transitions
        if trans isa Translation
            push!(object.internal_transitions, InternalTranslation(O))
        elseif trans isa Rotation
            push!(object.internal_transitions, InternalRotation(0.0, O))
        elseif trans isa Scaling
            push!(object.internal_transitions, InternalScaling((1.0, 1.0)))
        end
    end
end

"""
    compute_transition!(object::AbstractObject, video::Video, frame::Int)

Update object.internal_transitions for the current frame number
"""
function compute_transition!(object::AbstractObject, video::Video, frame::Int)
    for (trans, internal_trans) in zip(object.transitions, object.internal_transitions)
        compute_transition!(internal_trans, trans, video, object, frame)
    end
end

"""
    compute_transition!(internal_rotation::InternalRotation, rotation::Rotation, video,
                        object::AbstractObject, frame)

Computes the rotation transformation for the `object`.
If the `Rotation` is given directly it uses the frame number for interpolation.
If `rotation` includes symbols the current definition of that look up is used for computation.
"""
function compute_transition!(
    internal_rotation::InternalRotation,
    rotation::Rotation,
    video,
    object::AbstractObject,
    frame,
)
    t = get_interpolation(object, frame)
    from, to, center = rotation.from, rotation.to, rotation.center

    center isa Symbol && (center = pos(center))
    from isa Symbol && (from = angle(from))
    to isa Symbol && (to = angle(to))

    internal_rotation.angle = from + t * (to - from)
    internal_rotation.center = center
end

"""
    compute_transition!(internal_translation::InternalTranslation, translation::Translation,
                        video, object::AbstractObject, frame)

Computes the translation transformation for the `object`.
If the `translation` is given directly it uses the frame number for interpolation.
If `translation` includes symbols the current definition of that symbol is looked up
and used for computation.
"""
function compute_transition!(
    internal_translation::InternalTranslation,
    translation::Translation,
    video,
    object::AbstractObject,
    frame,
)
    t = get_interpolation(object, frame)
    from, to = translation.from, translation.to

    from isa Symbol && (from = pos(from))
    to isa Symbol && (to = pos(to))

    internal_translation.by = from + t * (to - from)
end

"""
    compute_transition!(internal_translation::InternalScaling, translation::Scaling,
                        video, object::AbstractObject, frame)

Computes the scaling transformation for the `object`.
If the `scaling` is given directly it uses the frame number for interpolation.
If `scaling` includes symbols, the current definition of that symbol is looked up
and used for computation.
"""
function compute_transition!(
    internal_scale::InternalScaling,
    scale::Scaling,
    video,
    object::AbstractObject,
    frame,
)
    t = get_interpolation(object, frame)
    from, to = scale.from, scale.to

    if !scale.compute_from_once || frame == first(get_frames(object))
        from isa Symbol && (from = get_scale(from))
        if scale.compute_from_once
            scale.from = from
        end
    end
    to isa Symbol && (to = get_scale(to))
    internal_scale.scale = from .+ t .* (to .- from)
end

"""
    perform_transformation(object::AbstractObject)

Perform the transformations as described in object.internal_transitions
"""
function perform_transformation(object::AbstractObject)
    for trans in object.internal_transitions
        perform_transformation(trans)
    end
end

"""
    perform_transformation(trans::InternalTranslation)

Translate as described in `trans`.
"""
function perform_transformation(trans::InternalTranslation)
    translate(trans.by)
end

"""
    perform_transformation(trans::InternalRotation)

Translate and rotate as described in `trans`.
"""
function perform_transformation(trans::InternalRotation)
    translate(trans.center)
    rotate(trans.angle)
end

"""
    perform_transformation(trans::InternalScaling)

Scale as described in `trans`.
"""
function perform_transformation(trans::InternalScaling)
    scaleto(trans.scale...)
end
