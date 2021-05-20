@testset "Check RFrame shorthands" begin
    function dummy(args...) end
    video = Video(10, 10)
    Background(1:20, dummy)
    a = Object(1:3, (args...) -> O) # 1:3
    b = Object(RFrames(1:3), (args...) -> O) # 4:6
    c = Object(RFrames(1:3, prev_start()), (args...) -> O) # 5:7
    d = Object(RFrames(prev_start(), prev_last()), (args...) -> O) # 5:7
    render(video; tempdirectory = "images", pathname = "")
    @test a.frames.frames == 1:3
    @test b.frames.frames == 4:6
    @test c.frames.frames == 5:7
    @test d.frames.frames == 5:7
end

@testset "Check RFrame helper function for previous object" begin
    function dummy(args...) end
    video = Video(10, 10)
    Background(1:20, dummy)
    a = Object(1:3, (args...) -> O) # 1:3
    b = Object(RFrames(2:5, prev_start(), default_last()), (args...) -> O) # 3:6
    c = Object(RFrames(2:5, prev_last()), (args...) -> O) # 8:11
    d = Object(RFrames(0:3, prev_start(c)), (args...) -> O) # 8:11
    e = Object(RFrames(2:5, prev_last(b)), (args...) -> O) # 8:11
    render(video; tempdirectory = "images", pathname = "")
    @test a.frames.frames == 1:3
    @test b.frames.frames == 3:6
    @test c.frames.frames == 8:11
    @test d.frames.frames == 8:11
    @test e.frames.frames == 8:11
end

@testset "Check RFrame helper function for previous action" begin
    function dummy(args...) end
    video = Video(10, 10)
    Background(1:20, dummy)
    a = Object(3:15, (args...) -> O) # 3:15
    act!(a, Action(1:3, appear(:fade))) # 1:3
    act!(a, Action(RFrames(2:5, prev_start()), appear(:fade))) # 3:6
    act!(a, Action(RFrames(2:5, prev_last()), appear(:fade))) # 8:11
    render(video; tempdirectory = "images", pathname = "")
    @test a.frames.frames == 3:15
    @test a.actions[1].frames.frames == 1:3
    @test a.actions[2].frames.frames == 3:6
    @test a.actions[3].frames.frames == 8:11
end

@testset "Check RFrame helper function parent_start and parent_last for object" begin
    function dummy(args...) end
    video = Video(10, 10)
    Background(1:20, dummy)
    a = Object(3:15, (args...) -> O) # 3:15
    b = Object(RFrames(-5:0, parent_last()), (args...) -> O) # last 5 frames of video i.e. 15:20
    c = Object(RFrames(5:10, parent_start()), (args...) -> O) # after first 5 frames of video i.e. 6:11
    render(video; tempdirectory = "images", pathname = "")
    @test a.frames.frames == 3:15
    @test b.frames.frames == 15:20
    @test c.frames.frames == 6:11
end

@testset "Check RFrame helper function parent_start and parent_last for action" begin
    function dummy(args...) end
    video = Video(10, 10)
    Background(1:20, dummy)
    a = Object(1:15, (args...) -> O) # 1:15
    act!(a, Action(RFrames(0:4, parent_start()), appear(:fade))) # 1:5 relative to parent
    act!(a, Action(RFrames(5:10, prev_last(), parent_last()), disappear(:fade))) # 10:15 relative to parent
    act!(a, Action(RFrames(-5:0, parent_last()), disappear(:scale))) # 10:15 relative to parent
    render(video; tempdirectory = "images", pathname = "")
    @test a.frames.frames == 1:15
    @test a.actions[1].frames.frames == 1:5
    @test a.actions[2].frames.frames == 10:15
    @test a.actions[3].frames.frames == 10:15
end
