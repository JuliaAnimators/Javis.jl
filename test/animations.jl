function ground(video, action, framenumber) 
    background("white")
    sethue("blue")
    return framenumber
end

function ground_color(color_bg, color_pen, framenumber) 
    background(color_bg)
    sethue(color_pen)
    return framenumber
end

function latex_title(args...)
    translate(0, -200)
    latex(L"E=mc^2", 20)
end

function circ(p=O, color="black")
    sethue(color)
    circle(p, 25, :fill)
    return p
end

function circ_ret_trans(p=O, color="black")
    sethue(color)
    circle(p, 25, :fill)
    return Transformation(p, 0.0)
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

@testset "Dancing circles" begin 
    p1 = Point(100,0)
    p2 = Point(100,80)
    from_rot = 0.0
    to_rot = 2π
    path_of_blue = Point[]
    path_of_red = Point[]

    video = Video(500, 500)
    javis(video, [
        BackgroundAction(1:25, ground, Rotation(0.0), Translation(Point(25, 25), Point(25, 25))),
        Action(latex_title),
        Action(Rel(-24:0), :red_ball, (args...)->circ(p1, "red"), Rotation(from_rot, to_rot)),
        Action(1:25, :blue_ball, (args...)->circ(p2, "blue"), Rotation(to_rot, from_rot, :red_ball)),
        Action(1:25, (video, args...)->path!(path_of_red, get_position(:red_ball), "red")),
        Action(:same, (video, args...)->path!(path_of_blue, pos(:blue_ball), "blue")),
        Action(1:25, (args...)->rad(pos(:red_ball), pos(:blue_ball), "black"))
    ], tempdirectory="images", pathname="dancing.gif")

    @test_reference "refs/dancing_circles_16.png" load("images/0000000016.png")
    @test isfile("dancing.gif")
    for i=1:25
        rm("images/$(lpad(i, 10, "0")).png")
    end
    rm("images/palette.bmp")
    rm("dancing.gif")
end

@testset "Dancing circles layered" begin 
    p1 = Point(100,0)
    p2 = Point(100,80)
    from_rot = 0.0
    to_rot = 2π
    path_of_blue = Point[]
    path_of_red = Point[]

    video = Video(500, 500)
    javis(video, [
        Action(1:25, ground, Rotation(π/2, π/2, O), Translation(Point(25,25), Point(25,25)); in_global_layer=true),
        Action(1:25, latex_title),
        Action(1:25, :red_ball, (args...)->circ(p1, "red"), Rotation(to_rot)),
        Action(1:25, :blue_ball, (args...)->circ(p2, "blue"), Rotation(to_rot, from_rot, :red_ball)),
        Action(1:25, (video, args...)->path!(path_of_red, get_position(:red_ball), "red")),
        Action(1:25, (video, args...)->path!(path_of_blue, pos(:blue_ball), "blue")),
        Action(1:25, (args...)->rad(pos(:red_ball), pos(:blue_ball), "black"))
    ], tempdirectory="images", pathname="")

    @test_reference "refs/dancing_circles_16_rot_trans.png" load("images/0000000016.png")
    for i=1:25
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Dancing circles layered return Transformation" begin 
    p1 = Point(100,0)
    p2 = Point(100,80)
    from_rot = 0.0
    to_rot = 2π
    path_of_blue = Point[]
    path_of_red = Point[]

    video = Video(500, 500)
    javis(video, [
        Action(1:25, ground, Rotation(π/2, π/2, O), Translation(Point(25,25), Point(25,25)); in_global_layer=true),
        Action(1:25, latex_title),
        Action(1:25, :red_ball, (args...)->circ_ret_trans(p1, "red"), Rotation(to_rot)),
        Action(1:25, :blue_ball, (args...)->circ_ret_trans(p2, "blue"), Rotation(to_rot, from_rot, :red_ball)),
        Action(1:25, (video, args...)->path!(path_of_red, pos(:red_ball), "red")),
        Action(1:25, (video, args...)->path!(path_of_blue, pos(:blue_ball), "blue")),
        Action(1:25, (args...)->rad(pos(:red_ball), pos(:blue_ball), "black"))
    ], tempdirectory="images", pathname="")

    @test_reference "refs/dancing_circles_16_rot_trans.png" load("images/0000000016.png")
    for i=1:25
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Drawing grid" begin
    video = Video(500, 500)
    javis(
        video,
        [
            Action(1:40, ground),
            
            Action(1:10, draw_grid(direction = "BL", line_gap = 25)),
            Action(zero_lines(direction = "BL", line_thickness = 10)),
            
            Action(Rel(10), draw_grid(direction = "BR", line_gap = 25)),
            Action(zero_lines(direction = "BR", line_thickness = 10)),
            
            Action(Rel(10), draw_grid(direction = "TL", line_gap = 25)),
            Action(zero_lines(direction = "TL", line_thickness = 10)),
            
            Action(Rel(10), draw_grid(direction = "TR", line_gap = 25)),
            Action(zero_lines(direction = "TR", line_thickness = 10)),

        ],
        tempdirectory = "images", pathname=""
    )

    @test_reference "refs/grid_drawing_bl.png" load("images/0000000008.png")
    @test_reference "refs/grid_drawing_br.png" load("images/0000000018.png")
    @test_reference "refs/grid_drawing_tl.png" load("images/0000000028.png")
    @test_reference "refs/grid_drawing_tr.png" load("images/0000000038.png")
    for i=1:40
	    rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Use returned angle" begin
    video = Video(500, 500)
    p = Point(100, 0)
    javis(video, [
        Action(1:10, ground),
        Action(:circ, (args...)->circ_ret_trans(p), Rotation(2π)),
        Action((args...)->line(Point(-200, 0), Point(-200, -10*ang(:circ)), :stroke))
    ], tempdirectory="images", pathname="")

    @test_reference "refs/circle_angle.png" load("images/0000000008.png")
    for i=1:10
	    rm("images/$(lpad(i, 10, "0")).png")
    end
end

astar(args...) = star(Point(-100,-100), 30) 
acirc(args...) = circle(Point(100,100), 30) 

@testset "morphing star2circle and back" begin
    video = Video(500, 500)
    javis(video, [
        BackgroundAction(1:20, :framenumber, (args...)->ground_color("white", "black", args[3])),
        Action(1:10, (args...)->circle(Point(-100, 0), val(:framenumber), :fill)),
        Action(1:10, morph(astar, acirc)),
        Action(11:20, morph(acirc, astar))
    ], tempdirectory="images", pathname="")

    @test_reference "refs/star2circle5.png" load("images/0000000005.png")
    @test_reference "refs/star2circle15.png" load("images/0000000015.png")
    for i=1:20
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

function ground_nicholas(args...)
    background("white")
    sethue("blue")
    setline(3)
end

function house_of_nicholas(;p1=O, width=100, color="black")
    # sethue(color)
    #     .p1
    # .p2   .p3
    #
    # .p4   .p5
    width2 = div(width, 2)
    p2 = p1 + Point(-width2, width2)
    p3 = p1 + Point(width2, width2)
    p4 = p2 + Point(0, width)
    p5 = p3 + Point(0, width)
    line(p4, p5, :stroke)
    line(p5, p2, :stroke)
    line(p2, p4, :stroke)
    line(p4, p3, :stroke)
    line(p3, p1, :stroke)
    line(p1, p2, :stroke)
    line(p2, p3, :stroke)
    setline(8)
    line(p3, p5, :stroke)
end

@testset "House of Nicholas line_width" begin
    demo = Video(500, 500)
    javis(demo, [
        BackgroundAction(1:50, ground_nicholas),
        Action((args...)->house_of_nicholas(); subactions = [
            SubAction(1:25, appear(:fade_line_width)),
            SubAction(26:50, disappear(:fade_line_width))
        ])
    ], tempdirectory="images", pathname="")

    @test_reference "refs/nicholas15.png" load("images/0000000015.png")
    @test_reference "refs/nicholas25.png" load("images/0000000025.png")
    @test_reference "refs/nicholas35.png" load("images/0000000035.png")
    for i=1:50
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

function ground_opacity(args...)
    background("white")
    sethue("black")
    setopacity(0.5)
end

function square_opacity(p1, w)
    setopacity(1.0)
    sethue("red")
    rect(p1, w, w, :fill)
end

@testset "Circle/square appear opacity" begin
    demo = Video(500, 500)
    javis(demo, [
        BackgroundAction(1:50, ground_opacity),
        Action((args...)->circ(); subactions = [
            SubAction(1:25, appear(:fade)),
            SubAction(26:50, disappear(:fade))
        ]),
        Action((args...)->square_opacity(Point(-100, 0), 60); subactions = [
            SubAction(1:25, appear(:fade)),
            SubAction(26:50, disappear(:fade))
        ])
    ], tempdirectory="images", pathname="")

    @test_reference "refs/circlerSquare15opacity.png" load("images/0000000015.png")
    @test_reference "refs/circlerSquare25opacity.png" load("images/0000000025.png")
    @test_reference "refs/circlerSquare35opacity.png" load("images/0000000035.png")
    for i=1:50
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "test default kwargs" begin
    video = Video(500, 500)
    pathname = javis(video, [
        Action(1:10, ground),
        Action(1:10, morph(astar, acirc))
    ]) 
    path, ext = splitext(pathname)
    @test ext == ".gif"
    @test isfile(pathname)
    rm(pathname)
end

@testset "test @error .mp3" begin
    video = Video(500, 500)
    @test_logs (:error,) javis(video, [
        Action(1:10, ground),
        Action(1:10, morph(astar, acirc))
    ]; pathname="test.mp3") 
end

