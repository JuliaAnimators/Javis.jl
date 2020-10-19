"""
    create_internal_transition!(action::AbstractAction)

The translation gets a representative `action.internal_transition`.
"""
function create_internal_transition!(action::AbstractAction)
    trans = action.transition
    if trans isa Translation
        action.internal_transition = InternalTranslation(O)
    elseif trans isa Rotation
        action.internal_transition = InternalRotation(0.0, O)
    elseif trans isa Scaling
        action.internal_transition = InternalScaling((1.0, 1.0))
    end
end

"""
    compute_transition!(action::AbstractAction, video::Video, frame::Int)

Update action.internal_transition for the current frame number
"""
function compute_transition!(action::AbstractAction, video::Video, frame::Int)
    action.transition === nothing && return
    compute_transition!(action.internal_transition, action.transition, video, action, frame)
end

"""
    compute_transition!(internal_rotation::InternalRotation, rotation::Rotation, video,
                        action::AbstractAction, frame)

Computes the rotation transformation for the `action`.
If the `Rotation` is given directly it uses the frame number for interpolation.
If `rotation` includes symbols the current definition of that look up is used for computation.
"""
function compute_transition!(
    internal_rotation::InternalRotation,
    rotation::Rotation,
    video,
    action::AbstractAction,
    frame,
)
    t = get_interpolation(action, frame)
    from, to, center = rotation.from, rotation.to, rotation.center

    center isa Symbol && (center = pos(center))
    from isa Symbol && (from = angle(from))
    to isa Symbol && (to = angle(to))

    internal_rotation.angle = from + t * (to - from)
    internal_rotation.center = center
end

"""
    compute_transition!(internal_translation::InternalTranslation, translation::Translation,
                        video, action::AbstractAction, frame)

Computes the translation transformation for the `action`.
If the `translation` is given directly it uses the frame number for interpolation.
If `translation` includes symbols the current definition of that symbol is looked up
and used for computation.
"""
function compute_transition!(
    internal_translation::InternalTranslation,
    translation::Translation,
    video,
    action::AbstractAction,
    frame,
)
    t = get_interpolation(action, frame)
    from, to = translation.from, translation.to

    from isa Symbol && (from = pos(from))
    to isa Symbol && (to = pos(to))

    internal_translation.by = from + t * (to - from)
end

"""
    compute_transition!(internal_translation::InternalScaling, translation::Scaling,
                        video, action::AbstractAction, frame)

Computes the scaling transformation for the `action`.
If the `scaling` is given directly it uses the frame number for interpolation.
If `scaling` includes symbols, the current definition of that symbol is looked up
and used for computation.
"""
function compute_transition!(
    internal_scale::InternalScaling,
    scale::Scaling,
    video,
    action::AbstractAction,
    frame,
)
    t = get_interpolation(action, frame)
    from, to = scale.from, scale.to

    if !scale.compute_from_once || frame == first(get_frames(action))
        from isa Symbol && (from = get_scale(from))
        if scale.compute_from_once
            scale.from = from
        end
    end
    to isa Symbol && (to = get_scale(to))
    internal_scale.scale = from .+ t .* (to .- from)
end

"""
    perform_transformation(action::AbstractAction)

Perform the transformation as described in action.internal_transition
"""
function perform_transformation(action::AbstractAction)
    action.internal_transition === nothing && return
    perform_transformation(action.internal_transition)
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
