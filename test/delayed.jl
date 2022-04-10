@testset "delayed operations" begin


    testvideo = Video(300, 300)
    Background(1:31, (args...) -> begin
        background("white")
        sethue("black")
    end)
    ball1 = Object(1:31, JCircle(O, 10, color = "black", action = :fill), Point(-45, 0))
    ball2 = Object(1:31, JCircle(O, 10, color = "blue", action = :fill), Point(0, 0))
    act!(ball1, Action(1:31, anim_translate(Point(-45, 0), Point(45, 0))))
    act!(ball2, Action(16:31, anim_translate(Point(25, 0), Point(0, -45))))
    mkdir("images/not_delayed/")
    render(testvideo, tempdirectory = "images/not_delayed", pathname = "")

    testvideo = Video(300, 300)
    Background(1:31, (args...) -> begin
        background("white")
        sethue("black")
    end)
    ball1 = Object(1:31, JCircle(O, 10, color = "black", action = :fill), Point(-45, 0))
    ball2 = Object(1:31, JCircle(O, 10, color = "blue", action = :fill), Point(0, 0))
    act!(ball1, Action(1:31, anim_translate(Point(-45, 0), Point(45, 0))))
    act!(
        ball2,
        Action(
            16:31,
            anim_translate(Javis.delayed_pos(ball1) + Point(25, 0), Point(0, -45)),
        ),
    )
    mkdir("images/delayed/")
    render(testvideo, tempdirectory = "images/delayed/", pathname = "")

    for frame in [1, 5, 14, 24, 30]
        png_name = lpad(frame, 10, "0")
        @test_reference "images/delayed/$(png_name).png" load(
            "images/not_delayed/$(png_name).png",
        )
    end

    rm("images/delayed", recursive = true)

    testvideo = Video(300, 300)
    Background(1:31, (args...) -> begin
        background("white")
        sethue("black")
    end)
    ball1 = Object(1:31, JCircle(O, 10, color = "black", action = :fill), Point(-45, 0))
    ball2 = Object(1:31, JCircle(O, 10, color = "blue", action = :fill), Point(0, 0))
    act!(ball1, Action(1:31, anim_translate(Point(-45, 0), Point(45, 0))))
    act!(
        ball2,
        Action(
            16:31,
            anim_translate(Javis.delayed_pos(ball1) - Point(-25, 0), Point(0, -45)),
        ),
    )
    mkdir("images/delayed/")
    render(testvideo, tempdirectory = "images/delayed/", pathname = "")

    for frame in [1, 5, 14, 24, 30]
        png_name = lpad(frame, 10, "0")
        @test_reference "images/delayed/$(png_name).png" load(
            "images/not_delayed/$(png_name).png",
        )
    end

    rm("images/delayed", recursive = true)

    testvideo = Video(300, 300)
    Background(1:31, (args...) -> begin
        background("white")
        sethue("black")
    end)
    ball1 = Object(1:31, JCircle(O, 10, color = "black", action = :fill), Point(-45, 0))
    ball2 = Object(1:31, JCircle(O, 10, color = "blue", action = :fill), Point(0, 0))
    act!(ball1, Action(1:31, anim_translate(Point(-45, 0), Point(45, 0))))
    act!(
        ball2,
        Action(
            16:31,
            anim_translate(Javis.delayed_pos(ball1) - Point(-25, 0), Point(0, -45)),
        ),
    )
    mkdir("images/delayed/")
    render(testvideo, tempdirectory = "images/delayed/", pathname = "")


    for frame in [1, 5, 14, 24, 30]
        png_name = lpad(frame, 10, "0")
        @test_reference "images/delayed/$(png_name).png" load(
            "images/not_delayed/$(png_name).png",
        )
    end

    rm("images/delayed", recursive = true)
    rm("images/not_delayed", recursive = true)

    @test Javis.CURRENTLY_RENDERING[1] == false
end



@testset "delayedposition Translation" begin
    testvideo = Video(300, 300)
    Background(1:31, (args...) -> begin
        background("white")
        sethue("black")
    end)
    ball1 = Object(1:31, JCircle(O, 10, color = "black", action = :fill), Point(-45, 0))
    act!(ball1, Action(1:31, anim_translate(Point(-45, 0), Point(45, 0))))
    act!(ball1, Action(17:31, anim_translate(Javis.delayed_pos(ball1), Point(0, -45))))
    render(testvideo, tempdirectory = "images", pathname = "")

    for frame in [1, 7, 15, 24, 30]
        png_name = lpad(string(frame), 10, "0")
        @test_reference "refs/delayed_translation_$(frame).png" load("images/$png_name.png")
    end

    for i in readdir("images", join = true)
        endswith(i, ".png") && rm(i)
    end
end

@testset "delayedposition rotation" begin
    testvideo = Video(300, 300)
    Background(1:31, (args...) -> begin
        background("white")
        sethue("black")
    end)

    ball1 = Object(1:31, JCircle(O, 10, color = "black", action = :fill), Point(-45, 0))
    ball2 = Object(1:31, JCircle(O, 10, color = "red", action = :fill), Point(0, -25))

    act!(ball1, Action(1:17, anim_translate(Point(-45, 0), O)))
    act!(ball2, Action(17:31, anim_rotate_around(-π, O)))
    render(testvideo, tempdirectory = "images", pathname = "")

    for frame in [1, 7, 15, 24, 30]
        png_name = lpad(string(frame), 10, "0")
        @test_reference "refs/delayed_rotation_$(frame).png" load("images/$png_name.png")
    end

    for i in readdir("images", join = true)
        if endswith(i, ".png")
            rm(i)
        end
    end
end


@testset "delayed_shorthands" begin
    vid = Video(500, 500)
    Background(1:200, (args...) -> background("black"))
    o1 = Object(JCircle(O, 30, color = "red", action = :fill), Point(50, 0))
    act!(o1, Action(anim_rotate_around(2π, Point(0, 0))))
    o2 = Object(50:200, JStar(Javis.delayed_pos(o1), 50, color = "blue", action = :fill))
    l1 = @JLayer 100:200 200 200 Javis.delayed_pos(o2) begin
        lo1 = Object(JStar(O, 50, color = "gray", action = :fill))
    end

    act!(o2, Action(anim_rotate_around(2π, Point(100, 0))))
    act!(l1, Action(1:100, anim_rotate_around(2π, Point(-100, 0))))

    o4 = Object(
        100:200,
        JEllipse(Javis.delayed_pos(o2), 10, 20, color = "green", action = :fill),
    )
    o5 = Object(
        100:200,
        JLine(Javis.delayed_pos(o2), Javis.delayed_pos(o1), color = "white"),
    )
    o6 = Object(
        100:200,
        JPoly(
            Luxor.AbstractPoint[O, Javis.delayed_pos(o1), Javis.delayed_pos(o2)],
            color = "navyblue",
            action = :stroke,
            linewidth = 10,
        ),
    )
    o3 = Object(
        100:200,
        JBox(Javis.delayed_pos(o2), 10, 10, color = "orange", action = :fill),
    )
    act!(
        o3,
        Action(
            anim_translate(Javis.delayed_pos(o2), Javis.delayed_pos(o1) + Point(10, 10)),
        ),
    )
    render(vid, pathname = "", tempdirectory = "images/")

    for frame in [1, 2, 41, 42, 101, 102, 151, 152, 200]
        png_name = lpad(string(frame), 10, "0")
        @test_reference "refs/delayed_shorthands_$(png_name).png" load(
            "images/$png_name.png",
        )
    end

    for i in readdir("images", join = true)
        endswith(i, ".png") && rm(i)
    end
end
