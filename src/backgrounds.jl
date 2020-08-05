"""

`draw_grid(video::Video, action::Action, frame::Int; direction::String = "TR", line_gap::Int = 25)`

Draws an oriented grid on the given frame of a Video.

# Arguments
- `direction::String`: Where grid animation finishes. Default: `"TR"` Available Orientations:
  - `"TR"` - Animation finishes in the **T**op **R**ight corner of the frame.
  - `"TL"` - Animation finishes in the **T**op **L**eft corner of the frame.
  - `"BR"` - Animation finishes in the **B**ottom **R**ight corner of the frame.
  - `"BL"` - Animation finishes in the **B**ottom **L**eft corner of the frame.
- `line_gap::Int`: How many pixels between each line. Default: `25`

# Example
Example call of this function within an `Action`.
```
...
 Action(1:100, :line, draw_grid(direction = "TL", line_gap = 25))
...
```

"""
function draw_grid(
    video::Video,
    action::Action,
    frame::Int;
    direction::String = "TR",
    line_gap::Int = 25,
)

    min_width = div(video.width, -2, RoundDown)
    max_width = div(video.width, 2, RoundUp)

    min_height = div(video.height, -2, RoundDown)
    max_height = div(video.height, 2, RoundUp)

    step = (frame - first(action.frames)) / (length(action.frames) - 1)
    if occursin("B", direction)

        for x_point = min_height:line_gap:max_height
            start_point = Point(x_point, min_height)
            end_point = start_point + step * (Point(x_point, max_height) - start_point)
            line(start_point, end_point, :stroke)
        end

        if occursin("R", direction)

            for y_point = min_width:line_gap:max_width
                start_point = Point(min_width, y_point)
                end_point = start_point + step * (Point(max_width, y_point) - start_point)
                line(start_point, end_point, :stroke)
            end

        else

            for y_point = min_width:line_gap:max_width
                start_point = Point(max_width, y_point)
                end_point = start_point + step * (Point(min_width, y_point) - start_point)
                line(start_point, end_point, :stroke)
            end

        end

    else

        for x_point = min_height:line_gap:max_height
            start_point = Point(x_point, max_height)
            end_point = start_point + step * (Point(x_point, min_height) - start_point)
            line(start_point, end_point, :stroke)
        end

        if occursin("R", direction)

            for y_point = min_width:line_gap:max_width
                start_point = Point(min_width, y_point)
                end_point = start_point + step * (Point(max_width, y_point) - start_point)
                line(start_point, end_point, :stroke)
            end

        else

            for y_point = min_width:line_gap:max_width
                start_point = Point(max_width, y_point)
                end_point = start_point + step * (Point(min_width, y_point) - start_point)
                line(start_point, end_point, :stroke)
            end

        end

    end
end

"""

`zero_lines(video::Video, action::Action, frame::Int; direction::String = "TR", line_thickness::Int = 10)`

Draws zero lines on the given frame of a Video.

# Arguments
- `direction::String`: Direction for how vertical and horizontal axes are drawn. Default: `"TR"` Available Orientations:
  - `"TR"` - Vertical axis drawn towards the **T**op and horizontal axis drawn to the **R**ight of the frame.
  - `"TL"` - Vertical axis drawn towards the **T**op and horizontal axis drawn to the **L**eft of the frame.
  - `"BR"` - Vertical axis drawn towards the **B**ottom and horizontal axis drawn to the **R**ight of the frame.
  - `"BL"` - Vertical axis drawn towards the **B**ottom and horizontal axis drawn to the **L**eft of the frame.
- `line_thickness::Int`: Defines the thickness of the zero lines. Default: `10`

# Example
This example will produce an animation with the vertical axis being drawn towards the top and the horizontal axis being drawn towards the left. One will need to define their own path for `tempdirectory` and `pathname`.

```
using Javis
using Luxor

function ground(args...)
    background("white")
    sethue("black")
end

video = Video(500, 500)
javis(
      video,
      [
          Action(1:100, ground),
	  Action(1:100, :line, (video, action, frame)-> zero_lines(video, action, frame, direction = "TL", line_thickness = 10)),
      ],
      tempdirectory = "/tmp-directory",
      creategif = true,
      pathname = "/tmp-directory/grid_animation.gif"
     )

```

"""
function zero_lines(
    video::Video,
    action::Action,
    frame::Int;
    direction::String = "TR",
    line_thickness::Int = 10,
)

    min_width = div(video.width, -2, RoundDown)
    max_width = div(video.width, 2, RoundUp)

    min_height = div(video.height, -2, RoundDown)
    max_height = div(video.height, 2, RoundUp)

    setline(line_thickness)

    step = (frame - first(action.frames)) / (length(action.frames) - 1)

    if occursin("B", direction)

        start_point_y = Point(0, min_height)
        end_point_y = start_point_y + step * (Point(0, max_height) - start_point_y)

        if occursin("R", direction)

            start_point_x = Point(min_width, 0)
            end_point_x = start_point_x + step * (Point(max_width, 0) - start_point_x)

        else

            start_point_x = Point(max_width, 0)
            end_point_x = start_point_x + step * (Point(min_width, 0) - start_point_x)

        end

    else

        start_point_y = Point(0, max_height)
        end_point_y = start_point_y + step * (Point(0, min_height) - start_point_y)

        if occursin("R", direction)

            start_point_x = Point(min_width, 0)
            end_point_x = start_point_x + step * (Point(max_width, 0) - start_point_x)

        else

            start_point_x = Point(max_width, 0)
            end_point_x = start_point_x + step * (Point(min_width, 0) - start_point_x)

        end

    end

    line(start_point_x, end_point_x, :stroke)
    line(start_point_y, end_point_y, :stroke)

end

export draw_grid, zero_lines
