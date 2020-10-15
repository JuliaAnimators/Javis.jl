#=

    Drawing Julia using a Fourier series.
    A high definition animation can be seen here: https://youtu.be/uM2sbIsqGg4

    This code was kindly provided by ric-cioffi (https://github.com/ric-cioffi)
=#

using Javis
using DelimitedFiles
using OffsetArrays, FFTW, FFTViews # (not strictly necessary, but make DFT indexing more intuitive)

#=
    Here we import the (ordered) coordinates of the julia logo. They were obtained by extracting the contours of the
    julia logo using JuliaImages; then, they were "ordered" by finding a solution to the Traveling Salesman Problem (that
    is, by finding the shortest path that travels once through all the points).
    To draw the logo using Fourier series approximation we then need to take the Discrete Fourier Transform of the set of
    coordinates. Doing everything in polar form and using OffsetArrays makes the computations slightly more intuitive.
=#
ps = readdlm("julia_logo.csv", ',')
coordinates_dft = complex.(ps[:, 1], ps[:, 2]) |> fft |> FFTView

vid = Video(800, 500)

function ground(args...)
    background("black")
    sethue("black")
end

function object(
    p = O,
    color = "white";
    size = 25,
    edge = "solid",
    style = :stroke,
    opacity = 1 / 3,
)
    sethue(color)
    setdash(edge)
    setopacity(opacity)
    circle(p, size, style)
    return p
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

import Javis.Point
Point(c::Complex) = Point(real(c), imag(c))
distance(p1::Point, p2::Point) = sqrt((p2.x - p1.x)^2 + (p2.y - p1.y)^2)

# Draw a vector between points p1 and p2
function vector(p1, p2; color = "white", opacity = 1 / 2, linewidth = 1, tipsize = 0.1)
    sethue(color)
    setopacity(opacity)
    setline(linewidth)

    θ = (p2.y - p1.y) / (p2.x - p1.x) |> atan # angle b/w p1 and p2
    s = sign(p2.x - p1.x)

    α = tipsize                             # heigth of the tip triangle (in terms of the distance b/w p1 and p2)
    ϑ = α / (1 - α) / 2 |> atan                 # angle b/w p1 and "bottom-left" vertex of the tip triangle
    d = distance(p1, p2)
    x = d * (1 - α) / cos(ϑ)                    # distance b/w p1 and triangle vertices

    v1 = p1 + s * x * Point(exp((θ + ϑ) * im))    # first triangle vertex
    v2 = p1 + s * x * Point(exp((θ - ϑ) * im))    # second triangle vertex

    line(p1, p2, :stroke)                   # vector line
    poly([p2, v1, v2, p2], :fill)           # vector tip
end

function draw_logo(cs, n::Int; frames = 2160)
    # This function uses the first n terms (both positive and negative frequencies) of the Discrete Fourier Transform
    # to draw a line by "summing up" the terms

    base_size = 7.5e-5
    n_rotations = 2         # how many times the "tip" goes around the drawing

    remap_idx(i::Int) = (-1)^(i - 1) * floor(Int, (i + 1) / 2)
    remap_inv(n::Int) = 2n * sign(n) - 1 * (n > 0)

    n0, nT = -ceil(Int, (n - 1) / 2), ceil(Int, (n - 1) / 2)
    ids = OffsetArray(map(i -> Symbol("ball_" * "$(i)"), n0:nT), n0:nT)
    indices = [remap_idx(i) for i in 0:(n - 1)]

    fade_fourier() = [
        SubAction(1:floor(Int, frames / 8), appear(:fade)),
        SubAction(floor(Int, 0.5 * frames):floor(Int, 0.9 * frames), disappear(:fade)),
    ]
    fade_main() = [
        SubAction(1:floor(Int, frames / 20), appear(:fade)),
        SubAction(floor(Int, 0.9 * frames):frames, disappear(:fade)),
    ]

    yellow_path = Point[]
    javis(
        vid,
        [
            BackgroundAction(1:frames, ground),
            Action(
                1:frames,
                ids[0],
                (args...) ->
                    object(Point(base_size * cs[0]), size = abs(base_size * cs[1])),
                subactions = fade_fourier(),
            ),
            map(
                n -> Action(
                    1:frames,
                    (args...) -> vector(
                        pos(ids[indices[remap_inv(n)]]),
                        pos(ids[indices[remap_inv(n) + 1]]),
                        opacity = 0.9,
                        linewidth = 2,
                    ),
                    subactions = fade_fourier(),
                ),
                indices[2:(end - 1)],
            )...,
            map(
                n -> Action(
                    1:frames,
                    ids[n],
                    (args...) -> object(
                        Point(base_size * cs[n]),
                        size = abs(base_size * cs[indices[remap_inv(n) + 2]]),
                    ),
                    Rotation(0.0, n_rotations * 2π * n, ids[indices[remap_inv(n)]]),
                    subactions = fade_fourier(),
                ),
                indices[2:(end - 1)],
            )...,
            Action(
                1:frames,
                (args...) -> draw_path!(yellow_path, pos(ids[indices[end - 1]]), "yellow");
                subactions = fade_main(),
            ),
            Action(
                1:frames,
                :tip,
                (args...) -> object(
                    Point(base_size * cs[indices[end - 1]]),
                    "yellow",
                    size = 4,
                    style = :fill,
                    opacity = 1.0,
                ),
                Rotation(0.0, 0.0, ids[indices[end - 1]]),
                subactions = fade_main(),
            ),
        ],
        pathname = "julia_logo.gif",
    )
end

draw_logo(coordinates_dft, 1001)
