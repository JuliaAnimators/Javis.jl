function (cs::CoordinateSystem)()
    left = cs.left
    right = cs.right
    bottom = cs.bottom
    top = cs.top
    fct = cs.fct
    mainwidth = cs.mainwidth
    gridwidth = cs.gridwidth
    step_size_x = cs.step_size_x
    step_size_y = cs.step_size_y
    maincolor = cs.maincolor
    gridcolor = cs.gridcolor

    @JShape begin
        if gridcolor !== nothing
            sethue(gridcolor)
        end
        if step_size_x != 0
            setline(gridwidth)
            # 1st and 4th quadrant
            for c in (top.x):step_size_x:(right.x)
                line(Point(c, bottom.y), Point(c, top.y))
            end
            # 2nd and 3rd quadrant
            for c in (top.x):(-step_size_x):(left.x)
                line(Point(c, bottom.y), Point(c, top.y))
            end
            strokepath()
        end
        if step_size_y != 0
            setline(gridwidth)
            # 1st and second quadrant
            for r in (left.y):(-step_size_y):(top.y)
                line(Point(left.x, r), Point(right.x, r))
            end
            # 3st and 4th quadrant
            for r in (left.y):step_size_y:(bottom.y)
                line(Point(left.x, r), Point(right.x, r))
            end
            strokepath()
        end
        if maincolor !== nothing
            sethue(maincolor)
        end
        setline(mainwidth)
        left !== right && fct(left, right)
        bottom !== top && fct(bottom, top)
        strokepath()
    end left = left right = right bottom = bottom top = top fct = fct mainwidth = mainwidth step_size_x =
        step_size_x step_size_y = step_size_y gridwidth = gridwidth
end

"""
    coordinate_system(left, right, bottom, top; kwargs...)

Create a [`CoordinateSystem`](@ref) to draw and animate.

# Arguments
- `left::Point` the point describing the left most position of the xaxis
- `right::Point` the point describing the right most position of the xaxis
- `bottom::Point` the point describing the bottom most position of the yaxis
- `top::Point` the point describing the top most position of the yaxis

# Keywords
- `fct` default:`line` can be `line` or `arrow` to draw an arrow for x and y axis
- `mainwidth` default:1 the line width of the axis
- `step_size_x` default:50 the step size of the grid itself in x dimension
- `step_size_y` default:50 the step size of the grid itself in y dimension
- `gridwidth` default:0.2 line width for the grid
- `maincolor` default:`nothing` color of the zero lines (nothing = doesn't set any color)
- `gridcolor` default:`nothing` color of the grid lines (nothing = doesn't set any color)

# Example
```julia
cs = coordinate_system(Point(-100, 0), Point(200, 0), Point(0, 100), Point(0, -200); 
fct=arrow)
cs_obj = Object(1:100, cs())
act!(cs_obj, Action(1:30, appear(cs, :top_left)))
```
"""
function coordinate_system(
    left,
    right,
    bottom,
    top;
    fct = line,
    mainwidth = 1,
    step_size_x = 10,
    step_size_y = 10,
    gridwidth = 0.2,
    maincolor = nothing,
    gridcolor = nothing,
)
    return CoordinateSystem(
        left,
        right,
        bottom,
        top,
        fct,
        mainwidth,
        gridwidth,
        step_size_x,
        step_size_y,
        maincolor,
        gridcolor,
    )
end

function xaxis_on_zero(sc::LinearScale{<:Point}, new_orign)
    left = Point(sc.output.from.x, new_origin.y)
    right = Point(sc.output.to.x, new_origin.y)
    return left, right
end

function yaxis_on_zero(sc::LinearScale{<:Point}, new_orign)
    top = Point(new_origin.x, sc.output.to.y)
    bottom = Point(new_origin.x, sc.output.from.y)
    return top, bottom
end

function xaxis_not_on_zero(sc::LinearScale{<:Point})
    # the xaxis is just at the bottom if y vals are positive or at the top if y vals are negative
    if sc.input.from.y >= 0
        left = Point(sc.output.from.x, sc.output.from.y)
        right = Point(sc.output.to.x, sc.output.from.y)
    else
        left = Point(sc.output.from.x, sc.output.to.y)
        right = Point(sc.output.to.x, sc.output.to.y)
    end
    return left, right
end

function yaxis_not_on_zero(sc::LinearScale{<:Point})
    # the yaxis is just left if x vals are positive or on the right if x vals are negative
    if sc.input.from.x >= 0
        top = Point(sc.output.from.x, sc.output.to.y)
        bottom = Point(sc.output.from.x, sc.output.from.y)
    else
        top = Point(sc.output.to.x, sc.output.to.y)
        bottom = Point(sc.output.to.x, sc.output.from.y)
    end
    return top, bottom
end

function coordinate_system(
    sc::LinearScale{<:Point};
    step_size_x = 1,
    step_size_y = 1,
    kwargs...,
)
    # check if the origin is in the to rectangle
    new_origin = sc(O; clamp = false)
    smx = min(sc.output.from.x, sc.output.to.x)
    bix = max(sc.output.from.x, sc.output.to.x)
    smy = min(sc.output.from.y, sc.output.to.y)
    biy = max(sc.output.from.y, sc.output.to.y)
    if smx <= new_origin.x <= bix && smy <= new_origin.y <= biy
        left, right = xaxis_on_zero(sc, new_origin)
        top, bottom = yaxis_on_zero(sc, new_origin)
    elseif smy <= new_origin.y <= biy
        # doesn't go through the origin
        # x axis does though
        left, right = xaxis_on_zero(sc, new_origin)
    elseif smx <= new_origin.x <= bix
        # doesn't go through the origin
        # y axis does though
        top, bottom = yaxis_on_zero(sc, new_origin)

        left, right = xaxis_not_on_zero(sc)
    else
        top, bottom = yaxis_not_on_zero(sc)
        left, right = xaxis_not_on_zero(sc)
    end

    sx, sy = scaling_factors(sc)
    step_size_x *= sx
    step_size_y *= sy

    return coordinate_system(
        left,
        right,
        bottom,
        top;
        step_size_x = abs(step_size_x),
        step_size_y = abs(step_size_y),
        kwargs...,
    )
end

"""
    appear(cs::CoordinateSystem, s::Symbol)

Appear function for a [`CoordinateSystem`](@ref).

# Arguments 
- `cs::CoordinateSystem` the CoordinateSystem which can be created with [`coordinate_system`](@ref)
- `s::Symbol` the direction of the drawing i.e `:top_right` will animate the creation of the grid from the bottom left to the top right.

[`coordinate_system`](@ref)
"""
function appear(cs::CoordinateSystem, s::Symbol)
    (video, object, action, rel_frame) -> begin
        str = string(s)
        for d in split(str, "_")
            if d == "right"
                _change(video, object, action, rel_frame, :right, cs.left => cs.right)
            elseif d == "top"
                _change(video, object, action, rel_frame, :top, cs.bottom => cs.top)
            elseif d == "left"
                _change(video, object, action, rel_frame, :left, cs.right => cs.left)
            elseif d == "bottom"
                _change(video, object, action, rel_frame, :bottom, cs.top => cs.bottom)
            end
        end
    end
end

"""
    disappear(cs::CoordinateSystem, s::Symbol)

Disappear function for a [`CoordinateSystem`](@ref).

# Arguments 
- `cs::CoordinateSystem` the CoordinateSystem which can be created with [`coordinate_system`](@ref)
- `s::Symbol` the direction of the drawing i.e `:top_right` will animate the destruction of the grid from the bottom left to the top right.
    Such that the last part that is getting destructed is at the `:top_right` in this case

[`coordinate_system`](@ref)
"""
function disappear(cs::CoordinateSystem, s::Symbol)
    (video, object, action, rel_frame) -> begin
        str = string(s)
        for d in split(str, "_")
            if d == "right"
                _change(video, object, action, rel_frame, :left, cs.left => cs.right)
            elseif d == "top"
                _change(video, object, action, rel_frame, :bottom, cs.bottom => cs.top)
            elseif d == "left"
                _change(video, object, action, rel_frame, :right, cs.right => cs.left)
            elseif d == "bottom"
                _change(video, object, action, rel_frame, :top, cs.top => cs.bottom)
            end
        end
    end
end
