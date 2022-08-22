obj1() = Object(1:30, (args...) -> begin
    box(O, 100, 100, :stroke)
    return O
end, Point(100, 150))

obj2() = Object(1:30, (args...) -> begin
    box(O, 100, 100, :stroke)
    return O
end, Point(-100, 250))

obj3() = Object(1:30, (args...) -> begin
    rotate(2π / 12)
    star(O, 50, 6, action = :stroke)
    return O
end, Point(-200, -150))

ground() = Background(1:30, (args...) -> begin
    background("black")
    sethue("white")
end)

@testset "Arrange objects vertically" begin
    video = Video(1000, 1000)
    ground()
    objlist = [obj1(), obj2(), obj3()]

    act!(10, arrange(10:30, objlist, O; gap = 4, dir = :vertical))
    render(video; tempdirectory = "images", pathname = "vid1.mp4")

    @test_reference "refs/arrange_vert1.png" load("images/0000000001.png")
    @test_reference "refs/arrange_vert10.png" load("images/0000000010.png")
    @test_reference "refs/arrange_vert20.png" load("images/0000000020.png")
    @test_reference "refs/arrange_vert30.png" load("images/0000000030.png")
    for i in 1:30
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Arrange objects horizontally" begin
    video = Video(1000, 1000)
    ground()
    objlist = [obj1(), obj2(), obj3()]

    act!(10, arrange(10:30, objlist, O; gap = 4, dir = :horizontal))
    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/arrange_horz1.png" load("images/0000000001.png")
    @test_reference "refs/arrange_horz2.png" load("images/0000000010.png")
    @test_reference "refs/arrange_horz20.png" load("images/0000000020.png")
    @test_reference "refs/arrange_horz30.png" load("images/0000000030.png")
    for i in 1:30
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "scale and arrange" begin
    video = Video(1000, 1000)
    ground()
    objlist = [obj1(), obj2(), obj3()]


    act!(objlist[1], Action(1:9, anim_scale(2)))
    act!(objlist[2], Action(1:9, anim_scale(1.5)))
    act!(objlist[3], Action(1:9, anim_scale(3)))
    act!(10, arrange(10:30, objlist, Point(0, -200); gap = 4, dir = :horizontal))
    render(video; tempdirectory = "images", pathname = "")

    @test_reference "refs/arrange_scale1.png" load("images/0000000001.png")
    @test_reference "refs/arrange_scale2.png" load("images/0000000010.png")
    @test_reference "refs/arrange_scale20.png" load("images/0000000020.png")
    @test_reference "refs/arrange_scale30.png" load("images/0000000030.png")
    for i in 1:30
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

#TODO add test for translate and arrange
#TODO add test for morph and arrange
