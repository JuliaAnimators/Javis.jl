abstract type Circle end

function _Lineobj(p1, p2, color)
    sethue(color)
    line(p1, p2,:stroke)
    return
end

function Lineobj(p1, p2; color="black")
    push!(CURRENT_OBJECT_META, Dict("shapetype"=>Line, "initial_pos" => p1, "final_pos" => p2))
    return (args...) -> _Lineobj(p1, p2, color)
end

Lineobj(p2) = Lineobj(O, p2)

function _Circle(center, radius, color, action)
    sethue(color)
    circle(center, radius, action)
    return
end

function Circle(center::Point, radius::Real; color="black", action=:fill) 
    push!(CURRENT_OBJECT_META, Dict("shapetype"=>Circle, "center" => center, "radius" => radius, "current_angle" => 0.0))
    return (args...) -> _Circle(center, radius, color, action)
end

Circle(center_x::Real, center_y::Real, radius::Real; color="black", action=:fill) = Circle(Point(center_x, center_y), radius, color, action)
Circle(p1::Real, p2::Real; color="black", action=:fill) = Circle(midpoint(p1, p2), distance(pt1, pt2)/2, color, action)

#==================#

# macros are difficult to generalize with all the different parameters taken by luxor methods

# macro shapetoobj(name::String, frames, start_pos, func)# todo have some defualt arguments here....defaults in the macro call
#     expr = quote
#         function ($(Symbol(name)))(frames=$frames, start_pos=$start_pos, func=$func)
#             return Object(frames, (args...)->func, start_pos)
#         end
#     end
#     return esc(expr)
# end
# @shapetoobj "JCircle" 1:15 O begin
#     circle()
# end

# function Circle(frames::UnitRange=1:15, center::Point=O, radius::Real=40, action::Symbol=:stroke, color::String="black")
#     function func(color, center, radius, action)
#         sethue(color)
#         circle(center, radius ,action)
#     end
#     return Object(frames, (args...)->func(color, center, radius, action))    
# end

# function Circle(frames::UnitRange=1:15, center_x::Float64=0, center_y::Float64=0, radius::Float64=40, action::Symbol=:stroke, color::String="black")
#     Circle(frames, Point(center_x, center_y), radius, action, color)
# end

# function Circle(frames::UnitRange=1:15, p1::Point=Point(20, 0), p2::Point=Point(-20, 0), p3::Point=Point(0, 20), action::Symbol=:stroke, color::String="black")
#     sethue(color)
#     return Object(frames, (args...)->circle(p1, p2, p3,action))
# end

# function Circle(frames::UnitRange=1:15, p1::Point=Point(20, 0), p2::Point=Point(-20, 0), action::Symbol=:stroke, color::String="black")
#     sethue(color)
#     return Object(frames, (args...)->circle(p1, p2, action))
# end

# function shift!(obj::Object, frames::UnitRange=obj.frames, fp::Union{Object,Point}=O, tp::Union{Object,Point}=O, easing=nothing)
#     if easing !== nothing
#         act!(obj, Action(frames, easing, anim_translate(fp, tp)))
#     else
#         act!(obj, Action(frames, anim_translate(fp, tp)))
#     end
# end

# function shift!(obj::Object, fp::Union{Object,Point}=O, tp::Union{Object,Point}=O, easing=nothing)
#     act!(obj, Action(anim_translate(fp, tp)))
# end

# function shift!(obj::Object, frames::UnitRange=obj.frames, fp::Union{Object,Point}=O, tp::Union{Object,Point}=O, easing=nothing)
#     act!(obj, Action(frames, anim_translate(fp, tp)))
# end


