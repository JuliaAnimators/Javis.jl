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

    render(vid; pathname = "")

    action_list = [back, star_obj]

    viewer_win, frame_dims, r_slide, tbox, canvas, layers, actions, total_frames, video =
        Javis._javis_viewer(vid, 100, action_list, false, layers = Javis.Layer[])
    visible(viewer_win, false)

    @test get_gtk_property(viewer_win, :title, String) == "Javis Viewer"

    Javis._increment(video, [r_slide, tbox], actions, frame_dims, canvas, total_frames, Javis.Layer[])
    sleep(0.1)
    curr_frame = Reactive.value(r_slide)
    second_frame = Javis.get_javis_frame(video, actions, curr_frame)
    @test Reactive.value(r_slide) == 2

    Javis._decrement(video, [r_slide, tbox], actions, frame_dims, canvas, total_frames, Javis.Layer[])
    sleep(0.1)
    curr_frame = Reactive.value(r_slide)
    first_frame = Javis.get_javis_frame(video, actions, curr_frame)
    @test Reactive.value(r_slide) == 1

    @test first_frame != second_frame

    Javis._decrement(video, [r_slide, tbox], actions, frame_dims, canvas, total_frames, Javis.Layer[])
    sleep(0.1)
    curr_frame = Reactive.value(r_slide)
    last_frame = Javis.get_javis_frame(video, actions, curr_frame)
    @test curr_frame == total_frames

    Javis._increment(video, [r_slide, tbox], actions, frame_dims, canvas, total_frames, Javis.Layer[])
    sleep(0.1)
    curr_frame = Reactive.value(r_slide)
    first_frame = Javis.get_javis_frame(video, actions, curr_frame)
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

    objects = vid.objects
    frames = Javis.preprocess_frames!(objects)

    img = Javis._jupyter_viewer(vid, length(frames), objects, 30, layers=Javis.Layer[])
    @test img.output.val == Javis.get_javis_frame(vid, objects, 1)

    txt = Interact.textbox(1:length(frames), typ = "Frame", value = 2)
    frm = Interact.slider(1:length(frames), label = "Frame", value = txt[] + 1)
    @test Javis.get_javis_frame(vid, objects, 2) ==
          Javis.get_javis_frame(vid, objects, txt[])
    @test Javis.get_javis_frame(vid, objects, 3) ==
          Javis.get_javis_frame(vid, objects, frm[])

    for i in 4:length(frames)
        output = Javis.get_javis_frame(vid, objects, i)
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

    objects = vid.objects
    frames = Javis.preprocess_frames!(objects)

    @test v.filename === "foo.png"
    img = Javis._pluto_viewer(vid, length(frames), objects;layers=Javis.Layer[])
    for i in 1:length(img)
        @test img[i] == Javis.get_javis_frame(vid, objects, i)
    end
end
