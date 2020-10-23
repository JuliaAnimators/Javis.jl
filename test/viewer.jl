function ground(args...)
    background("white")
    sethue("black")
end

@testset "Javis Viewer" begin
    astar(args...; do_action = :stroke) = star(O, 50, 5, 0.5, 0, do_action)
    acirc(args...; do_action = :stroke) = circle(Point(100, 100), 50, do_action)

    vid = Video(500, 500)
    back = BackgroundObject(1:100, ground)
    star_obj = Object(1:100, astar)
    act!(star_obj, Action(morph_to(acirc; do_action = :fill)))

    render(vid; pathname = "")

    action_list = [back, star_obj]

    viewer_win, frame_dims, r_slide, tbox, canvas, actions, total_frames, video =
        Javis._javis_viewer(vid, 100, action_list, false)
    visible(viewer_win, false)

    @test get_gtk_property(viewer_win, :title, String) == "Javis Viewer"

    Javis._increment(video, [r_slide, tbox], actions, frame_dims, canvas, total_frames)
    sleep(0.1)
    curr_frame = Reactive.value(r_slide)
    second_frame = Javis.get_javis_frame(video, actions, curr_frame)
    @test Reactive.value(r_slide) == 2

    Javis._decrement(video, [r_slide, tbox], actions, frame_dims, canvas, total_frames)
    sleep(0.1)
    curr_frame = Reactive.value(r_slide)
    first_frame = Javis.get_javis_frame(video, actions, curr_frame)
    @test Reactive.value(r_slide) == 1

    @test first_frame != second_frame

    Javis._decrement(video, [r_slide, tbox], actions, frame_dims, canvas, total_frames)
    sleep(0.1)
    curr_frame = Reactive.value(r_slide)
    last_frame = Javis.get_javis_frame(video, actions, curr_frame)
    @test curr_frame == total_frames

    Javis._increment(video, [r_slide, tbox], actions, frame_dims, canvas, total_frames)
    sleep(0.1)
    curr_frame = Reactive.value(r_slide)
    first_frame = Javis.get_javis_frame(video, actions, curr_frame)
    @test curr_frame == 1

    @test last_frame != first_frame
end
