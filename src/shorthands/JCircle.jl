function _JCircle(center, radius, linewidth, color, action)
    sethue(color)
    setline(linewidth)
    circle(center, radius, action)
    return center
end

"""
    1. JCircle(center::Point, radius::Real; kwargs...)
    2. JCircle(center_x::Real, center_y::Real, radius::Real; kwargs...)
    3. JCircle(p1::Point, p2::Point; kwargs...)
        - A circle that touches `p1` and `p2`
    4. JCircle(radius::Real)
        - A circle at the origin

# Keywords for all
- `color` = "black"
- `linewidth` = 1
- `action::Symbol` :stroke by default can be ``:fill` or other actions explained in the Luxor documentation.

Returns the center of the circle
"""
JCircle(center::Point, radius::Real; color = "black", linewidth = 1, action = :stroke) =
    (args...; center = center, radius = radius, color = color, action = action) ->
        _JCircle(center, radius, linewidth, color, action)

JCircle(center_x::Real, center_y::Real, radius::Real; kwargs...) =
    JCircle(Point(center_x, center_y), radius; kwargs...)

JCircle(p1::Point, p2::Point; kwargs...) =
    JCircle(midpoint(p1, p2), distance(p1, p2) / 2; kwargs...)

JCircle(radius::Real; kwargs...) = JCircle(O, radius; kwargs...)
