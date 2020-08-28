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
    - `:fade_line_width` which descreases the line width up to the default value
        or the value specified by [`setline`](@ref)
    - `:fade` which decreases the opcacity up to the default value
        or the value specified by [`setopacity`](@ref)
"""
function disappear(s::Symbol)
    (video, action, subaction, rel_frame) ->
        _disappear(video, action, subaction, rel_frame, Val(s))
end

function _disappear(video, action, subaction, rel_frame, symbol::Val{:fade_line_width})
    t = get_interpolation(subaction, rel_frame)
    action.current_setting.mul_line_width = 1-t
end

function _disappear(video, action, subaction, rel_frame, symbol::Val{:fade})
    t = get_interpolation(subaction, rel_frame)
    action.current_setting.mul_opacity = 1-t
end

"""
    translate()

Translate a function defined inside an [`Action`](@ref) using an Animation defined
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

This notation uses the Animations.jl library very explicitly. It's also possibble to do the
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
    (video, action, subaction, rel_frame) ->
        _translate(video, action, subaction, rel_frame)
end

function _translate(video, action, subaction, rel_frame)
    p = get_interpolation(subaction, rel_frame)
    Luxor.translate(p)
end
