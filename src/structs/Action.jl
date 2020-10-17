"""
    Action

Defines what is drawn in a defined frame range.

# Fields
- `frames::Frames`: A range of frames for which the `Action` is called
- `id::Union{Nothing, Symbol}`: An id which can be used to save the result of `func`
- `func::Function`: The drawing function which draws something on the canvas.
    It gets called with the arguments `video, action, frame`
- `anim::Animation`: defines the interpolation function for the transitions
- `transitions::Vector{Transition}` a list of transitions
    which can be performed before the function gets called.
- `internal_transitions::Vector{InternalTransition}`:
    Similar to `transitions` but holds the concrete information whereas `Transition` can
    hold links to other actions which need to be computed first.
    See [`compute_transition!`](@ref)
- `opts::Any` can hold any options defined by the user
- `change_keywords::Vector{Pair}`
"""
mutable struct Action <: AbstractAction
    frames::Frames
    id::Union{Nothing,Symbol}
    func::Function
    anim::Animation
    transitions::Vector{Transition}
    internal_transitions::Vector{InternalTransition}
    subactions::Vector{SubAction}
    current_setting::ActionSetting
    opts::Dict{Symbol,Any}
    change_keywords::Dict{Symbol,Any}
end

"""
    CURRENT_ACTION

holds the current action in an array to be declared as a constant
The current action can be accessed using CURRENT_ACTION[1]
"""
const CURRENT_ACTION = Array{Action,1}()

"""
    Action(frames, func::Function, args...)

The most simple form of an action (if there are no `args`/`kwargs`) just calls
`func(video, action, frame)` for each of the frames it is defined for.
`args` are defined it the next function definition and can be seen in action
    in this example [`javis`](@ref)
"""
Action(frames, func::Function, args...; kwargs...) =
    Action(frames, nothing, func, args...; kwargs...)

"""
    Action(frames_or_id::Symbol, func::Function, args...)

This function decides whether you wrote `Action(frames_symbol, ...)`,
    or `Action(id_symbol, ...)`
If the symbol `frames_or_id` is not a `FRAMES_SYMBOL` then it is used as an id_symbol.
"""
function Action(frames_or_id::Symbol, func::Function, args...; kwargs...)
    if frames_or_id in FRAMES_SYMBOL
        Action(frames_or_id, nothing, func, args...; kwargs...)
    else
        Action(:same, frames_or_id, func, args...; kwargs...)
    end
end

"""
    Action(func::Function, args...)

Similar to the above but uses the same frames as the action above.
"""
Action(func::Function, args...; kwargs...) =
    Action(:same, nothing, func, args...; kwargs...)

"""
    Action(frames, id::Union{Nothing,Symbol}, func::Function,
           transitions::Transition...; kwargs...)

Fallback constructor for an Action which doesn't define an animation.
A linear animation is assumed.
"""
function Action(
    frames,
    id::Union{Nothing,Symbol},
    func::Function,
    transitions::Transition...;
    kwargs...,
)

    Action(frames, id, func, easing_to_animation(linear()), transitions...; kwargs...)
end

"""
    Action(frames, id::Union{Nothing,Symbol}, func::Function, easing::Union{ReversedEasing, Easing},
           args...; kwargs...)

Fallback constructor for an Action which does define an animation using an easing function.

# Example
```
javis(
    video, [
        BackgroundAction(1:100, ground),
        Action((args...)->t(), sineio(), Translation(250, 0))
    ]
)
```
"""
function Action(
    frames,
    id::Union{Nothing,Symbol},
    func::Function,
    easing::Union{ReversedEasing,Easing},
    args...;
    kwargs...,
)

    Action(frames, id, func, easing_to_animation(easing), args...; kwargs...)
end

"""
    Action(frames, id::Union{Nothing,Symbol}, func::Function,
           transitions::Transition...; kwargs...)

# Arguments
- `frames`: defines for which frames this action is called
- `id::Symbol`: Is used if the `func` returns something which
    shall be accessible by other actions later
- `func::Function` the function that is called after the `transitions` are performed
- `transitions::Transition...` a list of transitions that are performed before
    the function `func` itself is called

The keywords arguments will be saved inside `.opts` as a `Dict{Symbol, Any}`
"""
function Action(
    frames,
    id::Union{Nothing,Symbol},
    func::Function,
    anim::Animation,
    transitions::Transition...;
    kwargs...,
)
    if isempty(CURRENT_VIDEO)
        throw(ErrorException("A `Video` must be defined before an `Action`"))
    end
    CURRENT_VIDEO[1].defs[:last_frames] = frames
    opts = Dict(kwargs...)
    subactions = SubAction[]
    if haskey(opts, :subactions)
        subactions = opts[:subactions]
        delete!(opts, :subactions)
    end
    Action(
        frames,
        id,
        func,
        anim,
        collect(transitions),
        [],
        subactions,
        ActionSetting(),
        opts,
        Dict{Symbol,Any}(),
    )
end

"""
    BackgroundAction(frames, func::Function, args...; kwargs...)

Create an Action where `in_global_layer` is set to true such that
i.e the specified color in the background is applied globally (basically a new default)
"""
function BackgroundAction(frames, func::Function, args...; kwargs...)
    Action(frames, nothing, func, args...; in_global_layer = true, kwargs...)
end

"""
    BackgroundAction(frames, id::Symbol, func::Function, args...; kwargs...)

Create an Action where `in_global_layer` is set to true and saves the return into `id`.
"""
function BackgroundAction(frames, id::Symbol, func::Function, args...; kwargs...)
    Action(frames, id, func, args...; in_global_layer = true, kwargs...)
end
