function _JRect(
    cornerpoint::Point,
    w::Real,
    h::Real,
    color,
    linewidth::Real,
    action::Symbol,
)
    sethue(color)
    setline(linewidth)
    rect(cornerpoint, w, h, action)
    return cornerpoint
end

"""
    1. JRect(cornerpoint::Point, w::Real, h::Real; kwargs...)
    2. JRect(xmin::Int64, ymin::Int64, w::Real, h::Real; kwargs...)
        - same as 1. with `cornerpoint = Point(xmin, ymin)`

Create a rectangle with one corner at cornerpoint with width w and height h and do an action.
You can specify the `linewidth` and the `color` of the rectangle.

# Keywords for all
- `color` = "black"
- `linewidth` = 1
- `action` Defines whether the rectangle should be outlined (`:stroke`) or filled (`:fill`)
"""
JRect(
    cornerpoint::Point,
    w::Real,
    h::Real;
    color = "black",
    linewidth = 1,
    action = :stroke,
) =
    (
        args...;
        cornerpoint = cornerpoint,
        w = w,
        h = h,
        color = color,
        linewidth = linewidth,
        action = action,
    ) -> _JRect(cornerpoint, w, h, color, linewidth, action)

JRect(xmin::Int64, ymin::Int64, w::Real, h::Real; kwargs...) =
    JRect(Point(xmin, ymin), w, h; kwargs...)


"""
TODO: Add Documentation
"""
JRect(
    cornerpoint::Point,
    w::Real,
    h::Real,
    color = "black",
    linewidth = 1,
    action = :stroke,
    image_path = "",
    scale_factor = :inset
) =
    (
        args...;
        cornerpoint = cornerpoint,
        w = w,
        h = h,
        color = color,
        linewidth = linewidth,
        action = action,
	image_path = image_path,
	scale_factor = scale_factor
    ) -> _JRect(cornerpoint, w, h, color, linewidth, action, image_path, scale_factor)

function _JRect(
    cornerpoint::Point,
    w::Real,
    h::Real,
    color,
    linewidth::Real,
    action::Symbol,
    image_path,
    scale_factor
)
    bbox = BoundingBox(box(cornerpoint, w, h, :path))

    if !isnothing(color)
        sethue(color)
        box(cornerpoint, w, h, :fill)
    end

    img = readpng(image_path)

    if scale_factor == :inset
	side = minimum([w, h])
        bbox = BoundingBox(box(cornerpoint, side, side, action = :path))
        boxside = max(boxwidth(bbox), boxheight(bbox))
        imageside = max(img.width, img.height)
        box(cornerpoint, side, side, action = :clip)
    elseif scale_factor == :clip
        bbox = BoundingBox(rect(O, w, h, action = :path))
        boxside = min(boxwidth(bbox), boxheight(bbox))
        imageside = min(img.width, img.height)
        rect(O, w, h, action = :clip)
    end

    translate(boxmiddlecenter(bbox))
    scale(boxside / imageside)
    placeimage(img, centered = true)
    return cornerpoint
end
