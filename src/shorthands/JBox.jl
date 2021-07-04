function _JBox(cornerpoint1::Point, cornerpoint2::Point, color::String, action::Symbol, vertices::Bool)
    sethue(color)
    verts = box(cornerpoint1, cornerpoint2, action, vertices=vertices)
    return verts[2]
end
function _JBox(points::Array, color::String, action::Symbol, vertices::Bool)
    sethue(color)
    verts = box(points, action, vertices=vertices)
    return verts[2]
end
function _JBox(pt::Point, width::Real, height::Real, color::String, action::Symbol, vertices::Bool)
    sethue(color)
    box(pt, width, height, action, vertices=vertices)
    return Point(pt.x - width/2, pt.y + height/2)
end
function _JBox(pt::Point, width::Real, height::Real, cornerradius::Float64, color::String, action::Symbol)
    sethue(color)
    box(pt, width, height, cornerradius, action=action)
    return Point(pt.x - width/2, pt.y + height/2)
end

"""
    JBox(cornerpoint1::Point, cornerpoint2::Point; color="black", action=:stroke, vertices=false)

Create a box (rectangle) between two points and do an action.
Use vertices=true to return an array of the four corner points: bottom left, top left, top right, bottom right.
"""
JBox(cornerpoint1::Point, cornerpoint2::Point; color="black", action=:stroke, vertices=false) = (args...;cornerpoint1=cornerpoint1, cornerpoint2=cornerpoint2, color=color, action=action, vertices=vertices) -> _JBox(cornerpoint1, cornerpoint2, color, action, vertices)

"""
    JBox(points::Array; color="black", action=:stroke, vertices=false)

Create a box/rectangle using the first two points of an array of Points to defined opposite corners.
Use vertices=true to return an array of the four corner points: bottom left, top left, top right, bottom right.
"""
JBox(points::Array; color="black", action=:stroke, vertices=false) = (args...; points=points, color=color, action=action, vertices=vertices) -> _JBox(points, color, action, vertices)

"""
    JBox(pt::Point, width::Real, height::Real; color="black", action=:stroke, vertices=false)

Create a box/rectangle centered at point pt with width and height. Use vertices=true to return an array of the four corner points rather than draw the box.
"""
JBox(pt::Point, width::Real, height::Real; color="black", action=:stroke, vertices=false) = (args...; pt=pt, width=width, height=height, color=color, action=action, vertices=vertices) -> _JBox(pt, width, height, color, action, vertices)

"""
    JBox(x::Int64, y::Int64, width::Real, height::Real; color="black", action=:stroke)

Create a box/rectangle centered at point x/y with width and height.
"""
JBox(x::Int64, y::Int64, width::Real, height::Real; color="black", action=:stroke) = JBox(Point(x, y), width, height, color=color, action=action)

"""
    JBox(pt::Point, width::Real, height::Real, cornerradius::Float64; color="black", action=:stroke)

Draw a box/rectangle centered at point pt with width and height and round each corner by cornerradius.
"""
JBox(pt::Point, width::Real, height::Real, cornerradius::Float64; color="black", action=:stroke) = (args...; pt=pt, width=width, height=height, cornerradius=cornerradius, color=color, action=action) -> _JBox(pt, width, height, cornerradius, color, action)
