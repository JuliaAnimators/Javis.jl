function _JPoly(pointlist, color, action, close, reversepath)
    sethue(color)
    poly(pointlist, action; close=close, reversepath=reversepath)
end

"""
    JPoly(pointlist::Array{Point, 1}; color="black", action = :stroke, close=true, reversepath=false)

Draw a polygon around points in the pointlist.
Closes the polygon by default
"""
JPoly(pointlist::Array{Point, 1}; color="black", action = :stroke, close=true, reversepath=false) = (args...) -> _JPoly(pointlist, color, action, close, reversepath)




function _JShape(body)
    eval(body)
end

macro JShape(body::Expr)
    expr = quote
        (args...) -> $_JShape($body)
    end
    esc(expr)
end