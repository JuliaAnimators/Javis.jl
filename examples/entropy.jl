#=

    Simulating the path of 9 non-interacting balls in a closed system while reporting the relative entropy..

    This code is based on code from the question https://discourse.julialang.org/t/javis-collision-detection/87398/10
    But was rewritten by Michael Green and any mistakes are most likely his fault :).
=#

using Javis

video = Video(500, 500)
nframes = 250
Background(1:nframes, (v, o, f) -> background("black"))

const kb = 1.380649e-23
const ballsize = 25
const colors =
    ("red", "green", "blue", "pink", "orange", "yellow", "brown", "purple", "teal")

entropy(n, k) = log(binomial(n, k))

function numright()
    sum([pos(obj).x > 0 for obj in objs])
end

# Infobox
function info_box(video, object, frame)
    sethue("white")
    fontsize(12)
    box(140, -210, 170, 40, :stroke)
    text("Statistics:", 140, -220, valign = :middle, halign = :center)
    nr = numright()
    text("t = $(frame)s Right: $(nr)", 140, -200, valign = :middle, halign = :center)
    text(
        "Entropy: $(round(entropy(length(colors), nr); digits=2))",
        140,
        -180,
        valign = :middle,
        halign = :center,
    )
end

# Vertical line
function vline(video, object, frame)
    sethue("white")
    line(Point(0, -250), Point(0, 250), :stroke)
end

# Create all the balls
randvelocity() = (floor(Int64, randn() * 10), floor(Int64, randn() * 5))

function createobj(color = "red")
    obj = Object(1:nframes, (v, o, f) -> begin
        sethue(color)
        circle(O, ballsize, :fill)
        return O
    end)
    obj.opts[:velocity] = randvelocity()
    obj
end
objs = [createobj(colors[i]) for i in 1:length(colors)]

#not really an obj , as in draws nothing , but runs a function
# Logic for updating the velocity based on wall collissions
updaterobj = Object(1:nframes, (v, o, f) -> begin
    #hardcoded boundaries of the video
    function updateone(obj)
        radius = floor(ballsize / 2)
        if !(-250 + radius < pos(obj).x < 250 - radius)
            v = obj.opts[:velocity]
            obj.opts[:velocity] = (-v[1], v[2])
        end
        if !(-250 + radius < pos(obj).y < 250 - radius)
            v = obj.opts[:velocity]
            obj.opts[:velocity] = (v[1], -v[2])
        end
    end
    updateone.(objs)
end)

# Update each balls position based on their velocity
move() =
    (v, o, a, f) -> begin
        if f == first(Javis.get_frames(a))
            translate(o.start_pos + o.opts[:velocity])
        else
            translate(get_position(o) - o.start_pos + o.opts[:velocity])
        end
    end

for i in 1:length(objs)
    act!(objs[i], Action(1:nframes, move()))
end

info = Object(info_box)
vertline = Object(vline)

render(video; pathname = "entropy.gif")
