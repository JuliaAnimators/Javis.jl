function _JLine(p1, p2, color)
    sethue(color)
    line(p1, p2,:stroke)
end
JLine(p1, p2, color="black") = (args...) -> _JLine(p1, p2, color)
JLine(p2) = JLine(O, p2)