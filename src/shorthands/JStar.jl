function _JStar(
    center,
    radius,
    color,
    linewidth,
    npoints,
    ratio,
    orientation,
    action,
    reversepath,
)
    sethue(color)
    setline(linewidth)
    center = get_position(center)
    star(center, radius, npoints, ratio, orientation, action, reversepath = reversepath)
    return center
end

"""
    1. JStar(center::Point, radius; kwargs...)
    2. JStar(xcenter, ycenter, radius; kwargs...)
        - same as 1. with `center = Point(xcenter, ycenter)`

Draw a star centered at a position. 
Return the center of the star.

# Keywords for all
- `color` color of the outline or fill of the star (default: "black")
- `linewidth` linewidth of the outline (default: 1)
- `action` defines whether the rectangle should be outlined (`:stroke`) or filled (`:fill`)
- `npoints` number of points the star has (default: 5)
- `ratio` height of the smaller radius relative to the larger radius (default: 0.5)
- `orientation` orientation of the star given by an angle (default: 0)
- `reversepath` if true it reverses the path and therefore creates a hole (default: true)
"""
JStar(
    center::PointOrDelayed,
    radius;
    color = "black",
    linewidth = 1,
    npoints = 5,
    ratio = 0.5,
    orientation = 0,
    action = :stroke,
    reversepath = false,
) =
    (
        args...;
        center = center,
        radius = radius,
        color = color,
        linewidth = linewidth,
        action = action,
        npoints = npoints,
    ) -> _JStar(
        center,
        radius,
        color,
        linewidth,
        npoints,
        ratio,
        orientation,
        action,
        reversepath,
    )

JStar(xcenter, ycenter, radius; kwargs...) =
    JStar(Point(xcenter, ycenter), radius; kwargs...)
