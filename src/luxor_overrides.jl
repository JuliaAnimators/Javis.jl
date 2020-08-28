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
    cs.scale = (scl_x, scl_y)
    current_scale = cs.scale .* cs.mul_scale
    Luxor.scale(current_scale...)
    cs.current_scale = cs.current_scale .* current_scale
end
