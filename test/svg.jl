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
    Background(1:35, latex_ground)
    runtime = Object((args...) -> latex(L"\mathcal{O}(\log{n})"))
    act!(runtime, Action(1:15, appear(:draw_text)))
    act!(runtime, Action(21:35, disappear(:draw_text)))
    Object((args...) -> latex_blend(L"\mathcal{O}\left(\frac{\log{x}}{2}\right)", 20))
    render(video; tempdirectory = "images", pathname = "")
    @test_reference "refs/ologn.png" load("images/0000000016.png")
    @test_reference "refs/ologn_mid.png" load("images/0000000007.png")
    @test_reference "refs/ologn_dis_mid.png" load("images/0000000027.png")
    for i in 1:35
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "latex pos in function" begin
    function latex_ground(args...)
        background("white")
        sethue("black")
        fontsize(30)
    end

    video = Video(400, 200)
    Background(1:1, latex_ground)
    Object((args...) -> latex(L"8")) # default fontsize 50
    render(video; tempdirectory = "images", pathname = "")
    @test_reference "refs/latex_8.png" load("images/0000000001.png")
    rm("images/0000000001.png")
end

@testset "latex alignment in function" begin
    function latex_ground(args...)
        background("white")
        sethue("black")
    end

    video = Video(400, 200)
    Background(1:1, latex_ground)
    Object((args...) -> latex(L"8", O + Point(20, 20), :bottom, :right))
    Object((args...) -> latex(L"8", O + Point(20, 20), :bottom, :left))
    Object((args...) -> latex(L"8", O + Point(20, 20), :top, :right))

    # testing for warn log message on passing incorrect input alignment parameters (default used)
    Object((args...) -> latex(L"8", O + Point(20, 20), :left, :top))

    Object((args...) -> latex(L"8", 0, 0, :middle, :centre))
    Object(
        (args...) -> Javis.animate_latex(L"8", O - Point(20, 20), 2, :top, :left, :stroke),
    )
    Object(
        (args...) ->
            Javis.animate_latex(L"8", O - Point(20, 20), 2, :bottom, :left, :stroke),
    )
    Object(
        (args...) -> Javis.animate_latex(L"8", O - Point(20, 20), 2, :top, :right, :stroke),
    )
    Object(
        (args...) ->
            Javis.animate_latex(L"8", O - Point(20, 20), 2, :bottom, :right, :stroke),
    )
    Object(
        (args...) ->
            Javis.animate_latex(L"8", O - Point(-20, 20), 0, :middle, :center, :stroke),
    )
    @test_logs (:warn,) (:warn,) render(video; tempdirectory = "images", pathname = "")
    @test_reference "refs/latex_alignment.png" load("images/0000000001.png")
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
    Background(1:1, latex_ground)
    Object(
        (args...) -> latex(
            L"$\begin{equation}\left[\begin{array}{ccc}1 & 2 & 3 \\4 & 5 & 6 \\7 & 8 & 9 \\\end{array}\right]\end{equation}$",
        ),
    )
    render(video; tempdirectory = "images", pathname = "")
    @test_reference "refs/latex_3x3_matrix.png" load("images/0000000001.png")
    rm("images/0000000001.png")
end

@testset "LaTeX 8" begin
    function latex_ground(args...)
        translate(-200, -100)
        background("white")
        sethue("black")
        fontsize(50)
    end

    video = Video(400, 200)
    Background(1:1, latex_ground)
    Object((args...) -> latex(L"\mathcal{O}(\log{n})"))
    render(video; tempdirectory = "images", pathname = "")
    @test_reference "refs/ologn_circ.png" load("images/0000000001.png")
    rm("images/0000000001.png")
end

@testset "Checking for \$\$" begin
    a = L"\sqrt{x^2}"
    b = LaTeXString("\\sqrt{x^2}")
    @test Javis.strip_eq(a) == Javis.strip_eq(b)
end

@testset "Checking polywh to get svg width and height" begin
    video = Video(400, 200)
    newpath()
    circle(O, 5, :path)
    closepath()
    poly = pathtopoly()
    w, h = Javis.polywh(poly)
    @test w == 10.0
end
