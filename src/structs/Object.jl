"""
    Object

Defines what is drawn in a defined frame range.

# Fields
- `frames::Frames`: A range of frames for which the `Object` is called
- `id::Union{Nothing, Symbol}`: An id which can be used to save the result of `func`
- `func::Function`: The drawing function which draws something on the canvas.
    It gets called with the arguments `video, object, frame`
- `start_pos::Point` defines the origin the object gets translated to this point
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

"""
    Object(frames, func::Function, args...)

The most simple form of an object (if there are no `args`/`kwargs`) just calls
`func(video, object, frame)` for each of the frames it is defined for.
`args` are defined it the next function definition and can be seen in object
    in this example [`javis`](@ref)
"""
Object(frames, func::Function, args...; kwargs...) =
    Object(frames, nothing, func, args...; kwargs...)

"""
    Object(frames_or_id::Symbol, func::Function, args...)

This function decides whether you wrote `Object(frames_symbol, ...)`,
    or `Object(id_symbol, ...)`
If the symbol `frames_or_id` is not a `FRAMES_SYMBOL` then it is used as an id_symbol.
"""
function Object(frames_or_id::Symbol, func::Function, args...; kwargs...)
    if frames_or_id in FRAMES_SYMBOL
        Object(frames_or_id, nothing, func, args...; kwargs...)
    else
        Object(:same, frames_or_id, func, args...; kwargs...)
    end
end

"""
    Object(func::Function, args...)

Similar to the above but uses the same frames as the object above.
"""
Object(func::Function, args...; kwargs...) =
    Object(:same, nothing, func, args...; kwargs...)

Object(frames, id::Union{Nothing,Symbol}, func::Function; kwargs...) =
    Object(frames, id, func, O; kwargs...)

"""
    Object(frames, id::Union{Nothing,Symbol}, func::Function,
           start_pos::Point; kwargs...)

# Arguments
- `frames`: defines for which frames this object is called
- `id::Symbol`: Is used if the `func` returns something which
    shall be accessible by other objects later
- `func::Function` the function that is called after the `transition` is performed
- `start_pos::Point` the start position

The keywords arguments will be saved inside `.opts` as a `Dict{Symbol, Any}`
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

"""
    BackgroundObject(frames, func::Function, args...; kwargs...)

Create an Object where `in_global_layer` is set to true such that
i.e the specified color in the background is applied globally (basically a new default)
"""
function BackgroundObject(frames, func::Function, args...; kwargs...)
    Object(frames, nothing, func, args...; in_global_layer = true, kwargs...)
end

"""
    BackgroundObject(frames, id::Symbol, func::Function, args...; kwargs...)

Create an Object where `in_global_layer` is set to true and saves the return into `id`.
"""
function BackgroundObject(frames, id::Symbol, func::Function, args...; kwargs...)
    Object(frames, id, func, args...; in_global_layer = true, kwargs...)
end
