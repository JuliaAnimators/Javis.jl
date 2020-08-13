using Javis
using Random

function ground(args...)
    background("white")
    sethue("black")
end

function draw_line(p1 = O, p2 = O, color = "black", action = :stroke, edge = "solid")
    sethue(color)
    setdash(edge)
    line(p1, p2, action)
end

function circ(p = O, color = "black", action = :fill, radius = 25, edge = "solid")
    sethue(color)
    setdash(edge)
    circle(p, radius, action)
end

function info_box(video, action, frame)
    fontsize(12)
    box(140, -210, 170, 40, :stroke)
    text("10-20 EEG Array Readings", 140, -220, valign = :middle, halign = :center)
    text("t = $(frame)s", 140, -200, valign = :middle, halign = :center)
end

function electrode(
    p = O,
    fill_color = "white",
    outline_color = "black",
    action = :fill,
    radius = 25,
    circ_text = "",
)
    sethue(fill_color)
    circle(p, radius, :fill)
    sethue(outline_color)
    circle(p, radius, :stroke)
    text(circ_text, p, valign = :middle, halign = :center)
end

electrode_locations = [
    O,
    Point(-70, 0),
    Point(70, 0),
    Point(-140, 0),
    Point(140, 0),
    Point(0, 70),
    Point(-50, 70),
    Point(50, 70),
    Point(0, -70),
    Point(-50, -70),
    Point(50, -70),
    Point(115, -80),
    Point(-115, -80),
    Point(115, 80),
    Point(-115, 80),
    Point(40, -135),
    Point(-40, -135),
    Point(-190, -10),
    Point(190, -10),
    Point(-40, 135),
    Point(40, 135),
]

electrode_names = [
    "Cz",
    "C3",
    "C4",
    "T3",
    "T4",
    "Pz",
    "P3",
    "P4",
    "Fz",
    "F3",
    "F4",
    "F8",
    "F7",
    "T6",
    "T5",
    "Fp2",
    "Fp1",
    "A1",
    "A2",
    "O1",
    "O2",
]

radius = 15
indicators = ["tomato", "darkolivegreen1", "gold1", "white"]
demo = Video(500, 500)
javis(
    demo,
    [
        BackgroundAction(1:10, ground),
        Action(
            :inside_circle,
            (args...) -> circ(O, "black", :stroke, 140, "longdashed"),
        ),
        Action(:head, (args...) -> circ(O, "black", :stroke, 170)),
        Action(
            :vert_line,
            (args...) ->
                draw_line(Point(0, -170), Point(0, 170), "black", :stroke, "longdashed"),
        ),
        Action(
            :horiz_line,
            (args...) ->
                draw_line(Point(-170, 0), Point(170, 0), "black", :stroke, "longdashed"),
        ),
        Action(
            :electrodes,
            (args...) ->
                electrode.(
                    electrode_locations,
                    rand(indicators, length(electrode_locations)),
                    "black",
                    :fill,
                    radius,
                    electrode_names,
                ),
        ),
        Action(:info, info_box),
    ],
    pathname = "eeg.gif",
    framerate = 1,
)

