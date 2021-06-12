video = Video(600, 600)

@testset "Layers Feature" begin
    function ground(args...)
        background("white")
        sethue("black")
    end

    Background(1:70, ground)

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

    l1 = Javis.@Layer 20:60 600 600 Point(0, 0) begin
        Background(20:60, ground1)
        red_ball = Object(20:60, (args...) -> object_layer(O, "red"), Point(50, 0))
        act!(red_ball, Action(anim_rotate_around(2π, O)))
        blue_ball = Object(20:60, (args...) -> object_layer(O, "blue"), Point(100, 40))
        act!(blue_ball, Action(anim_rotate_around(2π, 0.0, red_ball)))
        connect = Object(
            20:60,
            (args...) -> connector(pos(red_ball), pos(blue_ball), "black"),
        )
        path_ofRed =
            Object(20:60, (args...) -> path!(path_of_red, pos(red_ball), "red"))
        path_ofBlue =
            Object(20:60, (args...) -> path!(path_of_blue, pos(blue_ball), "blue"))
    end

    l2 = Javis.@Layer 20:60 begin
        Background(20:60, ground1)
        ball1 = Object(20:60, (args...) -> object_layer(O, "red"), Point(50, 0))
        act!(ball1, Action(anim_rotate_around(2π, O)))
        ball2 = Object(20:60, (args...) -> object_layer(O, "blue"), Point(100, 40))
        act!(ball2, Action(anim_rotate_around(2π, 0.0, ball1)))
        conn = Object(
            20:60,
            (args...) -> connector(pos(ball1), pos(ball2), "black"),
        )
        path_ball1 =
            Object(20:60, (args...) -> path!(path_of_red, pos(ball1), "red"))
        path_ball2 =
            Object(20:60, (args...) -> path!(path_of_blue, pos(ball2), "blue"))
    end

    l3 = Javis.@Layer 20:60 600 600 begin
        Background(20:60, ground1)
        rball = Object(20:60, (args...) -> object_layer(O, "red"), Point(50, 0))
        act!(rball, Action(anim_rotate_around(2π, O)))
        bball = Object(20:60, (args...) -> object_layer(O, "blue"), Point(100, 40))
        act!(bball, Action(anim_rotate_around(2π, 0.0, rball)))
        con = Object(
            20:60,
            (args...) -> connector(pos(rball), pos(bball), "black"),
        )
        path_rball =
            Object(20:60, (args...) -> path!(path_of_red, pos(rball), "red"))
        path_bball =
            Object(20:60, (args...) -> path!(path_of_blue, pos(bball), "blue"))
    end

    # dont forget to update the reference images once anim_rotate is fixed
    layer_actions = [
        Action(30:50, anim_translate(l1.position, Point(300, 300))),
        Action(30:50, anim_rotate(2π)),
        Action(30:50, disappear(:fade)),
        Action(30:50, anim_scale(0)),
    ]

    act!([l1, l2, l3], layer_actions)
    
    ball1 = Object(20:60, (args...) -> object_layer(O, "red"), Point(50, 0))
    act!(ball1, Action(anim_rotate_around(2π, O)))
    ball2 = Object(20:60, (args...) -> object_layer(O, "blue"), Point(100, 40))
    act!(ball2, Action(anim_rotate_around(2π, 0.0, ball1)))
    conn = Object(20:60, (args...) -> connector(pos(ball1), pos(ball2), "black"))
    por = Object(20:60, (args...) -> path!(path_of_red, pos(ball1), "red"))
    pob = Object(20:60, (args...) -> path!(path_of_blue, pos(ball2), "blue"))
    layer_objects = [ball1, ball2, conn, por, pob]

    @testset "Layer macro" begin
        @test l1.frames.frames==l2.frames.frames==l3.frames.frames
        @test l1.width==l2.width==l3.width==600
        @test l1.height==l2.height==l3.height==600
        @test l1.position==l2.position==l3.position==O
        @test length(l1.children)==length(l2.children)==length(l3.children)==length(layer_objects)+1
        @test length(l1.actions)==length(l2.actions)==length(l3.actions)==length(layer_actions)
        @test l1.current_setting.opacity==l2.current_setting.opacity==l3.current_setting.opacity==1.0
        @test l1.current_setting.scale==l2.current_setting.scale==l3.current_setting.scale==Javis.Scale(1.0, 1.0)
        @test l1.current_setting.rotation_angle==l2.current_setting.rotation_angle==l3.current_setting.rotation_angle==0.0
        @test l1.image_matrix==l2.image_matrix==l3.image_matrix==Any[nothing]
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


    render(video; tempdirectory = "images", pathname = "layer_test.gif")

    for i in ["03", 10, 19, 21, 44, 45, 49, 51, 70]
        @test_reference "refs/layer$i.png" load("images/00000000$i.png")
        @test isfile("layer_test.gif")
    end

    for i in 1:70
        rm("images/$(lpad(i, 10, "0")).png")
    end

    rm("images/palette.png")
    rm("layer_test.gif")
end
