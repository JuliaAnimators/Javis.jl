function _JStar(
    center,
    radius,
    color,
    npoints,
    ratio,
    orientation,
    action,
    vertices,
    reversepath,
)
    sethue(color)
    star(
        center,
        radius,
        npoints,
        ratio,
        orientation,
        action,
        vertices = vertices,
        reversepath = reversepath,
    )
    return center
end

"""
    JStar(center, radius; color = "black", npoints=5, ratio=0.5, orientation=0, action=:stroke, vertices = false, reversepath=false)

Draw a star centered at a position. Returns the center of the star.
"""
JStar(
    center,
    radius;
    color = "black",
    npoints = 5,
    ratio = 0.5,
    orientation = 0,
    action = :stroke,
    vertices = false,
    reversepath = false,
) =
    (
        args...;
        center = center,
        radius = radius,
        color = color,
        action = action,
        npoints = npoints,
        vertices = vertices,
    ) -> _JStar(
        center,
        radius,
        color,
        npoints,
        ratio,
        orientation,
        action,
        vertices,
        reversepath,
    )

"""
    JStar(xcenter, ycenter, radius; color = "black", npoints=5, ratio=0.5, orientation=0, action=:stroke, vertices = false, reversepath=false)

Make a star. ratio specifies the height of the smaller radius of the star relative to the larger. Use vertices=true to return the vertices of a star instead of drawing it.
Returns the center of the star.
"""
JStar(
    xcenter,
    ycenter,
    radius;
    color = "black",
    npoints = 5,
    ratio = 0.5,
    orientation = 0,
    action = :stroke,
    vertices = false,
    reversepath = false,
) = JStar(
    Point(xcenter, ycenter),
    radius,
    color = color,
    npoints = npoints,
    ratio = ratio,
    orientation = orientation,
    action = action,
    vertices = vertices,
    reversepath = reversepath,
)
