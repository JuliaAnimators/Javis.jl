
struct CoordinateSystem
    left::Point
    right::Point
    bottom::Point
    top::Point
    fct::Function
    mainwidth::Float64
    gridwidth::Float64
    step_size_x::Float64
    step_size_y::Float64
end

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
    @JShape begin 
        setline(mainwidth)
        left !== right && fct(left, right)
        bottom !== top && fct(bottom, top)
        strokepath()
        if step_size_x != 0
            setline(gridwidth)
            # 1st and 4th quadrant
            for c in top.x:step_size_x:right.x
                line(Point(c, bottom.y), Point(c, top.y))
            end
            # 2nd and 3rd quadrant
            for c in top.x:-step_size_x:left.x
                line(Point(c, bottom.y), Point(c, top.y))
            end
            strokepath()
        end
        if step_size_y != 0
            setline(gridwidth)
            # 1st and second quadrant
            for r in left.y:-step_size_y:top.y
                line(Point(left.x, r), Point(right.x, r))
            end
            # 3st and 4th quadrant
            for r in left.y:step_size_y:bottom.y
                line(Point(left.x, r), Point(right.x, r))
            end
            strokepath()
        end
    end left=left right=right bottom=bottom top=top fct=fct mainwidth=mainwidth step_size_x=step_size_x step_size_y=step_size_y gridwidth=gridwidth
end

function coordinate_system(left, right, bottom, top; fct=line, mainwidth=1, step_size_x=50, step_size_y=50, gridwidth=0.2)
    return CoordinateSystem(left, right, bottom, top, fct, mainwidth, gridwidth, step_size_x, step_size_y)
end

function appear(cs::CoordinateSystem, s::Symbol)
    (video, object, action, rel_frame) -> 
        begin
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