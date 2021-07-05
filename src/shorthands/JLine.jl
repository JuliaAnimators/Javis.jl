function _JLine(p1, p2, color)
    sethue(color)
    line(p1, p2, :stroke)
end

"""
    JLine(p1::Point, p2::Point, color="black")

Make a line between two points, pt1 and pt2 and do an action.
"""
JLine(p1::Point, p2::Point, color = "black") =
    (args...; color = color, p1 = p1, p2 = p2) -> _JLine(p1, p2, color)

"""
    JLine(pt::Point)

Draw a line from the origin to the pt.
"""
JLine(pt::Point) = JLine(O, pt)
