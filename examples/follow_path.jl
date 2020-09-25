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

# let the points appear one by one
draw_points = [
    Action(
        frame_start:200,
        (args...) -> circle(O, 10, :fill);
        subactions = [
            # easiest to move canvas to draw at origin
            SubAction(1:1, Translation(points[i])),
            SubAction(1:5, appear(:scale)),
            SubAction((100 - frame_start):(100 - frame_start + 20), Scaling(0.5)),
            SubAction((200 - frame_start - 10):(200 - frame_start), disappear(:scale)),
        ],
    ) for (frame_start, i) in zip(1:2:(2 * npoints), 1:npoints)
]

# generate the bezier path
bezierpath = makebezierpath(points)
bezierpathpoly = bezierpathtopoly(bezierpath)

# let the bezier path appear and disappear in the end
draw_bezier = Action(
    (2 * npoints + 10):200,
    (args...) -> drawbezierpath(bezierpath, :stroke);
    subactions = [
        SubAction(1:10, appear(:fade)),
        SubAction(
            (200 - (2 * npoints + 10) - 10):(200 - (2 * npoints + 10)),
            disappear(:fade),
        ),
    ],
)

# let a red circle appear and follow the bezier path polygon
circle_action = Action(
    120:220,
    (args...) -> circle_with_color(first(points), 10, "red");
    subactions = [
        SubAction(1:20, appear(:fade)),
        SubAction(21:70, sineio(), follow_path(bezierpathpoly .- first(points))),
        SubAction(71:80, disappear(:fade)),
    ],
)

# render everything using javis
javis(
    video,
    [BackgroundAction(1:220, ground), draw_points..., draw_bezier, circle_action];
    pathname = "gifs/follow_bezier_path.gif",
)
