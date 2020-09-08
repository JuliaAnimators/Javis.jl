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
    p2 = Point(100, 80)
    from_rot = 0.0
    to_rot = 2π
    path_of_blue = Point[]
    path_of_red = Point[]

    video = Video(500, 500)
    javis(
        video,
        [
            BackgroundAction(
                1:25,
                ground,
                Rotation(0.0),
                Translation(Point(25, 25), Point(25, 25)),
            ),
            Action(latex_title),
            Action(
                Rel(-24:0),
                :red_ball,
                (args...) -> circ(p1, "red"),
                Rotation(from_rot, to_rot),
            ),
            Action(
                1:25,
                :blue_ball,
                (args...) -> circ(p2, "blue"),
                Rotation(to_rot, from_rot, :red_ball),
            ),
            Action(
                1:25,
                (video, args...) -> path!(path_of_red, get_position(:red_ball), "red"),
            ),
            Action(:same, (video, args...) -> path!(path_of_blue, pos(:blue_ball), "blue")),
            Action(1:25, (args...) -> rad(pos(:red_ball), pos(:blue_ball), "black")),
        ],
        tempdirectory = "images",
        pathname = "dancing.gif",
    )

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
    p2 = Point(100, 80)
    from_rot = 0.0
    to_rot = 2π
    path_of_blue = Point[]
    path_of_red = Point[]

    video = Video(500, 500)
    javis(
        video,
        [
            BackgroundAction(
                1:2,
                ground,
                Rotation(0.0),
                Translation(Point(25, 25), Point(25, 25)),
            ),
            Action(latex_title),
            Action(
                Rel(-1:0),
                :red_ball,
                (args...) -> circ(p1, "red"),
                Rotation(from_rot, to_rot),
            ),
            Action(
                1:2,
                :blue_ball,
                (args...) -> circ(p2, "blue"),
                Rotation(to_rot, from_rot, :red_ball),
            ),
            Action(
                1:2,
                (video, args...) -> path!(path_of_red, get_position(:red_ball), "red"),
            ),
            Action(:same, (video, args...) -> path!(path_of_blue, pos(:blue_ball), "blue")),
            Action(1:2, (args...) -> rad(pos(:red_ball), pos(:blue_ball), "black")),
        ],
        tempdirectory = "images",
        pathname = "dancing.mp4",
    )

    # The `y` for isapprox was determined experimentally on a Fedora 32 OS.
    # On that machine, the time duration was found to be `0.067` seconds.
    # The `atol` was also experimentally determined based upon VideoIO's
    # `get_duration` function.
    @test isapprox(VideoIO.get_duration("dancing.mp4"), 0.07, atol = 0.01)
    rm("dancing.mp4")
end

@testset "Dancing circles layered" begin
    p1 = Point(100, 0)
    p2 = Point(100, 80)
    from_rot = 0.0
    to_rot = 2π
    path_of_blue = Point[]
    path_of_red = Point[]

    video = Video(500, 500)
    javis(
        video,
        [
            Action(
                1:25,
                ground,
                Rotation(π / 2, π / 2, O),
                Translation(Point(25, 25), Point(25, 25));
                in_global_layer = true,
            ),
            Action(1:25, latex_title),
            Action(1:25, :red_ball, (args...) -> circ(p1, "red"), Rotation(to_rot)),
            Action(
                1:25,
                :blue_ball,
                (args...) -> circ(p2, "blue"),
                Rotation(to_rot, from_rot, :red_ball),
            ),
            Action(
                1:25,
                (video, args...) -> path!(path_of_red, get_position(:red_ball), "red"),
            ),
            Action(1:25, (video, args...) -> path!(path_of_blue, pos(:blue_ball), "blue")),
            Action(1:25, (args...) -> rad(pos(:red_ball), pos(:blue_ball), "black")),
        ],
        tempdirectory = "images",
        pathname = "",
    )

    @test_reference "refs/dancing_circles_16_rot_trans.png" load("images/0000000016.png")
    for i in 1:25
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Dancing circles layered return Transformation" begin
    p1 = Point(100, 0)
    p2 = Point(100, 80)
    from_rot = 0.0
    to_rot = 2π
    path_of_blue = Point[]
    path_of_red = Point[]

    video = Video(500, 500)
    javis(
        video,
        [
            Action(
                1:25,
                ground,
                Rotation(π / 2, π / 2, O),
                Translation(Point(25, 25), Point(25, 25));
                in_global_layer = true,
            ),
            Action(1:25, latex_title),
            Action(
                1:25,
                :red_ball,
                (args...) -> circ_ret_trans(p1, "red"),
                Rotation(to_rot),
            ),
            Action(
                1:25,
                :blue_ball,
                (args...) -> circ_ret_trans(p2, "blue"),
                Rotation(to_rot, from_rot, :red_ball),
            ),
            Action(1:25, (video, args...) -> path!(path_of_red, pos(:red_ball), "red")),
            Action(1:25, (video, args...) -> path!(path_of_blue, pos(:blue_ball), "blue")),
            Action(1:25, (args...) -> rad(pos(:red_ball), pos(:blue_ball), "black")),
        ],
        tempdirectory = "images",
        pathname = "",
    )

    @test_reference "refs/dancing_circles_16_rot_trans.png" load("images/0000000016.png")
    for i in 1:25
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
        tempdirectory = "images",
        pathname = "",
    )

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
    javis(
        video,
        [
            Action(1:10, ground),
            Action(:circ, (args...) -> circ_ret_trans(p), Rotation(2π)),
            Action(
                (args...) -> line(Point(-200, 0), Point(-200, -10 * ang(:circ)), :stroke),
            ),
        ],
        tempdirectory = "images",
        pathname = "",
    )

    @test_reference "refs/circle_angle.png" load("images/0000000008.png")
    for i in 1:10
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

astar(args...) = star(Point(-100, -100), 30)
acirc(args...) = circle(Point(100, 100), 30)

@testset "morphing star2circle and back" begin
    video = Video(500, 500)
    javis(
        video,
        [
            BackgroundAction(
                1:20,
                :framenumber,
                (args...) -> ground_color("white", "black", args[3]),
            ),
            Action(1:10, (args...) -> circle(Point(-100, 0), val(:framenumber), :fill)),
            Action(1:10, morph(astar, acirc)),
            Action(11:20, morph(acirc, astar)),
        ],
        tempdirectory = "images",
        pathname = "",
    )

    @test_reference "refs/star2circle5.png" load("images/0000000005.png")
    @test_reference "refs/star2circle15.png" load("images/0000000015.png")
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
    javis(
        demo,
        [
            BackgroundAction(1:50, ground_nicholas),
            Action(
                (args...) -> house_of_nicholas();
                subactions = [
                    SubAction(1:25, appear(:fade_line_width)),
                    SubAction(Rel(25), disappear(:fade_line_width)),
                ],
            ),
        ],
        tempdirectory = "images",
        pathname = "",
    )

    @test_reference "refs/nicholas15.png" load("images/0000000015.png")
    @test_reference "refs/nicholas25.png" load("images/0000000025.png")
    @test_reference "refs/nicholas35.png" load("images/0000000035.png")
    for i in 1:50
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Squeezing a circle using scale" begin
    demo = Video(500, 500)
    javis(
        demo,
        [
            BackgroundAction(1:100, ground),
            Action(:start_scale, (args...) -> (1.0, 1.0)),
            Action(
                (args...) -> circ();
                subactions = [
                    SubAction(1:25, Scaling((1.0, 1.5))),
                    SubAction(Rel(25), Scaling((2.0, 1.0))),
                    SubAction(Rel(25), Scaling(:start_scale)),
                    SubAction(Rel(25), Scaling(2.0)),
                ],
            ),
            Action((args...) -> circ(Point(-100, 0))),
        ],
        tempdirectory = "images",
        pathname = "",
    )

    @test_reference "refs/squeeze15.png" load("images/0000000015.png")
    @test_reference "refs/squeeze25.png" load("images/0000000025.png")
    @test_reference "refs/squeeze35.png" load("images/0000000035.png")
    @test_reference "refs/squeeze65.png" load("images/0000000065.png")
    @test_reference "refs/squeeze85.png" load("images/0000000085.png")
    for i in 1:100
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
    javis(
        demo,
        [
            BackgroundAction(1:50, ground_opacity),
            Action(
                (args...) -> circ();
                subactions = [
                    SubAction(1:25, appear(:fade)),
                    SubAction(26:50, disappear(:fade)),
                ],
            ),
            Action(
                5:50,
                (args...) -> square_opacity(Point(-100, 0), 60);
                subactions = [
                    SubAction(1:15, linear(), appear(:fade)),
                    SubAction(Rel(20), linear(), Translation(100, 50)),
                    SubAction(Rel(5), disappear(:fade)),
                    # for global frames 46-50 it should still be disappeared
                ],
            ),
        ],
        tempdirectory = "images",
        pathname = "",
    )

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
    javis(
        video,
        [
            BackgroundAction(1:150, ground),
            Action(
                (args...) -> circle(O, 25, :fill);
                subactions = [SubAction(1:150, circle_anim, translate())],
            ),
        ],
        tempdirectory = "images",
        pathname = "",
    )
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
    # warning as animation goes to 1.2 but should go to 1.0
    @test_logs (:warn,) (:warn,) javis(
        video,
        [
            BackgroundAction(1:2, ground),
            Action(
                (args...) -> circle(O, 25, :fill);
                subactions = [SubAction(1:2, circle_anim, translate())],
            ),
        ],
        pathname = "",
    )
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

    javis(
        video,
        [
            BackgroundAction(1:150, ground),
            Action(
                (args...) -> circle(O, 25, :fill);
                subactions = [
                    SubAction(1:10, sineio(), scale()),
                    SubAction(11:50, translate_anim, translate()),
                    SubAction(51:100, rotate_anim, rotate_around(Point(-150, 0))),
                    SubAction(101:140, translate_back_anim, translate()),
                    SubAction(141:150, rev(sineio()), scale()),
                ],
            ),
        ],
        tempdirectory = "images",
        pathname = "",
    )

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
    javis(
        video,
        [
            BackgroundAction(1:50, ground),
            BackgroundAction(1:50, (args...) -> scaleto(2)),
            Action(
                (args...) -> circ(Point(75, 0)),
                subactions = [SubAction(1:50, rotate_anim, rotate())],
            ),
        ],
        tempdirectory = "images",
        pathname = "",
    )

    @test_reference "refs/rotate_center25.png" load("images/0000000025.png")
    @test_reference "refs/rotate_center45.png" load("images/0000000045.png")

    for i in 1:50
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Scaling circle" begin
    video = Video(500, 500)
    javis(
        video,
        [
            BackgroundAction(1:50, ground),
            Action(:set_scale, (args...) -> 2),
            Action(
                (args...) -> circ(),
                subactions = [
                    SubAction(1:15, Scaling(0.0, :set_scale)),
                    SubAction(36:50, Scaling(0.0)),
                ],
            ),
        ],
        tempdirectory = "images",
        pathname = "",
    )

    @test_reference "refs/scalingCircle07.png" load("images/0000000007.png")
    @test_reference "refs/scalingCircle25.png" load("images/0000000025.png")
    @test_reference "refs/scalingCircle42.png" load("images/0000000042.png")

    # test using appear and disappear
    video = Video(500, 500)
    javis(
        video,
        [
            BackgroundAction(1:50, ground),
            BackgroundAction(1:50, (args...) -> scale(2)),
            Action(
                (args...) -> circ(),
                subactions = [
                    SubAction(1:15, appear(:scale)),
                    SubAction(36:50, disappear(:scale)),
                ],
            ),
        ],
        tempdirectory = "images",
        pathname = "",
    )

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

@testset "test default kwargs" begin
    video = Video(500, 500)
    pathname = javis(video, [Action(1:10, ground), Action(1:10, morph(astar, acirc))])
    path, ext = splitext(pathname)
    @test ext == ".gif"
    @test isfile(pathname)
    rm(pathname)
end

@testset "test @error .mp3" begin
    video = Video(500, 500)
    @test_logs (:error,) javis(
        video,
        [Action(1:10, ground), Action(1:10, morph(astar, acirc))];
        pathname = "test.mp3",
    )
end
