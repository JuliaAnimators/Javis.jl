"""
    setline(linewidth)

Set the line width and multiply it with the current multiplier
which is i.e. set by [`appear`](@ref) and [`disappear`](@ref).

Normal behavior without any animation is the same as `Luxor.setline`.

# Example
```
setline(10)
line(O, Point(10, 10))
```

# Arguments:
- `linewidth`: the line width in pixel
"""
function setline(linewidth)
    cs = get_current_setting()
    cs.line_width = linewidth
    current_line_width = cs.line_width * cs.mul_line_width
    Luxor.setline(current_line_width)
end

"""
    setopacity(opacity)

Set the opacity and multiply it with the current multiplier
which is i.e. set by [`appear`](@ref) and [`disappear`](@ref).

Normal behavior without any animation is the same as `Luxor.setopacity`.

# Example
```
setopacity(0.5)
circle(O, 20, :fill)
```

# Arguments:
- `opacity`: the opacity between 0.0 and 1.0
"""
function setopacity(opacity)
    cs = get_current_setting()
    cs.opacity = opacity
    current_opacity = cs.opacity * cs.mul_opacity
    Luxor.setopacity(current_opacity)
end

"""
    fontsize(fsize)

Same as `Luxor.fontsize`: Sets the current font size.

# Example
```
fontsize(12)
text("Hello World!")
```

# Arguments:
- `fsize`: the new font size
"""
function fontsize(fsize)
    cs = get_current_setting()
    cs.fontsize = fsize
    Luxor.fontsize(fsize)
end

"""
    get_fontsize(fsize)

Same as `Luxor.get_fontsize` but works with every version of Luxor that is supported by Javis.

# Example
```
fontsize(12)
fsize = get_fontsize()
text("Hello World! \$fsize")
```

# Returns
- `Float64`: the current font size
"""
function get_fontsize()
    cs = get_current_setting()
    return cs.fontsize
end

"""
    scale(scl)

Set the scale and multiply it with the current multiplier
which is i.e. set by [`appear`](@ref) and [`disappear`](@ref).

Normal behavior without any animation is the same as `Luxor.scale`.

# Example
```
scale(0.5)
circle(O, 20, :fill) # the radius would be 10 because of the scaling
```

# Arguments:
- `scl`: the new default scale
"""
function scale(scl::Number)
    scale(scl, scl)
end

function scale(scl::Scale)
    scale(scl.x, scl.y)
end

"""
    scale(scl_x, scl_y)

Same as [`scale`](@ref) but the x scale and y scale can be changed independently.

# Arguments:
- `scl_x`: scale in x direction
- `scl_y`: scale in y direction
"""
function scale(scl_x, scl_y)
    cs = get_current_setting()
    cs.desired_scale = Scale(scl_x, scl_y)
    scale_by = cs.desired_scale * cs.mul_scale
    if scale_by.x ≈ 0.0 || scale_by.y ≈ 0.0
        cs.show_object = false
    else
        Luxor.scale(scale_by.x, scale_by.y)
        cs.current_scale = cs.current_scale * scale_by
    end
end

scaleto(s::Scale) = scaleto(s.x, s.y)
scaleto(xy) = scaleto(xy, xy)

"""
    scaleto(x, y)

Scale to a specific scaling instead of multiplying it with the current scale.
For scaling on top of the current scale have a look at [`scale`](@ref).
"""
function scaleto(x, y)
    cs = get_current_setting()
    cs.desired_scale = Scale(x, y)
    scaling = Scale(x, y) / cs.current_scale
    # we divided by 0 but clearly we want to scale to 0
    # -> we want scaling to be 0 not Inf
    if x ≈ 0 || y ≈ 0
        cs.show_object = false
        return
    end
    Luxor.scale(scaling.x, scaling.y)
    cs.current_scale = Scale(x, y)
end

"""
    animate_text(
        str,
        pos::Point,
        valign::Symbol,
        halign::Symbol,
        angle::Float64,
        t::Float64,
    )

This function is used as a subfunction of [`text`](@ref) and animates the `str` by
clipping the textoutlines and creating a growing circle in the lower left corner to display
the text from left to right in an animated fashion.
"""
function animate_text(
    str,
    pos::Point,
    valign::Symbol,
    halign::Symbol,
    angle::Float64,
    t::Float64,
)
    if t >= 1
        return Luxor.text(str, pos; valign = valign, halign = halign, angle = angle)
    end

    # copied from Luxor.text
    xbearing, ybearing, textwidth, textheight, xadvance, yadvance = textextents(str)
    halignment = findfirst(isequal(halign), [:left, :center, :right, :centre])

    # if unspecified or wrong, default to left, also treat UK spelling centre as center
    if halignment === nothing
        halignment = 1
    elseif halignment == 4
        halignment = 2
    end

    textpointx = pos.x - [0, textwidth / 2, textwidth][halignment]

    valignment = findfirst(isequal(valign), [:top, :middle, :baseline, :bottom])

    # if unspecified or wrong, default to baseline
    if valignment === nothing
        valignment = 3
    end

    textpointy = pos.y - [ybearing, ybearing / 2, 0, textheight + ybearing][valignment]


    gsave()
    translate(Point(textpointx, textpointy))
    rotate(angle)
    # clipping region
    textoutlines(str, O, :clip)
    complete_radius = sqrt(textwidth^2 + textheight^2)
    r = t * complete_radius
    circle(O, r, :fill)
    grestore()
    return Point(textpointx, textpointy)
end

"""
    text(str, pos = O; valign = :baseline, halign = :left, angle = 0.0)

Has bacially the same functionality as Luxor.text but overrides that method to allow to
animate text with [`appear`](@ref).

# Example
```julia
text_obj = Object(1:100, (args...) -> text("Hello Stream!"; halign = :center))
act!(text_obj, Action(1:15, sineio(), appear(:draw_text)))
act!(text_obj, Action(76:100, sineio(), disappear(:draw_text)))
```
draws the text from left to right in the first 15 frames and in the last 15 frames it disappears.

# Arguments
- `str::AbstractString` the string that should be shown
- `pos::Point` defaults to the origin and can be written as `x,y` as well as `Point(x,y)`.

# Keywords
- `valign::Symbol` defaults to `:baseline` and takes `(:top, :middle, :bottom, :baseline)`
- `halign::Symbol` defaults to `:left` and takes `(:left, :center, :centre, :right)`
- `angle::Float64` defaults to `0.0` and specifies the angle of the text
"""
function text(str, pos = O; valign = :baseline, halign = :left, angle = 0.0)
    object = CURRENT_OBJECT[1]
    opts = object.opts
    t = get(opts, :draw_text_t, 1.0)
    return animate_text(str, pos, valign, halign, angle, t)
end

function text(str, x, y; kwargs...)
    text(str, Point(x, y); kwargs...)
end
