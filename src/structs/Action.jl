"""
    Action <: AbstractAction

A Action can be used in the keyword arguments of an [`Object`](@ref) to define small
sub objects on the object function, such as [`appear`](@ref).

A Action should not be created by hand but instead by using one of the constructors.

# Fields
- `frames::Frames`: the frames relative to the parent [`Object`](@ref)
- `anim::Animation`: defines the interpolation function for the transition
- `func::Function`: the function that gets called in each of those frames.
    Takes the following arguments: `video, object, action, rel_frame`
- `transition::Transition`: A [`Translation`](@ref)
- `internal_transition::InternalTransition`:
    A transition which stores the current transition for a specific frame.
- `keep::Bool` defines whether this Action is called even after the last frame it was defined on
- `defs::Dict{Symbol, Any}` any kind of definitions that are relevant for the action.
"""
mutable struct Action <: AbstractAction
    frames::Frames
    anim::Animation
    func::Function
    transition::Union{Nothing,Transition}
    internal_transition::Union{Nothing,InternalTransition}
    keep::Bool
    defs::Dict{Symbol,Any}
end

"""
    Action([frames], [Animation], func::Union{Function, Transition}; keep=true)

An `Action` gives an [`Object`](@ref) the opportunity to move, change color or much more.
It can be defined in many different ways.

# Arguments
- frames can be a `Symbol`, a `UnitRange` or a relative way to define frames see [`Rel`](@ref)
    - **Default:** If not defined it will be the same as the previous [`Action`](@ref) or
        if it's the first action then it will be applied for the whole length of the object.
    - It defines for which frames the action acts on the object.
    - These are defined in a relative fashion so `1:10` means the first ten frames of the object
        and **not** the first ten frames of the [`Video`](@ref)
- animation can be an easing function or animation which can be defined by Animations.jl
    - **Default:** The default is `linear()`
    - Possible simple easing functions is `sineio()` for more check
        [Animations.jl](https://jkrumbiegel.github.io/Animations.jl/stable/)
- func is either a `Function` or a `Transition`
    - This is the actual action that is applied to the parent object.
    - It can be either a general function which takes in the following four arguments
        - video, object, action, rel_frame
    - If you don't need them you can write `(args...)->your_function(arg1, arg2)`
    - You often don't need an own function and instead can use predefined functions like
        - [`appear`](@ref), [`disappear`](@ref), [`follow_path`](@ref)
    - Another way is to define a transition with
        - [`Translation`](@ref)
        - [`Rotation`](@ref)
        - [`Scaling`](@ref)

# Keywords
- `keep::Bool` defaults to `true` defines whether the [`Action`](@ref) is called
    even for frames after it's last defined.
    In more simple terms: If one has `Action(1:10, anim, translate())`
    It will get translated to the last position on frame `11:END_OF_OBJECT`.
    One can set `; keep = false` to turn off this behavior.

# Example
```julia
function ground(args...)
    background("black")
    sethue("white")
end

video = Video(500, 500)
BackgroundObject(1:100, ground)
obj = Object((args...)->circle(O, 50, :fill))
act!(obj, Action(1:20, appear(:fade)))
act!(obj, Action(21:50, Translation(50, 50)))
act!(obj, Action(51:80, Translation(-50, -50)))
act!(obj, Action(81:100, disappear(:fade)))
render(video; pathname="test.gif")
```
"""
Action(func::Union{Function,Transition}; keep = true) = Action(:same, func; keep = keep)

Action(
    frames,
    easing::Union{ReversedEasing,Easing},
    func::Union{Function,Transition};
    keep = true,
) = Action(frames, easing_to_animation(easing), func; keep = keep)

Action(frames, anim::Animation, transition::Transition; keep = true) =
    Action(frames, anim, (args...) -> 1, transition; keep = keep)

Action(anim::Animation, func::Union{Function,Transition}; keep = true) =
    Action(:same, anim, func; keep = keep)

Action(
    easing::Union{ReversedEasing,Easing},
    func::Union{Function,Transition};
    keep = true,
) = Action(:same, easing_to_animation(easing), func; keep = keep)

Action(frames, func::Union{Function,Transition}; keep = true) =
    Action(frames, easing_to_animation(linear()), func; keep = keep)

Action(frames, trans::Transition; keep = true) =
    Action(frames, easing_to_animation(linear()), (args...) -> 1, trans; keep = keep)

Action(frames, anim::Animation, func::Function; keep = true) =
    Action(frames, anim, func, nothing, nothing, keep, Dict{Symbol,Any}())

Action(frames, anim::Animation, func::Function, transition::Transition; keep = true) =
    Action(frames, anim, func, transition, nothing, keep, Dict{Symbol,Any}())


Base.copy(a::Action) = Action(
    copy(a.frames),
    a.anim,
    a.func,
    a.transition,
    a.internal_transition,
    a.keep,
    a.defs,
)
