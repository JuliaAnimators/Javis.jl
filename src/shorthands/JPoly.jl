function _JPoly(pointlist, color, linewidth, action, close, reversepath)
    sethue(color)
    setline(linewidth)
    poly(pointlist, action; close = close, reversepath = reversepath)
end

"""
    JPoly(pointlist::Vector{Point}; color="black", linewidth=1, action = :stroke, close=true, reversepath=false)

Draw a polygon around points in the pointlist.

# Keywords
- `color` specifies the color of the outline or the fill of it (depends on action)
- `linewidth` linewidth of the outline
- `action` can be `:stroke`, `:fill` or other symbols (check the Luxor documentation for details) (default: :stroke)
- `close` whether the polygon should be closed or not (default: closed)
- `reversepath` can be set to `true` to reverse the path and create a polygon hole
"""
JPoly(
    pointlist::Vector{Point};
    color = "black",
    linewidth = 1,
    action = :stroke,
    close = true,
    reversepath = false,
) =
    (
        args...;
        pointlist = pointlist,
        color = color,
        linewidth = linewidth,
        action = action,
    ) -> _JPoly(pointlist, color, linewidth, action, close, reversepath)

"""
TODO: Add documentation
"""
JPoly(
    pointlist,
    color = "white",
    linewidth = 1,
    action = :stroke,
    close = true,
    reversepath = false,
    image_path = "",
    scale_factor = :inset,
) =
    (
        args...;
        pointlist = pointlist,
        color = color,
        linewidth = linewidth,
        action = action,
        image_path = image_path,
        scale_factor = scale_factor,
    ) -> _JPoly(
        pointlist,
        color,
        linewidth,
        action,
        close,
        reversepath,
        image_path,
        scale_factor,
    )

function _JPoly(
    pointlist,
    color,
    linewidth,
    action,
    close,
    reversepath,
    image_path,
    scale_factor,
)
    img = readpng(image_path)
    bbox = BoundingBox(poly(pointlist, :path))

    if !isnothing(color)
        sethue(color)
        setline(linewidth)
        poly(pointlist, action; close = close, reversepath = reversepath)
    end

    if scale_factor == :inset
        boxside = max(boxwidth(bbox), boxheight(bbox))
        imageside = max(img.width, img.height)
    elseif scale_factor == :clip
        boxside = min(boxwidth(bbox), boxheight(bbox))
        imageside = min(img.width, img.height)
    end
    
    poly(pointlist, :clip)
    scalefactor = boxside / imageside

    translate(boxmiddlecenter(bbox))
    scale(scalefactor)
    placeimage(img, centered = true)

end
