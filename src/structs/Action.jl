"""
    Action <: AbstractAction

A Action can be used in the keyword arguments of an [`Object`](@ref) to define small
sub objects on the object function, such as [`appear`](@ref).

A Action should not be created by hand but instead by using one of the constructors.

# Fields
- `frames::Frames`: the frames relative to the parent [`Object`](@ref)
- `anim::Animation`: defines the interpolation function for the transitions
- `func::Function`: the function that gets called in each of those frames.
    Takes the following arguments: `video, object, action, rel_frame`
- `transitions::Vector{Transition}`: A list of transitions like [`Translation`](@ref)
- `internal_transitions::Vector{InternalTransition}`:
    A list of internal transitions which store the current transition for a specific frame.
- `defs::Dict{Symbol, Any}` any kind of definitions that are relevant for the action.
"""
mutable struct Action <: AbstractAction
    frames::Frames
    anim::Animation
    func::Function
    transitions::Vector{Transition}
    internal_transitions::Vector{InternalTransition}
    defs::Dict{Symbol,Any}
end

Action(transitions::Transition...) = Action(:same, transitions...)
Action(func::Function) = Action(:same, func)

"""
    Action(frames, easing::Union{ReversedEasing, Easing}, args...)

A `Action` can be defined with frames an
[easing function](https://jkrumbiegel.github.io/Animations.jl/stable/#Easings-1) and either
a function or transformation(s).


# Example
In the following example a filled circle with radius 50 appears in the first 20 frames,
which means the opacity is increased from 0 to 1.0. The interpolation function used here is
sineio from [`Animations.jl`](https://github.com/jkrumbiegel/Animations.jl).
Then it stays at full opacity and disappears the same way in the last 20 frames using a
linear decay.

```julia
javis(demo, [
    BackgroundObject(1:100, ground),
    Object((args...)->circle(O, 50, :fill); actions = [
        Action(1:20, sineio(), appear(:fade)),
        Action(81:100, disappear(:fade))
    ])
])
```

# Arguments
- `frames`: A list of frames for which the function should be called.
    - The frame numbers are relative to the parent [`Object`](@ref).
- `easing::Union{ReversedEasing, Easing}`: The easing function for `args...`
- `args...`: Either a function like [`appear`](@ref) or a Transformation
    like [`Translation`](@ref)
"""
Action(frames, easing::Union{ReversedEasing,Easing}, args...) =
    Action(frames, easing_to_animation(easing), args...)

Action(frames, anim::Animation, transition::Transition...) =
    Action(frames, anim, (args...) -> 1, transition...)

Action(easing::Union{ReversedEasing,Easing}, args...) =
    Action(:same, easing_to_animation(easing), args...)

Action(anim::Animation, args...) = Action(:same, anim, args...)
"""
    Action(frames, func::Function)

A `Action` can be defined with frames and a function
inside the `actions` kwarg of an [`Object`](@ref).
In the following example a filled circle with radius 50 appears in the first 20 frames,
which means the opacity is increased from 0 to 1.0.
Then it stays at full opacity and disappears the same way in the last 20 frames.

# Example
javis(demo, [
    BackgroundObject(1:100, ground),
    Object((args...)->circle(O, 50, :fill); actions = [
        Action(1:20, appear(:fade)),
        Action(81:100, disappear(:fade))
    ])
])

# Arguments
- `frames`: A list of frames for which the function should be called.
    - The frame numbers are relative to the parent [`Object`](@ref).
- `func::Function`: The function that gets called for the frames.
    - Needs to have four arguments: `video, object, action, rel_frame`
    - For [`appear`](@ref) and [`disappear`](@ref) a closure exists,
      such that `appear(:fade)` works.
"""
Action(frames, func::Function) = Action(frames, easing_to_animation(linear()), func)

"""
    Action(frames, trans::Transition...)

A `Action` can also be defined this way with having a list of transitions.
This is similar to defining transitions inside [`Object`](@ref)

In the following example a circle is faded in during the first 25 frames then moves to
- `Point(100, 20)` then to `Point(120, -20)` (the translations are added)
- and then back to the origin
In the last 25 frames it disappears from the world.

# Example
```
javis(demo, [
        BackgroundObject(1:200, ground_opacity),
        Object((args...)->circle(O, 50, :fill); actions = [
            Action(1:25, appear(:fade)),
            Action(26:75, Translation(Point(100, 20))),
            Action(76:100, Translation(Point(20, -40))),
            Action(101:175, Translation(Point(-120, 20))),
            Action(176:200, disappear(:fade))
        ]),
    ], tempdirectory="current/images", pathname="current/circle_square.gif")
```

# Arguments
- `frames`: A list of frames for which the function should be called.
    - The frame numbers are relative to the parent [`Object`](@ref).
- `trans::Transition...`: A list of transitions that shall be performed.
"""
Action(frames, trans::Transition...) =
    Action(frames, easing_to_animation(linear()), (args...) -> 1, trans...)


Action(frames, anim::Animation, func::Function, transitions::Transition...) =
    Action(frames, anim, func::Function, collect(transitions), [], Dict{Symbol,Any}())
