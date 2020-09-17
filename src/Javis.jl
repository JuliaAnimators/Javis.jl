module Javis

using Animations
using Cairo: CairoImageSurface, image
using ColorTypes: ARGB32
using FFMPEG
using Gtk
using GtkReactive
using Images
using LaTeXStrings
using LightXML
import Luxor
import Luxor: Point, @layer
using ProgressMeter
using Random
using VideoIO

const FRAMES_SYMBOL = [:same]

"""
    ReversedEasing

Will be used to reverse an easing inside [`easing_to_animation`](@ref).
Can be constructed from an easing function using [`rev`](@ref).
"""
struct ReversedEasing
    easing::Easing
end

"""
    rev(e::Easing)

Reverse an easing function such that `easing_to_animation` maps it to `[1.0, 0.0]` instead of `[0.0, 1.0]`.
An example can be seen in [`rotate`](@ref)
"""
rev(e::Easing) = ReversedEasing(e)

"""
    Video

Defines the video canvas for an animation.

# Fields
- `width::Int` the width in pixel
- `height::Int` the height in pixel
- `defs::Dict{Symbol, Any}` Some definitions which should be accessible throughout the video.
"""
mutable struct Video
    width::Int
    height::Int
    defs::Dict{Symbol,Any}
end

"""
    CURRENT_VIDEO

holds the current video in an array to be declared as a constant
The current video can be accessed using CURRENT_VIDEO[1]
"""
const CURRENT_VIDEO = Array{Video,1}()


"""
    Video(width, height)

Create a video with a certain `width` and `height` in pixel.
This also sets `CURRENT_VIDEO`.
"""
function Video(width, height)
    video = Video(width, height, Dict{Symbol,Any}())
    if isempty(CURRENT_VIDEO)
        push!(CURRENT_VIDEO, video)
    else
        CURRENT_VIDEO[1] = video
    end
    return video
end

"""
    Rel

Ability to define frames in a relative fashion.

# Example
```
 Action(1:100, ground; in_global_layer=true),
 Action(1:90, :red_ball, (args...)->circ(p1, "red"), Rotation(from_rot, to_rot)),
 Action(Rel(10), :blue_ball, (args...)->circ(p2, "blue"), Rotation(2π, from_rot, :red_ball)),
 Action((video, args...)->path!(path_of_red, pos(:red_ball), "red"))
```
is the same as
```
Action(1:100, ground; in_global_layer=true),
Action(1:90, :red_ball, (args...)->circ(p1, "red"), Rotation(from_rot, to_rot)),
Action(91:100, :blue_ball, (args...)->circ(p2, "blue"), Rotation(2π, from_rot, :red_ball)),
Action(91:100, (video, args...)->path!(path_of_red, pos(:red_ball), "red"))
```

# Fields
- rel::UnitRange defines the frames in a relative fashion.
"""
struct Rel
    rel::UnitRange
end

"""
    Rel(i::Int)

Shorthand for Rel(1:i)
"""
Rel(i::Int) = Rel(1:i)

"""
    Frames

Stores the actual computed frames and the user input
which can be i.e. `:same` or `Rel(10)`.
The `frames` are computed in `javis`.
"""
mutable struct Frames{T}
    frames::Union{Nothing,UnitRange}
    user::T
end

Base.convert(::Type{Frames}, x::Union{Symbol,Rel}) = Frames(nothing, x)
Base.convert(::Type{Frames}, x::UnitRange) = Frames(x, x)

"""
    Transformation

Defines a transformation which can be returned by an action to be accessible later.
See the `circ` function inside the [`javis`](@ref) as an example.

It can be accessed by another [`Action`])(@ref) using the symbol notation
like `:red_ball` in the example.

# Fields
- `p::Point`: the translation part of the transformation
- `angle::Float64`: the angle component of the transformation (in radians)
"""
mutable struct Transformation
    p::Point
    angle::Float64
end

abstract type Transition end
abstract type InternalTransition end

abstract type AbstractAction end

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
"""
mutable struct SubAction <: AbstractAction
    frames::Frames
    anim::Animation
    func::Function
    transitions::Vector{Transition}
    internal_transitions::Vector{InternalTransition}
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
    SubAction(frames, anim, func::Function, collect(transitions), [])

"""
    ActionSetting

The current settings of an [`Action`](@ref) which are saved in `action.current_setting`.

# Fields
- `line_width::Float64`: the current line width
- `mul_line_width::Float64`: the current multiplier for line width.
    The actual line width is then: `mul_line_width * line_width`
- `opacity::Float64`: the current opacity
- `mul_opacity::Float64`: the current multiplier for opacity.
    The actual opacity is then: `mul_opacity * opacity`
- `fontsize::Float64` the current font size
- `current_scale::Tuple{Float64, Float64}`: the current scale
- `desired_scale::Tuple{Float64, Float64}`: the new desired scale
- `mul_scale::Float64`: the multiplier for the new desired scale.
    The actual new scale is then: `mul_scale * desired_scale`
"""
mutable struct ActionSetting
    line_width::Float64
    mul_line_width::Float64 # the multiplier of line width is between 0 and 1
    opacity::Float64
    mul_opacity::Float64 # the multiplier of opacity is between 0 and 1
    fontsize::Float64
    # scale has three fields instead of just the normal two
    # current scale
    # desired scale and scale multiplier => `desired_scale*mul_scale` is the new desired scale
    # the scale change needs to be computed using `current_scale` and the desired scale
    current_scale::Tuple{Float64,Float64}
    desired_scale::Tuple{Float64,Float64}
    mul_scale::Float64 # the multiplier of scale is between 0 and 1
end

ActionSetting() = ActionSetting(1.0, 1.0, 1.0, 1.0, 10.0, (1.0, 1.0), (1.0, 1.0), 1.0)

"""
    update_ActionSetting!(as::ActionSetting, by::ActionSetting)

Set the fields of `as` to the same as `by`. Basically copying them over.
"""
function update_ActionSetting!(as::ActionSetting, by::ActionSetting)
    as.line_width = by.line_width
    as.mul_line_width = by.mul_line_width
    as.opacity = by.opacity
    as.mul_opacity = by.mul_opacity
    as.fontsize = by.fontsize
    as.current_scale = by.current_scale
    as.desired_scale = by.desired_scale
    as.mul_scale = by.mul_scale
end

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
    See [`compute_transformation!`](@ref)
- `opts::Any` can hold any options defined by the user
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
end

"""
    set_frames!(a::AbstractAction, last_frames::UnitRange)

Compute the frames based on a.frames and `last_frames`.
Save the result in `a.frames.frames` which can be accessed via [`get_frames`](@ref).
"""
function set_frames!(a::AbstractAction, last_frames::UnitRange)
    frames = a.frames.user
    a.frames.frames = get_frames(frames, last_frames)
end

"""
    get_frames(a::AbstractAction)

Return `a.frames.frames` which holds the computed frames for the AbstractAction `a`.
"""
get_frames(a::AbstractAction) = a.frames.frames

"""
    get_frames(frames::Symbol, last_frames::UnitRange)

Get the frames based on a symbol (currently only `same`) and the `last_frames`.
Throw `ArgumentError` if symbol is unknown
"""
function get_frames(frames::Symbol, last_frames::UnitRange)
    if frames === :same
        return last_frames
    else
        throw(ArgumentError("Currently the only symbol supported for defining frames is `:same`"))
    end
end

"""
    get_frames(frames::Rel, last_frames::UnitRange)

Return the frames based on a relative frames [`Rel`](@ref) object and the `last_frames`.
"""
function get_frames(frames::Rel, last_frames::UnitRange)
    start_frame = last(last_frames) + first(frames.rel)
    last_frame = last(last_frames) + last(frames.rel)
    return start_frame:last_frame
end

"""
    CURRENT_ACTION

holds the current action in an array to be declared as a constant
The current action can be accessed using CURRENT_ACTION[1]
"""
const CURRENT_ACTION = Array{Action,1}()

"""
    easing_to_animation(easing)

Converts an easing to an Animation with time goes from `0.0` to `1.0` and value from `0` to `1`.
"""
easing_to_animation(easing) = Animation(0.0, 0.0, easing, 1.0, 1.0)

"""
    easing_to_animation(rev_easing::ReversedEasing)

Converts an easing to an Animation with time goes from `0.0` to `1.0` and value from `1` to `0`.
"""
easing_to_animation(rev_easing::ReversedEasing) =
    Animation(0.0, 1.0, rev_easing.easing, 1.0, 0.0)

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

Similar to the above but uses the same as frames as the action above.
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

"""
    InternalTranslation <: InternalTransition

Saves a translation as described by [`Translation`](@ref) for the current frame.
Is part of the [`Action`](@ref) struct.
"""
mutable struct InternalTranslation <: InternalTransition
    by::Point
end

"""
    InternalRotation <: InternalTransition

Saves a rotation as described by [`Rotation`](@ref) for the current frame.
Is part of the [`Action`](@ref) struct.
"""
mutable struct InternalRotation <: InternalTransition
    angle::Float64
    center::Point
end

"""
    InternalScaling <: InternalTransition

Saves a scaling as described by [`Scaling`](@ref) for the current frame.
Is part of the [`Action`](@ref) struct.
"""
mutable struct InternalScaling <: InternalTransition
    scale::Tuple{Float64,Float64}
end

"""
    Translation <: Transition

Stores the `Point` or a link for the start and end position of the translation

# Fields
`from::Union{Point, Symbol}`: The start position or a link to the start position.
    See `:red_ball` in [`javis`](@ref)
`to::Union{Point, Symbol}`: The end position or a link to the end position
"""
struct Translation <: Transition
    from::Union{Point,Symbol}
    to::Union{Point,Symbol}
end

"""
    Translation(p::Union{Point, Symbol})

Create a `Translation(O, p)` such that a translation is done from the origin.
"""
Translation(p::Union{Point,Symbol}) = Translation(O, p)

"""
    Translation(x::Real, y::Real)

Create a `Translation(O, Point(x,y))` such that a translation is done from the origin.
Shorthand for writing `Translation(Point(x,y))`.
"""
Translation(x::Real, y::Real) = Translation(Point(x, y))

"""
    Rotation <: Transition

Stores the rotation similar to [`Translation`](@ref) with `from` and `to`
but also the rotation point.

# Fields
- `from::Union{Float64, Symbol}`: The start rotation or a link to it
- `to::Union{Float64, Symbol}`: The end rotation or a link to it
- `center::Union{Point, Symbol}`: The center of the rotation or a link to it.
"""
struct Rotation <: Transition
    from::Union{Float64,Symbol}
    to::Union{Float64,Symbol}
    center::Union{Point,Symbol}
end

"""
    Rotation(r::Union{Float64, Symbol})

Rotation as a transition from 0.0 to `r` .
Can be used as a short-hand.
"""
Rotation(r::Union{Float64,Symbol}) = Rotation(0.0, r)

"""
    Rotation(r::Union{Float64, Symbol}, center::Union{Point, Symbol})

Rotation as a transition from `0.0` to `r` around `center`.
Can be used as a short-hand for rotating around a `center` point.
"""
Rotation(r::Union{Float64,Symbol}, center::Union{Point,Symbol}) = Rotation(0.0, r, center)

"""
    Rotation(from, to)

Rotation as a transition from `from` to `to` (in radians) around the origin.
"""
Rotation(from, to) = Rotation(from, to, O)

"""
    Scaling <: Transition

Stores the scaling similar to [`Translation`](@ref) with `from` and `to`.

# Example
- Can be called with different constructors like:
```
Scaling(10) -> Scaling(CURRENT_SCALING, (10.0, 10.0))
Scaling(10, :my-scale) -> Scaling((10.0, 10.0), :my_scale)
Scaling(10, 2) -> Scaling((10.0, 10.0), (2.0, 2.0))
Scaling(10, (1,2)) -> Scaling((10.0, 10.0), (1.0, 2.0))
```

# Fields
- `from::Union{Tuple{Float64, Float64}, Symbol}`: The start scaling or a link to it
- `to::Union{Tuple{Float64, Float64}, Symbol}`: The end scaling or a link to it
- `compute_from_once::Bool`: Saves whether the from is computed for the first frame or
    every frame. Is true if from is `:_current_scale`.
"""
mutable struct Scaling <: Transition
    from::Union{Tuple{Float64,Float64},Symbol}
    to::Union{Tuple{Float64,Float64},Symbol}
    compute_from_once::Bool
end

Scaling(to::Tuple) = Scaling(:_current_scale, to, true)
Scaling(to::Real) = Scaling(:_current_scale, convert(Float64, to), true)
Scaling(to::Symbol) = Scaling(:_current_scale, to, true)

function Scaling(from::Real, to::Real, compute_from_once = false)
    from_flt = convert(Float64, from)
    to_flt = convert(Float64, to)
    Scaling((from_flt, from_flt), (to_flt, to_flt), compute_from_once)
end

function Scaling(from::Real, to, compute_from_once = false)
    flt = convert(Float64, from)
    Scaling((flt, flt), to, compute_from_once)
end

function Scaling(from, to::Real, compute_from_once = false)
    flt = convert(Float64, to)
    Scaling(from, (flt, flt), compute_from_once)
end

"""
    Line

A type to define a line by two points. Can be used i.e. in [`projection`](@ref)
We mean the mathematic definition of a continuous line and not a segment of a line.

# Fields
- `p1::Point`: start point
- `p2::Point`: second point to define the line
"""
struct Line
    p1::Point
    p2::Point
end

"""
    Base.:*(m::Array{Float64,2}, transformation::Transformation)

Convert the transformation to a matrix and multiplies m*trans_matrix.
Return a new Transformation
"""
function Base.:*(m::Array{Float64,2}, transformation::Transformation)
    θ = transformation.angle
    p = transformation.p
    trans_matrix = [
        cos(θ) -sin(θ) p.x
        sin(θ) cos(θ) p.y
        0 0 1
    ]
    res = m * trans_matrix
    return Transformation(Point(gettranslation(res)...), getrotation(res))
end

# cache such that creating svgs from LaTeX don't need to be created every time
# this is also used for test cases such that `tex2svg` doesn't need to be installed on Github Actions
const LaTeXSVG = Dict{LaTeXString,String}(
    L"\mathcal{O}(\log{n})" =>
        "<svg xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"8.413ex\" height=\"2.843ex\" style=\"vertical-align: -0.838ex;\" viewBox=\"0 -863.1 3622.2 1223.9\" role=\"img\" focusable=\"false\" xmlns=\"http://www.w3.org/2000/svg\" aria-labelledby=\"MathJax-SVG-1-Title\">\n<title id=\"MathJax-SVG-1-Title\">script upper O left-parenthesis log n right-parenthesis</title>\n<defs aria-hidden=\"true\">\n<path stroke-width=\"1\" id=\"E1-MJCAL-4F\" d=\"M308 428Q289 428 289 438Q289 457 318 508T378 593Q417 638 475 671T599 705Q688 705 732 643T777 483Q777 380 733 285T620 123T464 18T293 -22Q188 -22 123 51T58 245Q58 327 87 403T159 533T249 626T333 685T388 705Q404 705 404 693Q404 674 363 649Q333 632 304 606T239 537T181 429T158 290Q158 179 214 114T364 48Q489 48 583 165T677 438Q677 473 670 505T648 568T601 617T528 636Q518 636 513 635Q486 629 460 600T419 544T392 490Q383 470 372 459Q341 430 308 428Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-28\" d=\"M94 250Q94 319 104 381T127 488T164 576T202 643T244 695T277 729T302 750H315H319Q333 750 333 741Q333 738 316 720T275 667T226 581T184 443T167 250T184 58T225 -81T274 -167T316 -220T333 -241Q333 -250 318 -250H315H302L274 -226Q180 -141 137 -14T94 250Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-6C\" d=\"M42 46H56Q95 46 103 60V68Q103 77 103 91T103 124T104 167T104 217T104 272T104 329Q104 366 104 407T104 482T104 542T103 586T103 603Q100 622 89 628T44 637H26V660Q26 683 28 683L38 684Q48 685 67 686T104 688Q121 689 141 690T171 693T182 694H185V379Q185 62 186 60Q190 52 198 49Q219 46 247 46H263V0H255L232 1Q209 2 183 2T145 3T107 3T57 1L34 0H26V46H42Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-6F\" d=\"M28 214Q28 309 93 378T250 448Q340 448 405 380T471 215Q471 120 407 55T250 -10Q153 -10 91 57T28 214ZM250 30Q372 30 372 193V225V250Q372 272 371 288T364 326T348 362T317 390T268 410Q263 411 252 411Q222 411 195 399Q152 377 139 338T126 246V226Q126 130 145 91Q177 30 250 30Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-67\" d=\"M329 409Q373 453 429 453Q459 453 472 434T485 396Q485 382 476 371T449 360Q416 360 412 390Q410 404 415 411Q415 412 416 414V415Q388 412 363 393Q355 388 355 386Q355 385 359 381T368 369T379 351T388 325T392 292Q392 230 343 187T222 143Q172 143 123 171Q112 153 112 133Q112 98 138 81Q147 75 155 75T227 73Q311 72 335 67Q396 58 431 26Q470 -13 470 -72Q470 -139 392 -175Q332 -206 250 -206Q167 -206 107 -175Q29 -140 29 -75Q29 -39 50 -15T92 18L103 24Q67 55 67 108Q67 155 96 193Q52 237 52 292Q52 355 102 398T223 442Q274 442 318 416L329 409ZM299 343Q294 371 273 387T221 404Q192 404 171 388T145 343Q142 326 142 292Q142 248 149 227T179 192Q196 182 222 182Q244 182 260 189T283 207T294 227T299 242Q302 258 302 292T299 343ZM403 -75Q403 -50 389 -34T348 -11T299 -2T245 0H218Q151 0 138 -6Q118 -15 107 -34T95 -74Q95 -84 101 -97T122 -127T170 -155T250 -167Q319 -167 361 -139T403 -75Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMATHI-6E\" d=\"M21 287Q22 293 24 303T36 341T56 388T89 425T135 442Q171 442 195 424T225 390T231 369Q231 367 232 367L243 378Q304 442 382 442Q436 442 469 415T503 336T465 179T427 52Q427 26 444 26Q450 26 453 27Q482 32 505 65T540 145Q542 153 560 153Q580 153 580 145Q580 144 576 130Q568 101 554 73T508 17T439 -10Q392 -10 371 17T350 73Q350 92 386 193T423 345Q423 404 379 404H374Q288 404 229 303L222 291L189 157Q156 26 151 16Q138 -11 108 -11Q95 -11 87 -5T76 7T74 17Q74 30 112 180T152 343Q153 348 153 366Q153 405 129 405Q91 405 66 305Q60 285 60 284Q58 278 41 278H27Q21 284 21 287Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-29\" d=\"M60 749L64 750Q69 750 74 750H86L114 726Q208 641 251 514T294 250Q294 182 284 119T261 12T224 -76T186 -143T145 -194T113 -227T90 -246Q87 -249 86 -250H74Q66 -250 63 -250T58 -247T55 -238Q56 -237 66 -225Q221 -64 221 250T66 725Q56 737 55 738Q55 746 60 749Z\"></path>\n</defs>\n<g stroke=\"currentColor\" fill=\"currentColor\" stroke-width=\"0\" transform=\"matrix(1 0 0 -1 0 0)\" aria-hidden=\"true\">\n <use xlink:href=\"#E1-MJCAL-4F\" x=\"0\" y=\"0\"></use>\n <use xlink:href=\"#E1-MJMAIN-28\" x=\"796\" y=\"0\"></use>\n<g transform=\"translate(1186,0)\">\n <use xlink:href=\"#E1-MJMAIN-6C\"></use>\n <use xlink:href=\"#E1-MJMAIN-6F\" x=\"278\" y=\"0\"></use>\n <use xlink:href=\"#E1-MJMAIN-67\" x=\"779\" y=\"0\"></use>\n</g>\n <use xlink:href=\"#E1-MJMATHI-6E\" x=\"2632\" y=\"0\"></use>\n <use xlink:href=\"#E1-MJMAIN-29\" x=\"3232\" y=\"0\"></use>\n</g>\n</svg>",
    L"\mathcal{O}\left(\frac{\log{x}}{2}\right)" =>
        "<svg xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"11.183ex\" height=\"6.176ex\" style=\"vertical-align: -2.505ex;\" viewBox=\"0 -1580.7 4814.8 2659.1\" role=\"img\" focusable=\"false\" xmlns=\"http://www.w3.org/2000/svg\" aria-labelledby=\"MathJax-SVG-1-Title\">\n<title id=\"MathJax-SVG-1-Title\">script upper O left-parenthesis StartFraction log x Over 2 EndFraction right-parenthesis</title>\n<defs aria-hidden=\"true\">\n<path stroke-width=\"1\" id=\"E1-MJCAL-4F\" d=\"M308 428Q289 428 289 438Q289 457 318 508T378 593Q417 638 475 671T599 705Q688 705 732 643T777 483Q777 380 733 285T620 123T464 18T293 -22Q188 -22 123 51T58 245Q58 327 87 403T159 533T249 626T333 685T388 705Q404 705 404 693Q404 674 363 649Q333 632 304 606T239 537T181 429T158 290Q158 179 214 114T364 48Q489 48 583 165T677 438Q677 473 670 505T648 568T601 617T528 636Q518 636 513 635Q486 629 460 600T419 544T392 490Q383 470 372 459Q341 430 308 428Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-28\" d=\"M94 250Q94 319 104 381T127 488T164 576T202 643T244 695T277 729T302 750H315H319Q333 750 333 741Q333 738 316 720T275 667T226 581T184 443T167 250T184 58T225 -81T274 -167T316 -220T333 -241Q333 -250 318 -250H315H302L274 -226Q180 -141 137 -14T94 250Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-6C\" d=\"M42 46H56Q95 46 103 60V68Q103 77 103 91T103 124T104 167T104 217T104 272T104 329Q104 366 104 407T104 482T104 542T103 586T103 603Q100 622 89 628T44 637H26V660Q26 683 28 683L38 684Q48 685 67 686T104 688Q121 689 141 690T171 693T182 694H185V379Q185 62 186 60Q190 52 198 49Q219 46 247 46H263V0H255L232 1Q209 2 183 2T145 3T107 3T57 1L34 0H26V46H42Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-6F\" d=\"M28 214Q28 309 93 378T250 448Q340 448 405 380T471 215Q471 120 407 55T250 -10Q153 -10 91 57T28 214ZM250 30Q372 30 372 193V225V250Q372 272 371 288T364 326T348 362T317 390T268 410Q263 411 252 411Q222 411 195 399Q152 377 139 338T126 246V226Q126 130 145 91Q177 30 250 30Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-67\" d=\"M329 409Q373 453 429 453Q459 453 472 434T485 396Q485 382 476 371T449 360Q416 360 412 390Q410 404 415 411Q415 412 416 414V415Q388 412 363 393Q355 388 355 386Q355 385 359 381T368 369T379 351T388 325T392 292Q392 230 343 187T222 143Q172 143 123 171Q112 153 112 133Q112 98 138 81Q147 75 155 75T227 73Q311 72 335 67Q396 58 431 26Q470 -13 470 -72Q470 -139 392 -175Q332 -206 250 -206Q167 -206 107 -175Q29 -140 29 -75Q29 -39 50 -15T92 18L103 24Q67 55 67 108Q67 155 96 193Q52 237 52 292Q52 355 102 398T223 442Q274 442 318 416L329 409ZM299 343Q294 371 273 387T221 404Q192 404 171 388T145 343Q142 326 142 292Q142 248 149 227T179 192Q196 182 222 182Q244 182 260 189T283 207T294 227T299 242Q302 258 302 292T299 343ZM403 -75Q403 -50 389 -34T348 -11T299 -2T245 0H218Q151 0 138 -6Q118 -15 107 -34T95 -74Q95 -84 101 -97T122 -127T170 -155T250 -167Q319 -167 361 -139T403 -75Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMATHI-78\" d=\"M52 289Q59 331 106 386T222 442Q257 442 286 424T329 379Q371 442 430 442Q467 442 494 420T522 361Q522 332 508 314T481 292T458 288Q439 288 427 299T415 328Q415 374 465 391Q454 404 425 404Q412 404 406 402Q368 386 350 336Q290 115 290 78Q290 50 306 38T341 26Q378 26 414 59T463 140Q466 150 469 151T485 153H489Q504 153 504 145Q504 144 502 134Q486 77 440 33T333 -11Q263 -11 227 52Q186 -10 133 -10H127Q78 -10 57 16T35 71Q35 103 54 123T99 143Q142 143 142 101Q142 81 130 66T107 46T94 41L91 40Q91 39 97 36T113 29T132 26Q168 26 194 71Q203 87 217 139T245 247T261 313Q266 340 266 352Q266 380 251 392T217 404Q177 404 142 372T93 290Q91 281 88 280T72 278H58Q52 284 52 289Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-32\" d=\"M109 429Q82 429 66 447T50 491Q50 562 103 614T235 666Q326 666 387 610T449 465Q449 422 429 383T381 315T301 241Q265 210 201 149L142 93L218 92Q375 92 385 97Q392 99 409 186V189H449V186Q448 183 436 95T421 3V0H50V19V31Q50 38 56 46T86 81Q115 113 136 137Q145 147 170 174T204 211T233 244T261 278T284 308T305 340T320 369T333 401T340 431T343 464Q343 527 309 573T212 619Q179 619 154 602T119 569T109 550Q109 549 114 549Q132 549 151 535T170 489Q170 464 154 447T109 429Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-29\" d=\"M60 749L64 750Q69 750 74 750H86L114 726Q208 641 251 514T294 250Q294 182 284 119T261 12T224 -76T186 -143T145 -194T113 -227T90 -246Q87 -249 86 -250H74Q66 -250 63 -250T58 -247T55 -238Q56 -237 66 -225Q221 -64 221 250T66 725Q56 737 55 738Q55 746 60 749Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJSZ3-28\" d=\"M701 -940Q701 -943 695 -949H664Q662 -947 636 -922T591 -879T537 -818T475 -737T412 -636T350 -511T295 -362T250 -186T221 17T209 251Q209 962 573 1361Q596 1386 616 1405T649 1437T664 1450H695Q701 1444 701 1441Q701 1436 681 1415T629 1356T557 1261T476 1118T400 927T340 675T308 359Q306 321 306 250Q306 -139 400 -430T690 -924Q701 -936 701 -940Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJSZ3-29\" d=\"M34 1438Q34 1446 37 1448T50 1450H56H71Q73 1448 99 1423T144 1380T198 1319T260 1238T323 1137T385 1013T440 864T485 688T514 485T526 251Q526 134 519 53Q472 -519 162 -860Q139 -885 119 -904T86 -936T71 -949H56Q43 -949 39 -947T34 -937Q88 -883 140 -813Q428 -430 428 251Q428 453 402 628T338 922T245 1146T145 1309T46 1425Q44 1427 42 1429T39 1433T36 1436L34 1438Z\"></path>\n</defs>\n<g stroke=\"currentColor\" fill=\"currentColor\" stroke-width=\"0\" transform=\"matrix(1 0 0 -1 0 0)\" aria-hidden=\"true\">\n <use xlink:href=\"#E1-MJCAL-4F\" x=\"0\" y=\"0\"></use>\n<g transform=\"translate(963,0)\">\n <use xlink:href=\"#E1-MJSZ3-28\"></use>\n<g transform=\"translate(736,0)\">\n<g transform=\"translate(120,0)\">\n<rect stroke=\"none\" width=\"2138\" height=\"60\" x=\"0\" y=\"220\"></rect>\n<g transform=\"translate(60,726)\">\n <use xlink:href=\"#E1-MJMAIN-6C\"></use>\n <use xlink:href=\"#E1-MJMAIN-6F\" x=\"278\" y=\"0\"></use>\n <use xlink:href=\"#E1-MJMAIN-67\" x=\"779\" y=\"0\"></use>\n <use xlink:href=\"#E1-MJMATHI-78\" x=\"1446\" y=\"0\"></use>\n</g>\n <use xlink:href=\"#E1-MJMAIN-32\" x=\"819\" y=\"-687\"></use>\n</g>\n</g>\n <use xlink:href=\"#E1-MJSZ3-29\" x=\"3115\" y=\"-1\"></use>\n</g>\n</g>\n</svg>",
    L"E=mc^2" =>
        "<svg xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"8.976ex\" height=\"2.676ex\" style=\"vertical-align: -0.338ex;\" viewBox=\"0 -1006.6 3864.5 1152.1\" role=\"img\" focusable=\"false\" xmlns=\"http://www.w3.org/2000/svg\" aria-labelledby=\"MathJax-SVG-1-Title\">\n<title id=\"MathJax-SVG-1-Title\">upper E equals m c squared</title>\n<defs aria-hidden=\"true\">\n<path stroke-width=\"1\" id=\"E1-MJMATHI-45\" d=\"M492 213Q472 213 472 226Q472 230 477 250T482 285Q482 316 461 323T364 330H312Q311 328 277 192T243 52Q243 48 254 48T334 46Q428 46 458 48T518 61Q567 77 599 117T670 248Q680 270 683 272Q690 274 698 274Q718 274 718 261Q613 7 608 2Q605 0 322 0H133Q31 0 31 11Q31 13 34 25Q38 41 42 43T65 46Q92 46 125 49Q139 52 144 61Q146 66 215 342T285 622Q285 629 281 629Q273 632 228 634H197Q191 640 191 642T193 659Q197 676 203 680H757Q764 676 764 669Q764 664 751 557T737 447Q735 440 717 440H705Q698 445 698 453L701 476Q704 500 704 528Q704 558 697 578T678 609T643 625T596 632T532 634H485Q397 633 392 631Q388 629 386 622Q385 619 355 499T324 377Q347 376 372 376H398Q464 376 489 391T534 472Q538 488 540 490T557 493Q562 493 565 493T570 492T572 491T574 487T577 483L544 351Q511 218 508 216Q505 213 492 213Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-3D\" d=\"M56 347Q56 360 70 367H707Q722 359 722 347Q722 336 708 328L390 327H72Q56 332 56 347ZM56 153Q56 168 72 173H708Q722 163 722 153Q722 140 707 133H70Q56 140 56 153Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMATHI-6D\" d=\"M21 287Q22 293 24 303T36 341T56 388T88 425T132 442T175 435T205 417T221 395T229 376L231 369Q231 367 232 367L243 378Q303 442 384 442Q401 442 415 440T441 433T460 423T475 411T485 398T493 385T497 373T500 364T502 357L510 367Q573 442 659 442Q713 442 746 415T780 336Q780 285 742 178T704 50Q705 36 709 31T724 26Q752 26 776 56T815 138Q818 149 821 151T837 153Q857 153 857 145Q857 144 853 130Q845 101 831 73T785 17T716 -10Q669 -10 648 17T627 73Q627 92 663 193T700 345Q700 404 656 404H651Q565 404 506 303L499 291L466 157Q433 26 428 16Q415 -11 385 -11Q372 -11 364 -4T353 8T350 18Q350 29 384 161L420 307Q423 322 423 345Q423 404 379 404H374Q288 404 229 303L222 291L189 157Q156 26 151 16Q138 -11 108 -11Q95 -11 87 -5T76 7T74 17Q74 30 112 181Q151 335 151 342Q154 357 154 369Q154 405 129 405Q107 405 92 377T69 316T57 280Q55 278 41 278H27Q21 284 21 287Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMATHI-63\" d=\"M34 159Q34 268 120 355T306 442Q362 442 394 418T427 355Q427 326 408 306T360 285Q341 285 330 295T319 325T330 359T352 380T366 386H367Q367 388 361 392T340 400T306 404Q276 404 249 390Q228 381 206 359Q162 315 142 235T121 119Q121 73 147 50Q169 26 205 26H209Q321 26 394 111Q403 121 406 121Q410 121 419 112T429 98T420 83T391 55T346 25T282 0T202 -11Q127 -11 81 37T34 159Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-32\" d=\"M109 429Q82 429 66 447T50 491Q50 562 103 614T235 666Q326 666 387 610T449 465Q449 422 429 383T381 315T301 241Q265 210 201 149L142 93L218 92Q375 92 385 97Q392 99 409 186V189H449V186Q448 183 436 95T421 3V0H50V19V31Q50 38 56 46T86 81Q115 113 136 137Q145 147 170 174T204 211T233 244T261 278T284 308T305 340T320 369T333 401T340 431T343 464Q343 527 309 573T212 619Q179 619 154 602T119 569T109 550Q109 549 114 549Q132 549 151 535T170 489Q170 464 154 447T109 429Z\"></path>\n</defs>\n<g stroke=\"currentColor\" fill=\"currentColor\" stroke-width=\"0\" transform=\"matrix(1 0 0 -1 0 0)\" aria-hidden=\"true\">\n <use xlink:href=\"#E1-MJMATHI-45\" x=\"0\" y=\"0\"></use>\n <use xlink:href=\"#E1-MJMAIN-3D\" x=\"1042\" y=\"0\"></use>\n <use xlink:href=\"#E1-MJMATHI-6D\" x=\"2098\" y=\"0\"></use>\n<g transform=\"translate(2977,0)\">\n <use xlink:href=\"#E1-MJMATHI-63\" x=\"0\" y=\"0\"></use>\n <use transform=\"scale(0.707)\" xlink:href=\"#E1-MJMAIN-32\" x=\"613\" y=\"583\"></use>\n</g>\n</g>\n</svg>\n",
    L"8" =>
        "<svg xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"1.162ex\" height=\"2.176ex\" style=\"vertical-align: -0.338ex;\" viewBox=\"0 -791.3 500.5 936.9\" role=\"img\" focusable=\"false\" xmlns=\"http://www.w3.org/2000/svg\" aria-labelledby=\"MathJax-SVG-1-Title\">\n<title id=\"MathJax-SVG-1-Title\">8</title>\n<defs aria-hidden=\"true\">\n<path stroke-width=\"1\" id=\"E1-MJMAIN-38\" d=\"M70 417T70 494T124 618T248 666Q319 666 374 624T429 515Q429 485 418 459T392 417T361 389T335 371T324 363L338 354Q352 344 366 334T382 323Q457 264 457 174Q457 95 399 37T249 -22Q159 -22 101 29T43 155Q43 263 172 335L154 348Q133 361 127 368Q70 417 70 494ZM286 386L292 390Q298 394 301 396T311 403T323 413T334 425T345 438T355 454T364 471T369 491T371 513Q371 556 342 586T275 624Q268 625 242 625Q201 625 165 599T128 534Q128 511 141 492T167 463T217 431Q224 426 228 424L286 386ZM250 21Q308 21 350 55T392 137Q392 154 387 169T375 194T353 216T330 234T301 253T274 270Q260 279 244 289T218 306L210 311Q204 311 181 294T133 239T107 157Q107 98 150 60T250 21Z\"></path>\n</defs>\n<g stroke=\"currentColor\" fill=\"currentColor\" stroke-width=\"0\" transform=\"matrix(1 0 0 -1 0 0)\" aria-hidden=\"true\">\n <use xlink:href=\"#E1-MJMAIN-38\" x=\"0\" y=\"0\"></use>\n</g>\n</svg>\n",
    L"$\begin{equation}\left[\begin{array}{ccc}1 & 2 & 3 \\4 & 5 & 6 \\7 & 8 & 9 \\\end{array}\right]\end{equation}$" =>
        "<svg xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"11.985ex\" height=\"9.176ex\" style=\"vertical-align: -4.005ex;\" viewBox=\"0 -2226.5 5160 3950.7\" role=\"img\" focusable=\"false\" xmlns=\"http://www.w3.org/2000/svg\" aria-labelledby=\"MathJax-SVG-1-Title\">\n<title id=\"MathJax-SVG-1-Title\">Start 3 By 3 Matrix 1st Row 1st Column 1 2nd Column 2 3rd Column 3 2nd Row 1st Column 4 2nd Column 5 3rd Column 6 3rd Row 1st Column 7 2nd Column 8 3rd Column 9 EndMatrix</title>\n<defs aria-hidden=\"true\">\n<path stroke-width=\"1\" id=\"E1-MJMAIN-5B\" d=\"M118 -250V750H255V710H158V-210H255V-250H118Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-31\" d=\"M213 578L200 573Q186 568 160 563T102 556H83V602H102Q149 604 189 617T245 641T273 663Q275 666 285 666Q294 666 302 660V361L303 61Q310 54 315 52T339 48T401 46H427V0H416Q395 3 257 3Q121 3 100 0H88V46H114Q136 46 152 46T177 47T193 50T201 52T207 57T213 61V578Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-32\" d=\"M109 429Q82 429 66 447T50 491Q50 562 103 614T235 666Q326 666 387 610T449 465Q449 422 429 383T381 315T301 241Q265 210 201 149L142 93L218 92Q375 92 385 97Q392 99 409 186V189H449V186Q448 183 436 95T421 3V0H50V19V31Q50 38 56 46T86 81Q115 113 136 137Q145 147 170 174T204 211T233 244T261 278T284 308T305 340T320 369T333 401T340 431T343 464Q343 527 309 573T212 619Q179 619 154 602T119 569T109 550Q109 549 114 549Q132 549 151 535T170 489Q170 464 154 447T109 429Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-33\" d=\"M127 463Q100 463 85 480T69 524Q69 579 117 622T233 665Q268 665 277 664Q351 652 390 611T430 522Q430 470 396 421T302 350L299 348Q299 347 308 345T337 336T375 315Q457 262 457 175Q457 96 395 37T238 -22Q158 -22 100 21T42 130Q42 158 60 175T105 193Q133 193 151 175T169 130Q169 119 166 110T159 94T148 82T136 74T126 70T118 67L114 66Q165 21 238 21Q293 21 321 74Q338 107 338 175V195Q338 290 274 322Q259 328 213 329L171 330L168 332Q166 335 166 348Q166 366 174 366Q202 366 232 371Q266 376 294 413T322 525V533Q322 590 287 612Q265 626 240 626Q208 626 181 615T143 592T132 580H135Q138 579 143 578T153 573T165 566T175 555T183 540T186 520Q186 498 172 481T127 463Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-34\" d=\"M462 0Q444 3 333 3Q217 3 199 0H190V46H221Q241 46 248 46T265 48T279 53T286 61Q287 63 287 115V165H28V211L179 442Q332 674 334 675Q336 677 355 677H373L379 671V211H471V165H379V114Q379 73 379 66T385 54Q393 47 442 46H471V0H462ZM293 211V545L74 212L183 211H293Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-35\" d=\"M164 157Q164 133 148 117T109 101H102Q148 22 224 22Q294 22 326 82Q345 115 345 210Q345 313 318 349Q292 382 260 382H254Q176 382 136 314Q132 307 129 306T114 304Q97 304 95 310Q93 314 93 485V614Q93 664 98 664Q100 666 102 666Q103 666 123 658T178 642T253 634Q324 634 389 662Q397 666 402 666Q410 666 410 648V635Q328 538 205 538Q174 538 149 544L139 546V374Q158 388 169 396T205 412T256 420Q337 420 393 355T449 201Q449 109 385 44T229 -22Q148 -22 99 32T50 154Q50 178 61 192T84 210T107 214Q132 214 148 197T164 157Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-36\" d=\"M42 313Q42 476 123 571T303 666Q372 666 402 630T432 550Q432 525 418 510T379 495Q356 495 341 509T326 548Q326 592 373 601Q351 623 311 626Q240 626 194 566Q147 500 147 364L148 360Q153 366 156 373Q197 433 263 433H267Q313 433 348 414Q372 400 396 374T435 317Q456 268 456 210V192Q456 169 451 149Q440 90 387 34T253 -22Q225 -22 199 -14T143 16T92 75T56 172T42 313ZM257 397Q227 397 205 380T171 335T154 278T148 216Q148 133 160 97T198 39Q222 21 251 21Q302 21 329 59Q342 77 347 104T352 209Q352 289 347 316T329 361Q302 397 257 397Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-37\" d=\"M55 458Q56 460 72 567L88 674Q88 676 108 676H128V672Q128 662 143 655T195 646T364 644H485V605L417 512Q408 500 387 472T360 435T339 403T319 367T305 330T292 284T284 230T278 162T275 80Q275 66 275 52T274 28V19Q270 2 255 -10T221 -22Q210 -22 200 -19T179 0T168 40Q168 198 265 368Q285 400 349 489L395 552H302Q128 552 119 546Q113 543 108 522T98 479L95 458V455H55V458Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-38\" d=\"M70 417T70 494T124 618T248 666Q319 666 374 624T429 515Q429 485 418 459T392 417T361 389T335 371T324 363L338 354Q352 344 366 334T382 323Q457 264 457 174Q457 95 399 37T249 -22Q159 -22 101 29T43 155Q43 263 172 335L154 348Q133 361 127 368Q70 417 70 494ZM286 386L292 390Q298 394 301 396T311 403T323 413T334 425T345 438T355 454T364 471T369 491T371 513Q371 556 342 586T275 624Q268 625 242 625Q201 625 165 599T128 534Q128 511 141 492T167 463T217 431Q224 426 228 424L286 386ZM250 21Q308 21 350 55T392 137Q392 154 387 169T375 194T353 216T330 234T301 253T274 270Q260 279 244 289T218 306L210 311Q204 311 181 294T133 239T107 157Q107 98 150 60T250 21Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-39\" d=\"M352 287Q304 211 232 211Q154 211 104 270T44 396Q42 412 42 436V444Q42 537 111 606Q171 666 243 666Q245 666 249 666T257 665H261Q273 665 286 663T323 651T370 619T413 560Q456 472 456 334Q456 194 396 97Q361 41 312 10T208 -22Q147 -22 108 7T68 93T121 149Q143 149 158 135T173 96Q173 78 164 65T148 49T135 44L131 43Q131 41 138 37T164 27T206 22H212Q272 22 313 86Q352 142 352 280V287ZM244 248Q292 248 321 297T351 430Q351 508 343 542Q341 552 337 562T323 588T293 615T246 625Q208 625 181 598Q160 576 154 546T147 441Q147 358 152 329T172 282Q197 248 244 248Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-5D\" d=\"M22 710V750H159V-250H22V-210H119V710H22Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJSZ4-23A1\" d=\"M319 -645V1154H666V1070H403V-645H319Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJSZ4-23A3\" d=\"M319 -644V1155H403V-560H666V-644H319Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJSZ4-23A2\" d=\"M319 0V602H403V0H319Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJSZ4-23A4\" d=\"M0 1070V1154H347V-645H263V1070H0Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJSZ4-23A6\" d=\"M263 -560V1155H347V-644H0V-560H263Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJSZ4-23A5\" d=\"M263 0V602H347V0H263Z\"></path>\n</defs>\n<g stroke=\"currentColor\" fill=\"currentColor\" stroke-width=\"0\" transform=\"matrix(1 0 0 -1 0 0)\" aria-hidden=\"true\">\n<g transform=\"translate(0,2150)\">\n <use xlink:href=\"#E1-MJSZ4-23A1\" x=\"0\" y=\"-1155\"></use>\n<g transform=\"translate(0,-2048.5066225165565) scale(1,0.49337748344370863)\">\n <use xlink:href=\"#E1-MJSZ4-23A2\"></use>\n</g>\n <use xlink:href=\"#E1-MJSZ4-23A3\" x=\"0\" y=\"-3155\"></use>\n</g>\n<g transform=\"translate(834,0)\">\n<g transform=\"translate(-11,0)\">\n <use xlink:href=\"#E1-MJMAIN-31\" x=\"0\" y=\"1350\"></use>\n <use xlink:href=\"#E1-MJMAIN-34\" x=\"0\" y=\"-50\"></use>\n <use xlink:href=\"#E1-MJMAIN-37\" x=\"0\" y=\"-1450\"></use>\n</g>\n<g transform=\"translate(1490,0)\">\n <use xlink:href=\"#E1-MJMAIN-32\" x=\"0\" y=\"1350\"></use>\n <use xlink:href=\"#E1-MJMAIN-35\" x=\"0\" y=\"-50\"></use>\n <use xlink:href=\"#E1-MJMAIN-38\" x=\"0\" y=\"-1450\"></use>\n</g>\n<g transform=\"translate(2990,0)\">\n <use xlink:href=\"#E1-MJMAIN-33\" x=\"0\" y=\"1350\"></use>\n <use xlink:href=\"#E1-MJMAIN-36\" x=\"0\" y=\"-50\"></use>\n <use xlink:href=\"#E1-MJMAIN-39\" x=\"0\" y=\"-1450\"></use>\n</g>\n</g>\n<g transform=\"translate(4492,2150)\">\n <use xlink:href=\"#E1-MJSZ4-23A4\" x=\"0\" y=\"-1155\"></use>\n<g transform=\"translate(0,-2048.5066225165565) scale(1,0.49337748344370863)\">\n <use xlink:href=\"#E1-MJSZ4-23A5\"></use>\n</g>\n <use xlink:href=\"#E1-MJSZ4-23A6\" x=\"0\" y=\"-3155\"></use>\n</g>\n</g>\n</svg>\n",
)

include("util.jl")
include("luxor_overrides.jl")
include("backgrounds.jl")
include("svg2luxor.jl")
include("morphs.jl")
include("subaction_animations.jl")
include("javis_viewer.jl")

latex(text::LaTeXString) = latex(text, O)
latex(text::LaTeXString, pos::Point) = latex(text, pos, :stroke)
latex(text::LaTeXString, x, y) = latex(text, Point(x, y), :stroke)
@deprecate latex(text::LaTeXString, fsize::Real) begin
    fontsize(fsize)
    latex(text)
end

"""
    latex(text::LaTeXString, pos::Point, action::Symbol)

Add the latex string `text` to the top left corner of the LaTeX path.
Can be added to `Luxor.jl` graphics via [`Video`](@ref).

**NOTES:**
- **This only works if `tex2svg` is installed.**
    It can be installed using the following command (you may have to prefix this command with `sudo` depending on your installation):

        npm install -g mathjax-node-cli

- **The `latex` method must be called from within an [`Action`](@ref).**

# Arguments
- `text::LaTeXString`: a LaTeX string to render.
- `pos::Point`: position of the upper left corner of the latex text. Default: `O`
    - can be written as `x, y` instead of `Point(x, y)`
- `action::Symbol`: graphics actions defined by `Luxor.jl`. Default `:stroke`.
Available actions:
  - `:stroke` - Draws the latex string on the canvas. For more info check `Luxor.strokepath`
  - `:path` - Creates the path of the latex string but does not render it to the canvas.

# Throws
- `IOError`: mathjax-node-cli is not installed

# Example

```
using Javis
using LaTeXStrings

function ground(args...)
    background("white")
    sethue("black")
end

function draw_latex(video, action, frame)
    x = 100
    y = 120
    latex(L"\\sqrt{5}", x, y)
end

demo = Video(500, 500)
javis(demo, [BackgroundAction(1:2, ground), Action(draw_latex)],
      pathname = "latex.gif")
```

"""
function latex(text::LaTeXString, pos::Point, action::Symbol)
    translate(pos)
    # check if it's cached
    if haskey(LaTeXSVG, text)
        svg = LaTeXSVG[text]
    else
        # remove the $
        ts = text.s[2:(end - 1)]
        command = `tex2svg $ts`
        try
            svg = read(command, String)
        catch e
            @warn "Using LaTeX needs the program `tex2svg` which might not be installed"
            @info "It can be installed using `npm install -g mathjax-node-cli`"
            throw(e)
        end
        LaTeXSVG[text] = svg
    end
    pathsvg(svg)
    if action != :path
        # stroke is also fill for letters
        do_action(:fill)
    end
    translate(-pos)
end

"""
    compute_transformation!(action::AbstractAction, video::Video, frame::Int)

Update action.internal_transitions for the current frame number
"""
function compute_transformation!(action::AbstractAction, video::Video, frame::Int)
    for (trans, internal_trans) in zip(action.transitions, action.internal_transitions)
        compute_transition!(internal_trans, trans, video, action, frame)
    end
end

"""
    compute_transition!(internal_rotation::InternalRotation, rotation::Rotation, video,
                        action::AbstractAction, frame)

Computes the rotation transformation for the `action`.
If the `Rotation` is given directly it uses the frame number for interpolation.
If `rotation` includes symbols the current definition of that look up is used for computation.
"""
function compute_transition!(
    internal_rotation::InternalRotation,
    rotation::Rotation,
    video,
    action::AbstractAction,
    frame,
)
    t = get_interpolation(action, frame)
    from, to, center = rotation.from, rotation.to, rotation.center

    center isa Symbol && (center = pos(center))
    from isa Symbol && (from = angle(from))
    to isa Symbol && (to = angle(to))

    internal_rotation.angle = from + t * (to - from)
    internal_rotation.center = center
end

"""
    compute_transition!(internal_translation::InternalTranslation, translation::Translation,
                        video, action::AbstractAction, frame)

Computes the translation transformation for the `action`.
If the `translation` is given directly it uses the frame number for interpolation.
If `translation` includes symbols the current definition of that symbol is looked up
and used for computation.
"""
function compute_transition!(
    internal_translation::InternalTranslation,
    translation::Translation,
    video,
    action::AbstractAction,
    frame,
)
    t = get_interpolation(action, frame)
    from, to = translation.from, translation.to

    from isa Symbol && (from = pos(from))
    to isa Symbol && (to = pos(to))

    internal_translation.by = from + t * (to - from)
end

"""
    compute_transition!(internal_translation::InternalScaling, translation::Scaling,
                        video, action::AbstractAction, frame)

Computes the scaling transformation for the `action`.
If the `scaling` is given directly it uses the frame number for interpolation.
If `scaling` includes symbols, the current definition of that symbol is looked up
and used for computation.
"""
function compute_transition!(
    internal_scale::InternalScaling,
    scale::Scaling,
    video,
    action::AbstractAction,
    frame,
)
    t = get_interpolation(action, frame)
    from, to = scale.from, scale.to

    if !scale.compute_from_once || frame == first(get_frames(action))
        from isa Symbol && (from = get_scale(from))
        if scale.compute_from_once
            scale.from = from
        end
    end
    to isa Symbol && (to = get_scale(to))
    internal_scale.scale = from .+ t .* (to .- from)
end

"""
    perform_transformation(action::AbstractAction)

Perform the transformations as described in action.internal_transitions
"""
function perform_transformation(action::AbstractAction)
    for trans in action.internal_transitions
        perform_transformation(trans)
    end
end

"""
    perform_transformation(trans::InternalTranslation)

Translate as described in `trans`.
"""
function perform_transformation(trans::InternalTranslation)
    translate(trans.by)
end

"""
    perform_transformation(trans::InternalRotation)

Translate and rotate as described in `trans`.
"""
function perform_transformation(trans::InternalRotation)
    translate(trans.center)
    rotate(trans.angle)
end

"""
    perform_transformation(trans::InternalScaling)

Scale as described in `trans`.
"""
function perform_transformation(trans::InternalScaling)
    scaleto(trans.scale...)
end

"""
    get_value(s::Symbol)

Get access to the value that got saved in `s` by a previous action.
If you want to access a position or angle check out [`get_position`](@ref)
and [`get_angle`](@ref).

# Returns
- `Any`: the value stored by a previous action.
"""
function get_value(s::Symbol)
    is_internal = first(string(s)) == '_'
    if is_internal
        internal_sym = Symbol(string(s)[2:end])
        if hasfield(ActionSetting, internal_sym)
            return getfield(get_current_setting(), internal_sym)
        end
    end

    defs = CURRENT_VIDEO[1].defs
    if haskey(defs, s)
        return defs[s]
    else
        error("The symbol $s is not defined.")
    end
end

"""
    val(x)

`val` is just a short-hand for [`get_value`](@ref)
"""
val(x) = get_value(x)

get_position(p::Point) = p
get_position(t::Transformation) = t.p

"""
    get_position(s::Symbol)

Get access to the position that got saved in `s` by a previous action.

# Returns
- `Point`: the point stored by a previous action.
"""
get_position(s::Symbol) = get_position(val(s))

"""
    pos(x)

`pos` is just a short-hand for [`get_position`](@ref)
"""
pos(x) = get_position(x)

# As it is just the number tuple -> return it
get_scale(x::Tuple{<:Number,<:Number}) = x

# If just the number -> return it as a tuple
get_scale(x::Number) = (x, x)

"""
    get_scale(s::Symbol)

Get access to the scaling that got saved in `s` by a previous action.

# Returns
- `Scaling`: the scale stored by a previous action.
"""
get_scale(s::Symbol) = get_scale(val(s))

"""
    scl(x)

`scl` is just a short-hand for [`get_scale`](@ref)
"""
scl(x) = get_scale(x)

get_angle(t::Transformation) = t.angle


"""
    get_angle(s::Symbol)

Get access to the angle that got saved in `s` by a previous action.

# Returns
- `Float64`: the angle stored by a previous action i.e via `return Transformation(p, angle)`
"""
get_angle(s::Symbol) = get_angle(val(s))

"""
    ang(x)

`ang` is just a short-hand for [`get_angle`](@ref)
"""
ang(x) = get_angle(x)

"""
    projection(p::Point, l::Line)

Return the projection of a point to a line.
"""
function projection(p::Point, l::Line)
    # move line to origin and describe it as a vector
    o = l.p1
    v = l.p2 - o
    # point also moved to origin
    x = p - o

    # scalar product <x,v>/<v,v>
    c = (x.x * v.x + x.y * v.y) / (v.x^2 + v.y^2)
    return c * v + o
end

"""
    create_internal_transitions!(action::AbstractAction)

For every translation an internal translation is added to `action.internal_transitions`.
Same is true for all other transitions.
"""
function create_internal_transitions!(action::AbstractAction)
    for trans in action.transitions
        if trans isa Translation
            push!(action.internal_transitions, InternalTranslation(O))
        elseif trans isa Rotation
            push!(action.internal_transitions, InternalRotation(0.0, O))
        elseif trans isa Scaling
            push!(action.internal_transitions, InternalScaling((1.0, 1.0)))
        end
    end
end

"""
    javis(
        video::Video,
        actions::Vector{AbstractAction};
        framerate=30,
        pathname="",
        tempdirectory="",
        liveview=false
    )

Similar to `animate` in Luxor with a slightly different structure.
Instead of using actions and a video instead of scenes in a movie.

# Arguments
- `video::Video`: The video which defines the dimensions of the output
- `actions::Vector{Action}`: All actions that are performed

# Keywords
- `framerate::Int`: The frame rate of the video
- `pathname::String`: The path for the rendered gif or mp4 (i.e `output.gif` or `output.mp4`)
- `tempdirectory::String`: The folder where each frame is stored
    Defaults to a temporary directory when not set
- `liveview::Bool`: Causes a live image viewer to appear to assist with animation development

# Example
```
function ground(args...)
    background("white")
    sethue("black")
end

function circ(p=O, color="black")
    sethue(color)
    circle(p, 25, :fill)
    return Transformation(p, 0.0)
end

from = Point(-200, -200)
to = Point(-20, -130)
p1 = Point(0,-100)
p2 = Point(0,-50)
from_rot = 0.0
to_rot = 2π

demo = Video(500, 500)
javis(demo, [
    Action(1:100, ground),
    Action(1:100, :red_ball, (args...)->circ(p1, "red"), Rotation(from_rot, to_rot)),
    Action(1:100, (args...)->circ(p2, "blue"), Rotation(to_rot, from_rot, :red_ball))
], tempdirectory="images", pathname="rotating.gif")
```

This structure makes it possible to refer to positions of previous actions
i.e :red_ball is an id for the position or the red ball which can be used in the
rotation of the next ball.
"""
function javis(
    video::Video,
    actions::Vector{AA};
    framerate = 30,
    pathname = "javis_$(randstring(7)).gif",
    liveview = false,
    tempdirectory = "",
) where {AA<:AbstractAction}
    compute_frames!(actions)

    for action in actions
        compute_frames!(action.subactions; last_frames = get_frames(action))
    end

    # get all frames
    frames = Int[]
    for action in actions
        append!(frames, collect(get_frames(action)))
    end
    frames = unique(frames)

    # create internal transition objects
    for action in actions
        create_internal_transitions!(action)
        for subaction in action.subactions
            create_internal_transitions!(subaction)
        end
    end

    # create defs object
    for action in actions
        if action.id !== nothing
            video.defs[action.id] = Transformation(O, 0.0)
        end
    end

    if isempty(CURRENT_ACTION)
        push!(CURRENT_ACTION, actions[1])
    else
        CURRENT_ACTION[1] = actions[1]
    end

    if liveview == true
        _javis_viewer(video, length(frames), actions)
        return "Live preview started."
    end

    path, ext = "", ""
    if !isempty(pathname)
        path, ext = splitext(pathname)
    end
    render_mp4 = ext == ".mp4"
    codec_props = [:priv_data => ("crf" => "22", "preset" => "medium")]
    if render_mp4
        video_io = Base.open("temp.stream", "w")
    end
    video_encoder = nothing
    # if we render a gif and the user hasn't set a tempdirectory
    if !render_mp4 && isempty(tempdirectory)
        tempdirectory = mktempdir()
    end

    filecounter = 1
    @showprogress 1 "Rendering frames..." for frame in frames
        frame_image = convert.(RGB, get_javis_frame(video, actions, frame))
        if !isempty(tempdirectory)
            Images.save("$(tempdirectory)/$(lpad(filecounter, 10, "0")).png", frame_image)
        end
        if render_mp4
            if frame == first(frames)
                video_encoder = prepareencoder(
                    frame_image,
                    framerate = framerate,
                    AVCodecContextProperties = codec_props,
                )
            end
            appendencode!(video_encoder, video_io, frame_image, filecounter)
        end
        filecounter += 1
    end

    isempty(pathname) && return
    if ext == ".gif"
        # generate a colorpalette first so ffmpeg does not have to guess it
        ffmpeg_exe(`-loglevel panic -i $(tempdirectory)/%10d.png -vf
                    "palettegen=stats_mode=diff" -y "$(tempdirectory)/palette.bmp"`)
        # then apply the palette to get better results
        ffmpeg_exe(`-loglevel panic -framerate $framerate -i $(tempdirectory)/%10d.png -i
                    "$(tempdirectory)/palette.bmp" -lavfi
                    "paletteuse=dither=sierra2_4a" -y $pathname`)
    elseif ext == ".mp4"
        finishencode!(video_encoder, video_io)
        close(video_io)
        mux("temp.stream", pathname, framerate; silent = true)
    else
        @error "Currently, only gif and mp4 creation is supported. Not a $ext."
    end
    return pathname
end

"""
    get_javis_frame(video, actions, frame)

Get a frame from an animation given a video object, its actions, and frame.

# Arguments
- `video::Video`: The video which defines the dimensions of the output
- `actions::Vector{Action}`: All actions that are performed
- `frame::Int`: Specific frame to be returned

# Returns
- `Array{ARGB32, 2}` - request frame as a matrix
"""
function get_javis_frame(video, actions, frame)
    background_settings = ActionSetting()
    Drawing(video.width, video.height, :image)
    origin()
    origin_matrix = cairotojuliamatrix(getmatrix())
    # this frame needs doing, see if each of the scenes defines it
    for action in actions
        # if action is not in global layer this sets the background_settings
        # from the parent background action
        update_action_settings!(action, background_settings)
        CURRENT_ACTION[1] = action
        if frame in get_frames(action)
            # check if the action should be part of the global layer (i.e BackgroundAction)
            # or in its own layer (default)
            in_global_layer = get(action.opts, :in_global_layer, false)
            if !in_global_layer
                @layer begin
                    perform_action(action, video, frame, origin_matrix)
                end
            else
                perform_action(action, video, frame, origin_matrix)
                # update origin_matrix as it's inside the global layer
                origin_matrix = cairotojuliamatrix(getmatrix())
            end
        end
        # if action is in global layer this changes the background settings
        update_background_settings!(background_settings, action)
    end
    img = convert.(ARGB32, image_as_matrix())
    finish()
    return img
end

function update_background_settings!(setting::ActionSetting, action::Action)
    in_global_layer = get(action.opts, :in_global_layer, false)
    if in_global_layer
        update_ActionSetting!(setting, action.current_setting)
    end
end

function update_action_settings!(action::Action, setting::ActionSetting)
    update_ActionSetting!(action.current_setting, setting)
end

"""
    perform_action(action, video, frame, origin_matrix)

Is called inside the `javis` and does everything handled for an `AbstractAction`.
It is a 4-step process:
- compute the transformation for this action (translation, rotation, scale)
- do the transformation
- call the action function
- save the result of the action if wanted inside `video.defs`
"""
function perform_action(action, video, frame, origin_matrix)
    # first compute and perform the global transformations of this action
    compute_transformation!(action, video, frame)
    perform_transformation(action)

    # relative frame number for subactions
    rel_frame = frame - first(get_frames(action)) + 1
    # call currently active subactions and their transformations
    for subaction in action.subactions
        if rel_frame in get_frames(subaction)
            subaction.func(video, action, subaction, rel_frame)
            compute_transformation!(subaction, video, rel_frame)
            perform_transformation(subaction)
        elseif rel_frame > last(get_frames(subaction))
            # call the subaction on the last frame i.e. disappeared things stay disappeared
            subaction.func(video, action, subaction, last(get_frames(subaction)))
            # have the transformation from the last active frame
            compute_transformation!(subaction, video, last(get_frames(subaction)))
            perform_transformation(subaction)
        end
    end

    # set the defaults for the frame like setline() and setopacity()
    # which can depend on the subactions
    set_action_defaults!(action)
    res = action.func(video, action, frame)
    if action.id !== nothing
        current_global_matrix = cairotojuliamatrix(getmatrix())
        # obtain current matrix without the initial matrix part
        current_matrix = inv(origin_matrix) * current_global_matrix

        # if a transformation let's save the global coordinates
        if res isa Point
            vec = current_matrix * [res.x, res.y, 1.0]
            video.defs[action.id] = Point(vec[1], vec[2])
        elseif res isa Transformation
            trans = current_matrix * res
            video.defs[action.id] = trans
        else # just save the result such that it can be used as one wishes
            video.defs[action.id] = res
        end
    end
end

"""
    set_action_defaults!(action)

Set the default action values
- line_width and calls `Luxor.setline`.
- opacity and calls `Luxor.opacity`.
- scale and calls `Luxor.scale`.
"""
function set_action_defaults!(action)
    cs = action.current_setting
    current_line_width = cs.line_width * cs.mul_line_width
    Luxor.setline(current_line_width)
    current_opacity = cs.opacity * cs.mul_opacity
    Luxor.setopacity(current_opacity)

    desired_scale = cs.desired_scale .* cs.mul_scale
    scaleto(desired_scale...)
end

const LUXOR_DONT_EXPORT = [
    :boundingbox,
    :Boxmaptile,
    :Sequence,
    :setline,
    :setopacity,
    :fontsize,
    :get_fontsize,
    :scale,
]

# Export each function from Luxor
for func in names(Luxor; imported = true)
    if !(func in LUXOR_DONT_EXPORT)
        eval(Meta.parse("import Luxor." * string(func)))
        eval(Expr(:export, func))
    end
end

export javis, latex
export Video, Action, BackgroundAction, SubAction, Rel
export Line, Translation, Rotation, Transformation, Scaling
export val, pos, ang, get_value, get_position, get_angle
export projection, morph
export appear, disappear, rotate_around
export rev
export scaleto

# custom override of luxor extensions
export setline, setopacity, fontsize, get_fontsize, scale

end
