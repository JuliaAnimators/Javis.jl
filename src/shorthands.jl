function _JLine(p1, p2, color)
    sethue(color)
    line(p1, p2,:stroke)
end
JLine(p1, p2; color="black") = (args...) -> _JLine(p1, p2, color)
JLine(p2) = JLine(O, p2)


function _JCircle(center, radius, color, action)
    sethue(color)
    circle(center, radius, action)
    return
end
JCircle(center::Point, radius::Real; color="black", action=:fill) = (args...) -> _JCircle(center, radius, color, action)
JCircle(center_x::Real, center_y::Real, radius::Real; color="black", action=:fill) = JCircle(Point(center_x, center_y), radius, color=color, action=action)
JCircle(p1::Real, p2::Real; color="black", action=:fill) = JCircle(midpoint(p1, p2), distance(pt1, pt2)/2, color=color, action=action)
JCircle(radius::Real; color="black", action=:fill) = JCircle(O, radius, color=color, action=action)