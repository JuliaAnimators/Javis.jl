function _JLine(p1, p2, color)
    sethue(color)
    line(p1, p2,:stroke)
end
JLine(p1, p2, color="black") = (args...) -> _JLine(p1, p2, color)
JLine(p2) = JLine(O, p2)


function _JCircle(center, radius, color, action)
    sethue(color)
    circle(center, radius, action)
    return
end
JCircle(center::Point, radius::Real; color="black", action=:fill) = (args...) -> _JCircle(center, radius, color, action)
JCircle(center_x::Real, center_y::Real, radius::Real; color="black", action=:fill) = JCircle(Point(center_x, center_y), radius, color=color, action=action)
JCircle(p1::Real, p2::Real; color="black", action=:fill) = JCircle(midpoint(p1, p2), distance(pt1, pt2)/2, color=color, action=action)
JCircle(radius::Real; color="black", action=:fill) = JCircle(O, radius, color=color, action=action)

# test box and rect
function _JRect(cornerpoint::Point, w::Real, h::Real, color::String, action::Symbol, vertices::Bool)
    sethue(color)
    rect(cornerpoint, w, h, action; vertices=vertices)
end
JRect(cornerpoint::Point, w::Real, h::Real; color="black", action=:stroke, vertices=false) = (args...) -> _JRect(cornerpoint, w, h, color, action, vertices)
JRect(xmin::Int64, ymin::Int64, w::Real, h::Real; color="black", action=:stroke) = JRect(Point(xmin, ymin), w, h, color=color, action=action)


function _JBox(cornerpoint1::Point, cornerpoint2::Point, color::String, action::Symbol, vertices::Bool)
    sethue(color)
    box(cornerpoint1, cornerpoint2, action, vertices=vertices)
end
function _JBox(points::Array, color::String, action::Symbol, vertices::Bool)
    sethue(color)
    box(points, action, vertices=vertices)
end
function _JBox(pt::Point, width::Real, height::Real, color::String, action::Symbol, vertices::Bool)
    sethue(color)
    box(pt, width, height, action, vertices=vertices)
end
function _JBox(pt::Point, width::Real, height::Real, cornerradius::Float64, color::String, action::Symbol)
    sethue(color)
    box(pt, width, height, cornerradius, action=action)
end
JBox(cornerpoint1::Point, cornerpoint2::Point; color="black", action=:stroke, vertices=false) = (args...) -> _JBox(cornerpoint1, cornerpoint2, color, action, vertices)
JBox(points::Array; color="black", action=:stroke, vertices=false) = (args...) -> _JBox(points, color, action, vertices)
JBox(pt::Point, width::Real, height::Real; color="black", action=:stroke, vertices=false) = (args...) -> _JBox(pt, width, height, color, action, vertices)
JBox(x::Int64, y::Int64, width::Real, height::Real; color="black", action=:stroke) = JBox(Point(x, y), width, height, color=color, action=action)
JBox(pt::Point, width::Real, height::Real, cornerradius::Float64; color="black", action=:stroke) = (args...) -> _JBox(pt, width, height, cornerradius, color, action)

