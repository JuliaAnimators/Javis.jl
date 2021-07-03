#============== Line ==============#
function _JLine(p1, p2, color)
    sethue(color)
    line(p1, p2,:stroke)
end
JLine(p1, p2, color="black") = (args...) -> _JLine(p1, p2, color)
JLine(p2) = JLine(O, p2)



#============== Circle ==============#
function _JCircle(center, radius, color, action)
    sethue(color)
    circle(center, radius, action)
    return
end
JCircle(center::Point, radius::Real; color="black", action=:stroke) = (args...) -> _JCircle(center, radius, color, action)
JCircle(center_x::Real, center_y::Real, radius::Real; color="black", action=:stroke) = JCircle(Point(center_x, center_y), radius, color=color, action=action)
JCircle(p1::Real, p2::Real; color="black", action=:stroke) = JCircle(midpoint(p1, p2), distance(pt1, pt2)/2, color=color, action=action)
JCircle(radius::Real; color="black", action=:stroke) = JCircle(O, radius, color=color, action=action)



#============== Rect ==============#
function _JRect(cornerpoint::Point, w::Real, h::Real, color::String, action::Symbol, vertices::Bool)
    sethue(color)
    rect(cornerpoint, w, h, action; vertices=vertices)
end
JRect(cornerpoint::Point, w::Real, h::Real; color="black", action=:stroke, vertices=false) = (args...) -> _JRect(cornerpoint, w, h, color, action, vertices)
JRect(xmin::Int64, ymin::Int64, w::Real, h::Real; color="black", action=:stroke) = JRect(Point(xmin, ymin), w, h, color=color, action=action)


#============== Box ==============#
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


#============== Ellipse ==============#
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

#============== Star ==============#
function _JStar(center, radius, color, npoints, ratio, orientation, action, vertices, reversepath)
    sethue(color)
    star(center, radius, npoints, ratio, orientation, action, vertices=vertices, reversepath=reversepath)
end

"""
Draw a star centered at a position.
"""
JStar(center, radius; color = "black", npoints=5, ratio=0.5, orientation=0, action=:stroke, vertices = false, reversepath=false) = (args...) -> _JStar(center, radius, color, npoints, ratio, orientation, action, vertices, reversepath)

"""
Make a star. ratio specifies the height of the smaller radius of the star relative to the larger. Use vertices=true to return the vertices of a star instead of drawing it.
"""
JStar(xcenter, ycenter, radius; color = "black", npoints=5, ratio=0.5, orientation=0, action=:stroke, vertices = false, reversepath=false) = JStar(Point(xcenter, ycenter), radius, color=color, npoints=npoints, ratio=ratio, orientation=orientation, action=action, vertices=vertices, reversepath=reversepath)


#============== Star ==============#
"""
Draw a polygon. 
"""
function _JPoly(pointlist, color, action, close, reversepath)
    sethue(color)
    poly(pointlist, action; close=close, reversepath=reversepath)
end

JPoly(pointlist::Array{Point, 1}; color="black", action = :stroke, close=true, reversepath=false) = (args...) -> _JPoly(pointlist, color, action, close, reversepath)