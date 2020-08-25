"""

`draw_grid(video::Video, action::Action, frame::Int; direction::AbstractString = "TR", line_gap = 25)`

Draws an oriented grid on the given frame of a Video.

# Arguments
- `direction::AbstractString`: Where grid animation finishes. Default: `"TR"` Available Orientations:
  - `"TR"` - Animation finishes in the **T**op **R**ight corner of the frame.
  - `"TL"` - Animation finishes in the **T**op **L**eft corner of the frame.
  - `"BR"` - Animation finishes in the **B**ottom **R**ight corner of the frame.
  - `"BL"` - Animation finishes in the **B**ottom **L**eft corner of the frame.
- `line_gap`: How many pixels between each line. Default: `25`

# Example
Example call of this function within an `Action`.
```
...
 Action(1:100, :line, draw_grid(direction = "TL", line_gap = 25))
...
```

"""
function draw_grid(; direction::AbstractString = "TR", line_gap = 25)
    return (video, action, frame) ->
        _draw_grid(video, action, frame; direction = direction, line_gap = line_gap)
end

function _draw_grid(
    video::Video,
    action::Action,
    frame::Int;
    direction::AbstractString = "TR",
    line_gap = 25,
)

    min_width = div(video.width, -2, RoundDown)
    max_width = div(video.width, 2, RoundUp)

    min_height = div(video.height, -2, RoundDown)
    max_height = div(video.height, 2, RoundUp)

    # This determines how quickly the animation is drawn
    step = (frame - first(get_frames(action))) / (length(get_frames(action)) - 1)

    if direction[1] == 'T'
        # Bottom to top for vertical grid lines
        for x_point = min_width:line_gap:max_width
            start_point = Point(x_point, max_height)
            finish_point = Point(x_point, min_height)
            end_point = start_point + step * (finish_point - start_point)
            line(start_point, end_point, :stroke)
        end
    else
        # Top to bottom motion for vertical grid lines
        for x_point = min_width:line_gap:max_width
            start_point = Point(x_point, min_height)
            finish_point = Point(x_point, max_height)
            end_point = start_point + step * (finish_point - start_point)
            line(start_point, end_point, :stroke)
        end
    end

    if direction[2] == 'R'
        # Left to right motion for horizontal grid lines
        for y_point = min_height:line_gap:max_height
            start_point = Point(min_width, y_point)
            finish_point = Point(max_width, y_point)
            end_point = start_point + step * (finish_point - start_point)
            line(start_point, end_point, :stroke)
        end
    else
        # Right to left motion for horizontal grid lines
        for y_point = min_height:line_gap:max_height
            start_point = Point(max_width, y_point)
            finish_point = Point(min_width, y_point)
            end_point = start_point + step * (finish_point - start_point)
            line(start_point, end_point, :stroke)
        end
    end

end

"""

`zero_lines(video::Video, action::Action, frame::Int; direction::AbstractString = "TR",
            line_thickness = 10)`

Draws zero lines on the given frame of a Video.

# Arguments
- `direction::AbstractString`: Direction for how vertical and horizontal axes are drawn.
Default: `"TR"` Available Orientations:
  - `"TR"` - Vertical axis drawn towards the **T**op and horizontal axis drawn
    to the **R**ight of the frame.
  - `"TL"` - Vertical axis drawn towards the **T**op and horizontal axis drawn
    to the **L**eft of the frame.
  - `"BR"` - Vertical axis drawn towards the **B**ottom and horizontal axis drawn
    to the **R**ight of the frame.
  - `"BL"` - Vertical axis drawn towards the **B**ottom and horizontal axis drawn
    to the **L**eft of the frame.
- `line_thickness`: Defines the thickness of the zero lines. Default: `10`

# Example
This example will produce an animation with the vertical axis being drawn towards the top
and the horizontal axis being drawn towards the left.
One will need to define their own path for `tempdirectory` and `pathname`.

```
...
 Action(1:100, :line, zero_lines(direction = "TL", line_thickness = 10)),
...
```

"""
function zero_lines(; direction::AbstractString = "TR", line_thickness = 10)
    return (video, action, frame) -> _zero_lines(
        video,
        action,
        frame;
        direction = direction,
        line_thickness = line_thickness,
    )
end

function _zero_lines(
    video::Video,
    action::Action,
    frame::Int;
    direction::AbstractString,
    line_thickness,
)

    min_width = div(video.width, -2, RoundDown)
    max_width = div(video.width, 2, RoundUp)

    min_height = div(video.height, -2, RoundDown)
    max_height = div(video.height, 2, RoundUp)

    setline(line_thickness)

    # This determines how quickly the animation is drawn
    step = (frame - first(get_frames(action))) / (length(get_frames(action)) - 1)

    if direction[1] == 'B'
        # Top to bottom motion for vertical line
        start_point_y = Point(0, min_height)
        end_point_y = start_point_y + step * (Point(0, max_height) - start_point_y)
    else
        # Bottom to top motion for vertical line
        start_point_y = Point(0, max_height)
        end_point_y = start_point_y + step * (Point(0, min_height) - start_point_y)
    end

    if direction[2] == 'R'
        # Left to right motion for horizontal line
        start_point_x = Point(min_width, 0)
        end_point_x = start_point_x + step * (Point(max_width, 0) - start_point_x)
    else
        # Right to left motion for horizontal line
        start_point_x = Point(max_width, 0)
        end_point_x = start_point_x + step * (Point(min_width, 0) - start_point_x)
    end

    line(start_point_x, end_point_x, :stroke)
    line(start_point_y, end_point_y, :stroke)

end

export draw_grid, zero_lines
