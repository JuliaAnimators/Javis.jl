"""
    Object

Defines what is drawn in a defined frame range.

# Fields
- `frames::Frames`: A range of frames for which the `Object` is called
- `id::Union{Nothing, Symbol}`: An id which can be used to save the result of `func`
- `func::Function`: The drawing function which draws something on the canvas.
    It gets called with the arguments `video, object, frame`
- `start_pos::Point` defines the origin of the object. It gets translated to this point
- `actions::Vector{Action}` a list of actions applied to this object
- `current_setting`:: The current state of the object see [ObjectSetting](@ref)
- `opts::Any` can hold any options defined by the user
"""
struct Object <: AbstractObject
    frames::Frames
    id::Union{Nothing,Symbol}
    func::Function
    start_pos::Point
    actions::Vector{Action}
    current_setting::ObjectSetting
    opts::Dict{Symbol,Any}
end

"""
    CURRENT_OBJECT

holds the current object in an array to be declared as a constant
The current object can be accessed using CURRENT_OBJECT[1]
"""
const CURRENT_OBJECT = Array{Object,1}()

Object(frames, func::Function, args...; kwargs...) =
    Object(frames, nothing, func, args...; kwargs...)

function Object(frames_or_id::Symbol, func::Function, args...; kwargs...)
    if frames_or_id in FRAMES_SYMBOL
        Object(frames_or_id, nothing, func, args...; kwargs...)
    else
        Object(:same, frames_or_id, func, args...; kwargs...)
    end
end

Object(func::Function, args...; kwargs...) =
    Object(:same, nothing, func, args...; kwargs...)

Object(frames, id::Union{Nothing,Symbol}, func::Function; kwargs...) =
    Object(frames, id, func, O; kwargs...)


"""
    Object([frames], [id], func::Function, [start_pos]; kwargs...)

# Arguments
- frames can be a `Symbol`, a `UnitRange` or a relative way to define frames see [`Rel`](@ref)
    - **Default:** If not defined it will be the same as the previous [`Object`](@ref).
    - **Important:** The first `Object` needs the frames specified as a `UnitRange`.
    - It defines for which frames the object is active
- id gives the object a name (must be a Symbol or nothing)
    - **Default:** nothing (no information is saved)
    - This can be used to save the information the object returns.
      i.e the global position of the object in the current frame
    - You can check [`pos`](@ref) to receive that postion
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
function Object(
    frames,
    id::Union{Nothing,Symbol},
    func::Function,
    start_pos::Point;
    kwargs...,
)
    if isempty(CURRENT_VIDEO)
        throw(ErrorException("A `Video` must be defined before an `Object`"))
    end
    CURRENT_VIDEO[1].defs[:last_frames] = frames
    opts = Dict(kwargs...)
    Object(frames, id, func, start_pos, Action[], ObjectSetting(), opts)
end

function Base.:+(object::AbstractObject, action::AbstractAction)
    push!(object.actions, action)
    return object
end

function add!(object::AbstractObject, actions::Vector{<:AbstractAction})
    for action in actions
        object += action
    end
end

function add!(objects::Vector{<:AbstractObject}, actions::Vector{<:AbstractAction})
    for object in objects
        add!(object, actions)
    end
end


function BackgroundObject(frames, func::Function, args...; kwargs...)
    Object(frames, nothing, func, args...; in_global_layer = true, kwargs...)
end

function BackgroundObject(frames, id::Symbol, func::Function, args...; kwargs...)
    Object(frames, id, func, args...; in_global_layer = true, kwargs...)
end
