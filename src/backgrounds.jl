"""

`grid_lines(frame::UnitRange; direction::AbstractString = "TR", line_gap = 25)`

Draws an oriented grid on the given frame of a Video.

# Arguments
- `direction::AbstractString`: Where grid animation finishes. Default: `"TR"` Available Orientations:
- `line_gap`: How many pixels between each line. Default: `25`

# Example
Example call of this function within an `Object`.
```
...
Object(1:100, grid_lines(direction = "TL", line_gap = 25))
...
```

"""
function grid_lines(; line_gap = 25)
    return (video, object, frame) -> _grid_lines(video, object, frame; line_gap = line_gap)
end

function _grid_lines(video::Video, object::AbstractObject, frame::Int; line_gap = 25)

    min_width = div(video.width, -2, RoundDown)
    max_width = div(video.width, 2, RoundUp)

    min_height = div(video.height, -2, RoundDown)
    max_height = div(video.height, 2, RoundUp)

    # Creates the vertical lines of the grid
    # Drawn from bottom to top
    for x_point in min_width:line_gap:max_width
        start_point = Point(x_point, max_height)
        finish_point = Point(x_point, min_height)
        line(start_point, finish_point, :stroke)
    end

    # Creates the horizontal lines of the grid
    # Drawn from left to right
    for y_point in min_height:line_gap:max_height
        start_point = Point(min_width, y_point)
        finish_point = Point(max_width, y_point)
        line(start_point, finish_point, :stroke)
    end

end

"""

`zero_lines(frame::UnitRange; direction::AbstractString = "TR", line_thickness = 10)`

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
Object(1:100, zero_lines(direction = "TL", line_thickness = 10)),
...
```

"""
function zero_lines(; line_thickness = 10)
    return (video, object, frame) ->
        _zero_lines(video, object, frame; line_thickness = line_thickness)
end

function _zero_lines(video::Video, object::AbstractObject, frame::Int; line_thickness)

    min_width = div(video.width, -2, RoundDown)
    max_width = div(video.width, 2, RoundUp)

    min_height = div(video.height, -2, RoundDown)
    max_height = div(video.height, 2, RoundUp)

    setline(line_thickness)

    # Creates a vertical zero line
    # Top to bottom motion for vertical line
    start_point_y = Point(0, min_height)
    end_point_y = Point(0, max_height) - start_point_y

    # Creates a horizontal zero line
    # Left to right motion for horizontal line
    start_point_x = Point(min_width, 0)
    end_point_x = Point(max_width, 0) - start_point_x

    line(start_point_x, end_point_x, :stroke)
    line(start_point_y, end_point_y, :stroke)

end

export grid_lines, zero_lines
