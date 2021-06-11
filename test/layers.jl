@testset "Layers Feature" begin
    function ground(args...)
        background("white")
        sethue("black")
    end

    video = Video(600, 600)
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

    l1 = Javis.@javis_layer 1:70 600 600 Point(0, 0) begin
        Background(1:70, ground1)
        red_ball = Object(1:70, (args...) -> object_layer(O, "red"), Point(50, 0))
        act!(red_ball, Action(anim_rotate_around(2π, O)))
        blue_ball = Object(1:70, (args...) -> object_layer(O, "blue"), Point(100, 40))
        act!(blue_ball, Action(anim_rotate_around(2π, 0.0, red_ball)))
        connect =
            Object(1:70, (args...) -> connector(pos(red_ball), pos(blue_ball), "black"))
        path_ofRed = Object(1:70, (args...) -> path!(path_of_red, pos(red_ball), "red"))
        path_ofBlue =
            Object(1:70, (args...) -> path!(path_of_blue, pos(blue_ball), "blue"))
    end

    act!(l1, [Action(10:50, anim_translate(l1.position, Point(300, 300)))])
    act!(l1, Action(10:50, anim_rotate(2π)))
    act!(l1, Action(10:50, disappear(:fade)))
    act!(l1, Action(10:50, anim_scale(0)))

    layer_actions = [
        Action(10:50, anim_translate(l1.position, Point(300, 300))),
        Action(10:50, anim_rotate(2π)),
        Action(10:50, disappear(:fade)),
        Action(10:50, anim_scale(0)),
    ]

    ball1 = Object(1:70, (args...) -> object_layer(O, "red"), Point(50, 0))
    act!(ball1, Action(anim_rotate_around(2π, O)))
    ball2 = Object(1:70, (args...) -> object_layer(O, "blue"), Point(100, 40))
    act!(ball2, Action(anim_rotate_around(2π, 0.0, ball1)))
    conn = Object(1:70, (args...) -> connector(pos(ball1), pos(ball2), "black"))
    por = Object(1:70, (args...) -> path!(path_of_red, pos(ball1), "red"))
    pob = Object(1:70, (args...) -> path!(path_of_blue, pos(ball2), "blue"))
    layer_objects = [ball1, ball2, conn, por, pob]

    @testset "layer struct" begin
        @test l1 isa Javis.Layer
        @test l1.frames.frames == 1:70
        @test l1.width == 600
        @test l1.height == 600
        @test l1.position == O
        @test length(l1.children) == length(layer_objects) + 1
        @test length(l1.actions) == length(layer_actions)
        @test l1.current_setting.opacity == 1.0
        @test l1.current_setting.scale == Javis.Scale(1.0, 1.0)
        @test l1.current_setting.rotation_angle == 0.0
        @test l1.image_matrix == Any[nothing]
    end

    @test get_position(l1) == O

    astar(args...; do_action = :stroke) = star(O, 50, 5, 0.5, 0, do_action)
    acirc(args...; do_action = :stroke) = circle(Point(100, 100), 50, do_action)
    star_obj = Object(1:30, astar)
    act!(star_obj, Action(linear(), morph_to(acirc)))
    circle_obj = Object(31:60, acirc)
    act!(circle_obj, Action(linear(), morph_to(astar)))


    render(video; tempdirectory = "images", pathname = "layer_test.gif")

    for i in [10, 32, 50, 70]
        @test_reference "refs/layer$i.png" load("images/00000000$i.png")
        @test isfile("layer_test.gif")
    end

    for i in 1:70
        rm("images/$(lpad(i, 10, "0")).png")
    end

    rm("images/palette.png")
    rm("layer_test.gif")
end
