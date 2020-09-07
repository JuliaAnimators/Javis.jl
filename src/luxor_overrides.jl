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

"""
    scale(scl_x, scl_y)

Same as [`scale`](@ref) but the x scale and y scale can be changed independently.

# Arguments:
- `scl_x`: scale in x direction
- `scl_y`: scale in y direction
"""
function scale(scl_x, scl_y)
    cs = get_current_setting()
    cs.desired_scale = (scl_x, scl_y)
    current_scale = cs.desired_scale .* cs.mul_scale
    Luxor.scale(current_scale...)
    cs.current_scale = cs.current_scale .* current_scale
    # println("cs.current_scale: $(cs.current_scale)")
end

scaleto(xy) = scaleto(xy, xy)

"""
    scaleto(x, y)

Scale to a specific scaling instead of multiplying it with the current scale.
For scaling on top of the current scale have a look at [`scale`](@ref).
"""
function scaleto(x, y)
    cs = get_current_setting()
    cs.desired_scale = (x, y)
    scaling = (x, y) ./ cs.current_scale
    # we divided by 0 but clearly we want to scale to 0
    # -> we want scaling to be 0 not Inf
    if x ≈ 0
        scaling = (0.0, scaling[2])
    end
    if y ≈ 0
        scaling = (scaling[1], 0.0)
    end
    Luxor.scale(scaling...)
    cs.current_scale = (x, y)
end
