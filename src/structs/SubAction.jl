"""
    SubAction <: AbstractAction

A SubAction can be used in the keyword arguments of an [`Action`](@ref) to define small
sub actions on the action function, such as [`appear`](@ref).

A SubAction should not be created by hand but instead by using one of the constructors.

# Fields
- `frames::Frames`: the frames relative to the parent [`Action`](@ref)
- `anim::Animation`: defines the interpolation function for the transitions
- `func::Function`: the function that gets called in each of those frames.
    Takes the following arguments: `video, action, subaction, rel_frame`
- `transitions::Vector{Transition}`: A list of transitions like [`Translation`](@ref)
- `internal_transitions::Vector{InternalTransition}`:
    A list of internal transitions which store the current transition for a specific frame.
- `defs::Dict{Symbol, Any}` any kind of definitions that are relevant for the subaction.
"""
mutable struct SubAction <: AbstractAction
    frames::Frames
    anim::Animation
    func::Function
    transitions::Vector{Transition}
    internal_transitions::Vector{InternalTransition}
    defs::Dict{Symbol,Any}
end

SubAction(transitions::Transition...) = SubAction(:same, transitions...)
SubAction(func::Function) = SubAction(:same, func)

"""
    SubAction(frames, easing::Union{ReversedEasing, Easing}, args...)

A `SubAction` can be defined with frames an
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
    BackgroundAction(1:100, ground),
    Action((args...)->circle(O, 50, :fill); subactions = [
        SubAction(1:20, sineio(), appear(:fade)),
        SubAction(81:100, disappear(:fade))
    ])
])
```

# Arguments
- `frames`: A list of frames for which the function should be called.
    - The frame numbers are relative to the parent [`Action`](@ref).
- `easing::Union{ReversedEasing, Easing}`: The easing function for `args...`
- `args...`: Either a function like [`appear`](@ref) or a Transformation
    like [`Translation`](@ref)
"""
SubAction(frames, easing::Union{ReversedEasing,Easing}, args...) =
    SubAction(frames, easing_to_animation(easing), args...)

SubAction(frames, anim::Animation, transition::Transition...) =
    SubAction(frames, anim, (args...) -> 1, transition...)

SubAction(easing::Union{ReversedEasing,Easing}, args...) =
    SubAction(:same, easing_to_animation(easing), args...)

SubAction(anim::Animation, args...) = SubAction(:same, anim, args...)
"""
    SubAction(frames, func::Function)

A `SubAction` can be defined with frames and a function
inside the `subactions` kwarg of an [`Action`](@ref).
In the following example a filled circle with radius 50 appears in the first 20 frames,
which means the opacity is increased from 0 to 1.0.
Then it stays at full opacity and disappears the same way in the last 20 frames.

# Example
javis(demo, [
    BackgroundAction(1:100, ground),
    Action((args...)->circle(O, 50, :fill); subactions = [
        SubAction(1:20, appear(:fade)),
        SubAction(81:100, disappear(:fade))
    ])
])

# Arguments
- `frames`: A list of frames for which the function should be called.
    - The frame numbers are relative to the parent [`Action`](@ref).
- `func::Function`: The function that gets called for the frames.
    - Needs to have four arguments: `video, action, subaction, rel_frame`
    - For [`appear`](@ref) and [`disappear`](@ref) a closure exists,
      such that `appear(:fade)` works.
"""
SubAction(frames, func::Function) = SubAction(frames, easing_to_animation(linear()), func)

"""
    SubAction(frames, trans::Transition...)

A `SubAction` can also be defined this way with having a list of transitions.
This is similar to defining transitions inside [`Action`](@ref)

In the following example a circle is faded in during the first 25 frames then moves to
- `Point(100, 20)` then to `Point(120, -20)` (the translations are added)
- and then back to the origin
In the last 25 frames it disappears from the world.

# Example
```
javis(demo, [
        BackgroundAction(1:200, ground_opacity),
        Action((args...)->circle(O, 50, :fill); subactions = [
            SubAction(1:25, appear(:fade)),
            SubAction(26:75, Translation(Point(100, 20))),
            SubAction(76:100, Translation(Point(20, -40))),
            SubAction(101:175, Translation(Point(-120, 20))),
            SubAction(176:200, disappear(:fade))
        ]),
    ], tempdirectory="current/images", pathname="current/circle_square.gif")
```

# Arguments
- `frames`: A list of frames for which the function should be called.
    - The frame numbers are relative to the parent [`Action`](@ref).
- `trans::Transition...`: A list of transitions that shall be performed.
"""
SubAction(frames, trans::Transition...) =
    SubAction(frames, easing_to_animation(linear()), (args...) -> 1, trans...)


SubAction(frames, anim::Animation, func::Function, transitions::Transition...) =
    SubAction(frames, anim, func::Function, collect(transitions), [], Dict{Symbol,Any}())
