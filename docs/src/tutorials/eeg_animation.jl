using Javis
using Luxor

function ground(args...)
    background("white")
    sethue("black")
end

function draw_line(p1 = O, p2 = O,  color = "black", action = :stroke, edge = "solid")
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

function outline_circ(p = O, fill_color = "white", outline_color = "black", action = :fill, radius = 25)
    sethue(fill_color)
    circle(p, radius, :fill)
    sethue(outline_color)
    circle(p, radius, :stroke)
    return Transformation(p, 0.0)
end

radius = 15
demo = Video(500, 500)
javis(
    demo,
    [
        Action(1:30, ground),
        Action(
            :same,
            :inside_circle,
            (args...) -> circ(O, "black", :stroke, 140, "longdashed"),
        ),
        Action(:same, :head, (args...) -> circ(O, "black", :stroke, 170)),

        Action(:same, :vert_line, (args...) -> draw_line(Point(0, -170), Point(0, 170),"black", :stroke, "longdashed")),
        Action(:same, :horiz_line, (args...) -> draw_line(Point(-170, 0), Point(170, 0),"black", :stroke, "longdashed")),

        Action(:same, :cz, (args...) -> outline_circ(O, "white", "black", :fill, radius)),
        Action(:same, :c3, (args...) -> outline_circ(Point(-70, 0), "white", "black", :fill, radius)),
        Action(:same, :c4, (args...) -> outline_circ(Point(70, 0), "white", "black", :fill, radius)),

        Action(:same, :t3, (args...) -> outline_circ(Point(-140, 0), "white", "black", :fill, radius)),
        Action(:same, :t4, (args...) -> outline_circ(Point(140, 0), "white", "black", :fill, radius)),


        Action(:same, :pz, (args...) -> outline_circ(Point(0, 70), "white", "black", :fill, radius)),
        Action(:same, :p3, (args...) -> outline_circ(Point(-50, 70),"white", "black", :stroke, radius)),
        Action(:same, :p4, (args...) -> outline_circ(Point(50, 70), "white", "black", :stroke, radius)),

        Action(:same, :fz, (args...) -> outline_circ(Point(0, -70), "white", "black", :fill, radius)),
	Action(:same, :f3, (args...) -> outline_circ(Point(-50, -70), "white",  "black", :stroke, radius)),
        Action(:same, :f4, (args...) -> outline_circ(Point(50, -70), "white", "black", :stroke, radius)),
        Action(:same, :f8, (args...) -> outline_circ(Point(115, -80), "white", "black", :fill, radius)),
        Action(:same, :f7, (args...) -> outline_circ(Point(-115, -80), "white", "black", :fill, radius)),
        
	Action(:same, :t6, (args...) -> outline_circ(Point(115, 80), "white", "black", :fill, radius)),

        Action(:same, :t5, (args...) -> outline_circ(Point(-115, 80), "white", "black", :fill, radius)),
        
	Action(:same, :fp2, (args...) -> outline_circ(Point(40, -135), "white", "black", :fill, radius)),

	Action(:same, :fp1, (args...) -> outline_circ(Point(-40, -135), "white", "black", :fill, radius)),

	Action(:same, :a1, (args...) -> outline_circ(Point(-190, -10), "white", "black", :fill, radius)),

	Action(:same, :a2, (args...) -> outline_circ(Point(190, -10), "white", "black", :fill, radius)),

	Action(:same, :o1, (args...) -> outline_circ(Point(-40, 135), "white", "black", :fill, radius)),

	Action(:same, :o2, (args...) -> outline_circ(Point(40, 135), "white", "black", :fill, radius)),
    ],
    tempdirectory = "tmp-directory",
    creategif = true,
    pathname = "eeg.gif",
)

