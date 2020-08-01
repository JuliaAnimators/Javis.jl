"""

`draw_grid(video::Video, action::Action, frame::Int; grid_direction::Symbol = :TR)`

Draws an oriented grid on the given frame of a Video.

# Arguments
- `grid_direction::Symbol`: Where grid animation finishes. Default: `:TR` Available Orientations:
  - `:TR` - Animation finishes in the **T**op **R**ight corner of the frame.
  - `:TL` - Animation finishes in the **T**op **L**eft corner of the frame.
  - `:BR` - Animation finishes in the **B**ottom **R**ight corner of the frame.
  - `:BL` - Animation finishes in the **B**ottom **L**eft corner of the frame.

# Example
This example will produce a grid animation that finishes in the top left corner of the animation. One will need to define their own path for `tempdirectory` and `pathname`.

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
          Action(1:100, (args...) -> draw_grid(args..., grid_direction = :TL)),
      ],
      tempdirectory = "/tmp-directory",
      creategif = true,
      pathname = "/tmp-directory/grid_animation.gif"
     )

```

"""
function draw_grid(video::Video, action::Action, frame::Int; grid_direction::Symbol = :TR)

    min_width = div(video.width, -2, RoundDown)
    max_width = div(video.width, 2, RoundUp)

    min_height = div(video.height, -2, RoundDown)
    max_height = div(video.height, 2, RoundUp)

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

"""

`zero_lines(video::Video, action::Action, frame::Int; line_direction::Symbol = :TR)`

Draws zero lines on the given frame of a Video.

# Arguments
- `line_direction::Symbol`: Direction for how vertical and horizontal axes are drawn. Default: `:TR` Available Orientations:
  - `:TR` - Vertical axis drawn towards the **T**op and horizontal axis drawn to the **R**ight of the frame.
  - `:TL` - Vertical axis drawn towards the **T**op and horizontal axis drawn to the **L**eft of the frame.
  - `:BR` - Vertical axis drawn towards the **B**ottom and horizontal axis drawn to the **R**ight of the frame.
  - `:BL` - Vertical axis drawn towards the **B**ottom and horizontal axis drawn to the **L**eft of the frame.

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
	  Action(1:100, (args...) -> zero_lines(args..., line_direction = :TL)),
      ],
      tempdirectory = "/tmp-directory",
      creategif = true,
      pathname = "/tmp-directory/grid_animation.gif"
     )

```

"""
function zero_lines(video::Video, action::Action, frame::Int; line_direction::Symbol = :TR)

    min_width = div(video.width, -2, RoundDown)
    max_width = div(video.width, 2, RoundUp)

    min_height = div(video.height, -2, RoundDown)
    max_height = div(video.height, 2, RoundUp)

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
