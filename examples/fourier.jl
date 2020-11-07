#=

    Drawing Julia using a Fourier series.
    A high definition animation can be seen here: https://youtu.be/rrmx2Q3sO1Y

    This code is based on code kindly provided by ric-cioffi (https://github.com/ric-cioffi)
    But was rewritten for v0.3 by Ole Kröger.
=#

using Javis, FFTW, FFTViews
using TravelingSalesmanHeuristics

function ground(args...)
    background("black")
    sethue("white")
end

function circ(; r = 10, vec = O, action = :stroke, color = "white")
    sethue(color)
    circle(O, r, action)
    my_arrow(O, vec)
    return vec
end

function my_arrow(start_pos, end_pos)
    arrow(
        start_pos,
        end_pos;
        linewidth = distance(start_pos, end_pos) / 100,
        arrowheadlength = 7,
    )
    return end_pos
end

function draw_line(
    p1 = O,
    p2 = O;
    color = "white",
    action = :stroke,
    edge = "solid",
    linewidth = 3,
)
    sethue(color)
    setdash(edge)
    setline(linewidth)
    line(p1, p2, action)
end

function draw_path!(path, pos, color)
    sethue(color)

    push!(path, pos)
    draw_line.(path[2:end], path[1:(end - 1)]; color = color)
end

function get_points(npoints, options)
    Drawing() # julialogo needs a drawing
    julialogo(action = :path, centered = true)
    shapes = pathtopoly()
    new_shapes = shapes[1:6]
    last_i = 1
    # the circles in the JuliaLogo are part of a single shape
    # this loop creates new shapes for each circle
    for shape in shapes[7:7]
        max_dist = 0.0
        for i in 2:length(shape)
            d = distance(shape[i - 1], shape[i])
            if d > 3
                push!(new_shapes, shape[last_i:(i - 1)])
                last_i = i
            end
        end
    end
    push!(new_shapes, shapes[7][last_i:end])
    shapes = new_shapes
    for i in 1:length(shapes)
        shapes[i] .*= options.shape_scale
    end

    total_distance = 0.0
    for shape in shapes
        total_distance += polyperimeter(shape)
    end
    parts = []
    points = Point[]
    start_i = 1
    for shape in shapes
        len = polyperimeter(shape)
        portion = len / total_distance
        nlocalpoints = floor(Int, portion * npoints)
        new_points = [
            Javis.get_polypoint_at(shape, i / (nlocalpoints - 1))
            for i in 0:(nlocalpoints - 1)
        ]
        append!(points, new_points)
        new_i = start_i + length(new_points) - 1
        push!(parts, start_i:new_i)
        start_i = new_i
    end
    return points, parts
end

c2p(c::Complex) = Point(real(c), imag(c))

remap_idx(i::Int) = (-1)^i * floor(Int, i / 2)
remap_inv(n::Int) = 2n * sign(n) - 1 * (n > 0)

function animate_fourier(options)
    npoints = options.npoints
    nplay_frames = options.nplay_frames
    nruns = options.nruns
    nframes = nplay_frames + options.nend_frames

    # obtain points from julialogo
    points, parts = get_points(npoints, options)
    npoints = length(points)
    println("#points: $npoints")
    # solve tsp to reduce length of extra edges
    distmat = [distance(points[i], points[j]) for i in 1:npoints, j in 1:npoints]

    path, cost = solve_tsp(distmat; quality_factor = 40)
    println("TSP cost: $cost")
    points = points[path] # tsp saves the last point again

    # optain the fft result and scale
    x = [p.x for p in points]
    y = [p.y for p in points]

    fs = fft(complex.(x, y)) |> FFTView
    # normalize the points as fs isn't normalized
    fs ./= npoints
    npoints = length(fs)

    video = Video(options.width, options.height)
    Background(1:nframes, ground)

    circles = Object[]

    for i in 1:npoints
        ridx = remap_idx(i)

        push!(circles, Object((args...) -> circ(; r = abs(fs[ridx]), vec = c2p(fs[ridx]))))

        if i > 1
            # translate to the tip of the vector of the previous circle
            act!(circles[i], Action(1:1, anim_translate(circles[i - 1])))
        end
        ridx = remap_idx(i)
        act!(circles[i], Action(1:nplay_frames, anim_rotate(0.0, ridx * 2π * nruns)))
    end

    trace_points = Point[]
    Object(1:nframes, (args...) -> draw_path!(trace_points, pos(circles[end]), "red"))

    render(video, pathname = options.filename)
end

function main()
    hd_options = (
        npoints = 3001, # rough number of points for the shape => number of circles
        nplay_frames = 1200, # number of frames for the animation of fourier
        nruns = 2, # how often it's drawn
        nend_frames = 200,  # number of frames in the end
        width = 1920,
        height = 1080,
        shape_scale = 2.5, # scale factor for the logo
        filename = "julia_hd.mp4",
    )

    fast_options = (
        npoints = 1001, # rough number of points for the shape => number of circles
        nplay_frames = 600, # number of frames for the animation of fourier
        nruns = 1, # how often it's drawn
        nend_frames = 200,  # number of frames in the end
        width = 1000,
        height = 768,
        shape_scale = 1.5, # scale factor for the logo
        filename = "julia_fast.mp4",
    )
    animate_fourier(fast_options)
end

main()
