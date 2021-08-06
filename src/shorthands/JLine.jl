function _JLine(p1, p2, linewidth, color)
    sethue(color)
    setline(linewidth)
    line(p1, p2, :stroke)
    return p2
end

"""
    1. JLine(p1::Point, p2::Point; kwargs...)
    2. JLine(pt2::Point; kwargs...)
        - `pt1` is set as the origin `O`

# Keywords for all
- `color` = "black"
- `linewidth` = 1

Draw a line between the points pt1 and pt2.
Returns the final point of the line
"""
JLine(p1::Point, p2::Point; linewidth = 1, color = "black") =
    (args...; color = color, linewidth = linewidth, p1 = p1, p2 = p2) -> _JLine(p1, p2, linewidth, color)

JLine(pt::Point; kwargs...) = JLine(O, pt; kwargs...)
