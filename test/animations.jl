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
    fontsize(20)
    latex(L"E=mc^2", 0, -200)
end

function circ(p = O, color = "black")
    sethue(color)
    circle(p, 25, :fill)
    return p
end

function circ_ret_trans(p = O, color = "black")
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
    line(p1, p2, :stroke)
end

@testset "Dancing circles (gif)" begin
    p1 = Point(100, 0)
    p2 = Point(200, 80)
    from_rot = 0.0
    to_rot = 2π
    path_of_blue = Point[]
    path_of_red = Point[]

    video = Video(500, 500)
    back = BackgroundObject(1:25, ground, Point(25, 25))

    Object(latex_title)
    red_ball = Object(Rel(-24:0), (args...) -> circ(O, "red"), p1)
    act!(red_ball, Action(anim_rotate_around(from_rot, to_rot, O)))

    blue_ball = Object(1:25, (args...) -> circ(O, "blue"), p2)
    act!(blue_ball, Action(anim_rotate_around(to_rot, from_rot, red_ball)))
    path_red =
        Object(1:25, (video, args...) -> path!(path_of_red, get_position(red_ball), "red"))
    path_blue =
        Object(:same, (video, args...) -> path!(path_of_blue, pos(blue_ball), "blue"))
    string = Object(1:25, (args...) -> rad(pos(red_ball), pos(blue_ball), "black"))

    render(video; tempdirectory = "images", pathname = "dancing.gif")

    @test_reference "refs/dancing_circles_16.png" load("images/0000000016.png")
    @test isfile("dancing.gif")
    for i in 1:25
        rm("images/$(lpad(i, 10, "0")).png")
    end
    rm("images/palette.bmp")
    rm("dancing.gif")
end

@testset "Dancing circles (mp4)" begin
    p1 = Point(100, 0)
    p2 = Point(200, 80)
    from_rot = 0.0
    to_rot = 2π
    path_of_blue = Point[]
    path_of_red = Point[]

    video = Video(500, 500)
    back = BackgroundObject(1:30, ground, Point(25, 25))

    Object(latex_title)
    red_ball = Object((args...) -> circ(O, "red"), p1)
    act!(red_ball, Action(anim_rotate_around(from_rot, to_rot, O)))

    blue_ball = Object(1:30, (args...) -> circ(O, "blue"), p2)
    act!(blue_ball, Action(anim_rotate_around(to_rot, from_rot, red_ball)))
    path_red = Object((video, args...) -> path!(path_of_red, get_position(red_ball), "red"))
    path_blue =
        Object(:same, (video, args...) -> path!(path_of_blue, pos(blue_ball), "blue"))
    string = Object((args...) -> rad(pos(red_ball), pos(blue_ball), "black"))

    render(video; tempdirectory = "images", pathname = "dancing.mp4", framerate = 1)

    # 30 frames with a framerate of 1 should take about 30 seconds ;)
    @test isapprox(VideoIO.get_duration("dancing.mp4"), 30.0, atol = 0.1)
    rm("dancing.mp4")
end

@testset "Dancing circles layered" begin
    p1 = Point(100, 0)
    p2 = Point(200, 80)
    from_rot = 0.0
    to_rot = 2π
    path_of_blue = Point[]
    path_of_red = Point[]

    video = Video(500, 500)
    back = Object(1:25, ground, in_global_layer = true)
    act!(back, Action(anim_rotate(π / 2, π / 2)))
    act!(back, Action(anim_translate(Point(25, 25), Point(25, 25))))

    Object(latex_title)
    red_ball = Object(Rel(-24:0), (args...) -> circ(O, "red"), p1)
    act!(red_ball, Action(anim_rotate_around(from_rot, to_rot, O)))

    blue_ball = Object(1:25, (args...) -> circ(O, "blue"), p2)
    act!(blue_ball, Action(anim_rotate_around(to_rot, from_rot, red_ball)))
    path_red =
        Object(1:25, (video, args...) -> path!(path_of_red, get_position(red_ball), "red"))
    path_blue =
        Object(:same, (video, args...) -> path!(path_of_blue, pos(blue_ball), "blue"))
    string = Object(1:25, (args...) -> rad(pos(red_ball), pos(blue_ball), "black"))

    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/dancing_circles_16_rot_trans.png" load("images/0000000016.png")
    for i in 1:25
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Dancing circles layered return Transformation" begin
    p1 = Point(100, 0)
    p2 = Point(200, 80)
    from_rot = 0.0
    to_rot = 2π
    path_of_blue = Point[]
    path_of_red = Point[]

    video = Video(500, 500)
    back = Object(1:25, ground, in_global_layer = true)
    act!(back, Action(anim_rotate(π / 2, π / 2)))
    act!(back, Action(anim_translate(Point(25, 25), Point(25, 25))))

    Object(latex_title)
    red_ball = Object(Rel(-24:0), (args...) -> circ_ret_trans(O, "red"), p1)
    act!(red_ball, Action(anim_rotate_around(from_rot, to_rot, O)))

    blue_ball = Object(1:25, (args...) -> circ_ret_trans(O, "blue"), p2)
    act!(blue_ball, Action(anim_rotate_around(to_rot, from_rot, red_ball)))
    path_red =
        Object(1:25, (video, args...) -> path!(path_of_red, get_position(red_ball), "red"))
    path_blue =
        Object(:same, (video, args...) -> path!(path_of_blue, pos(blue_ball), "blue"))
    string = Object(1:25, (args...) -> rad(pos(red_ball), pos(blue_ball), "black"))

    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/dancing_circles_16_rot_trans.png" load("images/0000000016.png")
    for i in 1:25
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Drawing grid" begin
    video = Video(500, 500)
    Object(1:40, ground), Object(1:10, draw_grid(direction = "BL", line_gap = 25))
    Object(zero_lines(direction = "BL", line_thickness = 10))
    Object(Rel(10), draw_grid(direction = "BR", line_gap = 25))
    Object(zero_lines(direction = "BR", line_thickness = 10))
    Object(Rel(10), draw_grid(direction = "TL", line_gap = 25))
    Object(zero_lines(direction = "TL", line_thickness = 10))
    Object(Rel(10), draw_grid(direction = "TR", line_gap = 25))
    Object(zero_lines(direction = "TR", line_thickness = 10))

    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/grid_drawing_bl.png" load("images/0000000008.png")
    @test_reference "refs/grid_drawing_br.png" load("images/0000000018.png")
    @test_reference "refs/grid_drawing_tl.png" load("images/0000000028.png")
    @test_reference "refs/grid_drawing_tr.png" load("images/0000000038.png")
    for i in 1:40
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Use returned angle" begin
    video = Video(500, 500)
    p = Point(100, 0)

    Object(1:10, ground)
    circ = Object((args...) -> circ_ret_trans(), p)
    act!(circ, Action(anim_rotate_around(0.0, 2π, O)))
    Object((args...) -> line(Point(-200, 0), Point(-200, -10 * ang(circ)), :stroke))

    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/circle_angle.png" load("images/0000000008.png")
    for i in 1:10
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

astar(args...; do_action = :stroke) = star(Point(-100, -100), 30, 5, 0.5, 0, do_action)
acirc(args...; do_action = :stroke) = circle(Point(100, 100), 30, do_action)

@testset "morphing star2circle and back" begin
    video = Video(500, 500)

    back = BackgroundObject(1:20, (args...) -> ground_color("white", "black", args[3]))
    Object(1:10, (args...) -> circle(Point(-100, 0), val(back), :fill))
    star_obj = Object(1:10, astar)
    act!(star_obj, Action(linear(), morph_to(acirc)))
    circle_obj = Object(11:20, acirc)
    act!(circle_obj, Action(:same, morph_to(astar)))

    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/star2circle5.png" load("images/0000000005.png")
    @test_reference "refs/star2circle15.png" load("images/0000000015.png")
    for i in 1:20
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "morphing star2circle and back with fill" begin
    video = Video(500, 500)
    back = BackgroundObject(1:20, (args...) -> ground_color("white", "black", args[3]))
    Object(1:10, (args...) -> circle(Point(-100, 0), val(back), :fill))
    star_obj = Object(1:10, astar)
    act!(star_obj, Action(morph_to(acirc; draw_object = :fill)))

    circle_obj = Object(11:20, acirc)
    act!(circle_obj, Action(morph_to(astar; draw_object = :fill)))

    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/star2circle_fill5.png" load("images/0000000005.png")
    @test_reference "refs/star2circle_fill15.png" load("images/0000000015.png")
    for i in 1:20
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

function ground_nicholas(args...)
    background("white")
    sethue("blue")
    setline(3)
end

function house_of_nicholas(; p1 = O, width = 100, color = "black")
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
    BackgroundObject(1:50, ground_nicholas)
    house = Object((args...) -> house_of_nicholas())
    act!(house, Action(1:25, appear(:fade_line_width)))
    act!(house, Action(Rel(25), disappear(:fade_line_width)))

    render(demo; tempdirectory = "images", pathname = "")

    @test_reference "refs/nicholas15.png" load("images/0000000015.png")
    @test_reference "refs/nicholas25.png" load("images/0000000025.png")
    @test_reference "refs/nicholas35.png" load("images/0000000035.png")
    for i in 1:50
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Squeezing a circle using scale" begin
    demo = Video(500, 500)

    BackgroundObject(1:125, ground)
    start_scale = Object((args...) -> (1.0, 1.0))
    circle_obj = Object((args...) -> circ())
    act!(circle_obj, Action(1:25, anim_scale((1.0, 1.5))))
    act!(circle_obj, Action(Rel(25), anim_scale((2.0, 1.0))))
    act!(circle_obj, Action(Rel(25), anim_scale(start_scale)))
    act!(circle_obj, Action(Rel(25), anim_scale(2.0); keep = false))
    Object((args...) -> circ(Point(-100, 0)))

    render(demo; tempdirectory = "images", pathname = "")

    @test_reference "refs/squeeze15.png" load("images/0000000015.png")
    @test_reference "refs/squeeze25.png" load("images/0000000025.png")
    @test_reference "refs/squeeze35.png" load("images/0000000035.png")
    @test_reference "refs/squeeze65.png" load("images/0000000065.png")
    @test_reference "refs/squeeze85.png" load("images/0000000085.png")
    @test_reference "refs/squeeze110.png" load("images/0000000110.png")
    for i in 1:125
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

    BackgroundObject(1:50, ground_opacity)
    circle_obj = Object(1:42, (args...) -> circ())
    act!(circle_obj, Action(1:25, appear(:fade)))
    act!(circle_obj, Action(26:42, disappear(:fade)))

    square_obj = Object(5:50, (args...) -> square_opacity(Point(-100, 0), 60))
    act!(square_obj, Action(1:15, linear(), appear(:fade)))
    act!(square_obj, Action(Rel(20), linear(), anim_translate(100, 50)))
    act!(square_obj, Action(Rel(5), disappear(:fade)))
    # for global frames 46-50 it should still be disappeared

    render(demo; tempdirectory = "images", pathname = "")

    @test_reference "refs/circleSquare07opacity.png" load("images/0000000007.png")
    @test_reference "refs/circleSquare25opacity.png" load("images/0000000025.png")
    @test_reference "refs/circleSquare42opacity.png" load("images/0000000042.png")
    # test that the last frame is completely white
    @test sum(load("images/0000000050.png")) ==
          RGB{Float64}(500 * 500, 500 * 500, 500 * 500)
    for i in 1:50
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Animations.jl translate()" begin
    video = Video(500, 500)
    circle_anim = Animation(
        [0, 0.3, 0.6, 1], # must go from 0 to 1
        [O, Point(150, 0), Point(150, 150), O],
        [sineio(), polyin(5), expin(8)],
    )

    BackgroundObject(1:150, ground)
    circle_obj = Object((args...) -> circle(O, 25, :fill))
    act!(circle_obj, Action(1:150, circle_anim, translate()))

    render(video; tempdirectory = "images", pathname = "")
    @test_reference "refs/anim_circle020.png" load("images/0000000020.png")
    @test_reference "refs/anim_circle075.png" load("images/0000000075.png")
    @test_reference "refs/anim_circle142.png" load("images/0000000142.png")
    for i in 1:150
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Animations.jl @warn" begin
    video = Video(500, 500)
    circle_anim = Animation(
        [0, 0.3, 0.6, 1.2], # must go from 0 to 1
        [O, Point(150, 0), Point(150, 150), O],
        [sineio(), polyin(5), expin(8)],
    )

    BackgroundObject(1:2, ground)
    circle_obj = Object((args...) -> circle(O, 25, :fill))
    act!(circle_obj, Action(circle_anim, translate()))

    # warning as animation goes to 1.2 but should go to 1.0
    @test_logs (:warn,) (:warn,) render(video; pathname = "")
end

@testset "Animations.jl rotate, scale, translate" begin
    video = Video(500, 500)
    translate_anim = Animation(
        [0, 1], # must go from 0 to 1
        [O, Point(150, 0)],
        [sineio()],
    )

    translate_back_anim = Animation(
        [0, 1], # must go from 0 to 1
        [O, Point(-150, 0)],
        [sineio()],
    )

    rotate_anim = Animation(
        [0, 1], # must go from 0 to 1
        [0, 2π],
        [linear()],
    )

    color_anim = Animation(
        [0, 0.5, 1], # must go from 0 to 1
        [Lab(colorant"red"), Lab(colorant"cyan"), Lab(colorant"black")],
        [sineio(), sineio()],
    )


    BackgroundObject(1:150, ground)
    circle_obj = Object((args...) -> circle(O, 25, :fill))
    act!(circle_obj, Action(1:10, sineio(), scale()))
    act!(circle_obj, Action(11:50, translate_anim, translate()))
    act!(circle_obj, Action(51:100, rotate_anim, rotate_around(Point(-150, 0))))
    act!(circle_obj, Action(101:140, translate_back_anim, translate()))
    act!(circle_obj, Action(141:150, rev(sineio()), scale()))
    act!(circle_obj, Action(1:150, color_anim, sethue()))

    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/animations_all_05.png" load("images/0000000005.png")
    @test_reference "refs/animations_all_25.png" load("images/0000000025.png")
    @test_reference "refs/animations_all_65.png" load("images/0000000065.png")
    @test_reference "refs/animations_all_125.png" load("images/0000000125.png")
    @test_reference "refs/animations_all_145.png" load("images/0000000145.png")

    for i in 1:150
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Rotate around center animation" begin
    rotate_anim = Animation([0.0, 1.0], [0.0, 2π], [sineio()])

    video = Video(500, 500)
    BackgroundObject(1:50, ground)
    BackgroundObject(1:50, (args...) -> scaleto(2))
    circle_obj = Object((args...) -> circ(Point(75, 0)))
    act!(circle_obj, Action(1:50, rotate_anim, rotate()))

    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/rotate_center25.png" load("images/0000000025.png")
    @test_reference "refs/rotate_center45.png" load("images/0000000045.png")

    for i in 1:50
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Scaling circle" begin
    video = Video(500, 500)

    BackgroundObject(1:50, ground)
    scale_obj = Object((args...) -> 2)
    circle_obj = Object((args...) -> circ())
    act!(circle_obj, Action(1:15, anim_scale(0.0, scale_obj)))
    act!(circle_obj, Action(36:50, anim_scale(0.0)))

    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/scalingCircle07.png" load("images/0000000007.png")
    @test_reference "refs/scalingCircle25.png" load("images/0000000025.png")
    @test_reference "refs/scalingCircle42.png" load("images/0000000042.png")

    # test using appear and disappear
    video = Video(500, 500)

    BackgroundObject(1:50, ground)
    BackgroundObject(1:50, (args...) -> scale(2))
    circle_obj = Object((args...) -> circ())
    act!(circle_obj, Action(1:15, appear(:scale)))
    act!(circle_obj, Action(36:50, disappear(:scale)))

    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/scalingCircle07.png" load("images/0000000007.png")
    @test_reference "refs/scalingCircle25.png" load("images/0000000025.png")
    @test_reference "refs/scalingCircle42.png" load("images/0000000042.png")
    # test that the last frame is completely white
    @test sum(load("images/0000000050.png")) ==
          RGB{Float64}(500 * 500, 500 * 500, 500 * 500)
    for i in 1:50
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "animating text" begin
    # does only test that it doesn't fail but I wasn't able to test this on all platforms
    # with using reference tests
    video = Video(400, 300)

    BackgroundObject(1:100, ground)
    BackgroundObject(1:100, (args...) -> fontsize(30))
    title = Object(1:100, (args...) -> text("Hello Stream!", -50, 50; halign = :centre))
    act!(title, Action(1:15, sineio(), appear(:draw_text)))
    act!(title, Action(76:100, sineio(), disappear(:draw_text)))
    title2 = Object(
        1:100,
        (args...) -> text("Hello World!", -50, -100; halign = :wrong, valign = :wrong),
    )
    act!(title2, Action(1:15, sineio(), appear(:draw_text)))
    act!(title2, Action(76:100, sineio(), disappear(:draw_text)))

    render(video; tempdirectory = "images", pathname = "")

    img07 = load("images/$(lpad(7, 10, "0")).png")
    img30 = load("images/$(lpad(30, 10, "0")).png")
    img82 = load("images/$(lpad(30, 10, "0")).png")

    # does only test that it doesn't fail but I wasn't able to test this on all platforms
    # with using reference tests
    video = Video(400, 300)

    BackgroundObject(1:100, ground)
    BackgroundObject(1:100, (args...) -> fontsize(30))
    title = Object(1:100, (args...) -> text("Hello Stream!", -50, 50; halign = :center))
    act!(title, Action(1:15, sineio(), appear(:draw_text)))
    act!(title, Action(76:100, sineio(), disappear(:draw_text)))
    title2 = Object(1:100, (args...) -> text("Hello World!", -50, -100))
    act!(title2, Action(1:15, sineio(), appear(:draw_text)))
    act!(title2, Action(76:100, sineio(), disappear(:draw_text)))

    render(video; tempdirectory = "images", pathname = "")

    img_other07 = load("images/$(lpad(7, 10, "0")).png")
    img_other30 = load("images/$(lpad(30, 10, "0")).png")
    img_other82 = load("images/$(lpad(30, 10, "0")).png")

    @test img07 == img_other07
    @test img30 == img_other30
    @test img82 == img_other82

    for i in 1:100
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Following a path" begin
    video = Video(800, 600)
    BackgroundObject(1:180, ground)

    anim = Animation([0, 1], [0.0, 2.0], [sineio()])

    color_anim = Animation(
        [0, 0.5, 1], # must go from 0 to 1
        [Lab(colorant"red"), Lab(colorant"cyan"), Lab(colorant"red")],
        [sineio(), sineio()],
    )


    actions = [
        Action(1:150, anim, follow_path(star(O, 100))),
        Action(1:150, color_anim, sethue()),
    ]

    objects = [
        Object(frame_start:(frame_start + 149), (args...) -> star(O, 20, 5, 0.5, 0, :fill)) for frame_start in 1:7:22
    ]

    act!(objects, actions)

    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/followPath10.png" load("images/0000000010.png")
    @test_reference "refs/followPath30.png" load("images/0000000030.png")
    @test_reference "refs/followPath100.png" load("images/0000000100.png")
    @test_reference "refs/followPath160.png" load("images/0000000160.png")

    # Following along a bezier path
    function simple_bezier()
        P1 = Point(-300, 0)
        CP1 = Point(-200, -200)
        CP2 = Point(200, -200)
        P2 = Point(300, 0)

        beziersegment = BezierPathSegment(P1, CP1, CP2, P2)
        beziertopoly(beziersegment)
    end

    video = Video(800, 600)
    BackgroundObject(1:180, ground)

    anim = Animation([0, 1], [0.0, 1.0], [sineio()])

    color_anim = Animation(
        [0, 0.5, 1], # must go from 0 to 1
        [Lab(colorant"red"), Lab(colorant"cyan"), Lab(colorant"red")],
        [sineio(), sineio()],
    )

    actions =
        (frame_start) -> [
            Action(1:10, appear(:fade)),
            Action(
                11:150,
                anim,
                follow_path(
                    simple_bezier() .- (simple_bezier()[1] + Point(0, 3 * frame_start));
                    closed = false,
                ),
            ),
            Action(1:150, color_anim, sethue()),
        ]

    objects = [
        Object(
            frame_start:(frame_start + 149),
            (args...) -> star(O, 20, 5, 0.5, 0, :fill),
            simple_bezier()[1] + Point(0, 3 * frame_start),
        ) for frame_start in 1:7:22
    ]

    for (object, frame_start) in zip(objects, 1:7:22)
        act!(object, actions(frame_start))
    end

    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/followPathBezier1.png" load("images/0000000001.png")
    @test_reference "refs/followPathBezier5.png" load("images/0000000005.png")
    @test_reference "refs/followPathBezier10.png" load("images/0000000010.png")
    @test_reference "refs/followPathBezier30.png" load("images/0000000030.png")
    @test_reference "refs/followPathBezier100.png" load("images/0000000100.png")
    @test_reference "refs/followPathBezier160.png" load("images/0000000160.png")

    for i in 1:180
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Change" begin

    function object(p, radius, color = "black")
        sethue(color)
        circle(p, radius, :fill)
        return p
    end

    anim =
        Animation([0.0, 0.5, 1.0], [O, Point(100, 0), Point(50, 50)], [sineio(), sineio()])

    rev_anim =
        Animation([0.0, 0.5, 1.0], [Point(50, 50), Point(100, 0), O], [sineio(), sineio()])

    myvideo = Video(500, 500)
    double_rotation = Animation([0.0, 1.0], [0.0, 4π], [linear()])

    BackgroundObject(1:100, ground)
    circ1 = Object((args...; radius = 25) -> object(Point(100, 0), radius, "red"))
    act!(circ1, Action(double_rotation, rotate()))
    act!(circ1, Action(1:50, change(:radius, 25 => 0)))
    act!(circ1, Action(51:100, change(:radius, 0 => 25)))

    circ2 = Object((args...; point = O) -> object(point, 25, "green"))
    act!(circ2, Action(1:50, anim, change(:point)))
    act!(circ2, Action(51:100, rev_anim, change(:point)))

    render(myvideo; tempdirectory = "images")

    @test_reference "refs/changeKeyword1.png" load("images/0000000001.png")
    @test_reference "refs/changeKeyword25.png" load("images/0000000025.png")
    @test_reference "refs/changeKeyword40.png" load("images/0000000040.png")
    @test_reference "refs/changeKeyword70.png" load("images/0000000070.png")
    @test_reference "refs/changeKeyword90.png" load("images/0000000090.png")

    for i in 1:100
        rm("images/$(lpad(i, 10, "0")).png")
    end
    rm("images/palette.bmp")
end

@testset "test default kwargs" begin
    video = Video(500, 500)
    Object(1:10, ground)
    Object(1:10, (args...) -> circle(O, 50, :fill))
    pathname = render(video)
    path, ext = splitext(pathname)
    @test ext == ".gif"
    @test isfile(pathname)
    rm(pathname)
end

@testset "test @error .mp3" begin
    video = Video(500, 500)
    Object(1:10, ground)
    Object(1:10, (args...) -> circle(O, 50, :fill))
    @test_logs (:error,) render(video; pathname = "test.mp3")
end
