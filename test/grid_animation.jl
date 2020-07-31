using Javis
using Luxor

function grid_animation()

    video = Video(500, 500)
    javis(
        video,
        [
            Action(1:100, ground),
            # Action(1:100, :line, draw_grid(truth_value=true)),
            Action(1:100, :line, draw_grid),
            Action(1:100, :line, zero_lines),
        ],
        tempdirectory = "/home/src/Projects/javis/test/grid_test",
        creategif = true,
        pathname = "/home/src/Projects/javis/test/grid_test.gif",
    )

end

# function draw_grid(video::Video=nothing, action::Action=nothing, frame::Int=1, truth_value::Bool=false)
function draw_grid(video::Video, action::Action, frame::Int)

    grid_directions = [:TL, :BL, :TR, :BR]
    grid_direction = :TR

    min_width = video.width / -2
    max_width = video.width / 2

    min_height = video.height / -2
    max_height = video.height / 2

    if grid_direction == :BR

        for y_point = min_width:25:max_width
            step = (frame - first(action.frames)) / (length(action.frames) - 1)
            start_point = Point(min_width, y_point)
            end_point = start_point + step * (Point(max_width, y_point) - start_point)
            line(start_point, end_point, :stroke)
        end

        for x_point = min_height:25:max_height
            step = (frame - first(action.frames)) / (length(action.frames) - 1)
            start_point = Point(x_point, min_height)
            end_point = start_point + step * (Point(x_point, max_height) - start_point)
            line(start_point, end_point, :stroke)
        end

    elseif grid_direction == :BL

        for y_point = min_width:25:max_width
            step = (frame - first(action.frames)) / (length(action.frames) - 1)
            start_point = Point(max_width, y_point)
            end_point = start_point + step * (Point(min_width, y_point) - start_point)
            line(start_point, end_point, :stroke)
        end

        for x_point = min_height:25:max_height
            step = (frame - first(action.frames)) / (length(action.frames) - 1)
            start_point = Point(x_point, min_height)
            end_point = start_point + step * (Point(x_point, max_height) - start_point)
            line(start_point, end_point, :stroke)
        end

    elseif grid_direction == :TR

        for y_point = min_width:25:max_width
            step = (frame - first(action.frames)) / (length(action.frames) - 1)
            start_point = Point(min_width, y_point)
            end_point = start_point + step * (Point(max_width, y_point) - start_point)
            line(start_point, end_point, :stroke)
        end

        for x_point = min_height:25:max_height
            step = (frame - first(action.frames)) / (length(action.frames) - 1)
            start_point = Point(x_point, max_height)
            end_point = start_point + step * (Point(x_point, min_height) - start_point)
            line(start_point, end_point, :stroke)
        end

    elseif grid_direction == :TL

        for y_point = min_width:25:max_width
            step = (frame - first(action.frames)) / (length(action.frames) - 1)
            start_point = Point(max_width, y_point)
            end_point = start_point + step * (Point(min_width, y_point) - start_point)
            line(start_point, end_point, :stroke)
        end

        for x_point = min_height:25:max_height
            step = (frame - first(action.frames)) / (length(action.frames) - 1)
            start_point = Point(x_point, max_height)
            end_point = start_point + step * (Point(x_point, min_height) - start_point)
            line(start_point, end_point, :stroke)
        end


    end

end

function zero_lines(video::Video, action::Action, frame::Int)

    line_directions = [:TL, :BL, :TR, :BR]
    line_direction = :TR

    min_width = video.width / -2
    max_width = video.width / 2

    min_height = video.height / -2
    max_height = video.height / 2

    setline(10)

    step = (frame - first(action.frames)) / (length(action.frames) - 1)

    if line_direction == :BR

        start_point = Point(min_width, 0)
        end_point = start_point + step * (Point(max_width, 0) - start_point)
        line(start_point, end_point, :stroke)

        start_point = Point(0, min_height)
        end_point = start_point + step * (Point(0, max_height) - start_point)
        line(start_point, end_point, :stroke)

    elseif line_direction == :BL

        start_point = Point(max_width, 0)
        end_point = start_point + step * (Point(min_width, 0) - start_point)
        line(start_point, end_point, :stroke)

        start_point = Point(0, min_height)
        end_point = start_point + step * (Point(0, max_height) - start_point)
        line(start_point, end_point, :stroke)

    elseif line_direction == :TR

        start_point = Point(min_width, 0)
        end_point = start_point + step * (Point(max_width, 0) - start_point)
        line(start_point, end_point, :stroke)

        start_point = Point(0, max_height)
        end_point = start_point + step * (Point(0, min_height) - start_point)
        line(start_point, end_point, :stroke)

    elseif line_direction == :TL

        start_point = Point(max_width, 0)
        end_point = start_point + step * (Point(min_width, 0) - start_point)
        line(start_point, end_point, :stroke)

        start_point = Point(0, max_height)
        end_point = start_point + step * (Point(0, min_height) - start_point)
        line(start_point, end_point, :stroke)

    end

end

function ground(args...)
    background("white")
    sethue("black")
end

