"""
    Frames

Stores the actual computed frames and the user input
which can be `:same` or `RFrames(10)`.
The `frames` are computed in [`render`](@ref).
"""
mutable struct Frames{T}
    frames::Union{Nothing,UnitRange}
    user::T
end

Base.convert(::Type{Frames}, x) = Frames(nothing, x)
Base.convert(::Type{Frames}, x::UnitRange) = Frames(x, x)

Base.copy(f::Frames) = Frames(f.frames, f.user)

"""
    set_frames!(parent, elem, last_frames::UnitRange; is_first=false)

Compute the frames based on a.frames and `last_frames`.
Save the result in `a.frames.frames` which can be accessed via [`get_frames`](@ref).

# Arguments
- `parent` is either nothing or the Object for the Action
- `elem` is the Object or Action
- `last_frames` holds the frames of the previous object or action.
- `is_first` defines whether this is the first child of the parent (for actions)
"""
function set_frames!(parent, elem, last_frames::UnitRange; is_first = false)
    frames = elem.frames.user
    elem.frames.frames = get_frames(parent, elem, frames, last_frames; is_first = is_first)
end

"""
    get_frames(elem)

Return `elem.frames.frames` which holds the computed frames for the AbstractObject or AbstractAction `a`.
"""
function get_frames(elem)
    elem.frames.frames
end


"""
    get_frames(parent, elem, frames::Symbol, last_frames::UnitRange; is_first=false)

Get the frames based on a symbol defined in `FRAMES_SYMBOL` and the `last_frames`.
Throw `ArgumentError` if symbol is unknown
"""
function get_frames(parent, elem, frames::Symbol, last_frames::UnitRange; is_first = false)
    if frames === :same
        if elem isa AbstractAction && is_first
            return 1:length(last_frames)
        end
        return last_frames
    elseif frames === :all
        return 1:maximum(CURRENT_VIDEO[1].background_frames)
    else
        backtick_frame_symbol = map(x -> "`:$x`", FRAMES_SYMBOL)
        allowed_frames_str = join(backtick_frame_symbol, ", ", " and ")
        err_msg = "Currently the only symbols supported for defining frames are $allowed_frames_str."
        throw(ArgumentError(err_msg))
    end
end

"""
    get_frames(parent, elem, relative::RFrames, last_frames::UnitRang; is_first=falsee)

Return the frames based on a relative frames [`RFrames`](@ref) object using `RFrames.start` or `RFrames.last`.
"""
function get_frames(
    parent,
    elem,
    relative::RFrames,
    last_frames::UnitRange;
    is_first = false,
)
    start_frame =
        relative.start(parent, elem, relative, last_frames) + first(relative.frames)
    last_frame = relative.last(parent, elem, relative, last_frames)
    return start_frame:last_frame
end


"""
    get_frames(parent, elem, glob::GFrames, last_frames::UnitRange)

Return the frames based on a global frames [`GFrames`](@ref) object and the `last_frames`.
If `is_action` is false this is the same as defining the frames as just a unit range.
Inside an action it's now defined globally though.
"""
function get_frames(parent, elem, glob::GFrames, last_frames::UnitRange; is_first = false)
    if elem isa AbstractAction
        return glob.frames .- first(get_frames(parent)) .+ 1
    end
    return glob.frames
end
