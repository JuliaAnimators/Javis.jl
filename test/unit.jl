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
        object = Object(1:100, (args...) -> O)
        act!(object, Action(1:100, anim_translate(Point(1, 1), Point(100, 100))))
        render(video; pathname = "")
        for f in [1, 50, 100]
            Javis.get_javis_frame(video, [object], f)
            @test get_position(object) == Point(f, f)
        end

        # with easing function
        video = Video(500, 500)
        object = Object(1:100, (args...) -> O)
        act!(object, Action(1:100, sineio(), anim_translate(Point(1, 1), Point(100, 100))))

        action = object.actions[1]

        anim = Animation([0.0, 1.0], [1.0, 100.0], [sineio()])
        render(video; pathname = "")
        for f in [1, 50, 100]
            m = (f - 1) / 99
            Javis.get_javis_frame(video, [object], f)
            @test get_position(object) == Point(at(anim, m), at(anim, m))
        end
    end

    @testset "Relative frames" begin
        video = Video(500, 500)
        Object(1:100, (args...) -> 1)
        # dummy object doesn't need a real function
        object = Object(Rel(10), (args...) -> 1)
        test_file = render(video)
        @test Javis.get_frames(object) == 101:110
        rm(test_file)
    end

    @testset "translation from origin" begin
        video = Video(500, 500)
        object = Object(1:100, (args...) -> O)
        act!(object, Action(1:100, anim_translate(Point(99, 99))))

        render(video; pathname = "")
        for f in [1, 50, 100]
            Javis.get_javis_frame(video, [object], f)
            @test get_position(object) == Point(f - 1, f - 1)
        end

        video = Video(500, 500)
        object = Object(1:100, (args...) -> O)
        act!(object, Action(1:100, anim_translate(99, 99)))

        render(video; pathname = "")
        for f in [1, 50, 100]
            Javis.get_javis_frame(video, [object], f)
            @test get_position(object) == Point(f - 1, f - 1)
        end
    end

    @testset "rotations" begin
        video = Video(500, 500)
        object = Object(1:100, (args...) -> O)
        act!(object, Action(1:100, anim_rotate(2π)))
        anim = Animation([0.0, 1.0], [0.0, 2π], [linear()])
        render(video; pathname = "")

        for f in [1, 50, 100]
            Javis.get_javis_frame(video, [object], f)
            @test get_angle(object) ≈ at(anim, (f - 1) / 99)
        end

        video = Video(500, 500)
        object = Object(1:100, (args...) -> O)
        rp = Point(2.0, 5.0)
        act!(object, Action(1:100, anim_rotate_around(2π, rp)))
        render(video; pathname = "")

        # compute radius
        r = sqrt(rp.x^2 + rp.y^2)
        shifted_start = -rp
        shifted_X = Point(r, 0)
        # compute start angle of O and rotation point
        start_angle = acos(dotproduct(shifted_X, shifted_start) / r^2)


        for f in [1, 50, 100]
            Javis.get_javis_frame(video, [object], f)
            @test get_angle(object) ≈ at(anim, (f - 1) / 99)
            # rotate clockwise because Luxor is flipped
            p = polar(r, start_angle - get_angle(object))
            p1 = Point(p.x, -p.y)
            @test get_position(object) ≈ p1 + rp
        end
    end

    @testset "scaling" begin
        video = Video(500, 500)
        # dummy object doesn't need a real function
        object = Object(1:50, (args...) -> O)
        act!(object, Action(1:50, anim_scale(1.0, 0.5)))
        render(video; pathname = "")

        anim = Animation([0.0, 1.0], [1.0, 0.5], [linear()])
        for f in [1, 50]
            Javis.get_javis_frame(video, [object], f)
            @test get_scale(object).x ≈ at(anim, (f - 1) / 49)
            @test get_scale(object).y ≈ at(anim, (f - 1) / 49)
        end
    end

    @testset "Relative frames" begin
        video = Video(500, 500)
        o1 = Object(1:100, (args...) -> 1)

        o2 = Object(Rel(10), (args...) -> 1)
        test_file = render(video)

        @test Javis.get_frames(o2) == 101:110
        rm(test_file)
    end

    @testset "translation from origin" begin
        video = Video(500, 500)
        object = Object(1:100, (args...) -> O)
        act!(object, Action(1:100, anim_translate(Point(99, 99))))
        render(video; pathname = "")
        for f in [1, 50, 100]
            Javis.get_javis_frame(video, [object], f)
            @test get_position(object) == Point(f - 1, f - 1)
        end

        video = Video(500, 500)
        object = Object(1:100, (args...) -> O)
        act!(object, Action(1:100, anim_translate(99, 99)))
        render(video; pathname = "")
        for f in [1, 50, 100]
            Javis.get_javis_frame(video, [object], f)
            @test get_position(object) == Point(f - 1, f - 1)
        end
    end

    @testset "action with a single frame" begin
        video = Video(500, 500)
        # dummy object doesn't need a real function
        object = Object(1:100, (args...) -> O)
        act!(object, Action(1:1, anim_translate(Point(10, 10))))
        render(video; pathname = "")
        Javis.get_javis_frame(video, [object], 1)
        @test get_position(object) == Point(10, 10)
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
        back = Background(1:50, (args...) -> 1)
        obj = Object((args...) -> 1)
        act!(obj, Action(anim_scale(1, 2)))

        objects = [back, obj]

        render(demo; pathname = "")
        @test Javis.get_frames(objects[1]) == 1:50
        @test Javis.get_frames(objects[2]) == 1:50
        @test Javis.get_frames(objects[2].actions[1]) == 1:50


        demo = Video(500, 500)
        back = Background(1:50, (args...) -> 1)
        obj = Object(Rel(-19:0), (args...) -> 1)
        act!(obj, Action(1:10, anim_scale(1, 2)))
        act!(obj, Action(Rel(10), anim_scale(1, 2)))

        objects = [back, obj]
        render(demo; pathname = "")
        @test Javis.get_frames(objects[1]) == 1:50
        @test Javis.get_frames(objects[2]) == 31:50
        @test Javis.get_frames(objects[2].actions[1]) == 1:10
        @test Javis.get_frames(objects[2].actions[2]) == 11:20
    end

    @testset "anim_" begin
        s = anim_scale(1, 2)
        @test s.from == Javis.Scale(1, 1)
        @test s.to == Javis.Scale(2, 2)

        s = anim_scale(Javis.Scale(1, 1), 2)
        @test s.from == Javis.Scale(1, 1)
        @test s.to == Javis.Scale(2, 2)

        s = anim_scale(Javis.Scale(1, 1), Javis.Scale(2, 2))
        @test s.from == Javis.Scale(1, 1)
        @test s.to == Javis.Scale(2, 2)

        s = anim_scale((1, 1), Javis.Scale(2, 1))
        @test s.from == Javis.Scale(1, 1)
        @test s.to == Javis.Scale(2, 1)

        s = anim_scale(Javis.Scale(2, 1))
        @test s.from == :current_scale
        @test s.to == Javis.Scale(2, 1)
    end
end
