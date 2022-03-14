using Animations
using GtkReactive
using Gtk: get_gtk_property, visible
using Images
import Interact
import Interact: @map, Widget, Widgets, @layout!, hbox, vbox
using Javis
import Latexify: latexify
using LaTeXStrings
using ReferenceTests
using Test
using VideoIO

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

#nframes=100
#exf=30
#Background(1:nframes+exf, (args...)-> background("black"))
#obj = Object(1:nframes+exf, (_,_,_)-> ( circle_line());)
#act!(obj,Action(1:nframes,linear(),show_creation()))
#render(video, pathname="circle_line_rect.gif")


#test strokepath
@testset "Drawing partial circles lines rectangles" begin
    video = Video(500, 500)

    nframes = 100
    Background(1:nframes, (args...) -> background("black"))
    obj = Object(1:nframes, (_, _, _) -> (circle_line());)
    act!(obj, Action(1:nframes, linear(), show_creation()))
    render(video, tempdirectory = "images", pathname = "show_creation.gif")

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
@testset "" begin
    video = Video(500, 500)

    nframes = 100
    Background(1:nframes, (args...) -> background("white"))
    moving_circle = Object(1:nframes, JCircle(O, 100))
    act!(moving_circle, Action(1:nframes, linear(), show_creation()))
    act!(moving_circle, Action(anim_translate(100, 100)))
    render(video, tempdirectory = "images", pathname = "circle_move_creation.gif")
    @test_reference "refs/moving_circle_creation_50.png" load("images/0000000050.png")
    @test_reference "refs/moving_circle_creation_25.png" load("images/0000000025.png")
    @test_reference "refs/moving_circle_creation_75.png" load("images/0000000075.png")
    for i in 1:100
        rm("images/$(lpad(i,10,"0")).png")
    end
    rm("images/palette.png")
end

#test scale 
@testset "" begin
    video = Video(500, 500)

    nframes = 100
    Background(1:nframes, (args...) -> background("white"))
    moving_circle = Object(1:nframes, JCircle(O, 100))
    stat_circle = Object(1:nframes, JCircle(O, 100))
    act!(moving_circle, Action(1:nframes, linear(), show_creation()))
    act!(moving_circle, Action(anim_scale(2)))
    render(video, tempdirectory = "images", pathname = "circle_scale_creation.gif")
    @test_reference "refs/scale_circle_creation_50.png" load("images/0000000050.png")
    @test_reference "refs/scale_circle_creation_25.png" load("images/0000000025.png")
    @test_reference "refs/scale_circle_creation_75.png" load("images/0000000075.png")
    for i in 1:100
        rm("images/$(lpad(i,10,"0")).png")
    end
    rm("images/palette.png")
end

#test rotate 
@testset "rotate" begin
    video = Video(500, 500)

    nframes = 100
    Background(1:nframes, (args...) -> background("white"))
    moving_circle = Object(1:nframes, JRect(0, 100, 50, 100))
    stat_circle = Object(1:nframes, JCircle(O, 100))
    act!(moving_circle, Action(1:nframes, linear(), show_creation()))
    act!(moving_circle, Action(anim_rotate(π)))
    render(video, tempdirectory = "images", pathname = "rect_rotate_creation.gif")
    @test_reference "refs/rotate_rect_creation_50.png" load("images/0000000050.png")
    @test_reference "refs/rotate_rect_creation_25.png" load("images/0000000025.png")
    @test_reference "refs/rotate_rect_creation_75.png" load("images/0000000075.png")
    for i in 1:100
        rm("images/$(lpad(i,10,"0")).png")
    end
    rm("images/palette.png")
end
