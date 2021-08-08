function ground(args...)
    background("white")
    sethue("black")
end

@testset "Javis Viewer" begin
    astar(args...; do_action = :stroke) = star(O, 50, 5, 0.5, 0, do_action)
    acirc(args...; do_action = :stroke) = circle(Point(100, 100), 50, do_action)

    vid = Video(500, 500)
    back = Background(1:100, ground)
    star_obj = Object(1:100, astar)
    act!(star_obj, Action(morph_to(acirc; do_action = :fill)))

    l1 = @JLayer 20:60 100 100 Point(0, 0) begin
        obj = Object((args...) -> circle(O, 25, :fill))
        act!(obj, Action(1:20, appear(:fade)))
    end

    render(vid; pathname = "")

    action_list = [back, star_obj]

    viewer_win, frame_dims, r_slide, tbox, canvas, actions, total_frames, video =
        Javis._javis_viewer(vid, 100, action_list, false)
    visible(viewer_win, false)

    @test get_gtk_property(viewer_win, :title, String) == "Javis Viewer"

    Javis._increment(video, [r_slide, tbox], actions, frame_dims, canvas, total_frames)
    sleep(0.1)
    curr_frame = Reactive.value(r_slide)
    second_frame = Javis.get_javis_frame(video, actions, curr_frame, layers = [l1])
    @test Reactive.value(r_slide) == 2

    Javis._decrement(video, [r_slide, tbox], actions, frame_dims, canvas, total_frames)
    sleep(0.1)
    curr_frame = Reactive.value(r_slide)
    first_frame = Javis.get_javis_frame(video, actions, curr_frame, layers = [l1])
    @test Reactive.value(r_slide) == 1

    @test first_frame != second_frame

    Javis._decrement(video, [r_slide, tbox], actions, frame_dims, canvas, total_frames)
    sleep(0.1)
    curr_frame = Reactive.value(r_slide)
    last_frame = Javis.get_javis_frame(video, actions, curr_frame, layers = [l1])
    @test curr_frame == total_frames

    Javis._increment(video, [r_slide, tbox], actions, frame_dims, canvas, total_frames)
    sleep(0.1)
    curr_frame = Reactive.value(r_slide)
    first_frame = Javis.get_javis_frame(video, actions, curr_frame, layers = [l1])
    @test curr_frame == 1

    @test last_frame != first_frame
end

@testset "Jupyter Viewer" begin
    astar(args...; do_action = :stroke) = star(O, 50, 5, 0.5, 0, do_action)
    acirc(args...; do_action = :stroke) = circle(Point(100, 100), 50, do_action)

    vid = Video(500, 500)
    back = Background(1:100, ground)
    star_obj = Object(1:100, astar)
    act!(star_obj, Action(morph_to(acirc; do_action = :fill)))

    l1 = @JLayer 20:60 100 100 Point(0, 0) begin
        obj = Object((args...) -> circle(O, 25, :fill))
        act!(obj, Action(1:20, appear(:fade)))
    end

    objects = vid.objects
    all_objects = [vid.objects..., Javis.flatten(vid.layers)...]
    frames = Javis.preprocess_frames!(all_objects)

    img = Javis._jupyter_viewer(vid, length(frames), objects, 30)
    @test img.output.val == Javis.get_javis_frame(vid, objects, 1, layers = [l1])

    txt = Interact.textbox(1:length(frames), typ = "Frame", value = 2)
    frm = Interact.slider(1:length(frames), label = "Frame", value = txt[] + 1)
    @test Javis.get_javis_frame(vid, objects, 2, layers = [l1]) ==
          Javis.get_javis_frame(vid, objects, txt[], layers = [l1])
    @test Javis.get_javis_frame(vid, objects, 3, layers = [l1]) ==
          Javis.get_javis_frame(vid, objects, frm[], layers = [l1])

    for i in 4:length(frames)
        output = Javis.get_javis_frame(vid, objects, i, layers = [l1])
        wdg = Widget(["frm" => frm, "txt" => txt], output = output)
        img = @layout! wdg vbox(hbox(:frm, :txt), output)
        @test img.output.val == output
    end
end

@testset "Pluto Viewer" begin
    v = Javis.PlutoViewer("foo.png")
    astar(args...; do_action = :stroke) = star(O, 50, 5, 0.5, 0, do_action)
    acirc(args...; do_action = :stroke) = circle(Point(100, 100), 50, do_action)

    vid = Video(500, 500)
    back = Background(1:100, ground)
    star_obj = Object(1:100, astar)
    act!(star_obj, Action(morph_to(acirc; do_action = :fill)))

    l1 = @JLayer 20:60 100 100 Point(0, 0) begin
        obj = Object((args...) -> circle(O, 25, :fill))
        act!(obj, Action(1:20, appear(:fade)))
    end

    objects = vid.objects
    all_objects = [vid.objects..., Javis.flatten(vid.layers)...]
    frames = Javis.preprocess_frames!(all_objects)

    @test v.filename === "foo.png"
    img = Javis._pluto_viewer(vid, length(frames), objects)
    for i in 1:length(img)
        @test img[i] == Javis.get_javis_frame(vid, objects, i, layers = [l1])
    end
end

@testset "Livestreaming" begin
    astar(args...; do_action = :stroke) = star(O, 50, 5, 0.5, 0, do_action)
    acirc(args...; do_action = :stroke) = circle(Point(100, 100), 50, do_action)

    vid = Video(500, 500)
    back = Background(1:100, ground)
    star_obj = Object(1:100, astar)
    act!(star_obj, Action(morph_to(acirc; do_action = :fill)))

    conf_local = setup_stream(:local, address = "0.0.0.0", port = 8081)
    @test conf_local isa Javis.StreamConfig
    @test conf_local.livestreamto == :local
    @test conf_local.protocol == "udp"
    @test conf_local.address == "0.0.0.0"
    @test conf_local.port == 8081
    @test conf_local.frames == :all

    conf_twitch_err = setup_stream(:twitch)
    conf_twitch = setup_stream(:twitch, twitch_key = "foo")
    @test conf_twitch_err isa Javis.StreamConfig
    @test conf_twitch_err.livestreamto == :twitch
    @test isempty(conf_twitch_err.twitch_key)
    @test conf_twitch.twitch_key == "foo"

    render(vid, pathname = "test_stream.gif", streamconfig = conf_local)
    # errors with macos; a good test to have
    # test_local = run(pipeline(`lsof -i -P -n`, `grep ffmpeg`))
    # @test test_local isa Base.ProcessChain
    # @test test_local.processes isa Vector{Base.Process}

    cancel_stream()
    @test_throws ProcessFailedException run(
        pipeline(
            `ps aux`,
            pipeline(`grep ffmpeg`, pipeline(`grep stream_loop`, `awk '{print $2}'`)),
        ),
    )
    
    # can't actually test the streamed frames but let's check if they're atleast created
    conf_local = setup_stream(:local, 56:60)
    render(vid, tempdirectory = "images", streamconfig = conf_local)

    for i in 56:60
        @test_reference "refs/livestream_frames$i.png" load(
            "images/$(lpad((i-55), 10, "0")).png",
        )
    end

    for i in 1:5
        rm("images/$(lpad(i, 10, "0")).png")
    end

    @test_throws ErrorException render(vid, streamconfig = conf_twitch_err)
end
