"""
    compute_frames!(actions::Vector{AA}; last_frames=nothing) where AA <: AbstractAction

Set action.frames.frames to the computed frames for each action in actions.
"""
function compute_frames!(
    actions::Vector{AA};
    last_frames = nothing,
) where {AA<:AbstractAction}
    for action in actions
        if last_frames === nothing && get_frames(action) === nothing
            throw(ArgumentError("Frames need to be defined explicitly in the initial
            AbstractAction like Action/BackgroundAction or SubAction."))
        end
        if get_frames(action) === nothing
            set_frames!(action, last_frames)
        end
        last_frames = get_frames(action)
    end
end

"""
    get_current_setting()

Return the current setting of the current action
"""
function get_current_setting()
    action = CURRENT_ACTION[1]
    return action.current_setting
end

"""
    get_interpolation(frames::UnitRange, frame)

Return a value between 0 and 1 which represents the relative `frame` inside `frames`.
"""
function get_interpolation(frames::UnitRange, frame)
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
    return at(action.anim, t)
end
