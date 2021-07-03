function _JEllipse(cpt::Point, w::Real, h::Real, color::String, action::Symbol)
    sethue(color)
    ellipse(cpt, w, h, action)
end

function _JEllipse(focus1::Point, focus2::Point, k::Union{Real, Point}, color::String, action::Symbol, stepvalue, vertices, reversepath)
    sethue(color)
    ellipse(focus1, focus2, k, action, stepvalue=stepvalue, vertices=vertices, reversepath=reversepath)
end

"""
Make an ellipse, centered at point c, with width w, and height h.
"""
JEllipse(cpt::Point, w::Real, h::Real; color ="black",action=:stroke) = (args...) -> _JEllipse(cpt, w, h, color, action)

"""
Make an ellipse, centered at xc/yc, fitting in a box of width w and height h.
"""
JEllipse(xc::Int, yc::Int, w::Real, h::Real; color="black", action=:stroke) = JEllipse(Point(xc, yc), w, h, color=color, action=action)

"""
Build a polygon approximation to an ellipse, given two points and a distance, k, which is the sum of the distances to the focii of any points on the ellipse (or the shortest length of string
required to go from one focus to the perimeter and on to the other focus).
"""
JEllipse(focus1::Point, focus2::Point, k::Real; color="black", action=:stroke, stepvalue=pi/100, vertices=false, reversepath=false) = (args...) -> _JEllipse(focus1, focus2, k, color, action, stepvalue, vertices, reversepath)

"""
Build a polygon approximation to an ellipse, given two points and a point somewhere on the ellipse.
"""
JEllipse(focus1::Point, focus2::Point, pt::Point; color="black", action=:stroke, stepvalue=pi/100, vertices=false, reversepath=false) = (args...) -> _JEllipse(focus1, focus2, pt, color, action, stepvalue, vertices, reversepath)
