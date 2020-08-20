"""
    compute_frames!(actions::Vector{AA}) where AA <: AbstractAction

Set action.frames.frames to the computed frames for each action in actions.
"""
function compute_frames!(actions::Vector{AA}) where AA <: AbstractAction
    last_frames = nothing
    for action in actions
        if last_frames === nothing && get_frames(action) === nothing
            throw(ArgumentError("Frames need to be defined explicitly, at least for the first frame."))
        end
        if get_frames(action) === nothing
            set_frames!(action, last_frames)
        end
        last_frames = get_frames(action)
    end
end
