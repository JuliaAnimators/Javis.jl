function _JRect(cornerpoint::Point, w::Real, h::Real, color::String, action::Symbol, vertices::Bool)
    sethue(color)
    rect(cornerpoint, w, h, action; vertices=vertices)
end
JRect(cornerpoint::Point, w::Real, h::Real; color="black", action=:stroke, vertices=false) = (args...) -> _JRect(cornerpoint, w, h, color, action, vertices)
JRect(xmin::Int64, ymin::Int64, w::Real, h::Real; color="black", action=:stroke) = JRect(Point(xmin, ymin), w, h, color=color, action=action)
