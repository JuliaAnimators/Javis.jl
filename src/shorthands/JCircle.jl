function _JCircle(center, radius, color, linewidth, action)
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

Draw a circle at `center` with the given `radius`

# Keywords for all
- `color` = "black"
- `linewidth` = 1
- `action::Symbol` :stroke by default can be `:fill` or other actions explained in the Luxor documentation.

Returns the center of the circle
"""
JCircle(center::Point, radius::Real; color = "black", linewidth = 1, action = :stroke) =
    (
        args...;
        center = center,
        radius = radius,
        color = color,
        linewidth = linewidth,
        action = action,
    ) -> _JCircle(center, radius, color, linewidth, action)

JCircle(center_x::Real, center_y::Real, radius::Real; kwargs...) =
    JCircle(Point(center_x, center_y), radius; kwargs...)

JCircle(p1::Point, p2::Point; kwargs...) =
    JCircle(midpoint(p1, p2), distance(p1, p2) / 2; kwargs...)

JCircle(radius::Real; kwargs...) = JCircle(O, radius; kwargs...)

"""
TODO: Add Documentation!
"""
JCircle(
    center::Point,
    radius::Real,
    color = "black",
    linewidth = 1,
    action = :stroke,
    image_path = "",
    scale_factor = :inset,
) =
    (
        args...;
        center = center,
        radius = radius,
        color = color,
        linewidth = linewidth,
        action = action,
        image_path = image_path,
        scale_factor = scale_factor,
    ) -> _JCircle(center, radius, color, linewidth, action, image_path, scale_factor)

function _JCircle(center, radius, color, linewidth, action, image_path, scale_factor)
    
    bbox = BoundingBox(circle(center, radius, :path))

    if !isnothing(color)
        sethue(color)
	circle(center, radius, :fill)
    end

    img = readpng(image_path)

    if scale_factor == :inset
        side = sqrt((radius * 2)^2 / 2)
        bbox = BoundingBox(box(O, side, side, action = :path))
        boxside = max(boxwidth(bbox), boxheight(bbox))
        imageside = max(img.width, img.height)
        box(O, side, side, action = :clip)
    elseif scale_factor == :clip
        bbox = BoundingBox(circle(O, radius, action = :path))
        boxside = min(boxwidth(bbox), boxheight(bbox))
        imageside = min(img.width, img.height)
        circle(O, radius, action = :clip)
    end

    scalefactor = boxside / imageside

    translate(boxmiddlecenter(bbox))
    scale(scalefactor)
    placeimage(img, centered = true)
    return center
end
