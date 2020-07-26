using Javis
using Luxor

function grid(bg_color="white", hue="black")

	Drawing(500, 500)
	background(bg_color)
	sethue(hue)

	A = Point(-250, 250)
	B = Point(250, 250)
	line(A, B, :stroke)
	finish()
end

# function circ(p=O, color="black")
    # sethue(color)
    # circle(p, 25, :fill)
    # return Transformation(p, 0.0)
# end

# function anim()
    # from = Point(-200, -200)
    # to = Point(-20, -130)
    # p1 = Point(0,-100)
    # p2 = Point(0,-50)
    # from_rot = 0.0
    # to_rot = 2π

    # demo = Video(500, 500)
    # javis(demo, [
        # Action(1:100, ground),
        # Action(1:100, :red_ball, (args...)->circ(p1, "red"), Rotation(from_rot, to_rot)),
        # Action(1:100, (args...)->circ(p2, "blue"), Rotation(to_rot, from_rot, :red_ball))
    # ], tempdirectory="/home/src/Projects/javis/test", creategif=true, pathname="circles.gif")
# end
