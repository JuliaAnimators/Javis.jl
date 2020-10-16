"""
    appear(s::Symbol)

Appear can be used inside a [`SubAction`](@ref)

# Example
```
Action(101:200, (args...)->house_of_nicholas(); subactions = [
    SubAction(1:20, appear(:fade)),
    SubAction(81:100, disappear(:fade))
])
```
In this case the `house_of_nicholas` will fade in during the first 20 frames
of the [`Action`](@ref) so `101-120`.

# Arguments
- `s::Symbol`: the symbol defines the animation of appearance
    The only symbols that are currently supported are:
    - `:fade_line_width` which increases the line width up to the default value
       or the value specified by [`setline`](@ref)
    - `:fade` which increases the opcacity up to the default value
       or the value specified by [`setopacity`](@ref)
    - `:scale` which increases the scale up to the default value `1`
       or the value specified by [`scale`](@ref)
    - `:draw_text` which only works for [`text`](@ref) and lets it appear from left to right.
"""
function appear(s::Symbol)
    (video, action, subaction, rel_frame) ->
        _appear(video, action, subaction, rel_frame, Val(s))
end

function _appear(video, action, subaction, rel_frame, symbol::Val{:fade_line_width})
    t = get_interpolation(subaction, rel_frame)
    action.current_setting.mul_line_width = t
end

function _appear(video, action, subaction, rel_frame, symbol::Val{:fade})
    t = get_interpolation(subaction, rel_frame)
    action.current_setting.mul_opacity = t
end

function _appear(video, action, subaction, rel_frame, symbol::Val{:scale})
    t = get_interpolation(subaction, rel_frame)
    action.current_setting.mul_scale = t
end

function _appear(video, action, subaction, rel_frame, symbol::Val{:draw_text})
    t = get_interpolation(subaction, rel_frame)
    action.opts[:draw_text_t] = t
end

"""
    disappear(s::Symbol)

Disappear can be used inside a [`SubAction`](@ref)

# Example
```
Action(101:200, (args...)->house_of_nicholas(); subactions = [
    SubAction(1:20, appear(:fade)),
    SubAction(81:100, disappear(:fade))
])
```
In this case the `house_of_nicholas` will fade out during the last 20 frames
of the [`Action`](@ref) so `181-200`.

# Arguments
- `s::Symbol`: the symbol defines the animation of disappearance
    The only symbols that are currently supported are:
    - `:fade_line_width` which decreases the line width down to `0`
    - `:fade` which decreases the opacity down to `0`
    - `:scale` which decreases the scale down to `0`
    - `:draw_text` which only works for text and let the text disappear from right to left.
"""
function disappear(s::Symbol)
    (video, action, subaction, rel_frame) ->
        _disappear(video, action, subaction, rel_frame, Val(s))
end

function _disappear(video, action, subaction, rel_frame, symbol::Val{:fade_line_width})
    t = get_interpolation(subaction, rel_frame)
    action.current_setting.mul_line_width = 1 - t
end

function _disappear(video, action, subaction, rel_frame, symbol::Val{:fade})
    t = get_interpolation(subaction, rel_frame)
    action.current_setting.mul_opacity = 1 - t
end

function _disappear(video, action, subaction, rel_frame, symbol::Val{:scale})
    t = get_interpolation(subaction, rel_frame)
    action.current_setting.mul_scale = 1 - t
end

function _disappear(video, action, subaction, rel_frame, symbol::Val{:draw_text})
    t = get_interpolation(subaction, rel_frame)
    action.opts[:draw_text_t] = 1 - t
end

"""
    translate()

Translate a function defined inside a [`SubAction`](@ref) using an Animation defined
with Animations.jl.

If you're used to working with Animations.jl this should feel quite natural.
Instead of defining each movement in its own subaction it's possible to define it in one
by using an Animation.

# Example
```
using Javis, Animations

function ground(args...)
    background("black")
    sethue("white")
end

video = Video(500, 500)
circle_anim = Animation(
    [0.0, 0.3, 0.6, 1.0], # must go from 0 to 1
    # the circle will move from the origin to `Point(150, 0)` then `Point(150, 150)`
    # and back to the origin `O`.
    [O, Point(150, 0), Point(150, 150), O],
    [sineio(), polyin(5), expin(8)],
)
javis(
    video, [
        BackgroundAction(1:150, ground),
        Action((args...)->circle(O, 25, :fill); subactions=[
            SubAction(1:150, circle_anim, translate())
        ])
    ], pathname="moving_a_circle.gif"
)
```

This notation uses the Animations.jl library very explicitly. It's also possible to do the
same with:

```
javis(
    video,
    [
        BackgroundAction(1:150, ground),
        Action((args...)->circle(O, 25, :fill); subactions = [
            SubAction(1:50, sineio(), Translation(150, 0)),
            SubAction(51:100, polyin(2), Translation(0, 150)),
            SubAction(101:150, expin(8), Translation(-150, -150))
        ])
    ],
    pathname = "moving_a_circle_javis.gif",
)
```

which uses the `SubAction` syntax three times and only uses easing functions instead of
specifying the `Animation` directly.

Here `circle_anim` defines the movement of the circle. The most important part is that the
time in animations has to be from `0.0` to `1.0`.
"""
function Luxor.translate()
    (video, action, subaction, rel_frame) -> _translate(video, action, subaction, rel_frame)
end

function _translate(video, action, subaction, rel_frame)
    p = get_interpolation(subaction, rel_frame)
    Luxor.translate(p)
end

"""
    rotate()

Rotate a function defined inside a [`SubAction`](@ref) using an Animation defined
with Animations.jl.

If you're used to working with Animations.jl this should feel quite natural.
Instead of defining each movement in its own subaction it's possible to define it in one
by using an Animation.

# Example
```
using Javis, Animations

video = Video(500, 500)
translate_anim = Animation(
    [0, 1], # must go from 0 to 1
    [O, Point(150, 0)],
    [sineio()],
)

translate_back_anim = Animation(
    [0, 1], # must go from 0 to 1
    [O, Point(-150, 0)],
    [sineio()],
)

rotate_anim = Animation(
    [0, 1], # must go from 0 to 1
    [0, 2π],
    [linear()],
)

javis(
    video,
    [
        BackgroundAction(1:150, ground),
        Action(
            (args...) -> circle(O, 25, :fill);
            subactions = [
                SubAction(1:10, sineio(), scale()),
                SubAction(11:50, translate_anim, translate()),
                SubAction(51:100, rotate_anim, rotate_around(Point(-150, 0))),
                SubAction(101:140, translate_back_anim, translate()),
                SubAction(141:150, rev(sineio()), scale())
            ],
        ),
    ],
    pathname = "animation.gif",
)
```

which uses the `SubAction` syntax five times with both easing functions directly and animation objects.
The `rev(sineio())` creates an `Animation` which goes from `1.0` to `0.0`.
"""
function Luxor.rotate()
    (video, action, subaction, rel_frame) -> _rotate(video, action, subaction, rel_frame)
end

function _rotate(video, action, subaction, rel_frame)
    p = get_interpolation(subaction, rel_frame)
    Luxor.rotate(p)
end

"""
    rotate_around(p::Point)

Rotate a function defined inside a [`SubAction`](@ref) using an Animation defined
with Animations.jl around the point `p`.

An example can be seen in [`rotate`](@ref).

# Arguments
- `p::Point`: the point to rotate around
"""
function rotate_around(p::Point)
    (video, action, subaction, rel_frame) ->
        _rotate_around(video, action, subaction, rel_frame, p)
end

function _rotate_around(video, action, subaction, rel_frame, p)
    i = get_interpolation(subaction, rel_frame)
    Luxor.translate(p)
    Luxor.rotate(i)
    Luxor.translate(-p)
end

"""
    scale()

Scale a function defined inside a [`SubAction`](@ref) using an Animation defined
with Animations.jl around the point `p`.

An example can be seen in [`rotate`](@ref).
"""
function scale()
    (video, action, subaction, rel_frame) -> _scale(video, action, subaction, rel_frame)
end

function _scale(video, action, subaction, rel_frame)
    p = get_interpolation(subaction, rel_frame)
    scale(p)
end

"""
    sethue()

Set the color of a function defined inside a [`SubAction`](@ref) using an Animation defined
with Animations.jl.

# Example
A possible animation would look like this:
```julia
color_anim = Animation(
    [0, 0.5, 1], # must go from 0 to 1
    [
        Lab(colorant"red"),
        Lab(colorant"cyan"),
        Lab(colorant"black"),
    ],
    [sineio(), sineio()],
)
```

An example on how to integrate this into a SubAction can be seen in [`rotate`](@ref).
Where this would be a valid SubAction: `SubAction(1:150, color_anim, sethue())`.
"""
function Luxor.sethue()
    (video, action, subaction, rel_frame) -> _sethue(video, action, subaction, rel_frame)
end

function _sethue(video, action, subaction, rel_frame)
    color = get_interpolation(subaction, rel_frame)
    Luxor.sethue(color)
end

"""
    follow_path(points::Vector{Point}; closed=true)

Can be applied inside a subaction such that the object defined in the parent action follows a path.
It takes a vector of points which can be created as an example by calling `circle(O, 50)` <- notice that the action is set to `:none` the default.

# Example
```julia
SubAction(1:150, follow_path(star(O, 300)))
```

# Arguments
- `points::Vector{Point}` - the vector of points the object should follow

# Keywords
- `closed::Bool` default: true, sets whether the path is a closed path as for example when
    using a circle, ellipse or any polygon. For a bezier path it should be set to false.
"""
function follow_path(points::Vector{Point}; closed = true)
    (video, action, subaction, rel_frame) ->
        _follow_path(video, action, subaction, rel_frame, points; closed = closed)
end

function _follow_path(video, action, subaction, rel_frame, points; closed = closed)
    isfirstframe = rel_frame == first(get_frames(subaction))
    t = get_interpolation(subaction, rel_frame)
    # if not closed it should be always between 0 and 1
    if !closed
        t = clamp(t, 0.0, 1.0)
    end
    # if t is discrete and not 0.0 take the last point or first if closed
    if !isfirstframe && isapprox_discrete(t)
        if closed
            translate(points[1])
        else
            translate(points[end])
        end
        return
    end
    # get only the fractional part to be between 0 and 1
    t -= floor(t)
    if isfirstframe
        # compute the distances only once for performance reasons
        subaction.defs[:p_dist] = polydistances(points, closed = closed)
    end
    if isapprox(t, 0.0, atol = 1e-4)
        translate(points[1])
        return
    end
    pdist = subaction.defs[:p_dist]
    ind, surplus = nearestindex(pdist, t * pdist[end])

    nextind = mod1(ind + 1, length(points))
    overshootpoint = between(
        points[ind],
        points[nextind],
        surplus / distance(points[ind], points[nextind]),
    )
    translate(overshootpoint)
end

"""
    change(s::Symbol, [vals::Pair])

Changes the keyword `s` of the parent [`Action`](@ref) from `vals[1]` to `vals[2]`
in an animated way.

# Arguments
- `s::Symbol` Change the keyword with the name `s`
- `vals::Pair` If vals is given i.e `0 => 25` it will be animated from 0 to 25.
    - The default is to use `0 => 1` or use the value given by the animation
    defined in the [`SubAction`](@ref)

# Example
```julia
myvideo = Video(500, 500)
javis(
    myvideo,
    [
        BackgroundAction(1:100, ground),
        Action(
            (args...; radius = 25) -> object(Point(100, 0), radius, "red"),
            Rotation(0.0, 4π);
            subactions = [
                SubAction(1:50, change(:radius, 25 => 0))
                SubAction(51:100, change(:radius, 0 => 25))
            ],
        )
    ]; pathname = "current/_change.gif"
)
```
"""
function change(s::Symbol, vals::Pair)
    (video, action, subaction, rel_frame) ->
        _change(video, action, subaction, rel_frame, s, vals)
end

function change(s::Symbol)
    (video, action, subaction, rel_frame) -> _change(video, action, subaction, rel_frame, s)
end

function _change(video, action, subaction, rel_frame, s, vals)
    t = get_interpolation(subaction, rel_frame)
    val = vals[1] + t * (vals[2] - vals[1])
    action.change_keywords[s] = val
end

function _change(video, action, subaction, rel_frame, s)
    val = get_interpolation(subaction, rel_frame)
    action.change_keywords[s] = val
end
