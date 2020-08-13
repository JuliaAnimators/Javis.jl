using Javis

function ground(args...)
    background("white")
    sethue("black")
end

function circ(p=O, color="black")
    sethue(color)
    circle(p, 25, :fill)
    return p
end

function path!(points, pos, color)
    sethue(color)
    push!(points, pos)
    circle.(points, 2, :fill)
end

function rad(p1, p2, color)
    sethue(color)
    line(p1,p2, :stroke)
end

function dc()
    p1 = Point(100,0)
    p2 = Point(100,80)
    path_of_blue = Point[]
    path_of_red = Point[]

    video = Video(500, 500)
    javis(video, [
        BackgroundAction(1:70, ground),
        Action(1:70, :red_ball, (args...)->circ(p1, "red"), Rotation(0.0, 2π)),
        Action(1:70, :blue_ball, (args...)->circ(p2, "blue"), Rotation(2π, 0.0, :red_ball)),
        Action(1:70, (video, args...)->path!(path_of_red, pos(:red_ball), "red")),
        Action(1:70, (video, args...)->path!(path_of_blue, pos(:blue_ball), "blue")),
        Action(1:70, (args...)->rad(pos(:red_ball), pos(:blue_ball), "black"))
    ],
		 pathname="dancing_circles.gif")
    return video
end

dc()
