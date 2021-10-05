function _JImage(pos, img, centering, shapeargs, shape, scaleargs)
    if !isnothing(shape)
        shape(shapeargs...)
    end
    scale(scaleargs)
    placeimage(img, pos, centered = centering)
    return pos
end

"""
    JImage(pos::Point, img, centering = true; shapeargs = (), shape = nothing, scaleargs = 1)

Place a given image at a given location as a `Javis` object.
Images can be cropped to different shapes and scaled to different sizes while being placed.

Returns the position of the image location.
"""
JImage(pos::Point, img, centering = true; shapeargs = (), shape = nothing, scaleargs = 1) =
    (
        args...;
        pos = pos,
        img = img,
        centering = centering,
        shapeargs = shapeargs,
        shape = shape,
	scaleargs = scaleargs,
    ) -> _JImage(pos, img, centering, shapeargs, shape, scaleargs)
