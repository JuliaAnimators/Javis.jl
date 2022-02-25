function _JRect(
    cornerpoint::Point,
    w::Real,
    h::Real,
    color,
    linewidth::Real,
    action::Symbol,
)
    sethue(color)
    setline(linewidth)
    rect(cornerpoint, w, h, action)
    return cornerpoint
end

"""
    1. JRect(cornerpoint::Point, w::Real, h::Real; kwargs...)
    2. JRect(xmin::Int64, ymin::Int64, w::Real, h::Real; kwargs...)
        - same as 1. with `cornerpoint = Point(xmin, ymin)`

Create a rectangle with one corner at cornerpoint with width w and height h and do an action.
You can specify the `linewidth` and the `color` of the rectangle.

# Keywords for all
- `color` = "black"
- `linewidth` = 2
- `action` Defines whether the rectangle should be outlined (`:stroke`) or filled (`:fill`)
"""
JRect(
    cornerpoint::Point,
    w::Real,
    h::Real;
    color = "black",
    linewidth = 2,
    action = :stroke,
) =
    (
        args...;
        cornerpoint = cornerpoint,
        w = w,
        h = h,
        color = color,
        linewidth = linewidth,
        action = action,
    ) -> _JRect(cornerpoint, w, h, color, linewidth, action)

JRect(xmin::Int64, ymin::Int64, w::Real, h::Real; kwargs...) =
    JRect(Point(xmin, ymin), w, h; kwargs...)
