"""
    Object

Defines what is drawn in a defined frame range.

# Fields
- `frames::Frames`: A range of frames for which the `Object` is called
- `func::Function`: The drawing function which draws something on the canvas.
    It gets called with the arguments `video, object, frame`
- `start_pos::Union{Object, Point}` defines the origin of the object. It gets translated to this point
- `actions::Vector{AbstractAction}` a list of actions applied to this object
- `current_setting`:: The current state of the object see [`ObjectSetting`](@ref)
- `opts::Any` can hold any options defined by the user
- `change_keywords::Dict{Symbol,Any}` the modified keywords changed by `change`
- `result::Vector` the result of the object (if something gets returned)
"""
mutable struct Object <: AbstractObject
    frames::Frames
    func::Function
    start_pos::Union{Object,Point}
    actions::Vector{AbstractAction}
    current_setting::ObjectSetting
    opts::Dict{Symbol,Any}
    change_keywords::Dict{Symbol,Any}
    result::Vector
    jpaths::Any
end


"""
    CURRENT_OBJECT

holds the current object in an array to be declared as a constant
The current object can be accessed using CURRENT_OBJECT[1]
"""
const CURRENT_OBJECT = Array{Object,1}()

const PREVIOUS_OBJECT = Array{Object,1}()
const CURRENT_OBJECT_ACTION_TYPE = Array{Symbol,1}()

Object(func::Function, args...; kwargs...) = Object(:same, func, args...; kwargs...)

Object(frames, func::Function; kwargs...) = Object(frames, func, O; kwargs...)

"""
    Object([frames], func::Function, [start_pos]; kwargs...)

# Arguments
- frames can be a `Symbol`, a `UnitRange` or a relative way to define frames see [`RFrames`](@ref)
    - **Default:** If not defined it will be the same as the previous [`Object`](@ref).
    - **Important:** The first `Object` needs the frames specified as a `UnitRange`.
    - It defines for which frames the object is active
- func is a `Function` and the only required argument
    - This defines the actual object that gets drawn.
    - The function takes the following three arguments:
        - video, object, frame
    - If you don't need them you can write `(args...)->your_function(arg1, arg2)`

# Example
```julia
function ground(args...)
    background("black")
    sethue("white")
end

video = Video(500, 500)
Background(1:100, ground)
Object((args...)->circle(O, 50, :fill))
render(video; pathname="test.gif")
```

Here the [`Background`](@ref) uses the named way of defining the function whereas
the circle object is defined in the anonymous function `(args...)->circle(O, 50, :fill)`.
It basically depends whether you want to have a simple Luxor object or something more complex.
"""
function Object(frames, func::Function, start_pos::Union{Object,Point}; kwargs...)
    if isempty(CURRENT_VIDEO)
        throw(ErrorException("A `Video` must be defined before an `Object`"))
    end

    CURRENT_VIDEO[1].defs[:last_frames] = frames
    opts = Dict(kwargs...)

    if get(opts, :in_global_layer, false) && frames isa UnitRange
        CURRENT_VIDEO[1].background_frames =
            union(CURRENT_VIDEO[1].background_frames, frames)
    end


    object = Object(
        frames,
        func,
        start_pos,
        AbstractAction[],
        ObjectSetting(),
        opts,
        Dict{Symbol,Any}(),
        Any[nothing],
        JPath[],
    )

    # store the original object func 
    # for actions where the object fuction is mutated
    push!(object.opts, :original_func => func)

    # should the object be pushedsp to the video or a layer
    if PUSH_TO_LAYER[1]
        push!(CURRENT_LAYER[1].layer_objects, object)
    else
        push!(CURRENT_VIDEO[1].objects, object)
    end

    return object
end

"""
    act!

Adds an [`Action`] or a list of actions to an [`Object`](@ref) /
[`Layer`](@ref) or a list of objects/layers.
One key different to note is that an action is applied to a layer as a whole and not on the objects inside it.

# Example
```julia
Background(1:100, ground)
obj = Object((args...) -> rect(O, 50, 50, :fill), Point(100, 0))
act!(obj, Action(1:50, anim_scale(1.5)))
```

Here the scaling is applied to the rectangle for the first fifty frames.

# Options
1. A single object/layer and action:

   `act!(object::AbstractObject, action::AbstractAction)`
   - `object::AbstractObject` - the object the action is applied to
   - `action::AbstractAction` - the action applied to the object

2. A single object/layer and a list of actions:

   `act!(object::AbstractObject, action)`
   - `object::AbstractObject` - the object actions are applied to
   - `actions` - the actions applied to an object **Attention:** Will fail if `actions` is not iterable

3. A list of objects/layers and a list of actions:

   `act!(object::Vector{<:AbstractObject}, action::Vector{<:AbstractAction})`
   - `object::Vector{<:AbstractObject}` - the objects actions are applied to
   - `action::Vector{<:AbstractAction}` - the actions applied to the objects

Actions can be applied to a layer using a similar syntax
```julia
l1 = Javis.@Javis.Layer 20:60 100 100 Point(0, 0) begin
    obj = Object((args...)->circle(O, 50, :fill))
    act!(obj, Action(1:20, appear(:fade)))
end
    
act!(l1, anim_translate(Point(100, 100)))
```
"""
function act!(object::AbstractObject, action::AbstractAction)
    push!(object.actions, copy(action))
end

function act!(object::AbstractObject, actions)
    for action in actions
        act!(object, action)
    end
end

function act!(objects, action)
    for object in objects
        act!(object, action)
    end
end

"""
    Background(frames, func)

The `Background` is internally just an [`Object`](@ref) and can be defined the same way.
In contrast to an object this a `Background` will change the global canvas and not just
a layer. Normally it's used to define defaults and the `background` color. See Luxor.background

# Example
```julia
function ground(args...)
    background("black")
    sethue("white")
end

video = Video(500, 500)
Background(1:100, ground)
Object((args...)->circle(O, 50, :fill))
render(video; pathname="test.gif")
```

This draws a white circle on a black background as `sethue` is defined for the global frame.
"""
function Background(frames, func::Function, args...; kwargs...)
    if PUSH_TO_LAYER[1]
        Object(frames, func, args...; in_local_layer = true, kwargs...)
    else
        Object(frames, func, args...; in_global_layer = true, kwargs...)
    end
end
