astar(args...; do_action = :stroke) = star(Point(-100, -100), 30, 5, 0.5, 0, do_action)
acirc(args...; do_action = :stroke) = circle(Point(100, 100), 30, do_action)

@testset "morphing star2circle and back" begin
    video = Video(500, 500)

    back = Background(1:20, (args...) -> ground_color("white", "black", args[3]))
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
    back = Background(1:20, (args...) -> ground_color("white", "black", args[3]))
    Object(1:10, (args...) -> circle(Point(-100, 0), val(back), :fill))
    star_obj = Object(1:10, astar)
    act!(star_obj, Action(morph_to(acirc; do_action = :fill)))

    circle_obj = Object(11:20, acirc)
    act!(circle_obj, Action(morph_to(astar; do_action = :fill)))

    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/star2circle_fill5.png" load("images/0000000005.png")
    @test_reference "refs/star2circle_fill15.png" load("images/0000000015.png")
    for i in 1:20
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "test default kwargs" begin
    video = Video(500, 500)
    back = Background(1:10, (args...) -> ground_color("white", "black", args[3]))
    Object(1:10, (args...) -> circle(Point(-100, 0), val(back), :fill))
    star_obj = Object(1:10, astar)
    act!(star_obj, Action(morph_to(acirc)))

    pathname = render(video)

    path, ext = splitext(pathname)
    @test ext == ".gif"
    @test isfile(pathname)
    rm(pathname)
end


@testset "transposing a matrix" begin
    function latex_ground(args...)
        translate(-200, -100)
        background("white")
        sethue("black")
        fontsize(50)
    end

    function matrix(args...; do_transpose = false, do_action = :stroke)
        fontsize(50)
        str =
            L"$\begin{equation}\left[\begin{array}{ccc}\alpha & \beta & \gamma \\x^{2} & \sqrt{y} & \lambda \\1 & 2 & y \\\end{array}\right]\end{equation}$"
        if do_transpose
            str =
                L"$\begin{equation}\left[\begin{array}{ccc}\alpha & x^{2} & 1 \\\beta & \sqrt{y} & 2 \\\gamma & \lambda & y \\\end{array}\right]\end{equation}$"
        end
        latex(str, O, do_action)
    end

    video = Video(600, 400)
    Background(1:62, latex_ground)
    m = Object(1:60, matrix)
    act!(
        m,
        Action(
            31:60,
            morph_to(
                (args...; do_action = :fill) ->
                    matrix(; do_transpose = true, do_action = do_action);
                do_action = :fill,
            ),
        ),
    )
    Object(61:62, (args...) -> matrix(; do_transpose = true))
    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/matrix_transpose1.png" load("images/0000000001.png")
    @test_reference "refs/matrix_transpose50.png" load("images/0000000050.png")
    @test_reference "refs/matrix_transpose55.png" load("images/0000000055.png")
    @test_reference "refs/matrix_transpose62.png" load("images/0000000062.png")
    for i in 1:62
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Matrix sequence" begin
    function sequence(args...; second = false, do_action = :stroke)
        fontsize(50)

        str =
            L"$\begin{equation}\left[\begin{array}{cc}2 & -1\\-1 & 2 \\\end{array}\right]\end{equation}$"
        if second
            str =
                L"$\begin{equation}\left[\begin{array}{ccc} 2 & -1 & 0 \\ -1 & 2 & -1 \\ 0 & -1 & 2 \\\end{array}\right]\end{equation}$"
        end
        if !second
            latex(str, Point(-150, -60), do_action)
        else
            latex(str, Point(-200, -120), do_action)
        end
    end

    video = Video(600, 400)
    Background(1:120, ground)
    seq = Object(1:60, sequence)
    act!(
        seq,
        Action(
            31:60,
            morph_to(
                (args...; do_action = :stroke) ->
                    sequence(; second = true, do_action = do_action);
                do_action = :fill,
            ),
        ),
    )
    seq2 = Object(
        61:120,
        (args...; do_action = :stroke) ->
            sequence(; second = true, do_action = do_action),
    )
    act!(
        seq2,
        Action(
            31:60,
            morph_to(
                (args...; do_action = :fill) -> sequence(; do_action = do_action);
                do_action = :fill,
            ),
        ),
    )
    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/matrix_sequence01.png" load("images/0000000001.png")
    @test_reference "refs/matrix_sequence50.png" load("images/0000000050.png")
    @test_reference "refs/matrix_sequence80.png" load("images/0000000080.png")
    @test_reference "refs/matrix_sequence99.png" load("images/0000000099.png")
    for i in 1:120
        rm("images/$(lpad(i, 10, "0")).png")
    end
end


@testset "Morphing mutates the object" begin
    function ground(args...)
        background("black")
        sethue("white")
    end

    astar(args...; do_action = :stroke) = star(O, 50, 5, 0.5, 0, do_action)
    abox(args...; do_action = :stroke) = rect(-50, -50, 100, 100, do_action)
    acirc(args...; do_action = :stroke) = circle(Point(0, 0), 50, do_action)

    video = Video(500, 500)
    back = Background(1:200, ground)
    star_obj = Object(1:200, abox)
    act!(star_obj, Action(10:20, morph_to(acirc)))
    act!(star_obj, Action(30:40, anim_translate(Point(100, -100))))

    # this is also a bug with the morph_to function
    # the star is formed at the incorrect position
    # the the origin is shifted and neve restored back
    # you can see this in the result of anim_translate actions
    # TODO: fix this at some point!
    act!(star_obj, Action(40:60, morph_to(astar)))
    act!(star_obj, Action(70:90, anim_translate(Point(100, -100))))
    act!(star_obj, Action(100:120, morph_to(abox)))
    act!(star_obj, Action(130:150, anim_translate(Point(-100, 50))))
    act!(star_obj, Action(160:180, morph_to(acirc)))
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

@testset "Morphing modes" begin
    function ground(args...)
        background("black")
        sethue("white")
    end

    astar(args...; do_action = :stroke) = star(O, 50, 5, 0.5, 0, do_action)
    abox(args...; do_action = :stroke) = rect(-150, -150, 100, 100, do_action)
    acirc(args...; do_action = :stroke) = circle(Point(0, 0), 50, do_action)

    video = Video(500, 500)
    back = Background(1:50, ground)
    star_obj = Object(1:50, astar)
    box_obj = Object(1:50, abox)
    act!(star_obj, Action(5:20, morph_to(acirc, style = :mode1)))
    act!(box_obj, Action(30:50, morph_to(astar, style = :mode1)))
    render(video; tempdirectory = "images", pathname = "")

    for i in [5, 10, 15, 19, 20, 21, 30, 35, 40, 45, 49, 50]
        @test_reference "refs/morph_modes$i.png" load("images/$(lpad(i, 10, "0")).png")
    end

    for i in 1:50
        rm("images/$(lpad(i, 10, "0")).png")
    end
end
