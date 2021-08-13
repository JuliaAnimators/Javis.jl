#=
Visualisation of a Galton Board, also known as a Bean Machine or quincunx (https://en.wikipedia.org/wiki/Bean_machine).

Invented by Francis Galton. the Galton Board is used to demonstrate how the central limit theorem works.
Specifically, it is used to show that for_ a sufficiently large sample size, the binomial distribution
will approximate the normal distribution.
=#

using Javis
using Colors
using Random

"""
    ground(args...)

Define the background and the initial "foreground" color.
"""
function ground(args...)
    background("black")
    sethue("white")
end

"""
    draw_separators(n, xpos, ypos, offset, height; color = "white")

Draws `n` vertical lines of length `height`, each spaced `offset` pixels apart. `xpos` represents the
x-coordinate of the leftmost line, and `ypos` represents the y-coordinate of the upper point used to
construct each line.
"""
function draw_separators(n, xpos, ypos, offset, height; color = "white")
    for i in 1:n
        x = xpos + offset * (i - 1)
        Object(JLine(Point(x, ypos), Point(x, ypos + height); color = color))
    end
end

"""
    draw_pins(n, xpos, ypos, offset; color = "white")

Draws `n` circles of radius 3, each spaced `offset` pixels apart. `xpos` represents the x-coordinate of
the leftmost circle, and `ypos` represents the y-coordinate of the centre of each circle.
"""
function draw_pins(n, xpos, ypos, offset; color = "white")
    for i in 1:n
        Object(
            JCircle(Point(xpos + offset * (i - 1), ypos), 3; color = color, action = :fill),
        )
    end
end

"""
    flip_coin()

Simulates flipping a coin, returning -1 and 1 with equal probability. Helper function used in `move_ball`.
"""
function flip_coin()
    return rand() < 0.5 ? 1 : -1
end

# Moves the ball from the top level all the to the bottom level
"""
    move_ball(ball, first, last, offset, fno)

Moves `ball` from the `first` level of pins to the `last` level of pins. `offset` should be the same offset
used when creating the bins using `draw_separators`. The value `fno` is the frame number from which the ball
should start moving.

Returns (fno, pos), where `fno` represents the last frame of the ball when it has reached it's destination,
and pos represents the "sum" of the direction movements. For example, a ball that moved 5 times left, and
7 times right would have a "sum" of -5 + 7 = 2.
"""
function move_ball(ball, first, last, offset, fno)
    pos = 0
    act!(ball, Action((fno + 1):(fno + 5), anim_translate(0, offset / 2)))
    fno += 5
    for i in first:last
        direction = flip_coin()
        pos += direction
        act!(ball, Action((fno + 1):(fno + 5), anim_translate(direction * offset / 2, 0)))
        fno += 5
        act!(ball, Action((fno + 1):(fno + 5), anim_translate(0, offset)))
        fno += 5
    end
    return (fno, pos)
end

"""
    galton(seed)

Create the Galton Board animation and saves it in the file `galton.gif`. `seed` is used to determine the seed
value for the pseudorandom number generation, and is used for reproducability.
"""
function galton(seed)
    nframes = 1200
    video = Video(250, 600)
    Background(1:nframes, ground)

    logocolors = Colors.JULIA_LOGO_COLORS # Use the Julia logo colors
    Random.seed!(seed)

    # Parameters
    n = 15
    xpos = -100
    ypos = -75
    width = 200
    gap = 15
    height = 350
    offset = width / (n - 1)
    radius = offset / 4

    # Draws the line separators or "bins"
    draw_separators(n, xpos, ypos + gap, offset, height)

    # Create "base" of the board
    Object(
        JRect(
            Point(xpos - offset, ypos + gap + height),
            width + 2 * offset,
            7;
            color = logocolors.purple,
            action = :fill,
        )
    )

    # Draws the pins starting from the bottom most level (closest to base)
    for level in n:-1:1
        draw_pins(level, xpos, ypos, offset; color = logocolors.blue)
        xpos += offset / 2
        ypos -= offset
    end

    nballs = 200
    colors = range(logocolors.green, logocolors.red, length = nballs)
    # Frequency table (i.e. bins), used to determine how much to translate each ball.
    # Total of n + 1 bins.
    slots = zeros(Int, n + 1)
    for i in 1:nballs
        # Set start frame of each ball, interval of 5 frames between each ball
        fno = 5 * i
        # Start each ball at the topmost level
        ball = Object(JCircle(Point(0, ypos), radius; color = colors[i], action = :fill))
        # Move the ball to the top of a bin
        fno_end, pos = move_ball(ball, 1, n, offset, fno)

        # Map from "sum" of directions to bin number
        index = (pos + n) ÷ 2 + 1
        # Move each ball into it's "bin"
        act!(
            ball,
            Action(
                (fno_end + 1):(fno_end + 10),
                anim_translate(0, height - 2 * radius * slots[index]),
            ),
        )
        # Update frequency table
        slots[index] += 1
    end

    render(video; pathname = "galton.gif", framerate = 30)
    return slots
end

galton(94)
