vid = Video(600, 600)
video = Video(600, 600)

@testset "Layers Feature" begin
    function ground(args...)
        background("white")
        sethue("black")
    end

    Background(1:80, ground)

    function object_layer(p = O, color = "black")
        sethue(color)
        circle(p, 5, :fill)
        return p
    end

    function path!(points, pos, color)
        sethue(color)
        push!(points, pos) # add pos to points
        circle.(points, 2, :fill) # draws a circle for each point using broadcasting
    end

    function connector(p1, p2, color)
        sethue(color)
        line(p1, p2, :stroke)
    end

    path_of_red = Point[]
    path_of_blue = Point[]

    function ground1(args...)
        background("black")
        sethue("white")
    end

    function ground2(args...)
        background("orange")
        sethue("blue")
    end

    l1 = @JLayer 20:60 600 600 Point(0, 0) begin
        Background(5:41, ground1)
        red_ball = Object(5:41, (args...) -> object_layer(O, "red"), Point(50, 0))
        act!(red_ball, Action(anim_rotate_around(2π, O)))
        blue_ball = Object(5:41, (args...) -> object_layer(O, "blue"), Point(100, 40))
        act!(blue_ball, Action(anim_rotate_around(2π, 0.0, red_ball)))

        # the frame range for actions have 2 level nesting(check for that)
        act!(blue_ball, Action(5:30, appear(:fade)))
        connect =
            Object(5:41, (args...) -> connector(pos(red_ball), pos(blue_ball), "black"))
        path_ofRed = Object(5:41, (args...) -> path!(path_of_red, pos(red_ball), "red"))
        path_ofBlue =
            Object(5:41, (args...) -> path!(path_of_blue, pos(blue_ball), "blue"))
    end

    l2 = @JLayer 20:60 begin
        Background(5:41, ground1)
        ball1 = Object(5:41, (args...) -> object_layer(O, "red"), Point(50, 0))
        act!(ball1, Action(anim_rotate_around(2π, O)))
        ball2 = Object(5:41, (args...) -> object_layer(O, "blue"), Point(100, 40))
        act!(ball2, Action(anim_rotate_around(2π, 0.0, ball1)))
        act!(ball2, Action(5:30, appear(:fade)))
        conn = Object(5:41, (args...) -> connector(pos(ball1), pos(ball2), "black"))
        path_ball1 = Object(5:41, (args...) -> path!(path_of_red, pos(ball1), "red"))
        path_ball2 = Object(5:41, (args...) -> path!(path_of_blue, pos(ball2), "blue"))
    end

    l3 = @JLayer 20:60 600 600 begin
        Background(5:41, ground1)
        rball = Object(5:41, (args...) -> object_layer(O, "red"), Point(50, 0))
        act!(rball, Action(anim_rotate_around(2π, O)))
        bball = Object(5:41, (args...) -> object_layer(O, "blue"), Point(100, 40))
        act!(bball, Action(anim_rotate_around(2π, 0.0, rball)))
        act!(bball, Action(5:30, appear(:fade)))
        con = Object(5:41, (args...) -> connector(pos(rball), pos(bball), "black"))
        path_rball = Object(5:41, (args...) -> path!(path_of_red, pos(rball), "red"))
        path_bball = Object(5:41, (args...) -> path!(path_of_blue, pos(bball), "blue"))
    end

    # dont forget to update the reference images once anim_rotate is fixed
    layer_actions = [
        Action(1:4, appear(:fade)),
        Action(5:25, anim_translate(l1.position, Point(300, 300))),
        Action(5:25, anim_rotate(2π)),
        Action(5:25, disappear(:fade)),
        Action(5:25, anim_scale(0)),
    ]

    act!([l1, l2, l3], layer_actions)

    ball1 = Object(5:41, (args...) -> object_layer(O, "red"), Point(50, 0))
    act!(ball1, Action(anim_rotate_around(2π, O)))
    ball2 = Object(5:41, (args...) -> object_layer(O, "blue"), Point(100, 40))
    act!(ball2, Action(anim_rotate_around(2π, 0.0, ball1)))
    act!(ball2, Action(10:30, disappear(:fade)))
    conn = Object(5:41, (args...) -> connector(pos(ball1), pos(ball2), "black"))
    por = Object(5:41, (args...) -> path!(path_of_red, pos(ball1), "red"))
    pob = Object(5:41, (args...) -> path!(path_of_blue, pos(ball2), "blue"))
    layer_objects = [ball1, ball2, conn, por, pob]

    @testset "Layer macro" begin
        @test l1.frames.frames == l2.frames.frames == l3.frames.frames
        @test l1.width == l2.width == l3.width == 600
        @test l1.height == l2.height == l3.height == 600
        @test l1.position == l2.position == l3.position == O
        @test length(l1.layer_objects) ==
              length(l2.layer_objects) ==
              length(l3.layer_objects) ==
              length(layer_objects) + 1
        @test length(l1.actions) ==
              length(l2.actions) ==
              length(l3.actions) ==
              length(layer_actions)
        @test l1.current_setting.opacity ==
              l2.current_setting.opacity ==
              l3.current_setting.opacity ==
              1.0
        @test l1.current_setting.scale ==
              l2.current_setting.scale ==
              l3.current_setting.scale ==
              Javis.Scale(1.0, 1.0)
        @test l1.current_setting.rotation_angle ==
              l2.current_setting.rotation_angle ==
              l3.current_setting.rotation_angle ==
              0.0
        @test l1.image_matrix == l2.image_matrix == l3.image_matrix == nothing
    end

    # remove duplicate layers after above testing
    video.layers = [l1]
    @test get_position(l1) == O

    astar(args...; do_action = :stroke) = star(O, 50, 5, 0.5, 0, do_action)
    acirc(args...; do_action = :stroke) = circle(Point(100, 100), 50, do_action)
    star_obj = Object(1:30, astar)
    act!(star_obj, Action(linear(), morph_to(acirc)))
    circle_obj = Object(31:60, acirc)
    act!(circle_obj, Action(linear(), morph_to(astar)))

    opacity_anim = Animation(
        [0, 0.5, 1], # must go from 0 to 1
        [0.0, 0.3, 0.7],
        [sineio(), sineio()],
    )

    l4 = @JLayer 5:20 200 200 Point(-50, 50) begin
        Background(1:14, ground2)
        rball = Object(1:14, (args...) -> object_layer(O, "black"), Point(50, 0))
        act!(rball, Action(anim_translate(Point(100, -100))))
    end

    act!(l4, Action(1:5, opacity_anim, setopacity()))

    Javis.show_layer_frame(71:79, 30:35, l1)
    Javis.show_layer_frame(71:79, 10, l4)

    render(video; tempdirectory = "images", pathname = "layer_test.gif")

    for i in ["03", "05", 10, 18, 19, 20, 24, 33, 44, 45, 49, 51, 59, 65, 71, 76, 77, 79]
        @test_reference "refs/layer$i.png" load("images/00000000$i.png")
        @test isfile("layer_test.gif")
    end

    for i in 1:80
        rm("images/$(lpad(i, 10, "0")).png")
    end

    rm("images/palette.png")
    rm("layer_test.gif")

    Javis.CURRENT_VIDEO[1] = vid
    Background(1:20, ground)
    l5 = @JLayer 5:20 200 200 Point(-50, 50) begin
        Background(1:14, ground2)
        rball = Object(1:14, (args...) -> object_layer(O, "black"), Point(50, 0))
    end

    act!(l5, Action(opacity_anim, setopacity()))

    @test_throws ErrorException Javis.get_layer_frame(vid, l5, 6)

end
