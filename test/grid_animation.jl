using Javis
using Luxor

function grid_animation()

	video = Video(500, 500)
	javis(video, 
	      [
	      	Action(1:100, ground),
		Action(1:100, :line, draw_grid)
	      ],
	      tempdirectory="/home/src/Projects/javis/test/grid_test",
	      creategif=true,
	      pathname="/home/src/Projects/javis/test/grid_test.gif"
	)

end

function draw_grid(video, action, frame)

min_width = video.width / -2
max_width = video.width / 2

min_height = video.height / -2
max_height = video.height / 2
   
for y_point in min_width:25:max_width
    	step = (frame - first(action.frames)) / (length(action.frames) - 1)
	start_point = Point(min_width, y_point)
	end_point = start_point + step * (Point(max_width, y_point) - start_point)
	line(start_point, end_point, :stroke)
end

for x_point in min_height:25:max_height
    	step = (frame - first(action.frames)) / (length(action.frames) - 1)
	start_point = Point(x_point, min_height)
	end_point = start_point + step * (Point(x_point, max_height) - start_point)
	line(start_point, end_point, :stroke)
end

end

function ground(args...)
    background("white")
    sethue("black")
end

