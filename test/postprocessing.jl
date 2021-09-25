
function ground(color)
    (args...) -> begin
        background(color)
        sethue("white")
    end
end

@testset "postprocess_frames_flow" begin

    function postprocess_frames_flow(frames)
        [frames; frames]
    end

    n_nopostprocess = 100
    nopostprocessvideo = Video(200, 200)
    Background(1:n_nopostprocess, ground("black"))
    circ = Object(1:25, JCircle(Point(-20, -20), 20, action = :fill, color = "white"))
    circ = Object(26:50, JCircle(Point(20, 20), 20, action = :fill, color = "white"))
    circ = Object(51:75, JCircle(Point(-20, -20), 20, action = :fill, color = "white"))
    circ = Object(76:100, JCircle(Point(20, 20), 20, action = :fill, color = "white"))
    render(
        nopostprocessvideo,
        tempdirectory = "images/withoutpostprocessing",
        pathname = "",
    )

    n_postprocess = 50
    postprocessvideo = Video(200, 200)
    Background(1:n_postprocess, ground("black"))
    circ = Object(1:25, JCircle(Point(-20, -20), 20, action = :fill, color = "white"))
    circ = Object(26:50, JCircle(Point(20, 20), 20, action = :fill, color = "white"))
    render(
        postprocessvideo,
        tempdirectory = "images/withpostprocessing",
        pathname = "",
        postprocess_frames_flow = postprocess_frames_flow,
    )

    for frame in [10, 30, 50, 70, 90, 100]
        png_name = lpad(string(frame), 10, "0")
        @test_reference "images/withpostprocessing/$png_name.png" load(
            "images/withoutpostprocessing/$png_name.png",
        )
    end

    for i in 1:n_nopostprocess
        rm("images/withpostprocessing/$(lpad(i, 10, "0")).png")
        rm("images/withoutpostprocessing/$(lpad(i, 10, "0")).png")
    end
    rm("images/withpostprocessing/", recursive = true)
    rm("images/withoutpostprocessing/", recursive = true)
end


@testset "postprocess_frame" begin

    function postprocess_frame(frame_image, frame, frames)
        h(x) = RGB(x.r, 1.0, x.b)
        return h.(frame_image)
    end

    n_frames = 50
    onepostprocessvideo = Video(200, 200)
    Background(1:n_frames, ground(RGB(0.0, 1.0, 0.0)))
    circ = Object(
        1:25,
        JCircle(Point(-20, -20), 20, action = :fill, color = RGB(1.0, 1.0, 0.0)),
    )
    circ = Object(
        26:50,
        JCircle(Point(20, 20), 20, action = :fill, color = RGB(1.0, 1.0, 0.0)),
    )

    render(
        onepostprocessvideo,
        tempdirectory = "images/withoutpostprocessing",
        pathname = "",
    )

    twopostprocessvideo = Video(200, 200)
    Background(1:n_frames, ground("black"))
    circ = Object(1:25, JCircle(Point(-20, -20), 20, action = :fill, color = "red"))
    circ = Object(26:50, JCircle(Point(20, 20), 20, action = :fill, color = "red"))
    render(
        twopostprocessvideo,
        tempdirectory = "images/withpostprocessing",
        pathname = "",
        postprocess_frame = postprocess_frame,
    )

    for frame in [5, 15, 25, 35, 45, 50]
        png_name = lpad(string(frame), 10, "0")
        @test_reference "images/withoutpostprocessing/$png_name.png" load(
            "images/withpostprocessing/$png_name.png",
        )
    end

    for i in 1:n_frames
        rm("images/withoutpostprocessing/$(lpad(i, 10, "0")).png")
        rm("images/withpostprocessing/$(lpad(i, 10, "0")).png")
    end
    rm("images/withoutpostprocessing/", recursive = true)
    rm("images/withpostprocessing/", recursive = true)
end

@testset "postprocess_frame and postprocess_frames_flow" begin

    function ground_double_color(c11, c12, c21, c22, framenumber, thr)
        if framenumber <= thr
            background(c11)
            sethue(c12)
        else
            background(c21)
            sethue(c22)
        end
    end

    function postprocess_frame(frame_image, idx, frames)
        h(x) = RGB(x.r, 1.0, x.b)
        return if idx <= 50
            h.(frame_image)
        else
            frame_image
        end
    end

    function postprocess_frames_flow(frames)
        [frames; reverse(frames)]
    end

    n_nopostprocess = 100
    nopostprocessvideo = Video(200, 200)
    Background(
        1:n_nopostprocess,
        (x, y, frame) ->
            ground_double_color(RGB(0.0, 1.0, 0.0), "white", "black", "red", frame, 50),
    )
    circ = Object(
        1:25,
        JCircle(Point(-20, -20), 20, action = :fill, color = RGB(0.0, 1.0, 1.0)),
    )
    circ = Object(
        26:50,
        JCircle(Point(20, 20), 20, action = :fill, color = RGB(0.0, 1.0, 1.0)),
    )
    circ = Object(51:75, JCircle(Point(20, 20), 20, action = :fill, color = "blue"))
    circ = Object(76:100, JCircle(Point(-20, -20), 20, action = :fill, color = "blue"))
    render(
        nopostprocessvideo,
        tempdirectory = "images/withoutpostprocessing",
        pathname = "",
    )

    n_postprocess = 50
    postprocessvideo = Video(200, 200)
    Background(1:n_postprocess, ground("black"))
    circ = Object(1:25, JCircle(Point(-20, -20), 20, action = :fill, color = "blue"))
    circ = Object(26:50, JCircle(Point(20, 20), 20, action = :fill, color = "blue"))
    render(
        postprocessvideo,
        tempdirectory = "images/withpostprocessing",
        pathname = "",
        postprocess_frames_flow = postprocess_frames_flow,
        postprocess_frame = postprocess_frame,
    )

    for frame in [10, 30, 50, 70, 90, 100]
        png_name = lpad(string(frame), 10, "0")
        @test_reference "images/withpostprocessing/$png_name.png" load(
            "images/withoutpostprocessing/$png_name.png",
        )
    end

    for i in 1:n_nopostprocess
        rm("images/withpostprocessing/$(lpad(i, 10, "0")).png")
        rm("images/withoutpostprocessing/$(lpad(i, 10, "0")).png")
    end
    rm("images/withpostprocessing/", recursive = true)
    rm("images/withoutpostprocessing/", recursive = true)
end
