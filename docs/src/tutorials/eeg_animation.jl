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

radius = 15
demo = Video(500, 500)
javis(
    demo,
    [
        Action(1:100, ground),
        Action(
            :same,
            :inside_circle,
            (args...) -> circ(O, "black", :stroke, 140, "longdashed"),
        ),
        Action(:same, :head, (args...) -> circ(O, "black", :stroke, 170)),

        Action(:same, :vert_line, (args...) -> draw_line(Point(0, -170), Point(0, 170),"black", :stroke, "longdashed")),
        Action(:same, :horiz_line, (args...) -> draw_line(Point(-170, 0), Point(170, 0),"black", :stroke, "longdashed")),

        Action(:same, :cz, (args...) -> circ(O, "white", :fill, radius)),
        Action(:same, :c3, (args...) -> circ(Point(-70, 0), "white", :fill, radius)),
        Action(:same, :c4, (args...) -> circ(Point(70, 0), "white", :fill, radius)),

        Action(:same, :cz, (args...) -> circ(O, "black", :stroke, radius)),
        Action(:same, :c3, (args...) -> circ(Point(-70, 0), "black", :stroke, radius)),
        Action(:same, :c4, (args...) -> circ(Point(70, 0), "black", :stroke, radius)),

        Action(:same, :t3, (args...) -> circ(Point(-140, 0), "white", :fill, radius)),
        Action(:same, :t4, (args...) -> circ(Point(140, 0), "white", :fill, radius)),

        Action(:same, :t3, (args...) -> circ(Point(-140, 0), "black", :stroke, radius)),
        Action(:same, :t4, (args...) -> circ(Point(140, 0), "black", :stroke, radius)),

        Action(:same, :pz, (args...) -> circ(Point(0, 70), "white", :fill, radius)),
        Action(:same, :pz, (args...) -> circ(Point(0, 70), "black", :stroke, radius)),
        Action(:same, :p3, (args...) -> circ(Point(-50, 70), "black", :stroke, radius)),
        Action(:same, :p4, (args...) -> circ(Point(50, 70), "black", :stroke, radius)),

        Action(:same, :fz, (args...) -> circ(Point(0, -70), "white", :fill, radius)),
        Action(:same, :fz, (args...) -> circ(Point(0, -70), "black", :stroke, radius)),
	Action(:same, :f3, (args...) -> circ(Point(-50, -70), "black", :stroke, radius)),
        Action(:same, :f4, (args...) -> circ(Point(50, -70), "black", :stroke, radius)),
        Action(:same, :f8, (args...) -> circ(Point(115, -80), "white", :fill, radius)),
        Action(:same, :f8, (args...) -> circ(Point(115, -80), "black", :stroke, radius)),
        Action(:same, :f7, (args...) -> circ(Point(-115, -80), "white", :fill, radius)),
        Action(:same, :f7, (args...) -> circ(Point(-115, -80), "black", :stroke, radius)),
        
	Action(:same, :t6, (args...) -> circ(Point(115, 80), "white", :fill, radius)),
        Action(:same, :t6, (args...) -> circ(Point(115, 80), "black", :stroke, radius)),

        Action(:same, :t5, (args...) -> circ(Point(-115, 80), "white", :fill, radius)),
        Action(:same, :t5, (args...) -> circ(Point(-115, 80), "black", :stroke, radius)),
        
	Action(:same, :fp2, (args...) -> circ(Point(40, -135), "white", :fill, radius)),
        Action(:same, :fp2, (args...) -> circ(Point(40, -135), "black", :stroke, radius)),

	Action(:same, :fp1, (args...) -> circ(Point(-40, -135), "white", :fill, radius)),
        Action(:same, :fp1, (args...) -> circ(Point(-40, -135), "black", :stroke, radius)),

	Action(:same, :a1, (args...) -> circ(Point(-190, -10), "white", :fill, radius)),
        Action(:same, :a1, (args...) -> circ(Point(-190, -10), "black", :stroke, radius)),

	Action(:same, :a2, (args...) -> circ(Point(190, -10), "white", :fill, radius)),
        Action(:same, :a2, (args...) -> circ(Point(190, -10), "black", :stroke, radius)),

	Action(:same, :o1, (args...) -> circ(Point(-40, 135), "white", :fill, radius)),
        Action(:same, :o1, (args...) -> circ(Point(-40, 135), "black", :stroke, radius)),

	Action(:same, :o2, (args...) -> circ(Point(40, 135), "white", :fill, radius)),
        Action(:same, :o2, (args...) -> circ(Point(40, 135), "black", :stroke, radius)),
    ],
    tempdirectory = "tmp-directory",
    creategif = true,
    pathname = "eeg.gif",
)

