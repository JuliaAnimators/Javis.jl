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
Base.convert(::Type{Frames}, x::Frames) = x
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
    get_frames(parent, elem, relative::RFrames, last_frames::UnitRange; is_first=falsee)

Return the frames based on a relative frames [`RFrames`](@ref) object and the `last_frames`.
"""
function get_frames(
    parent,
    elem,
    relative::RFrames,
    last_frames::UnitRange;
    is_first = false,
)
    start_frame = last(last_frames) + first(relative.frames)
    last_frame = last(last_frames) + last(relative.frames)
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

"""
    function get_frames(parent, elem, func_frames::Function, last_frames::UnitRange; is_first = false)

Return the frames based on a specified function. The function `func_frames` is simply evaluated 
"""
function get_frames(
    parent,
    elem,
    func_frames::Function,
    last_frames::UnitRange;
    is_first = false,
)
    return func_frames()
end

"""
    prev_start()

The start frame of the previous object or for an action the start frame of the parental object.
Can be used to provide frame ranges like:
```
@Frames(prev_start(), 10)
```
"""
function prev_start()
    if CURRENT_OBJECT_ACTION_TYPE[1] == :Object
        PREVIOUS_OBJECT[1].frames.frames[1]
    else
        PREVIOUS_ACTION[1].frames.frames[1]
    end
end

"""
    prev_end()

The end frame of the previous object or for an action the end frame of the parental object.
Can be used to provide frame ranges like:
```
@Frames(prev_end()-10, 10)
```
"""
function prev_end()
    if CURRENT_OBJECT_ACTION_TYPE[1] == :Object
        PREVIOUS_OBJECT[1].frames.frames[end]
    else
        PREVIOUS_ACTION[1].frames.frames[end]
    end
end

startof(oa::Union{AbstractAction,AbstractObject}) = oa.frames.frames[1]
endof(oa::Union{AbstractAction,AbstractObject}) = oa.frames.frames[end]

"""
    @Frames(start, len)
    @Frames(start, stop=)

Can be used to define frames using functions like [`prev_start`](@ref) or [`prev_end`](@ref)

# Example
```julia
red_circ = Object(1:90, (args...)->circ("red"))
blue_circ = Object(@Frames(prev_start()+20, 70), (args...)->circ("blue"))
blue_circ = Object(@Frames(prev_start()+20, stop=90), (args...)->circ("blue"))
```
is the same as
```julia
red_circ = Object(1:90, (args...)->circ("red"))
blue_circ = Object(21:90, (args...)->circ("blue"))
blue_circ = Object(41:90, (args...)->circ("blue"))
```
"""
macro Frames(start, in_args...)
    args = []
    kwargs = Pair{Symbol,Any}[]
    kwarg_symbols = Symbol[]
    for el in in_args
        if Meta.isexpr(el, :(=))
            push!(kwargs, Pair(el.args...))
            push!(kwarg_symbols, el.args[1])
        else
            push!(args, el)
        end
    end
    stop_idx = findfirst(==(:stop), kwarg_symbols)
    if stop_idx !== nothing
        stop = kwargs[stop_idx][2]
        return esc(quote
            Javis.Frames(nothing, () -> ($start):($stop))
        end)
    elseif isempty(kwarg_symbols)
        esc(quote
            Javis.Frames(nothing, () -> ($start):($start + $(args[1]) - 1))
        end)
    end
end
