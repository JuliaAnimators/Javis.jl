using Javis
using Luxor
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
    return Transformation(p, 0.0)
end

function info_box(video, action, frame)
    fontsize(12)
    box(140, -210, 170, 40, :stroke)
    text("10-20 EEG Array Readings", 140, -220, valign = :middle, halign = :center)
    text("t = $(frame)s", 140, -200, valign = :middle, halign = :center)
end

function outline_circ(
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

radius = 15
indicators = ["tomato", "darkolivegreen1", "gold1", "white"]
demo = Video(500, 500)
javis(
    demo,
    [
        Action(1:10, ground),
        Action(
            :same,
            :inside_circle,
            (args...) -> circ(O, "black", :stroke, 140, "longdashed"),
        ),
        Action(:same, :head, (args...) -> circ(O, "black", :stroke, 170)),
        Action(
            :same,
            :vert_line,
            (args...) ->
                draw_line(Point(0, -170), Point(0, 170), "black", :stroke, "longdashed"),
        ),
        Action(
            :same,
            :horiz_line,
            (args...) ->
                draw_line(Point(-170, 0), Point(170, 0), "black", :stroke, "longdashed"),
        ),
        Action(
            :same,
            :cz,
            (args...) -> outline_circ(O, rand(indicators), "black", :fill, radius, "Cz"),
        ),
        Action(
            :same,
            :c3,
            (args...) ->
                outline_circ(Point(-70, 0), rand(indicators), "black", :fill, radius, "C3"),
        ),
        Action(
            :same,
            :c4,
            (args...) ->
                outline_circ(Point(70, 0), rand(indicators), "black", :fill, radius, "C4"),
        ),
        Action(
            :same,
            :t3,
            (args...) -> outline_circ(
                Point(-140, 0),
                rand(indicators),
                "black",
                :fill,
                radius,
                "T3",
            ),
        ),
        Action(
            :same,
            :t4,
            (args...) ->
                outline_circ(Point(140, 0), rand(indicators), "black", :fill, radius, "T4"),
        ),
        Action(
            :same,
            :pz,
            (args...) ->
                outline_circ(Point(0, 70), rand(indicators), "black", :fill, radius, "Pz"),
        ),
        Action(
            :same,
            :p3,
            (args...) -> outline_circ(
                Point(-50, 70),
                rand(indicators),
                "black",
                :fill,
                radius,
                "P3",
            ),
        ),
        Action(
            :same,
            :p4,
            (args...) ->
                outline_circ(Point(50, 70), rand(indicators), "black", :fill, radius, "P4"),
        ),
        Action(
            :same,
            :fz,
            (args...) ->
                outline_circ(Point(0, -70), rand(indicators), "black", :fill, radius, "Fz"),
        ),
        Action(
            :same,
            :f3,
            (args...) -> outline_circ(
                Point(-50, -70),
                rand(indicators),
                "black",
                :fill,
                radius,
                "F3",
            ),
        ),
        Action(
            :same,
            :f4,
            (args...) -> outline_circ(
                Point(50, -70),
                rand(indicators),
                "black",
                :fill,
                radius,
                "F4",
            ),
        ),
        Action(
            :same,
            :f8,
            (args...) -> outline_circ(
                Point(115, -80),
                rand(indicators),
                "black",
                :fill,
                radius,
                "F8",
            ),
        ),
        Action(
            :same,
            :f7,
            (args...) -> outline_circ(
                Point(-115, -80),
                rand(indicators),
                "black",
                :fill,
                radius,
                "F7",
            ),
        ),
        Action(
            :same,
            :t6,
            (args...) -> outline_circ(
                Point(115, 80),
                rand(indicators),
                "black",
                :fill,
                radius,
                "T6",
            ),
        ),
        Action(
            :same,
            :t5,
            (args...) -> outline_circ(
                Point(-115, 80),
                rand(indicators),
                "black",
                :fill,
                radius,
                "T5",
            ),
        ),
        Action(
            :same,
            :fp2,
            (args...) -> outline_circ(
                Point(40, -135),
                rand(indicators),
                "black",
                :fill,
                radius,
                "Fp2",
            ),
        ),
        Action(
            :same,
            :fp1,
            (args...) -> outline_circ(
                Point(-40, -135),
                rand(indicators),
                "black",
                :fill,
                radius,
                "Fp1",
            ),
        ),
        Action(
            :same,
            :a1,
            (args...) -> outline_circ(
                Point(-190, -10),
                rand(indicators),
                "black",
                :fill,
                radius,
                "A1",
            ),
        ),
        Action(
            :same,
            :a2,
            (args...) -> outline_circ(
                Point(190, -10),
                rand(indicators),
                "black",
                :fill,
                radius,
                "A2",
            ),
        ),
        Action(
            :same,
            :o1,
            (args...) -> outline_circ(
                Point(-40, 135),
                rand(indicators),
                "black",
                :fill,
                radius,
                "O1",
            ),
        ),
        Action(
            :same,
            :o2,
            (args...) -> outline_circ(
                Point(40, 135),
                rand(indicators),
                "black",
                :fill,
                radius,
                "O2",
            ),
        ),
        Action(:same, :info, info_box),
    ],
    pathname = "eeg.gif",
    framerate = 1,
)

