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
