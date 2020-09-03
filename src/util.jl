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
