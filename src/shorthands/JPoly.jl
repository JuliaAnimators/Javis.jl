"""
Draw a polygon. 
"""
function _JPoly(pointlist, color, action, close, reversepath)
    sethue(color)
    poly(pointlist, action; close=close, reversepath=reversepath)
end

JPoly(pointlist::Array{Point, 1}; color="black", action = :stroke, close=true, reversepath=false) = (args...) -> _JPoly(pointlist, color, action, close, reversepath)