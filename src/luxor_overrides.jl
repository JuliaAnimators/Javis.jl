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
    setopacity(linewidth)

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

function fontsize(fsize)
    cs = get_current_setting()
    cs.fontsize = fsize
    Luxor.fontsize(fsize)
end

function get_fontsize()
    cs = get_current_setting()
    return cs.fontsize
end
