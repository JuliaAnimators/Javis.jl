function _JLine(p1, p2, color)
    sethue(color)
    line(p1, p2, :stroke)
    return p2
end

"""
    JLine(p1::Point, p2::Point, color="black")

Make a line between two points, pt1 and pt2 and do an action.
Returns the final point of the line
"""
JLine(p1::Point, p2::Point; color = "black") =
    (args...; color = color, p1 = p1, p2 = p2) -> _JLine(p1, p2, color)

"""
    JLine(pt::Point)

Draw a line from the origin to the pt.
Returns the final point of the line
"""
JLine(pt::Point; color = "black") = JLine(O, pt, color = color)
