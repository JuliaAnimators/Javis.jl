function _JLine(p1, p2, linewidth, color)
    sethue(color)
    setline(linewidth)
    line(p1, p2, :stroke)
    return p2
end

"""
    1. JLine(pt1::Point, pt2::Point; kwargs...)
    2. JLine(pt2::Point; kwargs...)
        - `pt1` is set as the origin `O`

# Keywords for all
- `color` = "black"
- `linewidth` = 1

Draw a line between the points pt1 and pt2.
Returns the final point of the line
"""
JLine(pt1::Point, pt2::Point; linewidth = 1, color = "black") =
    (args...; color = color, linewidth = linewidth, pt1 = pt1, pt2 = pt2) ->
        _JLine(pt1, pt2, linewidth, color)

JLine(pt::Point; kwargs...) = JLine(O, pt; kwargs...)
