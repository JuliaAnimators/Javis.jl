@testset "O(logn)" begin
    function latex_ground(args...)
        translate(-200, -100)
        background("white")
        sethue("black")
        fontsize(50)
    end

    function latex_blend(latex_string, fsize)
        orangeblue = blend(Point(50, 70), Point(50, 120), "orange", "blue")
        setblend(orangeblue)
        fontsize(fsize)
        latex(latex_string, Point(50, 70))
    end

    video = Video(400, 200)
    javis(
        video,
        [
            BackgroundObject(1:35, latex_ground),
            # default fontsize 50
            Object((args...) -> latex(L"\mathcal{O}(\log{n})");) +
            Action(1:15, appear(:draw_text)) +
            Action(21:35, disappear(:draw_text)),
            Object(
                (args...) -> latex_blend(L"\mathcal{O}\left(\frac{\log{x}}{2}\right)", 20),
            ),
        ],
        tempdirectory = "images",
        pathname = "",
    )
    @test_reference "refs/ologn.png" load("images/0000000016.png")
    @test_reference "refs/ologn_mid.png" load("images/0000000007.png")
    @test_reference "refs/ologn_dis_mid.png" load("images/0000000027.png")
    for i in 1:35
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "LaTeX 8" begin
    function latex_ground(args...)
        translate(-200, -100)
        background("white")
        sethue("black")
        fontsize(50)
    end

    video = Video(400, 200)
    javis(
        video,
        [
            BackgroundObject(1:1, latex_ground),
            Object((args...) -> latex(L"8")), # default fontsize 50
        ],
        tempdirectory = "images",
        pathname = "",
    )
    @test_reference "refs/latex_8.png" load("images/0000000001.png")
    rm("images/0000000001.png")
end

@testset "LaTeX 3x3 matrix" begin
    function latex_ground(args...)
        translate(-200, -100)
        background("white")
        sethue("black")
        fontsize(20)
    end

    video = Video(400, 200)
    javis(
        video,
        [
            BackgroundObject(1:1, latex_ground),
            Object(
                (args...) ->
                    latex(L"$\begin{equation}\left[\begin{array}{ccc}1 & 2 & 3 \\4 & 5 & 6 \\7 & 8 & 9 \\\end{array}\right]\end{equation}$"),
            ),
        ],
        tempdirectory = "images",
        pathname = "",
    )
    @test_reference "refs/latex_3x3_matrix.png" load("images/0000000001.png")
    rm("images/0000000001.png")
end

@testset "latex pos in function" begin
    function latex_ground(args...)
        background("white")
        sethue("black")
        fontsize(30)
    end

    function foreground(latex_string)
        latex(latex_string, Point(50, 40))
        circle(O, 20, :fill) # should be in the center and not affected by latex
    end

    video = Video(400, 200)
    javis(
        video,
        [
            BackgroundObject(1:1, latex_ground),
            Object((args...) -> foreground(L"\mathcal{O}(\log{n})")),
        ],
        tempdirectory = "images",
        pathname = "",
    )
    @test_reference "refs/ologn_circ.png" load("images/0000000001.png")
    rm("images/0000000001.png")
end
