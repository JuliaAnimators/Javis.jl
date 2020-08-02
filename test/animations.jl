function ground(args...) 
    background("white")
    sethue("blue")
end

function latex_title(args...)
    translate(0, -200)
    latex(L"E=mc^2", 20)
end

function circ(p=O, color="black")
    sethue(color)
    circle(p, 25, :fill)
    return Transformation(p, 0.0)
end

function path!(points, pos, color)
    sethue(color)
    push!(points, pos)
    circle.(points, 2, :fill)
end

function rad(p1, p2, color)
    sethue(color)
    line(p1,p2, :stroke)
end

@testset "Dancing circles" begin 
    p1 = Point(100,0)
    p2 = Point(100,80)
    from_rot = 0.0
    to_rot = 2π
    path_of_blue = Point[]
    path_of_red = Point[]

    video = Video(500, 500)
    javis(video, [
        BackgroundAction(1:25, ground),
        Action(1:25, latex_title),
        Action(1:25, :red_ball, (args...)->circ(p1, "red"), Rotation(from_rot, to_rot)),
        Action(1:25, :blue_ball, (args...)->circ(p2, "blue"), Rotation(to_rot, from_rot, :red_ball)),
        Action(1:25, (video, args...)->path!(path_of_red, pos(:red_ball), "red")),
        Action(1:25, (video, args...)->path!(path_of_blue, pos(:blue_ball), "blue")),
        Action(1:25, (args...)->rad(pos(:red_ball), pos(:blue_ball), "black"))
    ], tempdirectory="images")

    @test_reference "refs/dancing_circles_16.png" load("images/0000000016.png")
    for i=1:25
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

@testset "Dancing circles layered" begin 
    p1 = Point(100,0)
    p2 = Point(100,80)
    from_rot = 0.0
    to_rot = 2π
    path_of_blue = Point[]
    path_of_red = Point[]

    video = Video(500, 500)
    javis(video, [
        Action(1:25, ground; in_global_layer=true),
        Action(1:25, latex_title),
        Action(1:25, :red_ball, (args...)->circ(p1, "red"), Rotation(from_rot, to_rot)),
        Action(1:25, :blue_ball, (args...)->circ(p2, "blue"), Rotation(to_rot, from_rot, :red_ball)),
        Action(1:25, (video, args...)->path!(path_of_red, pos(:red_ball), "red")),
        Action(1:25, (video, args...)->path!(path_of_blue, pos(:blue_ball), "blue")),
        Action(1:25, (args...)->rad(pos(:red_ball), pos(:blue_ball), "black"))
    ], tempdirectory="images")

    @test_reference "refs/dancing_circles_16.png" load("images/0000000016.png")
    for i=1:25
        rm("images/$(lpad(i, 10, "0")).png")
    end
end

astar(args...) = star(Point(-100,-100), 30) 
acirc(args...) = circle(Point(100,100), 30) 

@testset "morphing star2circle" begin
    video = Video(500, 500)
    javis(video, [
        Action(1:10, ground),
        Action(1:10, morph(astar, acirc))
    ], tempdirectory="images")
    @test_reference "refs/star2circle5.png" load("images/0000000005.png")
    for i=1:10
        rm("images/$(lpad(i, 10, "0")).png")
    end
end