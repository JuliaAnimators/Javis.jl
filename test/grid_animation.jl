using Javis
using Luxor

function grid_animation()

	video = Video(500, 500)
	javis(video, 
	      [
	      	Action(1:100, ground),
		Action(1:100, :line, line_move)
	      ],
	      tempdirectory="/home/src/Projects/javis/test/grid_test",
	      creategif=true,
	      pathname="/home/src/Projects/javis/test/grid_test.gif"
	)

end

function line_move(video, action, frame)
    t = (frame - first(action.frames)) / (length(action.frames) - 1)
    line(Point(-200, 0), Point(-200, 0) + t * (Point(200, 0) - Point(-200, 0)), :stroke)
end

function ground(args...)
    background("white")
    sethue("black")
end

