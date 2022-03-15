function circle_line()
    sethue("red")
    circle(O, 100, :stroke)
    sethue("green")
    line(O, O + 100, :stroke)
    sethue("blue")
    rect(O - 100, 50, 50, :fillpreserve)
    newpath()
    sethue("orange")
    rect(O + 100, 60, 90, :path)
    #the usuall fillstroke calls fill first then stroke
    #the partial drawing happens in the order you call
    #these luxor functions. Since i want the outline
    #first then the fill...
    strokepreserve()
    fillpath()
end

@testset "Testing strokepath" begin
    video = Video(500, 500)

    nframes = 100
    Background(1:nframes, (args...) -> background("white"))
    circ = Object(1:nframes, (args...) -> circle(O, 100, :stroke))
    act!(circ, Action(1:nframes, linear(), show_creation()))

    mkpath("gifs")
    render(video, tempdirectory = "images", pathname = "gifs/strokepath.gif")
    @test_reference "refs/strokepath_10.png" load("images/0000000010.png")
    @test_reference "refs/strokepath_25.png" load("images/0000000025.png")
    @test_reference "refs/strokepath_50.png" load("images/0000000050.png")
    @test_reference "refs/strokepath_75.png" load("images/0000000075.png")
    for i in 1:100
        rm("images/$(lpad(i,10,"0")).png")
    end
    rm("images/palette.png")
end

@testset "Testing strokepreserve" begin
    video = Video(500, 500)

    nframes = 100
    Background(1:nframes, (args...) -> background("white"))
    circ = Object(1:nframes, (args...) -> (circle(O, 50, :path);
    strokepreserve();
    move(Point(100, 0));
    circle(O, 100, :path);
    strokepath()))
    act!(circ, Action(1:nframes, linear(), show_creation()))

    mkpath("gifs")
    render(video, tempdirectory = "images", pathname = "gifs/strokepreserve.gif")
    @test_reference "refs/strokepreserve_10.png" load("images/0000000010.png")
    @test_reference "refs/strokepreserve_25.png" load("images/0000000025.png")
    @test_reference "refs/strokepreserve_50.png" load("images/0000000050.png")
    @test_reference "refs/strokepreserve_75.png" load("images/0000000075.png")
    for i in 1:100
        rm("images/$(lpad(i,10,"0")).png")
    end
    rm("images/palette.png")
end

@testset "Testing fillpath" begin
    video = Video(500, 500)

    nframes = 100
    Background(1:nframes, (args...) -> background("white"))
    circ = Object(1:nframes, (args...) -> circle(O, 50, :fill))
    act!(circ, Action(1:nframes, linear(), show_creation()))

    mkpath("gifs")
    render(video, tempdirectory = "images", pathname = "gifs/fillpath.gif")
    @test_reference "refs/fillpath_10.png" load("images/0000000010.png")
    @test_reference "refs/fillpath_25.png" load("images/0000000025.png")
    @test_reference "refs/fillpath_50.png" load("images/0000000050.png")
    @test_reference "refs/fillpath_75.png" load("images/0000000075.png")
    for i in 1:100
        rm("images/$(lpad(i,10,"0")).png")
    end
    rm("images/palette.png")
end

@testset "Testing fillpreserve" begin
    video = Video(500, 500)

    nframes = 100
    Background(1:nframes, (args...) -> background("white"))
    circ = Object(
        1:nframes,
        (args...) -> (circle(O, 50, :fillpreserve); circle(O + 50, 100, :fill)),
    )
    act!(circ, Action(1:nframes, linear(), show_creation()))

    mkpath("gifs")
    render(video, tempdirectory = "images", pathname = "gifs/fillpreserve.gif")
    @test_reference "refs/fillpreserve_10.png" load("images/0000000010.png")
    @test_reference "refs/fillpreserve_25.png" load("images/0000000025.png")
    @test_reference "refs/fillpreserve_50.png" load("images/0000000050.png")
    @test_reference "refs/fillpreserve_75.png" load("images/0000000075.png")
    for i in 1:100
        rm("images/$(lpad(i,10,"0")).png")
    end
    rm("images/palette.png")
end

@testset "Drawing partial circles lines rectangles" begin
    video = Video(500, 500)

    nframes = 100
    Background(1:nframes, (args...) -> background("black"))
    obj = Object(1:nframes, (_, _, _) -> (circle_line());)
    act!(obj, Action(1:nframes, linear(), show_creation()))

    mkpath("gifs")
    render(video, tempdirectory = "images", pathname = "gifs/show_creation.gif")
    @test_reference "refs/draw_partial_circle_line_rect_50.png" load(
        "images/0000000050.png",
    )
    @test_reference "refs/draw_partial_circle_line_rect_25.png" load(
        "images/0000000025.png",
    )
    @test_reference "refs/draw_partial_circle_line_rect_75.png" load(
        "images/0000000075.png",
    )
    for i in 1:100
        rm("images/$(lpad(i,10,"0")).png")
    end
    rm("images/palette.png")
end

#test translate 
@testset "Showing Creation while translating" begin
    video = Video(500, 500)

    nframes = 100
    Background(1:nframes, (args...) -> background("white"))
    moving_circle = Object(1:nframes, JCircle(O, 100))
    act!(moving_circle, Action(1:nframes, linear(), show_creation()))
    act!(moving_circle, Action(anim_translate(100, 100)))
    mkpath("gifs")
    render(video, tempdirectory = "images", pathname = "gifs/circle_move_creation.gif")
    @test_reference "refs/moving_circle_creation_50.png" load("images/0000000050.png")
    @test_reference "refs/moving_circle_creation_25.png" load("images/0000000025.png")
    @test_reference "refs/moving_circle_creation_75.png" load("images/0000000075.png")
    for i in 1:100
        rm("images/$(lpad(i,10,"0")).png")
    end
    rm("images/palette.png")
end

#test scale 
@testset "Showing Creation while scaling" begin
    video = Video(500, 500)

    nframes = 100
    Background(1:nframes, (args...) -> background("white"))
    moving_circle = Object(1:nframes, JCircle(O, 100))
    stat_circle = Object(1:nframes, JCircle(O, 100))
    act!(moving_circle, Action(1:nframes, linear(), show_creation()))
    act!(moving_circle, Action(anim_scale(2)))

    mkpath("gifs")
    render(video, tempdirectory = "images", pathname = "gifs/circle_scale_creation.gif")
    @test_reference "refs/scale_circle_creation_50.png" load("images/0000000050.png")
    @test_reference "refs/scale_circle_creation_25.png" load("images/0000000025.png")
    @test_reference "refs/scale_circle_creation_75.png" load("images/0000000075.png")
    for i in 1:100
        rm("images/$(lpad(i,10,"0")).png")
    end
    rm("images/palette.png")
end

#test rotate 
@testset "Showing Creation while rotating" begin
    video = Video(500, 500)

    nframes = 100
    Background(1:nframes, (args...) -> background("white"))
    moving_circle = Object(1:nframes, JRect(0, 100, 50, 100))
    stat_circle = Object(1:nframes, JCircle(O, 100))
    act!(moving_circle, Action(1:nframes, linear(), show_creation()))
    act!(moving_circle, Action(anim_rotate(π)))

    mkpath("gifs")
    render(video, tempdirectory = "images", pathname = "gifs/rect_rotate_creation.gif")
    @test_reference "refs/rotate_rect_creation_50.png" load("images/0000000050.png")
    @test_reference "refs/rotate_rect_creation_25.png" load("images/0000000025.png")
    @test_reference "refs/rotate_rect_creation_75.png" load("images/0000000075.png")
    for i in 1:100
        rm("images/$(lpad(i,10,"0")).png")
    end
    rm("images/palette.png")
end
