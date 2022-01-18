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
    center::Point,
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

"""
TODO: Add documentation docstring
"""
JStar(
    center::Point,
    radius,
    color = "black",
    linewidth = 1,
    npoints = 5,
    ratio = 0.5,
    orientation = 0,
    action = :stroke,
    reversepath = false,
    image_path = "",
    scale_factor = :inset,
) =
    (
        args...;
        center = center,
        radius = radius,
        color = color,
        linewidth = linewidth,
        orientation = orientation,
        action = action,
        npoints = npoints,
        image_path = image_path,
        scale_factor = scale_factor,
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
        image_path,
        scale_factor,
    )

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
    image_path,
    scale_factor,
)
    img = readpng(image_path)
    bbox = BoundingBox(
        star(center, radius, npoints, ratio, orientation, :path, reversepath = reversepath),
    )
    if !isnothing(color)
        sethue(color)
        star(center, radius, npoints, ratio, orientation, :fill, reversepath = reversepath)
    end
    if scale_factor == :inset
        bbox = BoundingBox(circle(center, radius * ratio))
        boxside = max(boxwidth(bbox), boxheight(bbox))
        imageside = max(img.width, img.height)
        circle(center, radius * ratio, action = :clip)

        scalefactor = boxside / imageside

        translate(boxmiddlecenter(bbox))
        scale(scalefactor)
    elseif scale_factor == :clip
        boxside = min(boxwidth(bbox), boxheight(bbox))
        imageside = min(img.width, img.height)

        star(center, radius, npoints, ratio, orientation, action = :clip)

        scalefactor = boxside / imageside

        translate(boxmiddlecenter(bbox))
        scale(scalefactor)
    end

    sethue(color)
    setline(linewidth)

    placeimage(img, center, centered = true)

    return center
end
