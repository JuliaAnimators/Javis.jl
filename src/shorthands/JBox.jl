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
