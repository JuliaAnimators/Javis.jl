function _JRect(
    cornerpoint::Point,
    w::Real,
    h::Real,
    color::String,
    action::Symbol,
    vertices::Bool,
)
    sethue(color)
    rect(cornerpoint, w, h, action; vertices = vertices)
    return cornerpoint
end

"""
    JRect(cornerpoint::Point, w::Real, h::Real; color="black", action=:stroke, vertices=false)

Create a rectangle with one corner at cornerpoint with width w and height h and do an action.
"""
JRect(
    cornerpoint::Point,
    w::Real,
    h::Real;
    color = "black",
    action = :stroke,
    vertices = false,
) =
    (
        args...;
        kcornerpoint = cornerpoint,
        w = w,
        h = h,
        color = color,
        action = action,
        vertices = vertices,
    ) -> _JRect(kcornerpoint, w, h, color, action, vertices)

"""
    JRect(xmin::Int64, ymin::Int64, w::Real, h::Real; color="black", action=:stroke)

Create a rectangle with one corner at (xmin/ymin) with width w and height h and then do an action.
"""
JRect(xmin::Int64, ymin::Int64, w::Real, h::Real; color = "black", action = :stroke) =
    JRect(Point(xmin, ymin), w, h, color = color, action = action)
