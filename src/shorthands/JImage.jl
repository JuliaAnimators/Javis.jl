function _JImage(pos, img, centering, clipargs, clipshape)
    if clipshape != false
        clipshape(clipargs...)
    end
    placeimage(img, pos, centered = centering)
    return pos
end

JImage(pos::Point, img, centering = true; clipargs = (), clipshape = false) =
    (
        args...;
        pos = pos,
        img = img,
        centering = centering,
        clipargs = clipargs,
        clipshape = clipshape,
    ) -> _JImage(pos, img, centering, clipargs, clipshape)
