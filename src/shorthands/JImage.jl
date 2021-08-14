function _JImage(pos, img, centering, shapeargs, shape)
    if shape != false
        shape(shapeargs...)
    end
    placeimage(img, pos, centered = centering)
    return pos
end

JImage(pos::Point, img, centering = true; shapeargs = (), shape = false) =
    (
        args...;
        pos = pos,
        img = img,
        centering = centering,
        shapeargs = shapeargs,
        shape = shape,
    ) -> _JImage(pos, img, centering, shapeargs, shape)
