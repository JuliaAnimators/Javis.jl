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
  
    
    for y_point in (video.height / -2):25:(video.height / 2)
    	step = (frame - first(action.frames)) / (length(action.frames) - 1)
	start_point = Point(-250, y_point)
	end_point = Point(-250, y_point) + step * (Point(250, y_point) - Point(-250, y_point))
	line(start_point, end_point, :stroke)
    end
end

function ground(args...)
    background("white")
    sethue("black")
end

