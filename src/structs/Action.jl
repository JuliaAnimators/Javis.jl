"""
    Action <: AbstractAction

An Action can be used in the keyword arguments of an [`Object`](@ref) to define small
sub objects on the object function, such as [`appear`](@ref).

An Action should not be created by hand but instead by using one of the constructors.

# Fields
- `frames::Frames`: the frames relative to the parent [`Object`](@ref)
- `anim::Animation`: defines the interpolation function for the transition
- `func::Function`: the function that gets called in each of those frames.
    Takes the following arguments: `video, object, action, rel_frame`
- `transition::Union{Nothing, AbstractTransition}`
- `keep::Bool` defines whether this Action is called even after the last frame it was defined on
- `defs::Dict{Symbol, Any}` any kind of definitions that are relevant for the action.
"""
mutable struct Action <: AbstractAction
    frames::Frames
    anim::Animation
    func::Function
    transition::Union{Nothing,AbstractTransition}
    keep::Bool
    defs::Dict{Symbol,Any}
end

"""
    Action([frames], [Animation], func::Function; keep=true)

An `Action` gives an [`Object`](@ref) or a [`Layer`](@ref) the opportunity to move, change color or much more.
It can be defined in many different ways.

# Arguments
- frames can be a `Symbol`, a `UnitRange` or a [`GFrames`](@ref) to define them in a global way.
    - **Default:** If not defined it will be the same as the previous [`Action`](@ref) or
        if it's the first action then it will be applied for the whole length of the object.
    - It defines for which frames the action acts on the object.
    - These are defined in a relative fashion so `1:10` means the first ten frames of the object
        and **not** the first ten frames of the [`Video`](@ref)
- animation can be an easing function or animation which can be defined by Animations.jl
    - **Default:** The default is `linear()`
    - Possible simple easing functions is `sineio()` for more check
        [Animations.jl](https://jkrumbiegel.github.io/Animations.jl/stable/)
- func is the function that describes the actual action
    - It can be a general function which takes in the following four arguments
        - video, object, action, rel_frame
    - If you don't need them you can write `(args...)->your_function(arg1, arg2)`
    - You often don't need an own function and instead can use predefined functions like
        - [`appear`](@ref), [`disappear`](@ref), [`follow_path`](@ref)

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
Background(1:100, ground)
obj = Object((args...)->circle(O, 50, :fill))
act!(obj, Action(1:20, appear(:fade)))
act!(obj, Action(21:50, Translation(50, 50)))
act!(obj, Action(51:80, Translation(-50, -50)))
act!(obj, Action(81:100, disappear(:fade)))
render(video; pathname="test.gif")
```

Actions can be applied to a layer using a similar syntax
```julia
l1 = Javis.@Layer 20:60 100 100 Point(0, 0) begin
    obj = Object((args...)->circle(O, 50, :fill))
    act!(obj, Action(1:20, appear(:fade)))
end

act!(l2, anim_translate(Point(100, 100)))
```
"""
Action(func::Union{Function,AbstractTransition}; keep = true) =
    Action(:same, func; keep = keep)

Action(frames, easing::Union{ReversedEasing,Easing}, func::Function; keep = true) =
    Action(frames, easing_to_animation(easing), func; keep = keep)

function Action(
    frames,
    easing::Union{ReversedEasing,Easing},
    translation::Translation;
    keep = true,
)
    Action(
        frames,
        easing_to_animation(easing),
        translate();
        transition = translation,
        keep = keep,
    )
end

function Action(
    frames,
    easing::Union{ReversedEasing,Easing},
    rotation::Rotation;
    keep = true,
)
    anim = Animation([0.0, 1.0], [rotation.from, rotation.to], [easing])
    if rotation.center === nothing
        return Action(frames, anim, rotate(), transition = rotation; keep = keep)
    end
    Action(frames, anim, rotate_around(rotation.center); keep = keep)
end

function Action(frames, easing::Union{ReversedEasing,Easing}, scaling::Scaling; keep = true)
    Action(frames, easing_to_animation(easing), scale(); transition = scaling, keep = keep)
end

Action(anim::Animation, func::Function) = Action(:same, anim, func; keep = true)
Action(easing::Union{ReversedEasing,Easing}, func::Function; keep = true) =
    Action(:same, easing_to_animation(easing), func; keep = keep)

Action(frames, func::Union{Function,AbstractTransition}; keep = true) =
    Action(frames, linear(), func; keep = keep)

Action(frames, anim::Animation, func::Function; transition = nothing, keep = true) =
    Action(frames, anim, func, transition, keep, Dict{Symbol,Any}())

Base.copy(a::Action) = Action(copy(a.frames), a.anim, a.func, a.transition, a.keep, a.defs)
