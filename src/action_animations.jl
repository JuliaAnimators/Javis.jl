"""
    appear(s::Symbol)

Appear can be used inside an [`Action`](@ref) to make an [`Object`](@ref) or an entire [`Object`](@ref) (including it's objects) to appear.

# Example
```julia
house = Object(101:200, (args...)->house_of_nicholas())
act!(house, Action(1:20, appear(:fade)))
act!(house, Action(81:100, disappear(:fade)))
```
In this case the `house_of_nicholas` will fade in during the first 20 frames
of the [`Object`](@ref) so `101-120`.

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

For a layer only `appear(:fade)` is supported
"""
function appear(s::Symbol)
    (video, object, action, rel_frame) -> _appear(video, object, action, rel_frame, Val(s))
end

function _appear(video, object, action, rel_frame, symbol::Val{:fade_line_width})
    t = get_interpolation(action, rel_frame)
    object.current_setting.mul_line_width = t
end

function _appear(video, object, action, rel_frame, symbol::Val{:fade})
    t = get_interpolation(action, rel_frame)
    object.current_setting.mul_opacity = t
end

function _appear(video, layer::Layer, action, rel_frame, symbol::Val{:fade})
    t = get_interpolation(action, rel_frame)
    layer.current_setting.opacity = t
end

function _appear(video, object, action, rel_frame, symbol::Val{:scale})
    t = get_interpolation(action, rel_frame)
    object.current_setting.mul_scale = t
end

function _appear(video, object, action, rel_frame, symbol::Val{:draw_text})
    t = get_interpolation(action, rel_frame)
    object.opts[:draw_text_t] = t
end

"""
    disappear(s::Symbol)

Disappear can be used inside an [`Action`](@ref) to make an [`Object`](@ref) or an entire [`Layer`](@ref) (including it's objects) to disappear.

# Example
```julia
house = Object(101:200, (args...)->house_of_nicholas())
act!(house, Action(1:20, appear(:fade)))
act!(house, Action(81:100, disappear(:fade)))
```
In this case the `house_of_nicholas` will fade out during the last 20 frames
of the [`Object`](@ref) so `181-200`.

# Arguments
- `s::Symbol`: the symbol defines the animation of disappearance
    The only symbols that are currently supported are:
    - `:fade_line_width` which decreases the line width down to `0`
    - `:fade` which decreases the opacity down to `0`
    - `:scale` which decreases the scale down to `0`
    - `:draw_text` which only works for text and let the text disappear from right to left.

For a layer only `disappear(:fade)` is supported
"""
function disappear(s::Symbol)
    (video, object, action, rel_frame) ->
        _disappear(video, object, action, rel_frame, Val(s))
end

function _disappear(video, object, action, rel_frame, symbol::Val{:fade_line_width})
    t = get_interpolation(action, rel_frame)
    object.current_setting.mul_line_width = 1 - t
end

function _disappear(video, object, action, rel_frame, symbol::Val{:fade})
    t = get_interpolation(action, rel_frame)
    object.current_setting.mul_opacity = 1 - t
end

# for layer only disappear(:fade) is possible
function _disappear(video, layer::Layer, action, rel_frame, symbol::Val{:fade})
    t = get_interpolation(action, rel_frame)
    layer.current_setting.opacity = 1 - t
end


function _disappear(video, object, action, rel_frame, symbol::Val{:scale})
    t = get_interpolation(action, rel_frame)
    object.current_setting.mul_scale = 1 - t
end

function _disappear(video, object, action, rel_frame, symbol::Val{:draw_text})
    t = get_interpolation(action, rel_frame)
    object.opts[:draw_text_t] = 1 - t
end

"""
    translate()

Translate an [`Object`](@ref) or a [`Layer`](@ref) using an [`Action`](@ref) and an Animation defined
with Animations.jl.

If you're used to working with Animations.jl this should feel quite natural.
Instead of defining each movement in its own action it's possible to define it in one
by using an Animation.

# Example
```julia
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

Background(1:150, ground)
obj = Object((args...)->circle(O, 25, :fill))
act!(obj, Action(1:150, circle_anim, translate()))

render(video)
```

Here `circle_anim` defines the movement of the circle. The most important part is that the
time in animations has to be from `0.0` to `1.0`.

This notation uses the Animations.jl library very explicitly. It's also possible to do the
same with:

```julia
obj = Object((args...)->circle(O, 25, :fill))
act!(obj, Action(1:50, sineio(), anim_translate(150, 0)))
act!(obj, Action(51:100, polyin(2), anim_translate(0, 150)))
act!(obj, Action(101:150, expin(8), anim_translate(-150, -150)))
```

which uses the `Action` syntax three times and only uses easing functions instead of
specifying the `Animation` directly. Have a look at [`anim_translate`](@ref) for details.
"""
function Luxor.translate()
    (video, object, action, rel_frame) -> _translate(video, object, action, rel_frame)
end

function _translate(video, object, action, rel_frame)
    p = get_interpolation(action, rel_frame)
    Luxor.translate(p)
end

function _translate(video, layer::Layer, action, rel_frame)
    p = get_interpolation(action, rel_frame)
    layer.position += p
end

"""
    rotate()

Rotate an [`Object`](@ref) or a [`Layer`](@ref) using an [`Action`](@ref) and an Animation defined
with Animations.jl.

If you're used to working with Animations.jl this should feel quite natural.
Instead of defining each movement in its own action it's possible to define it in one
by using an Animation.

# Example
```julia
using Javis, Animations

# define ground function here

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

Background(1:150, ground)
ball = Object((args...) -> circle(O, 25, :fill))
act!(ball, Action(1:10, sineio(), scale()))
act!(ball, Action(11:50, translate_anim, translate()))
act!(ball, Action(51:100, rotate_anim, rotate_around(Point(-150, 0))))
act!(ball, Action(101:140, translate_back_anim, translate()))
act!(ball, Action(141:150, rev(sineio()), scale()))

render(video)
```

which uses the `Action` syntax five times with both easing functions directly and animation objects.
The `rev(sineio())` creates an `Animation` which goes from `1.0` to `0.0`.
"""
function Luxor.rotate()
    (video, object, action, rel_frame) -> _rotate(video, object, action, rel_frame)
end

function _rotate(video, object, action, rel_frame)
    a = get_interpolation(action, rel_frame)
    Luxor.rotate(a)
end

function _rotate(video, layer::Layer, action, rel_frame)
    a = get_interpolation(action, rel_frame)
    layer.current_setting.rotation_angle = a
end

"""
    rotate_around(p)

Rotate an [`Object`](@ref) or a [`Layer`](@ref) using an [`Action`](@ref) and an Animation defined
with Animations.jl around a point `p`. For [`rotate`](@ref) it rotates around the current origin.

An example can be seen in [`rotate`](@ref).

# Arguments
- `p`: the point to rotate around
"""
function rotate_around(p)
    (video, object, action, rel_frame) ->
        _rotate_around(video, object, action, rel_frame, get_position(p))
end

function _rotate_around(video, object, action, rel_frame, p)
    # p should be global so without the translated start_pos
    p = p - object.start_pos
    # save the radius and start angle
    r = get(action.defs, :rotate_radius, distance(p, O))
    pnormed = get(action.defs, :pnormed, p / r)
    if !haskey(action.defs, :rotate_radius)
        action.defs[:rotate_radius] = r
        action.defs[:pnormed] = pnormed
    end
    i = get_interpolation(action, rel_frame)
    Luxor.translate(p)
    Luxor.rotate(i)
    Luxor.translate(-r * pnormed)
end

function _rotate_around(video, layer::Layer, action, rel_frame, p)
    # p should be global so without the translated start_pos
    p = p - layer.position
    # save the radius and start angle
    r = get(action.defs, :rotate_radius, distance(p, O))
    pnormed = get(action.defs, :pnormed, p / r)
    if !haskey(action.defs, :rotate_radius)
        action.defs[:rotate_radius] = r
        action.defs[:pnormed] = pnormed
    end
    i = get_interpolation(action, rel_frame)
    p1 = -r * pnormed
    push!(
        layer.current_setting.misc,
        :rotate_around => true,
        :angle => i,
        :translate => p,
        :translate_back => p1,
    )
end

"""
    scale()

Scale a function defined inside an [`Action`](@ref) using an Animation defined
with Animations.jl.

An example can be seen in [`rotate`](@ref).
"""
function scale()
    (video, object, action, rel_frame) -> _scale(video, object, action, rel_frame)
end

function _scale(video, object, action, rel_frame)
    s = get_interpolation(action, rel_frame)
    scaleto(s)
end

function _scale(video, layer::Layer, action, rel_frame)
    s = get_interpolation(action, rel_frame)
    layer.current_setting.scale = s
end

"""
    sethue()

Set the color of an [`Object`](@ref) using an [`Action`](@ref) and an Animation defined
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

An example on how to integrate this into an [`Action`](@ref) can be seen in [`rotate`](@ref).
Where this would be a valid Action: `Action(1:150, color_anim, sethue())`.
"""
function Luxor.sethue()
    (video, object, action, rel_frame) -> _sethue(video, object, action, rel_frame)
end

function _sethue(video, object, action, rel_frame)
    color = get_interpolation(action, rel_frame)
    Luxor.sethue(color)
end

"""
    setopacity()

Set the color of an [`Object`](@ref) or a [`Layer`](@ref) using an [`Action`](@ref) and an Animation defined
with Animations.jl.

# Example
A possible animation would look like this:
```julia
opacity_anim = Animation(
    [0, 0.5, 1], # must go from 0 to 1
    [
        0.0,
        0.3,
        0.7,
    ],
    [sineio(), sineio()],
)
```

An example on how to integrate this into an [`Action`](@ref) can be seen in [`rotate`](@ref).
Where this would be a valid Action: `Action(1:150, opacity_anim, setopacity())`.
"""
function setopacity()
    (video, object, action, rel_frame) -> _setopacity(video, object, action, rel_frame)
end

function _setopacity(video, object, action, rel_frame)
    opacity = get_interpolation(action, rel_frame)
    setopacity(opacity)
end

function _setopacity(video, layer::Layer, action, rel_frame)
    opacity = get_interpolation(action, rel_frame)
    layer.current_setting.opacity = opacity
end

"""
    follow_path(points::Vector{Point}; closed=true)

Can be applied inside an action such that the parent object follows a path.
It takes a vector of points which can be created as an example by calling
`circle(O, 50)`. Notice that the object is set to `:none`, the default.

# Example
```julia
Action(1:150, follow_path(star(O, 300)))
```

# Arguments
- `points::Vector{Point}` - the vector of points the object should follow

# Keywords
- `closed::Bool` default: true, sets whether the path is a closed path as for example when
    using a circle, ellipse or any polygon. For a bezier path it should be set to false.
"""
function follow_path(points::Vector{Point}; closed = true)
    (video, object, action, rel_frame) ->
        _follow_path(video, object, action, rel_frame, points; closed = closed)
end

function _follow_path(video, object, action, rel_frame, points; closed = closed)
    isfirstframe = rel_frame == first(get_frames(action))
    t = get_interpolation(action, rel_frame)
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
    # get only the frobjectal part to be between 0 and 1
    t -= floor(t)
    if isfirstframe
        # compute the distances only once for performance reasons
        action.defs[:p_dist] = polydistances(points, closed = closed)
    end
    if isapprox(t, 0.0, atol = 1e-4)
        translate(points[1])
        return
    end
    pdist = action.defs[:p_dist]

    overshootpoint = get_polypoint_at(points, t; pdist = pdist)
    translate(overshootpoint)
end

"""
    change(s::Symbol, [val(s)])

Changes the keyword `s` of the parent [`Object`](@ref) from `vals[1]` to `vals[2]`
in an animated way if vals is given as a `Pair` otherwise it sets the keyword `s` to `val`.

# Arguments
- `s::Symbol` Change the keyword with the name `s`
- `vals::Pair` If vals is given i.e `0 => 25` it will be animated from 0 to 25.
    - The default is to use `0 => 1` or use the value given by the animation
    defined in the [`Action`](@ref)

# Example
```julia
Background(1:100, ground)
obj = Object((args...; radius = 25, color="red") -> object(O, radius, color), Point(100, 0))
act!(obj, Action(1:50, change(:radius, 25 => 0)))
act!(Action(51:100, change(:radius, 0 => 25)))
act!(Action(51:100, change(:color, "blue")))
```
"""
function change(s::Symbol, vals::Pair)
    (video, object, action, rel_frame) -> _change(video, object, action, rel_frame, s, vals)
end

function change(s::Symbol, val)
    (video, object, action, rel_frame) -> _change(video, object, action, rel_frame, s, val)
end

function change(s::Symbol)
    (video, object, action, rel_frame) -> _change(video, object, action, rel_frame, s)
end

function _change(video, object, action, rel_frame, s, vals::Pair)
    t = get_interpolation(action, rel_frame)
    # use the linear animation power by the Animation package to interpolate colors as well
    lin_anim = Animation([0.0, 1.0], interpolateable([vals...]))
    object.change_keywords[s] = at(lin_anim, t)
end

function _change(video, object, action, rel_frame, s, val)
    object.change_keywords[s] = val
end

function _change(video, object, action, rel_frame, s)
    val = get_interpolation(action, rel_frame)
    object.change_keywords[s] = val
end

"""
TODO write better docs for everything.
morph() to be used with Action, when an animation form Animations.jl is
provided.

Default samples for every polygon is 100, increase this 
if needed.
"""
function morph(samples = 100)
    (video, object, action, rel_frame) -> _morph(video, object, action, rel_frame, samples)
end

function _morph(video, object, action, rel_frame, samples)
    #at first relative frame of action , we resample polys inside
    #jpaths to have same number of points
    #the polymorph_noresample called inside get_interpolation, unlike luxors polymorph does not resample polys
    #but expects polys with same number of points.
    if rel_frame == action.frames.frames[begin]
        #if first frame and action.anim is of  type Animation{MorphFunction}
        #make it of type Animation{Vector{JPath}}
        if action.anim isa Animation{MorphFunction}
            println("yes")
            keyframes = Keyframe{Vector{JPath}}[]
            for kf in action.anim.frames
                println(typeof(kf.value))
                push!(keyframes, Keyframe(kf.t, getjpaths(kf.value.func, kf.value.args)))
            end
            action.anim = Animation(keyframes, action.anim.easings)
        end

        #make all the jpaths of the same length appending null_jpaths
        long_jpaths_len = max([length(kf.value) for kf in action.anim.frames]...)
        for kf in action.anim.frames
            newval = vcat(
                deepcopy(kf.value),
                repeat([null_jpath(samples)], long_jpaths_len - length(kf.value)),
            )
            empty!(kf.value)
            append!(kf.value, newval)
        end

        println("MAXMIN")
        println(
            max([length(kf.value) for kf in action.anim.frames]...),
            min([length(kf.value) for kf in action.anim.frames]...),
        )

        for kf in action.anim.frames
            for jpath in kf.value  #kf.value is an array of jpaths
                for i in 1:length(jpath.polys)
                    jpath.polys[i] =
                        polysample(jpath.polys[i], samples, closed = jpath.closed[i])
                end
            end
        end
    end

    interp_jpaths = get_interpolation(action, rel_frame)
    function drawfunc(args...)
        drawjpaths(interp_jpaths)
        global DISABLE_LUXOR_DRAW = true
        ret = object.opts[:original_func]()
        global DISABLE_LUXOR_DRAW = false
        ret
    end
    object.func = drawfunc
    if frame == action.frames.frames[end]
        if action.keep
            #make the objects jpaths the last objects (of the Animation) jpath
            empty!(object.jpaths)
            append!(object.jpaths, interp_jpaths)
        else
            object.func = object.opts[:func]
        end
    end
    # TODO if keep is true..then at rel_frame end 
    # replace obj.jpaths with interp_jpaths 
    # this allows it to be morphed again later
    # if keep is false replace object.func and object.jpaths 
    # with original
end
