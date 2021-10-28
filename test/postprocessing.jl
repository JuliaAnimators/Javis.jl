
function ground(color)
    (args...) -> begin
        background(color)
        sethue("white")
    end
end

@testset "postprocess_frames_flow" begin

    function postprocess_frames_flow(frames)
        [reverse(frames); reverse(frames)]
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

    postprocessvideo = Video(200, 200)
    Background(-24:25, ground("black"))
    circ = Object(-24:0, JCircle(Point(20, 20), 20, action = :fill, color = "white"))
    circ = Object(1:25, JCircle(Point(-20, -20), 20, action = :fill, color = "white"))
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

@testset "postprocess_frame cropped padded" begin

    function postprocess_pad(frame_image, idx, frames)
        return if idx > 25
            frame_image[1:100, 1:100]
        else
            frame_image
        end
    end

    n_frames = 50
    padvideo = Video(200, 200)
    Background(1:n_frames, ground(RGB(0.0, 1.0, 0.0)))

    render(
        padvideo,
        tempdirectory = "images",
        postprocess_frame = postprocess_pad,
        pathname = "",
    )


    for frame in [5, 15, 25]
        png_no_pad = lpad(string(frame), 10, "0")
        png_pad = lpad(string(frame + 25), 10, "0")
        @test_reference "images/$png_no_pad.png" load("images/$png_pad.png")
    end

    for i in readdir("images", join = true)
        endswith(i, ".png") && rm(i)
    end

    function postprocess_crop(frame_image, idx, frames)
        return if idx > 25
            repeat([frame_image[1, 1]], 300, 300)
        else
            frame_image
        end
    end

    cropvideo = Video(200, 200)
    Background(1:n_frames, ground("black"))
    render(
        cropvideo,
        tempdirectory = "images",
        pathname = "",
        postprocess_frame = postprocess_crop,
    )

    for frame in [5, 15, 25]
        png_no_crop = lpad(string(frame), 10, "0")
        png_crop = lpad(string(frame + 25), 10, "0")
        @test_reference "images/$png_no_crop.png" load("images/$png_crop.png")
    end

    for i in readdir("images", join = true)
        endswith(i, ".png") && rm(i)
    end
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

@testset "postprocess_frames_flow sanity check" begin
    h(x) = [x; 50]
    change_first(x) = x[10:end]
    n_frames = 20
    video = Video(200, 200)
    Background(1:n_frames, ground("black"))
    circ = Object(1:20, JCircle(Point(-20, -20), 20, action = :fill, color = "white"))

    @test_throws ErrorException render(video, pathname = "", postprocess_frames_flow = h)
end


@testset "crop" begin

    function gen_im(height, width)
        @imagematrix begin
            background("black")
            sethue("white")
            circle(O, 20, :fill)
            box(O, 50, 50, :stroke)
        end height width
    end

    h_w_1 = [(200, 200), (150, 150), (151, 151), (200, 200)]
    h_w_2 = [(100, 100), (59, 59), (67, 67), (49, 49)]

    for idx in 1:length(h_w_1)
        im1 = Javis.crop(gen_im(h_w_1[idx]...), h_w_2[idx]...)
        im2 = gen_im(h_w_2[idx]...)
        @test size(im1) == size(im2)
    end

end
