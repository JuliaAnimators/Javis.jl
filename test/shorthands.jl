video = Video(800, 800)

@testset "Shorthands" begin
    function ground(args...)
        background("white")
        sethue("black")
    end

    Background(1:70, ground)

    myline = Object(Javis.JLine(Point(100, -250)))
    myline1 = Object(Javis.JLine(Point(-350, 350), Point(100, -250)))

    mycircle = Object(Javis.JCircle(45, action = :fill))
    mycircle1 = Object(Javis.JCircle(O, 100, action = :stroke))
    mycircle2 = Object(Javis.JCircle(Point(200, -200), Point(190, -190), action = :fill))
    mycircle3 = Object(Javis.JCircle(-350, -250, 20, action = :fill))

    mybox = Object(
        Javis.JBox(Point(-200, 150), Point(10, -150), color = "red", action = :stroke),
    )
    mybox1 = Object(Javis.JBox([Point(20, -150), Point(100, 250)], color = "blue"))
    mybox2 =
        Object(Javis.JBox(Point(-250, -100), 200, 200, color = "yellow", action = :fill))
    mybox3 = Object(Javis.JBox(250, 300, 40, 40, color = "yellow", action = :fill))
    mybox4 = Object(Javis.JBox(O, 150, 150, 5.0, color = "black", action = :stroke))

    myrect = Object(Javis.JRect(250, 15, 30, 55, color = "orange", action = :fill))
    myrect1 =
        Object(Javis.JRect(Point(250, -150), 30, 55, color = "orange", action = :fill))

    myellipse = Object(Javis.JEllipse(-50, 15, 40, 25, color = "blue"))
    myellipse0 = Object(Javis.JEllipse(Point(-50, 15), 45, 30, color = "blue"))
    myellipse1 = Object(
        Javis.JEllipse(
            Point(-50, 15),
            Point(150, -50),
            70,
            color = "red",
            action = :stroke,
        ),
    )
    myellipse2 = Object(
        Javis.JEllipse(
            Point(-50, 15),
            Point(50, -50),
            Point(-100, 290),
            color = "red",
            action = :stroke,
        ),
    )

    mystar = Object(Javis.JStar(Point(-50, 15), 30, color = "red", action = :stroke))
    mystar1 = Object(Javis.JStar(50, -105, 45, color = "red", action = :fill))

    mypoly = Object(Javis.JPoly(ngon(O, 150, 3, -π / 2, vertices = true)))
    mypoly1 = Object(Javis.JPoly(ngon(O, 250, 4, π / 2, vertices = true)), action = :fill)

    somepath = Object(Javis.@JShape begin
        sethue("blue")
        circle.(ngon(O, 150, 3, -π / 2, vertices = true), 20, :fill)
    end)
    somepath1 = Object(Javis.@JShape action = :stroke color = "red" radius = 8 begin
        sethue(color)
        poly(ngon(O, 400, 11, 5, vertices = true), action, close = true)
    end)

    act!(
        [
            myline,
            mycircle,
            mycircle1,
            mycircle2,
            mycircle3,
            mybox,
            mybox1,
            mybox2,
            mybox3,
            myrect,
            myrect1,
            myellipse,
            myellipse0,
            myellipse1,
            myellipse2,
            mystar,
            mystar1,
            mypoly,
            mypoly1,
        ],
        Action(20:30, anim_translate(Point(-150, 150))),
    )


    act!([mycircle], Action(1:50, change(:radius, 45 => 10)))
    act!(
        [
            myline,
            mycircle,
            mycircle1,
            mybox,
            mybox1,
            mybox2,
            mybox3,
            mybox4,
            myrect,
            myrect1,
            myellipse,
            myellipse0,
            myellipse1,
            myellipse2,
            mystar,
            mystar1,
            mypoly,
            mypoly1,
        ],
        Action(40:51, change(:color, "blue")),
    )

    render(video; tempdirectory = "images", pathname = "shorthands.gif")

    for i in ["01", 20, 21, 39, 40, 59, 65]
        @test_reference "refs/shorthands$i.png" load("images/00000000$i.png")
        @test isfile("shorthands.gif")
    end

    for i in 1:70
        rm("images/$(lpad(i, 10, "0")).png")
    end

    rm("images/palette.png")
    rm("shorthands.gif")
end
