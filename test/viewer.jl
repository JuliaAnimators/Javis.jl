function ground(args...)
    background("white")
    sethue("black")
end

@testset "Javis Viewer" begin
    astar(args...) = star(O, 50)
    acirc(args...) = circle(Point(100, 100), 50)

    vid = Video(500, 500)
    action_list = [
        BackgroundAction(1:100, ground),
        Action(1:100, morph(astar, acirc; action = :fill)),
    ]

    javis(vid, action_list, pathname = "star_morph.gif")

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

    rm("star_morph.gif")
end
