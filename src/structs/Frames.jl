"""
    Frames

Stores the actual computed frames and the user input
which can be `:same` or `Rel(10)`.
The `frames` are computed in `javis`.
"""
mutable struct Frames{T}
    frames::Union{Nothing,UnitRange}
    user::T
end

Base.convert(::Type{Frames}, x::Union{Symbol,Rel}) = Frames(nothing, x)
Base.convert(::Type{Frames}, x::UnitRange) = Frames(x, x)


"""
    set_frames!(a::Union{AbstractObject, AbstractAction}, last_frames::UnitRange)

Compute the frames based on a.frames and `last_frames`.
Save the result in `a.frames.frames` which can be accessed via [`get_frames`](@ref).
"""
function set_frames!(a::Union{AbstractObject,AbstractAction}, last_frames::UnitRange)
    frames = a.frames.user
    a.frames.frames = get_frames(frames, last_frames; is_action = a isa AbstractAction)
end

"""
    get_frames(a::Union{AbstractObject, AbstractAction}; is_action = false)

Return `a.frames.frames` which holds the computed frames for the AbstractObject or AbstractAction `a`.
"""
get_frames(a::Union{AbstractObject,AbstractAction}; is_action = false) = a.frames.frames

"""
    get_frames(frames::Symbol, last_frames::UnitRange; is_action = false)

Get the frames based on a symbol (currently only `same`) and the `last_frames`.
Throw `ArgumentError` if symbol is unknown
"""
function get_frames(frames::Symbol, last_frames::UnitRange; is_action = false)
    if frames === :same
        if is_action
            return 1:length(last_frames)
        end
        return last_frames
    else
        throw(ArgumentError("Currently the only symbol supported for defining frames is `:same`"))
    end
end

"""
    get_frames(frames::Rel, last_frames::UnitRange; is_action = false)

Return the frames based on a relative frames [`Rel`](@ref) object and the `last_frames`.
"""
function get_frames(frames::Rel, last_frames::UnitRange; is_action = false)
    start_frame = last(last_frames) + first(frames.rel)
    last_frame = last(last_frames) + last(frames.rel)
    return start_frame:last_frame
end
