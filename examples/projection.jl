using Javis#, Animations

nframes = 200

function ground(args...) 
    background("white") # canvas background
    sethue("black") # pen color
end

myvideo = Video(300, 300)
Background(1:200, ground)

function draw_line(p1 = O, p2 = O, color = "black", action = :stroke, edge = "solid")
    sethue(color)
    setdash(edge)
    line(p1, p2, action)
end


# Draw the coordinate lines with solid in the positive side and dashed in the negative one
vert_line = Object(
    (args...) ->
        draw_line(Point(0, 170), Point(0, 0), "black", :stroke, "longdashed"),
)
horiz_line = Object(
    (args...) ->
        draw_line(Point(-170, 0), Point(0, 0), "black", :stroke, "longdashed"),
)

vert_line_solid = Object(
    (args...) ->
        draw_line(Point(0, 0), Point(0, -170), "black", :stroke, "solid"),
)
horiz_line_solid = Object(
    (args...) ->
        draw_line(Point(0, 0), Point(170, 0), "black", :stroke, "solid"),
)

"""
Take the position of an object as Point, and draw
a squircle that is its projection in the positive orthant
"""
function draw_proj(pos, color="blue")
    pos_proj = Point(
        max(pos.x, 0),
        min(pos.y, 0),
    )
    sethue(color)
    squircle(pos_proj, 10, 10, :fill)
    return pos_proj
end

function object(p=O, color="black", radius=12)
    sethue(color)
    circle(p, radius, :fill)
    return p
end

red_ball = Object(1:nframes, (args...)->object(O, "red"), Point(100,0))
act!(red_ball, Action(anim_rotate_around(2π, O)))

Object(1:nframes, (args...)->draw_proj(pos(red_ball)))

render(myvideo; pathname=joinpath(@__DIR__, "gifs/circle_projection.gif"), framerate=60)
