function _JPoly(pointlist, color, linewidth, action, close, reversepath)
    sethue(color)
    setline(linewidth)
    poly(pointlist, action; close = close, reversepath = reversepath)
end

"""
    JPoly(pointlist::Vector{Point}; color="black", linewidth=2, action = :stroke, close=true, reversepath=false)

Draw a polygon around points in the pointlist.

# Keywords
- `color` specifies the color of the outline or the fill of it (depends on action)
- `linewidth` linewidth of the outline
- `action` can be `:stroke`, `:fill` or other symbols (check the Luxor documentation for details) (default: :stroke)
- `close` whether the polygon should be closed or not (default: closed) 
- `reversepath` can be set to `true` to reverse the path and create a polygon hole
"""
JPoly(
    pointlist::Vector{Point};
    color = "black",
    linewidth = 2,
    action = :stroke,
    close = true,
    reversepath = false,
) =
    (
        args...;
        pointlist = pointlist,
        color = color,
        linewidth = linewidth,
        action = action,
    ) -> _JPoly(pointlist, color, linewidth, action, close, reversepath)
