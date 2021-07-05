function _JPoly(pointlist, color, action, close, reversepath)
    sethue(color)
    poly(pointlist, action; close = close, reversepath = reversepath)
end

"""
    JPoly(pointlist::Array{Point, 1}; color="black", action = :stroke, close=true, reversepath=false)

Draw a polygon around points in the pointlist.
Closes the polygon by default
"""
JPoly(
    pointlist::Array{Point,1};
    color = "black",
    action = :stroke,
    close = true,
    reversepath = false,
) =
    (args...; pointlist = pointlist, color = color, action = action) ->
        _JPoly(pointlist, color, action, close, reversepath)


function _JShape(body)
    eval.(body)
end

"""
    JShape(body...)

Creates a custom shape based on the luxor instructions in the begin...end block
```julia
somepath1 = Object(
    Javis.@JShape action = :stroke color ="red" radius = 8 
    begin
        sethue(color)
        poly(points, action, close= true)
    end
)
```
"""
macro JShape(body...)
    expr = quote
        (args...) -> $_JShape($body)
    end
    esc(expr)
end
