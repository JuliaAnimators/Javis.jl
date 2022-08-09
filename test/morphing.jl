#circfunc() = circle(Point(-100,-100),30,5,0.5,0,:stroke)
function bluecircfunc()
    sethue("blue")
    circle(O, 30, :fillpreserve)
    sethue("black")
    strokepath()
end

function starfunc(color)
    sethue(color)
    star(O, 30, 5, 0.5, 0, :stroke)
end

function boxfunc(color)
    sethue(color)
    box(O - 50, 50, 50, :stroke)
end

@testset "Morphing star to circle and back , morph to function" begin
    video = Video(500, 500)
    back = Background(1:20, (args...) -> background("white"))
    star_obj = Object(1:20, (args...) -> starfunc("red"), Point(-100, -100))
    act!(star_obj, Action(2:10, morph_to(bluecircfunc)))
    act!(star_obj, Action(2:10, anim_translate(Point(200, 200))))
    act!(star_obj, Action(11:20, morph_to(starfunc, ["red"])))
    act!(star_obj, Action(11:20, anim_translate(Point(-200, -200))))
    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/star2circle5.png" load("images/0000000005.png")
    @test_reference "refs/star2circle15.png" load("images/0000000015.png")

    for i in 1:20
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Morphing  star to circle (morph to Object)" begin
    video = Video(500, 500)
    back = Background(1:20, (args...) -> background("white"))
    circ_obj = Object(1:20, (args...) -> bluecircfunc())
    star_obj = Object(1:20, (args...) -> starfunc("red"))
    act!(star_obj, Action(2:20, morph_to(circ_obj)))

    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/star2circle_obj5.png" load("images/0000000005.png")
    @test_reference "refs/star2circle_obj15.png" load("images/0000000015.png")

    for i in 1:20
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Morphing using keyframes" begin
    video = Video(500, 500)
    back = Background(1:20, (args...) -> background("white"))
    circ_obj = Object(1:20, (args...) -> bluecircfunc())
    act!(
        circ_obj,
        Action(
            2:20,
            Animation(
                [0, 0.3, 1],
                MorphFunction[bluecircfunc, (boxfunc, ["red"]), (starfunc, "blue")],
            ),
            morph(),
        ),
    )
    render(video; tempdirectory = "images", pathname = "")
    @test_reference "refs/star2circle_keyframe5.png" load("images/0000000005.png")
    @test_reference "refs/star2circle_keyframe15.png" load("images/0000000015.png")

    for i in 1:20
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Morphing mutates the object" begin
    function ground(args...)
        background("black")
        sethue("white")
    end

    #astar(args...; do_action = :stroke) = star(O, 50, 5, 0.5, 0, do_action)
    #abox(args...; do_action = :stroke) = rect(-50, -50, 100, 100, do_action)
    #acirc(args...; do_action = :stroke) = circle(Point(0, 0), 50, do_action)
    function greenbox()
        sethue("green")
        rect(-50, -50, 100, 100, action = :fill)
    end

    video = Video(500, 500)
    back = Background(1:200, ground)
    start_obj = Object(1:200, (args...) -> greenbox())
    act!(start_obj, Action(10:20, morph_to(bluecircfunc)))
    act!(start_obj, Action(30:40, anim_translate(Point(100, -100))))

    #TODO: the following comment is from the old test.
    # ask Ole if new morph behaviour is working right.
    # this is also a bug with the morph_to function
    # the star is formed at the incorrect position
    # the the origin is shifted and neve restored back
    # you can see this in the result of anim_translate actions
    # TODO: fix this at some point!
    act!(start_obj, Action(40:60, morph_to(starfunc, ["red"])))
    act!(start_obj, Action(70:90, anim_translate(Point(100, -100))))
    act!(start_obj, Action(100:120, morph_to(greenbox)))
    act!(start_obj, Action(130:150, anim_translate(Point(-100, 50))))
    act!(start_obj, Action(160:180, morph_to(bluecircfunc)))
    render(video; tempdirectory = "images", pathname = "")

    for i in [
        1,
        10,
        20,
        21,
        30,
        31,
        40,
        41,
        60,
        61,
        70,
        91,
        101,
        121,
        126,
        131,
        150,
        151,
        161,
        180,
        190,
    ]
        @test_reference "refs/morph_mutate$i.png" load("images/$(lpad(i, 10, "0")).png")
    end

    for i in 1:200
        rm("images/$(lpad(i, 10, "0")).png")
    end
end
