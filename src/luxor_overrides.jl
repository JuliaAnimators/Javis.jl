"""
    setline(linewidth)

Set the line width and multiply it with the current multiplier
which is i.e. set by [`appear`](@ref) and [`disappear`](@ref).

# Arguments:
- `linewidth`: the line width in pixel
"""
function setline(linewidth)
    action = CURRENT_ACTION[1]
    cs  = action.current_setting
    cs.line_width  = linewidth
    current_line_width = cs.line_width * cs.mul_line_width
    Luxor.setline(current_line_width)
end

"""
    setopacity(linewidth)

Set the opacity and multiply it with the current multiplier
which is i.e. set by [`appear`](@ref) and [`disappear`](@ref).

# Arguments:
- `opacity`: the opacity between 0.0 and 1.0
"""
function setopacity(opacity)
    action = CURRENT_ACTION[1]
    cs  = action.current_setting
    cs.opacity  = opacity
    current_opacity = cs.opacity * cs.mul_opacity
    Luxor.setopacity(current_opacity)
end
