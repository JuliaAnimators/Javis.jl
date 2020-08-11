"""
    setline(linewidth)

Set the line width and multiplies it the current multiplier which is i.e. set by [`appear`](@ref) and [`disappear`](@ref).

# Arguments:
- `linewidth`: the line width in pixel
"""
function setline(linewidth)
    action = CURRENT_ACTION[1]
    cs  = action.current_setting
    current_line_width = linewidth * cs.mul_line_width
    Luxor.setline(current_line_width)
end