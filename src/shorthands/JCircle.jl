function _JCircle(center, radius, color, action)
    sethue(color)
    circle(center, radius, action)
    return center
end

"""
    JCircle(center::Point, radius::Real; color="black", action=:stroke)

Make a circle centered at pt.
Returns the center of the circle
"""
JCircle(center::Point, radius::Real; color = "black", action = :stroke) =
    (args...; center = center, radius = radius, color = color, action = action) ->
        _JCircle(center, radius, color, action)

"""
    JCircle(center_x::Real, center_y::Real, radius::Real; color="black", action=:stroke)

Make a circle of radius r centered at x/y.
action is one of the actions applied by do_action, defaulting to :none. You can also use ellipse() to draw circles and place them by their centerpoint.
Returns the center of the circle
"""
JCircle(center_x::Real, center_y::Real, radius::Real; color = "black", action = :stroke) =
    JCircle(Point(center_x, center_y), radius, color = color, action = action)

"""
    JCircle(p1::Real, p2::Real; color="black", action=:stroke)

Make a circle that passes through two points that define the diameter:
Returns the center of the circle
"""
JCircle(p1::Point, p2::Point; color = "black", action = :stroke) =
    JCircle(midpoint(p1, p2), distance(p1, p2) / 2, color = color, action = action)

"""
    JCircle(radius::Real; color="black", action=:stroke)

Make a circle that passes through three points.
Returns the center of the circle
"""
JCircle(radius::Real; color = "black", action = :stroke) =
    JCircle(O, radius, color = color, action = action)
