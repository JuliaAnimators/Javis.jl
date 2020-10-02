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
@testset "morphing star2circle and back with fill" begin
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
            Action(1:10, morph(astar, acirc; action = :fill)),
            Action(11:20, morph(acirc, astar; action = :fill)),
        ],
        tempdirectory = "images",
        pathname = "",
    )

    @test_reference "refs/star2circle_fill5.png" load("images/0000000005.png")
    @test_reference "refs/star2circle_fill15.png" load("images/0000000015.png")
    for i in 1:20
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "morphing star2circle and back with fill" begin
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
            Action(1:10, morph(astar, acirc; action = :fill)),
            Action(11:20, morph(acirc, astar; action = :fill)),
        ],
        tempdirectory = "images",
        pathname = "",
    )

    @test_reference "refs/star2circle_fill5.png" load("images/0000000005.png")
    @test_reference "refs/star2circle_fill15.png" load("images/0000000015.png")
    for i in 1:20
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


@testset "transposing a matrix" begin
    function latex_ground(args...)
        translate(-200, -100)
        background("white")
        sethue("black")
        fontsize(50)
    end

    function matrix(; do_transpose = false, action = :stroke)
        fontsize(50)
        str = L"$\begin{equation}\left[\begin{array}{ccc}\alpha & \beta & \gamma \\x^{2} & \sqrt{y} & \lambda \\1 & 2 & y \\\end{array}\right]\end{equation}$"
        if do_transpose
            str = L"$\begin{equation}\left[\begin{array}{ccc}\alpha & x^{2} & 1 \\\beta & \sqrt{y} & 2 \\\gamma & \lambda & y \\\end{array}\right]\end{equation}$"
        end
        action == :path && newpath()
        latex(str, O, action)
        return pathtopoly()
    end

    video = Video(600, 400)
    javis(
        video,
        [
            BackgroundAction(1:62, latex_ground),
            Action(1:30, (args...) -> matrix()),
            Action(
                31:60,
                morph(
                    (args...) -> matrix(; action = :path),
                    (args...) -> matrix(; action = :path, do_transpose = true);
                    action = :fill,
                ),
            ),
            Action(61:62, (args...) -> matrix(; do_transpose = true)),
        ],
        tempdirectory = "images",
        pathname = "",
    )

    @test_reference "refs/matrix_transpose1.png" load("images/0000000001.png")
    @test_reference "refs/matrix_transpose50.png" load("images/0000000050.png")
    @test_reference "refs/matrix_transpose55.png" load("images/0000000055.png")
    @test_reference "refs/matrix_transpose62.png" load("images/0000000062.png")
    for i in 1:62
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Matrix sequence" begin
    function sequence(; second = false, action = :stroke)
        fontsize(50)

        str = L"$\begin{equation}\left[\begin{array}{cc}2 & -1\\-1 & 2 \\\end{array}\right]\end{equation}$"
        if second
            str = L"$\begin{equation}\left[\begin{array}{ccc} 2 & -1 & 0 \\ -1 & 2 & -1 \\ 0 & -1 & 2 \\\end{array}\right]\end{equation}$"
        end
        if !second
            latex(str, Point(-150, -60), action)
        else
            latex(str, Point(-200, -120), action)
        end
    end

    video = Video(600, 400)

    javis(
        video,
        [
            BackgroundAction(1:120, ground),
            Action(1:30, (args...) -> sequence()),
            Action(
                31:60,
                morph(
                    (args...) -> sequence(; action = :path),
                    (args...) -> sequence(; action = :path, second = true);
                    action = :fill,
                ),
            ),
            Action(61:90, (args...) -> sequence(; second = true)),
            Action(
                91:120,
                morph(
                    (args...) -> sequence(; action = :path, second = true),
                    (args...) -> sequence(; action = :path);
                    action = :fill,
                ),
            ),
        ],
        pathname = "",
        tempdirectory = "images",
    )

    @test_reference "refs/matrix_sequence01.png" load("images/0000000001.png")
    @test_reference "refs/matrix_sequence50.png" load("images/0000000050.png")
    @test_reference "refs/matrix_sequence80.png" load("images/0000000080.png")
    @test_reference "refs/matrix_sequence99.png" load("images/0000000099.png")
    for i in 1:120
        rm("images/$(lpad(i, 10, "0")).png")
    end
end
