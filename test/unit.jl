@testset "unit tests" begin

    @testset "tmpdir" begin

        #=
        Leftover files from failed tests or errors can cause testing errors.
        Therefore, we remove any files in the `images` directory not pertinent to testing before executing a test.
        =#

        EXCLUDE_FILES = [".keep"]
        for f in readdir("images")
            !(f in EXCLUDE_FILES) && rm("images/$f")
        end
        @test length(readdir("images")) == length(EXCLUDE_FILES)
    end

    @testset "projection" begin
        x0 = Line(Point(0, 10), O)
        p = Point(10, 20)
        @test projection(p, x0) == Point(0, 20)

        y0 = Line(Point(10, 0), O)
        @test projection(p, y0) == Point(10, 0)
    end

    @testset "translation" begin
        video = Video(500, 500)
        # dummy action doesn't need a real function
        object = Object(1:100, () -> 1)
        act!(object, Action(1:100, Translation(Point(1, 1), Point(100, 100))))

        action = object.actions[1]

        # needs internal translation as well
        action.internal_transition = Javis.InternalTranslation(O)
        Javis.compute_transition!(action, video, 1)
        @test action.internal_transition.by == Point(1, 1)
        Javis.compute_transition!(action, video, 50)
        @test action.internal_transition.by == Point(50, 50)
        Javis.compute_transition!(action, video, 100)
        @test action.internal_transition.by == Point(100, 100)

        # with easing function
        video = Video(500, 500)
        # dummy action doesn't need a real function
        object = Object(1:100, () -> 1)
        act!(object, Action(1:100, sineio(), Translation(Point(1, 1), Point(100, 100))))

        action = object.actions[1]

        anim = Animation([0.0, 1.0], [1.0, 100.0], [sineio()])
        m = 49 / 99
        # needs internal translation as well
        action.internal_transition = Javis.InternalTranslation(O)
        Javis.compute_transition!(action, video, 1)
        @test action.internal_transition.by == Point(1, 1)
        Javis.compute_transition!(action, video, 50)
        @test action.internal_transition.by == Point(at(anim, m), at(anim, m))
        Javis.compute_transition!(action, video, 100)
        @test action.internal_transition.by == Point(100, 100)

        # with animation function
        anim_01 = Animation([0.0, 1.0], [0.0, 1.0], [sineio()])
        video = Video(500, 500)
        # dummy action doesn't need a real function
        object = Object(1:100, () -> 1)
        act!(object, Action(1:100, anim_01, Translation(Point(1, 1), Point(100, 100))))

        action = object.actions[1]

        anim = Animation([0.0, 1.0], [1.0, 100.0], [sineio()])
        m = 49 / 99
        # needs internal translation as well
        action.internal_transition = Javis.InternalTranslation(O)
        Javis.compute_transition!(action, video, 1)
        @test action.internal_transition.by == Point(1, 1)
        Javis.compute_transition!(action, video, 50)
        @test action.internal_transition.by == Point(at(anim, m), at(anim, m))
        Javis.compute_transition!(action, video, 100)
        @test action.internal_transition.by == Point(100, 100)
    end

    @testset "Relative frames" begin
        video = Video(500, 500)
        Object(1:100, (args...) -> 1)
        object = Object(Rel(10), (args...) -> 1)
        # dummy object doesn't need a real function
        test_file = render(video)
        @test Javis.get_frames(object) == 101:110
        rm(test_file)
    end

    @testset "translation from origin" begin
        video = Video(500, 500)
        # dummy object doesn't need a real function
        object = Object(1:100, () -> 1)
        act!(object, Action(1:100, Translation(Point(99, 99))))

        action = object.actions[1]

        # needs internal translation as well
        action.internal_transition = Javis.InternalTranslation(O)

        Javis.compute_transition!(action, video, 1)
        @test action.internal_transition.by == O
        Javis.compute_transition!(action, video, 50)
        @test action.internal_transition.by == Point(49, 49)
        Javis.compute_transition!(action, video, 100)
        @test action.internal_transition.by == Point(99, 99)

        video = Video(500, 500)
        # dummy object doesn't need a real function
        object = Object(1:100, () -> 1)
        act!(object, Action(1:100, Translation(99, 99)))
        action = object.actions[1]

        # needs internal translation as well
        action.internal_transition = Javis.InternalTranslation(O)

        Javis.compute_transition!(action, video, 1)
        @test action.internal_transition.by == O
        Javis.compute_transition!(action, video, 50)
        @test action.internal_transition.by == Point(49, 49)
        Javis.compute_transition!(action, video, 100)
        @test action.internal_transition.by == Point(99, 99)
    end

    @testset "rotations" begin
        video = Video(500, 500)
        # dummy object doesn't need a real function
        object = Object(1:100, () -> 1)
        act!(object, Action(1:100, Rotation(2π)))

        action = object.actions[1]
        # needs internal translation as well
        action.internal_transition = Javis.InternalRotation(0.0, O)

        Javis.compute_transition!(action, video, 1)
        @test action.internal_transition.angle == 0.0
        Javis.compute_transition!(action, video, 100)
        @test action.internal_transition.angle == 2π

        video = Video(500, 500)
        # dummy object doesn't need a real function
        object = Object(1:100, () -> 1)
        act!(object, Action(1:100, Rotation(2π, Point(2.0, 5.0))))

        action = object.actions[1]

        # needs internal translation as well
        action.internal_transition = Javis.InternalRotation(0.0, O)

        Javis.compute_transition!(action, video, 1)
        @test action.internal_transition.angle == 0.0
        @test action.internal_transition.center == Point(2.0, 5.0)
        Javis.compute_transition!(action, video, 100)
        @test action.internal_transition.angle == 2π
        @test action.internal_transition.center == Point(2.0, 5.0)
    end

    @testset "scaling" begin
        video = Video(500, 500)
        # dummy object doesn't need a real function
        object = Object(0:100, () -> 1)
        act!(object, Action(0:100, Scaling(0.0, 1.0)))
        action = object.actions[1]

        # needs internal scaling as well
        action.internal_transition = Javis.InternalScaling((0, 0))
        Javis.compute_transition!(action, video, 0)
        @test action.internal_transition.scale == (0.0, 0.0)
        Javis.compute_transition!(action, video, 50)
        @test action.internal_transition.scale == (0.5, 0.5)
        Javis.compute_transition!(action, video, 100)
        @test action.internal_transition.scale == (1.0, 1.0)
    end

    @testset "Relative frames" begin
        video = Video(500, 500)
        o1 = Object(1:100, (args...) -> 1)
        act!(o1, Action(1:100, Translation(Point(1, 1), Point(100, 100))))

        o2 = Object(Rel(10), (args...) -> 1)
        act!(o2, Action(1:10, Translation(Point(1, 1), Point(100, 100))))
        test_file = render(video)

        @test Javis.get_frames(o2) == 101:110
        rm(test_file)
    end

    @testset "translation from origin" begin
        video = Video(500, 500)
        # dummy object doesn't need a real function
        object = Object(1:100, () -> 1)
        act!(object, Action(1:100, Translation(Point(99, 99))))
        action = object.actions[1]

        # needs internal translation as well
        action.internal_transition = Javis.InternalTranslation(O)

        Javis.compute_transition!(action, video, 1)
        @test action.internal_transition.by == O
        Javis.compute_transition!(action, video, 50)
        @test action.internal_transition.by == Point(49, 49)
        Javis.compute_transition!(action, video, 100)
        @test action.internal_transition.by == Point(99, 99)

        video = Video(500, 500)
        # dummy object doesn't need a real function
        object = Object(1:100, () -> 1)
        act!(object, Action(1:100, Translation(99, 99)))
        action = object.actions[1]
        # needs internal translation as well
        action.internal_transition = Javis.InternalTranslation(O)

        Javis.compute_transition!(action, video, 1)
        @test action.internal_transition.by == O
        Javis.compute_transition!(action, video, 50)
        @test action.internal_transition.by == Point(49, 49)
        Javis.compute_transition!(action, video, 100)
        @test action.internal_transition.by == Point(99, 99)
    end

    @testset "rotations" begin
        video = Video(500, 500)
        # dummy object doesn't need a real function
        object = Object(1:100, () -> 1)
        act!(object, Action(1:100, Rotation(2π)))
        action = object.actions[1]
        # needs internal translation as well
        action.internal_transition = Javis.InternalRotation(0.0, O)

        Javis.compute_transition!(action, video, 1)
        @test action.internal_transition.angle == 0.0
        Javis.compute_transition!(action, video, 100)
        @test action.internal_transition.angle == 2π

        video = Video(500, 500)
        # dummy object doesn't need a real function
        object = Object(1:100, () -> 1)
        act!(object, Action(1:100, Rotation(2π, Point(2.0, 5.0))))
        action = object.actions[1]
        # needs internal translation as well
        action.internal_transition = Javis.InternalRotation(0.0, O)

        Javis.compute_transition!(action, video, 1)
        @test action.internal_transition.angle == 0.0
        @test action.internal_transition.center == Point(2.0, 5.0)
        Javis.compute_transition!(action, video, 100)
        @test action.internal_transition.angle == 2π
        @test action.internal_transition.center == Point(2.0, 5.0)
    end

    @testset "action with a single frame" begin
        video = Video(500, 500)
        # dummy object doesn't need a real function
        object = Object(1:1, () -> 1)
        act!(object, Action(1:1, Translation(Point(10, 10))))
        action = object.actions[1]
        # needs internal translation as well
        action.internal_transition = Javis.InternalTranslation(O)
        Javis.compute_transition!(action, video, 1)
        @test action.internal_transition.by == Point(10, 10)
    end

    @testset "Frames errors" begin
        # throws because a Video object was not previously defined
        empty!(Javis.CURRENT_VIDEO)
        @test_throws ErrorException Object(1:10, (args...) -> star(O, 20, 5, 0.5, 0, :fill))
        # throws because the frames of the first object need to be defined explicitly
        video = Video(500, 500)
        Object((args...) -> 1)
        @test_throws ArgumentError render(video)

        video = Video(500, 500)
        Object(Rel(10), (args...) -> 1)
        # throws because the frames of the first object need to be defined explicitly
        @test_throws ArgumentError render(video)

        video = Video(500, 500)
        Object(1:100, (args...) -> 1)
        Object(:some, (args...) -> 1)
        # throws because :some is not supported as Symbol for `frames`
        @test_throws ArgumentError render(video)
    end

    @testset "Frame computation" begin

        demo = Video(500, 500)
        back = BackgroundObject(1:50, (args...) -> 1)
        obj = Object((args...) -> 1)
        act!(obj, Action(Scaling(1, 2)))

        objects = [back, obj]

        render(demo; pathname = "")
        @test Javis.get_frames(objects[1]) == 1:50
        @test Javis.get_frames(objects[2]) == 1:50
        @test Javis.get_frames(objects[2].actions[1]) == 1:50


        demo = Video(500, 500)
        back = BackgroundObject(1:50, (args...) -> 1)
        obj = Object(Rel(-19:0), (args...) -> 1)
        act!(obj, Action(1:10, Scaling(1, 2)))
        act!(obj, Action(Rel(10), Scaling(1, 2)))

        objects = [back, obj]
        render(demo; pathname = "")
        @test Javis.get_frames(objects[1]) == 1:50
        @test Javis.get_frames(objects[2]) == 31:50
        @test Javis.get_frames(objects[2].actions[1]) == 1:10
        @test Javis.get_frames(objects[2].actions[2]) == 11:20
    end
end
