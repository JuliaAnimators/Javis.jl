function _JEllipse(cpt::Point, w::Real, h::Real, color, linewidth, action::Symbol)
    sethue(color)
    setline(linewidth)
    ellipse(cpt, w, h, action)
    return cpt
end

function _JEllipse(
    focus1::Point,
    focus2::Point,
    k::Union{Real,Point},
    color,
    linewidth,
    action::Symbol,
    stepvalue,
    reversepath,
)
    sethue(color)
    setline(linewidth)
    ellipse(focus1, focus2, k, action, stepvalue = stepvalue, reversepath = reversepath)
    return focus1, focus2
end

"""
    1. JEllipse(cpt::Point, w::Real, h::Real; kwargs...)
    2. JEllipse(xcenter::Int, ycenter::Int, w::Real, h::Real; kwargs...)

Make an ellipse, centered at point c, with width w, and height h.
Returns the center of the ellipse.

# Keywords for all
- `color` = "black"
- `linewidth` = 1
- `action::Symbol` :stroke by default can be `:fill` or other actions explained in the Luxor documentation.
"""
JEllipse(cpt::Point, w::Real, h::Real; color = "black", linewidth = 1, action = :stroke) =
    (
        args...;
        cpt = cpt,
        w = w,
        h = h,
        color = color,
        linewidth = linewidth,
        action = action,
    ) -> _JEllipse(cpt, w, h, color, linewidth, action)

JEllipse(xc::Int, yc::Int, w::Real, h::Real; kwargs...) =
    JEllipse(Point(xc, yc), w, h; kwargs...)

"""
    JEllipse(focus1::Point, focus2::Point, k::Real; color="black", linewidth=1, action=:stroke, stepvalue=pi/100, vertices=false, reversepath=false)

Build a polygon approximation to an ellipse, given two points and a distance, k, which is the sum of the distances to the focii of any points on the ellipse (or the shortest length of string
required to go from one focus to the perimeter and on to the other focus).
"""
JEllipse(
    focus1::Point,
    focus2::Point,
    k::Real;
    color = "black",
    linewidth = 1,
    action = :stroke,
    stepvalue = pi / 100,
    reversepath = false,
) =
    (
        args...;
        focus1 = focus1,
        focus2 = focus2,
        color = color,
        linewidth = linewidth,
        action = action,
    ) -> _JEllipse(focus1, focus2, k, color, linewidth, action, stepvalue, reversepath)

"""
    JEllipse(focus1::Point, focus2::Point, pt::Point; color="black", linewidth=1, action=:stroke, stepvalue=pi/100, reversepath=false)

Build a polygon approximation to an ellipse, given two points and a point somewhere on the ellipse.
"""
JEllipse(
    focus1::Point,
    focus2::Point,
    pt::Point;
    color = "black",
    linewidth = 1,
    action = :stroke,
    stepvalue = pi / 100,
    reversepath = false,
) =
    (
        args...;
        focus1 = focus1,
        focus2 = focus2,
        color = color,
        linewidth = linewidth,
        action = action,
    ) -> _JEllipse(focus1, focus2, pt, color, linewidth, action, stepvalue, reversepath)
