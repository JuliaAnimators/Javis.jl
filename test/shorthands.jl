video = Video(800, 800)

@testset "Shorthands" begin
    function ground(args...)
        background("white")
        sethue("black")
    end

    Background(1:90, ground)

    line = Object(JLine(Point(100, -250)))
    line1 = Object(JLine(Point(-350, 350), Point(100, -250)))

    circle0 = Object(JCircle(45, action = :fill))
    circle1 = Object(JCircle(O, 100, action = :stroke))
    circle2 = Object(JCircle(Point(200, -200), Point(190, -190), action = :fill))
    circle3 = Object(JCircle(-350, -250, 20, action = :fill))

    box = Object(JBox(Point(-200, 150), Point(10, -150), color = "red", action = :stroke))
    box1 = Object(JBox([Point(20, -150), Point(100, 250)], color = "blue"))
    box2 = Object(JBox(Point(-250, -100), 200, 200, color = "yellow", action = :fill))
    box3 = Object(JBox(250, 300, 40, 40, color = "yellow", action = :fill))
    box4 = Object(JBox(O, 150, 150, 5.0, color = "black", action = :stroke))

    rect = Object(JRect(250, 15, 30, 55, color = "orange", action = :fill))
    rect1 = Object(JRect(Point(250, -150), 30, 55, color = "orange", action = :fill))

    ellipse = Object(JEllipse(-50, 15, 40, 25, color = "blue"))
    ellipse0 = Object(JEllipse(Point(-50, 15), 45, 30, color = "blue"))
    ellipse1 = Object(
        JEllipse(Point(-50, 15), Point(150, -50), 70, color = "red", action = :stroke),
    )
    ellipse2 = Object(
        JEllipse(
            Point(-50, 15),
            Point(50, -50),
            Point(-100, 290),
            color = "red",
            action = :stroke,
        ),
    )

    star = Object(JStar(Point(-50, 15), 30, color = "red", action = :stroke))
    star1 = Object(JStar(50, -105, 45, color = "red", action = :fill))

    poly0 = Object(JPoly(ngon(O, 150, 3, -π / 2, vertices = true)))
    poly1 = Object(JPoly(ngon(O, 250, 4, π / 2, vertices = true)), action = :fill)

    somepath = Object(@JShape begin
        sethue("blue")
        circle.(ngon(O, 150, 3, -π / 2, vertices = true), 20, :fill)
    end)

    action = :stroke
    somepath1 = Object(
        @JShape begin
            sethue(color)
            poly(ngon(O, 400, 11, 5, vertices = true), action, close = true)
        end action = action color = "red" radius = 8
    )

    act!(
        [
            line,
            circle0,
            circle1,
            circle2,
            circle3,
            box,
            box1,
            box2,
            box3,
            rect,
            rect1,
            ellipse,
            ellipse0,
            ellipse1,
            ellipse2,
            star,
            star1,
            poly0,
            poly1,
        ],
        Action(20:30, anim_translate(Point(-150, 150))),
    )


    act!([circle0], Action(1:50, change(:radius, 45 => 10)))
    act!(
        [
            line,
            line1,
            circle0,
            circle1,
            box,
            box1,
            box2,
            box3,
            box4,
            rect,
            rect1,
            ellipse,
            ellipse0,
            ellipse1,
            ellipse2,
            star,
            star1,
            poly0,
            poly1,
        ],
        [
            Action(40:51, change(:color, "red")),
            Action(52:61, change(:color, colorant"red" => colorant"blue")),
        ],
    )
    act!(
        [
            line,
            line1,
            circle0,
            circle1,
            rect,
            rect1,
            ellipse,
            ellipse0,
            ellipse1,
            ellipse2,
            star,
            star1,
            poly0,
            poly1,
        ],
        Action(71:90, change(:linewidth, 1 => 5)),
    )

    render(video; tempdirectory = "images", pathname = "shorthands.gif")

    for i in ["01", 20, 21, 39, 40, 59, 65, 85]
        @test_reference "refs/shorthands$i.png" load("images/00000000$i.png")
        @test isfile("shorthands.gif")
    end

    for i in 1:90
        rm("images/$(lpad(i, 10, "0")).png")
    end

    rm("images/palette.png")
    rm("shorthands.gif")
end

video = Video(400, 400)
origin(Point(200, 200))
@testset "JImage for J-Objects" begin
    function ground(args...)
        background("white")
        sethue("black")
    end

    Background(1:30, ground)

    circle_img = Object(
        1:5,
        JImage(
            O,
            readpng("refs/dispatch.png"),
            true;
            shape = circle,
            shapeargs = (pt = O, r = 40, action = :clip),
            scaleargs = 1,
        ),
    )
    poly_img = Object(
        6:10,
        JImage(
            O,
            readpng("refs/dispatch.png"),
            true;
            shape = poly,
            shapeargs = (
                pointlist = [
                    Point(-100, 0),
                    Point(0, -100),
                    Point(100, 0),
                    Point(80, 100),
                    Point(-80, 100),
                ],
                action = :clip,
            ),
            scaleargs = 1,
        ),
    )
    box_img = Object(
        11:15,
        JImage(
            O,
            readpng("refs/dispatch.png"),
            true;
            shape = box,
            shapeargs = (points = [O, Point(-100, -100)], action = :clip),
            scaleargs = 1,
        ),
    )
    star_img = Object(
        16:20,
        JImage(
            O,
            readpng("refs/dispatch.png"),
            true;
            shape = star,
            shapeargs = (
                center = O,
                radius = 100,
                npoints = 5,
                ratio = 0.5,
                orientation = 0,
                action = :clip,
            ),
            scaleargs = 1,
        ),
    )
    ellipse_img = Object(
        21:25,
        JImage(
            O,
            readpng("refs/dispatch.png"),
            true;
            shape = ellipse,
            shapeargs = (cpt = O, w = 200, h = 100, action = :clip),
            scaleargs = 1,
        ),
    )

    render(video; tempdirectory = "images", pathname = "shorthands.gif")

    @test_reference "refs/jimage01.png" load("images/0000000001.png")
    @test_reference "refs/jimage06.png" load("images/0000000006.png")
    @test_reference "refs/jimage11.png" load("images/0000000011.png")
    @test_reference "refs/jimage16.png" load("images/0000000016.png")
    @test_reference "refs/jimage21.png" load("images/0000000021.png")

    # TODO: Add tests for scaling
    # for i in 1:90
        # rm("images/$(lpad(i, 10, "0")).png")
    # end

    rm("images/palette.png")
    rm("shorthands.gif")

end
