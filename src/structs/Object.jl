"""
    Object

Defines what is drawn in a defined frame range.

# Fields
- `frames::Frames`: A range of frames for which the `Object` is called
- `func::Function`: The drawing function which draws something on the canvas.
    It gets called with the arguments `video, object, frame`
- `start_pos::Point` defines the origin of the object. It gets translated to this point
- `actions::Vector{Action}` a list of actions applied to this object
- `current_setting`:: The current state of the object see [ObjectSetting](@ref)
- `opts::Any` can hold any options defined by the user
- `change_keywords::Dict{Symbol,Any}` the modified keywords changed by `change`
- `result::Vector` the result of the object (if something gets returned)
"""
struct Object <: AbstractObject
    frames::Frames
    func::Function
    start_pos::Point
    actions::Vector{Action}
    current_setting::ObjectSetting
    opts::Dict{Symbol,Any}
    change_keywords::Dict{Symbol,Any}
    result::Vector
end

"""
    CURRENT_OBJECT

holds the current object in an array to be declared as a constant
The current object can be accessed using CURRENT_OBJECT[1]
"""
const CURRENT_OBJECT = Array{Object,1}()

Object(func::Function, args...; kwargs...) = Object(:same, func, args...; kwargs...)

Object(frames, func::Function; kwargs...) = Object(frames, func, O; kwargs...)


"""
    Object([frames], func::Function, [start_pos]; kwargs...)

# Arguments
- frames can be a `Symbol`, a `UnitRange` or a relative way to define frames see [`Rel`](@ref)
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
javis(video, [
    BackgroundObject(1:100, ground),
    Object((args...)->circle(O, 50, :fill))
]; pathname="test.gif")
```

Here the [`BackgroundObject`](@ref) uses the named way of defining the function whereas
the circle object is defined in the anonymous function `(args...)->circle(O, 50, :fill)`.
It basically depends whether you want to have a simple Luxor object or something more complex.
"""
function Object(frames, func::Function, start_pos::Point; kwargs...)
    if isempty(CURRENT_VIDEO)
        throw(ErrorException("A `Video` must be defined before an `Object`"))
    end
    CURRENT_VIDEO[1].defs[:last_frames] = frames
    opts = Dict(kwargs...)
    object = Object(
        frames,
        func,
        start_pos,
        Action[],
        ObjectSetting(),
        opts,
        Dict{Symbol,Any}(),
        Any[nothing],
    )
    push!(CURRENT_VIDEO[1].objects, object)
    return object
end

function act!(object::AbstractObject, action::AbstractAction)
    push!(object.actions, copy(action))
end

function act!(object::AbstractObject, actions::Vector{<:AbstractAction})
    for action in actions
        act!(object, action)
    end
end

function act!(objects::Vector{<:AbstractObject}, action)
    for object in objects
        act!(object, action)
    end
end

"""
    BackgroundObject(frames, func)

The BackgroundObject is internally just an [`Object`](@ref) and can be defined the same way.
In contrast to an object this a `BackgroundObject` will change the global canvas and not just
a layer. Normally it's used to define defaults and the `background` color. See Luxor.background

# Example
```julia
function ground(args...)
    background("black")
    sethue("white")
end

video = Video(500, 500)
javis(video, [
    BackgroundObject(1:100, ground),
    Object((args...)->circle(O, 50, :fill))
]; pathname="test.gif")
```

This draws a white circle on a black background as `sethue` is defined for the global frame.
"""
function BackgroundObject(frames, func::Function, args...; kwargs...)
    Object(frames, func, args...; in_global_layer = true, kwargs...)
end
