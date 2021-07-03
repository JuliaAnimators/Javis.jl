function _JCircle(center, radius, color, action)
    sethue(color)
    circle(center, radius, action)
    return
end
JCircle(center::Point, radius::Real; color="black", action=:stroke) = (args...) -> _JCircle(center, radius, color, action)
JCircle(center_x::Real, center_y::Real, radius::Real; color="black", action=:stroke) = JCircle(Point(center_x, center_y), radius, color=color, action=action)
JCircle(p1::Real, p2::Real; color="black", action=:stroke) = JCircle(midpoint(p1, p2), distance(pt1, pt2)/2, color=color, action=action)
JCircle(radius::Real; color="black", action=:stroke) = JCircle(O, radius, color=color, action=action)
