using Javis
using Luxor

function grid_animation()

	Drawing(500, 500)
	background("white")
	sethue("black")

	prior_num = -250
	end_pt = Point(500, 0)

	for num in 0:1:500
		@png line(Point(prior_num + num, 0), end_pt, :stroke) 500 500 "grid_$num.png"
	end

	finish()

end
