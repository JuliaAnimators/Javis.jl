using Javis
using Luxor

function grid(bg_color="white", hue="black")

	vid = Video(500, 500)
	pt = Point(0, 250)
	end_pt = Point(500, 250)
	
	javis(vid, [Action(1:50, ground), 
		     Action(1:50, :my_line, (args...)->line(pt, end_pt), grow_line(pt)), 
		     ], tempdirectory="/home/src/Projects/javis/test", creategif=true, pathname="circles.gif")
end

function grow_line(point)
	point = Point(point.x + 10, point.y)
	return point
end

function ground(args...) 
	background("white")
	sethue("black")
end
