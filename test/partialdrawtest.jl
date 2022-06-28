function draw_complex_shape()
    circle(O+20,100,:stroke)
    sethue("red")
    box(O,100,120,:fillpreserve)
    sethue("black")
    strokepath()
    sethue("green")
    ngon(Point(-200,-200),50;action=:fillstroke)
end


@testset "Testing Partial drawing of Object" begin
    video = Video(500, 500)
    back = Background(1:20, (args...) -> background("white"))
    obj = Object(1:20, (args...) -> draw_complex_shape())
    act!(obj, Action(2:20, showcreation() ))
    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/star2circle5.png" load("images/0000000005.png")
    @test_reference "refs/star2circle15.png" load("images/0000000015.png")

    for i in 1:20
        rm("images/$(lpad(i, 10, "0")).png")
    end
end
