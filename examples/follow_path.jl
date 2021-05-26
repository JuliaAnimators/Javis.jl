using Javis, Animations

function ground(args...)
    background("white")
    sethue("black")
end

function circle_with_color(pos, radius, color)
    sethue(color)
    circle(pos, radius, :fill)
end

# the safest option is to declare the Video first all the time
video = Video(600, 600)

# the points that describe our car
points = [
    Point(-200, 20),
    Point(-170, 20),
    Point(-160, 10),
    Point(-150, 10),
    Point(-140, 20),
    Point(140, 20),
    Point(150, 10),
    Point(160, 10),
    Point(170, 20),
    Point(200, 20),
    Point(180, -20),
    Point(100, -60),
    Point(80, -70),
    Point(60, -90),
    Point(0, -90),
    Point(-90, -40),
    Point(-190, -20),
]
npoints = length(points)

Background(1:220, ground)

# let the points appear one by one
objects = [
    Object(@Frames(prev_start()+2, stop=200), (args...) -> circle(O, 10, :fill), points[i]) for i in 1:npoints
]

# easiest to move canvas to draw at origin
act!(objects, Action(1:5, appear(:scale)))
act!(objects, Action(GFrames(100:120), anim_scale(0.5)))
act!(objects, Action(GFrames(190:200), disappear(:scale)))

# generate the bezier path
bezierpath = makebezierpath(points)
bezierpathpoly = bezierpathtopoly(bezierpath)

# let the bezier path appear and disappear in the end
bezier_object =
    Object((2 * npoints + 10):200, (args...) -> drawbezierpath(bezierpath, :stroke))

act!(bezier_object, Action(1:10, appear(:fade)))
act!(bezier_object, Action(GFrames(190:200), disappear(:fade)))

# let a red circle appear and follow the bezier path polygon
red_circle = Object(120:220, (args...) -> circle_with_color(first(points), 10, "red"))
act!(red_circle, Action(1:20, appear(:fade)))
act!(red_circle, Action(21:70, sineio(), follow_path(bezierpathpoly .- first(points))))
act!(red_circle, Action(71:80, disappear(:fade)))

render(video; pathname = joinpath(@__DIR__, "gifs/follow_bezier_path.gif"))
