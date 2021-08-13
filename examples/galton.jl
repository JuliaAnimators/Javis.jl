#=
Visualisation of a Galton Board, also known as a Bean Machine (https://en.wikipedia.org/wiki/Bean_machine).
=#

using Javis, Colors, Random

function ground(args...)
    background("black")
    sethue("white")
end

# Draws the line separators or "buckets"
function draw_separators(n, xpos, ypos, offset, height; color = "white")
    for i in 1:n
        x = xpos + offset * (i - 1)
        Object(JLine(Point(x, ypos), Point(x, ypos + height); color = color))
    end
end

# Draw the pins for each level
function draw_pins(n, xpos, ypos, offset; color = "white")
    for i in 1:n
        Object(
            JCircle(Point(xpos + offset * (i - 1), ypos), 3; color = color, action = :fill),
        )
    end
end

# Simulates flipping a coin, used in move_ball
function flip_coin()
    return rand() < 0.5 ? 1 : -1
end

# Moves the ball from the top level all the to the bottom level
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

function galton(seed)
    nframes = 1200
    video = Video(250, 600)
    Background(1:nframes, ground)

    logocolors = Colors.JULIA_LOGO_COLORS
    Random.seed!(seed)

    n = 15
    xpos = -100
    ypos = -75
    width = 200
    gap = 15
    height = 350
    offset = width / (n - 1)
    radius = offset / 4

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
    slots = zeros(Int, n + 1) # Frequency table
    for i in 1:nballs
        fno = 5 * i # Set start frame of each ball, interval of 5 frames between each ball
        ball = Object(JCircle(Point(0, ypos), radius; color = colors[i], action = :fill))
        fno_end, pos = move_ball(ball, 1, n, offset, fno)

        # After moving the ball to the bottom level, move each ball into it's "bucket"
        index = (pos + n) ÷ 2 + 1
        act!(
            ball,
            Action(
                (fno_end + 1):(fno_end + 10),
                anim_translate(0, height - 2 * radius * slots[index]),
            ),
        )
        slots[index] += 1 # Update frequency table
    end

    render(video; pathname = "galton.gif", framerate = 30)
    return slots
end

galton(94)
