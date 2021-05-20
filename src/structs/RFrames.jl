"""
    RFrames

Ability to define frames in a relative fashion.

# Example
```
Background(1:100, ground)
Object(1:90, (args...)->circ("red"))
Object(RFrames(10), (args...)->circ("blue"))
Object((args...)->circ("red"))
```
is the same as
```
Background(1:100, ground)
Object(1:90, (args...)->circ("red"))
Object(91:100, (args...)->circ("blue"))
Object(91:100, (args...)->circ("red"))
```

# Fields
- frames::UnitRange defines the frames in a relative fashion.
- start::Function returns the reference global frame for the relative frame range.
- last::Function returns the ending global frame for the relative frame range (if specified ignores the ending for `frames` feild).
"""
struct RFrames
    frames::UnitRange
    start::Function
    last::Function
end

"""
    RFrames(i::Int)

Shorthand for RFrames(1:i)
"""
RFrames(i::Int) = RFrames(1:i, nothing, nothing)
RFrames(i::UnitRange) = RFrames(i, nothing, nothing)

"""
    RFrames(i::UnitRange, s::Function)

Shorthand for relative frame range with the reference start frame computed during rendering i.e. `(first(i)+s):(last(i)+s)`.
"""
RFrames(i::UnitRange, s::Function) = RFrames(i, s, nothing)

"""
    RFrames(s::Function, e::Function)

Shorthand for relative frame range with both reference start and global end frame computed during rendering.
"""
RFrames(s::Function, e::Function) = RFrames(0:0, s, e)

"""
    RFrames(frames::UnitRange, start, last)

# Arguments
- frames is a `UnitRange` defining the frame window relative to the starting reference frame
- start can be a `Function` or `nothing` to support the shorthands
    - This returns the starting reference frame number to which `frames` must be added.
    - Examples are [`prev_start()`](@ref), [`prev_last()`](@ref) etc.
- last can be a `Function` or `nothing` to support the shorthands
    - This directly returns the last frame number. If specified, the end frame calculated using `start` above is ignored.
    - Examples are [`parent_last()`](@ref), [`default_last()`](@ref) etc.
"""
function RFrames(frames::UnitRange, start, last)
    if start === nothing
        start = prev_last()
    end
    if last === nothing
        last = default_last()
    end
    return RFrames(frames, start, last)
end

"""
    default_last()

Calculate last frame relative to end of previous frame range.
"""
function default_last()
    (parent, elem, relative, last_frames) ->
        _default_last(parent, elem, relative, last_frames)
end

function _default_last(parent, elem, relative, last_frames)
    return relative.start(parent, elem, relative, last_frames) + last(relative.frames)
end

"""
    prev_start()

Return start frame of the previous object/action.
"""
function prev_start()
    (parent, elem, relative, last_frames) ->
        _prev_start(parent, elem, relative, last_frames)
end

function _prev_start(parent, elem, relative, last_frames)
    return first(last_frames)
end

"""
    prev_start(o::AbstractObject)

Return start frame of the specified previous object.
"""
function prev_start(o::AbstractObject)
    (args...) -> _prev_start(o)
end

function _prev_start(o::AbstractObject)
    return first(get_frames(o))
end

"""
    prev_last()

Return last frame of the previous object/action.
"""
function prev_last()
    (parent, elem, relative, last_frames) -> _prev_last(parent, elem, relative, last_frames)
end

function _prev_last(parent, elem, relative, last_frames)
    return last(last_frames)
end

"""
    prev_last(o::AbstractObject)

Return last frame of the specified previous object.
"""
function prev_last(o::AbstractObject)
    (args...) -> _prev_last(o)
end

function _prev_last(o::AbstractObject)
    return last(get_frames(o))
end

"""
    parent_start()

Return start frame of the parent object (for actions) or background (for objects).
"""
function parent_start()
    (parent, elem, relative, last_frames) ->
        _parent_start(parent, elem, relative, last_frames)
end

function _parent_start(parent, elem, relative, last_frames)
    if elem isa AbstractObject
        return first(get_frames(CURRENT_VIDEO[1].objects[1]))
    else
        return 1
    end
end

"""
    parent_last()

Return last frame of the parent object (for actions) or background (for objects).
"""
function parent_last()
    return (parent, elem, relative, last_frames) ->
        _parent_last(parent, elem, relative, last_frames)
end

function _parent_last(parent, elem, relative, last_frames)
    if elem isa AbstractObject
        return last(get_frames(CURRENT_VIDEO[1].objects[1]))
    else
        return last(get_frames(parent)) - first(get_frames(parent)) + 1
    end
end
