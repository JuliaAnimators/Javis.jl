function _JImage(pos, img, centering, shapeargs, shape, scaleargs)
    if shape != false
        shape(shapeargs...)
    end
    scale(scaleargs)
    placeimage(img, pos, centered = centering)
    return pos
end

JImage(pos::Point, img, centering = true; shapeargs = (), shape = false, scaleargs = 1) =
    (
        args...;
        pos = pos,
        img = img,
        centering = centering,
        shapeargs = shapeargs,
        shape = shape,
	scaleargs = scaleargs,
    ) -> _JImage(pos, img, centering, shapeargs, shape, scaleargs)
