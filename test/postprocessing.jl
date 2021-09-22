@testset "postprocessing" begin

    function ground(color)
        (args...) -> begin
            background(color)
            sethue("white")
        end
    end

    function postprocess_frame(frame_image, idx, frames)
        return if 1 <= idx <= 25
            frame_image[size(frame_image, 1):-1:1, size(frame_image, 2):-1:1]
        elseif 26 <= idx <= 50
            frame_image[:, size(frame_image, 2):-1:1]
        elseif 51 <= idx <= 75
            frame_image
        elseif 76 <= idx <= 100
            frame_image[size(frame_image, 1):-1:1, :]
        end
    end

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
        pathname = ""
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
        # postprocess_frame = postprocess_frame,
        postprocess_frames_flow = postprocess_frames_flow
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
    rm("images/withoutpostprocessing/", recursive = true)
    rm("images/withpostprocessing/", recursive = true) 
end