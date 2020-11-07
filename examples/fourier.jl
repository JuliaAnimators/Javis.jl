using Javis, FFTW, FFTViews
using TravelingSalesmanHeuristics

function ground(args...)
    background("black")
    sethue("white")
end

function pixel(fs, t)
    h = div(length(fs), 2)
    p = sum(fs[i]*exp(i*2π*im*t) for i in -h:h)
    return Point(real(p), imag(p))
end

function circ(;r=10, action=:stroke, color="white")
    sethue(color)
    circle(O, r, action)
    return O
end

function my_arrow(start_pos, end_pos)
    arrow(start_pos, end_pos; linewidth=distance(start_pos, end_pos)/100)
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

function get_points(npoints)
    julialogo(action=:path, centered=true)
    shapes = pathtopoly()
    new_shapes = shapes[1:6]
    last_i = 1
    for shape in shapes[7:7]
        max_dist = 0.0
        for i in 2:length(shape)
            d = distance(shape[i-1], shape[i])
            if d > 3
                push!(new_shapes, shape[last_i:i-1])
                last_i = i
            end
        end
    end
    push!(new_shapes, shapes[7][last_i:end])
    shapes = new_shapes
    for i in 1:length(shapes)
        shapes[i] .*= 2.5
    end

    total_distance = 0.0
    for shape in shapes
        total_distance += polyperimeter(shape)
    end
    points = Point[]
    parts = []
    start = 1
    for shape in shapes
        len = polyperimeter(shape)
        portion = len/total_distance
        nlocalpoints = floor(Int, portion*npoints)
        new_points = [Javis.get_polypoint_at(shape, i/(nlocalpoints-1)) for i in 0:(nlocalpoints-1)]
        append!(points, new_points)
        push!(parts, start:start+length(new_points)-1)
        start += length(new_points)-1
    end
    return points, parts
end

c2p(c::Complex) = Point(real(c), imag(c))

remap_idx(i::Int) = (-1)^i * floor(Int, i / 2)
remap_inv(n::Int) = 2n * sign(n) - 1 * (n > 0)

npoints = 3001
nframes = 700
nplay_frames = 500

video = Video(1920, 1080)
Background(1:nframes, ground)

# Object(1:nframes, (args...)->poly(shape, :stroke))
points, parts = get_points(npoints)
npoints = length(points)
distmat = [distance(points[i], points[j]) for i in 1:npoints, j in 1:npoints]
path, cost = solve_tsp(distmat; quality_factor=50)
println("cost: $cost")
points = points[path]

x = [p.x for p in points]
y = [p.y for p in points]

fs = fft(complex.(x, y)) |> FFTView
fs ./= npoints

circles = Object[]
vectors = Object[]
trace_points = Point[]
for i in 1:npoints
    ridx = remap_idx(i)

    push!(circles, Object((args...)->circ(;r=abs(fs[ridx]))))
end

for i in 2:npoints
    prev_ridx = remap_idx(i-1)

    act!(circles[i], Action(1:1, anim_translate(circles[i-1])))
    act!(circles[i], Action(1:nplay_frames, anim_rotate(0.0, prev_ridx*2π)))
    act!(circles[i], Action(1:1, anim_translate(c2p(fs[prev_ridx]))))
end

for i in 1:npoints-1
    push!(vectors, Object((args...)->my_arrow(pos(circles[i]), pos(circles[i+1]))))
end
ridx = remap_idx(npoints)
push!(vectors, Object(1:nplay_frames, (args...)->my_arrow(pos(circles[npoints]), pixel(fs, args[3]/nplay_frames))))

Object(1:nframes, (args...)->draw_path!(trace_points, pos(vectors[end]), "yellow"))

render(video, pathname="julia.mp4")
