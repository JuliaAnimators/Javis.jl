# TODO: Add scaling logic for each shape; see https://github.com/JuliaAnimators/Javis.jl/pull/399#issuecomment-1003549900 for details on what to do

function _JImage(pos, img, centering, shapeargs, shape, scaleargs)
    if !isnothing(shape)
        bbox = BoundingBox(shape(shapeargs...))
    end

    if scaleargs == :inset
        if Symbol(shape) == :box
            boxside = max(boxwidth(bbox), boxheight(bbox))
            imageside = max(img.width, img.height)

            scalefactor = boxside / imageside

            box(bbox, :clip)

            translate(boxmiddlecenter(bbox))
            scale(scalefactor)
        elseif Symbol(shape) == :star
            bbox = BoundingBox(circle(shapeargs.center, shapeargs.radius * shapeargs.ratio))
            boxside = max(boxwidth(bbox), boxheight(bbox))
            imageside = max(img.width, img.height)
            circle(shapeargs.center, shapeargs.radius * shapeargs.ratio, action = :clip)

            scalefactor = boxside / imageside

            translate(boxmiddlecenter(bbox))
            scale(scalefactor)
        end
    elseif scaleargs == :clip
        if Symbol(shape) == :box
            boxside = min(boxwidth(bbox), boxheight(bbox))
            imageside = min(img.width, img.height)

            box(bbox, :clip)

            scalefactor = boxside / imageside

            translate(boxmiddlecenter(bbox))
            scale(scalefactor)
        elseif Symbol(shape) == :star
            boxside = min(boxwidth(bbox), boxheight(bbox))
            imageside = min(img.width, img.height)

            star(
                shapeargs.center,
                shapeargs.radius,
                shapeargs.npoints,
                shapeargs.ratio,
                shapeargs.orientation,
                action = :clip,
            )

            scalefactor = boxside / imageside

            translate(boxmiddlecenter(bbox))
            scale(scalefactor)
        end
    else
        scale(scaleargs)
    end

    placeimage(img, pos, centered = centering)
    return pos
end

"""
    JImage(pos::Point, img::CairoSurfaceBase{UInt32}, centering = true; shapeargs = (), shape = nothing, scaleargs = 1)

Place a given image at a given location as a `Javis` object.
Images can be cropped to different shapes and scaled to different sizes while being placed.

# Arguments
- `pos::Point`: Where to place the image inside a shape.
- `img::CairoSurfaceBase{UInt32}`: Expects a CairoSurfaceBase object via `readpng("your_image.png")`
- `centering::Bool`: Centers the object at `pos`
- `shapeargs`: Arguments to be passed to a given shape type
- `shape`: A Luxor shape function such as `circle`, `box`, etc.
- `scaleargs`: The arguments used for scaling the image used on the shape

# Return

Returns the position of the image location, `pos`.
"""
JImage(
    pos::Point,
    img::CairoSurfaceBase{UInt32},
    centering::Bool = true;
    shapeargs = (),
    shape = nothing,
    scaleargs = :inset,
) =
    (
        args...;
        pos = pos,
        img = img,
        centering = centering,
        shapeargs = shapeargs,
        shape = shape,
        scaleargs = scaleargs,
    ) -> _JImage(pos, img, centering, shapeargs, shape, scaleargs)

"""
    JImage(pos::Point, img::String, centering = true; shapeargs = (), shape = nothing, scaleargs = 1)

Place a given image at a given location as a `Javis` object.
Images can be cropped to different shapes and scaled to different sizes while being placed.

# Arguments
- `pos::Point`: Where to place the image inside a shape
- `img::String`: Expects the path to an image
- `centering::Bool`: Centers the object at `pos`
- `shapeargs`: Arguments to be passed to a given shape type
- `shape`: A Luxor shape function such as `circle`, `box`, etc.
- `scaleargs`: The arguments used for scaling the image used on the shape

# Return

Returns the position of the image location, `pos`.
"""
JImage(
    pos::Point,
    img::String,
    centering::Bool = true;
    shapeargs = (),
    shape = nothing,
    scaleargs = :inset,
) =
    (
        args...;
        pos = pos,
        img = readpng(img),
        centering = centering,
        shapeargs = shapeargs,
        shape = shape,
        scaleargs = scaleargs,
    ) -> _JImage(pos, img, centering, shapeargs, shape, scaleargs)
