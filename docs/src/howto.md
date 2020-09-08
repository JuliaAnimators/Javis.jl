# How To?

This is a list of frequently ask questions answering basic "How to do X, Y, Z?" questions.

For all the questions below you need to start with:

```julia
using Javis

function ground(args...)
    background("black")
    sethue("white")
end

video = Video(500, 500)

javis(video, [
    BackgroundAction(1:100, ground),
    SNIPPETS_GO_HERE # Replace this line with the provided snippet!
]; pathname="how_to.gif")
```

Each of the code snippets should replace the variable `SNIPPETS_GO_HERE`.

## How can I move a circle from A to B?

First of all you need to define an [`Action`](@ref) which draws a circle.

```julia
Action(1:100, (args...)->circle(O, 50, :fill))
```

and then you need the [`Translation`](@ref) command to move the circle.

```julia
Action(1:100, (args...)->circle(O, 50, :fill), Translation(O, Point(100, 100))
```

The circle then moves from the origin (center of frame) 100 px down and to the right.

## How can I define frames?

There are currently three different ways to define frames inside Javis.
The simplest one is to define the `UnitRange` like `1:100` as above such that the action is called for every frame from `1` to `100`.

**Examples:**
```julia
Action(1:100, (args...)->circle(O, 50, :fill)),
Action(1:50, (args...)->circle(O, 70, :stroke))
```

It is relatively often the case that the following action should work with the same frames as the previous action this can be done with.

**Examples:**
```julia
Action(1:100, (args...)->circle(O, 50, :fill)),
Action(:same, (args...)->circle(Point(100, 100), 20, :stroke)),
Action((args...)->circle(Point(-100, 100), 20, :stroke))
```

so either use the symbol `:same` or just don't mention frames.

The last option is to define frames relative to the previous frame. More precisely the end of the last frame.

**Examples:**
```julia
Action(1:50, (args...)->circle(O, 50, :fill)),
Action(Rel(1:50), (args...)->circle(Point(100, 100), 20, :stroke)),
```

This is the same as:
```julia
Action(1:50, (args...)->circle(O, 50, :fill)),
Action(51:100, (args...)->circle(Point(100, 100), 20, :stroke)),
```

## How can I make an object fade in from the background?

Let's make the standard circle we used before appear from the background.

```julia
Action(1:100, (args...)->circle(O, 50, :fill); subactions=[
    SubAction(1:50, appear(:fade))
]),
```

this is using a change in opacity to show the circle.

There are two other options `:scale` and `:fade_line_width`. `:scale` also works for every kind of [`Action`](@ref) whereas `:fade_line_width` only works if you only draw the stroke instead of using fill.

**Example:**
```julia
Action(1:100, (args...)->circle(O, 50, :stroke); subactions=[
    SubAction(1:50, appear(:fade_line_width))
]),
```

Additionally you can use all of these three options for the [`disappear`](@ref) functionality.

> **NOTE:** A [`SubAction`](@ref) gets also called for frames after the last specified subaction frame such that disappeared objects stay disappeared.

## How can I move one object based on another object?

In this case we need to define our own `circ` function which draws the circle and returns the center point of the circle.

```julia
function circ(point, radius, action)
    circle(point, radius, action)
    return point
end
```

Now we define two actions:
1. Drawing a circle and saving the position inside `:my_circle`
2. Drawing a rectangle above the circle

```julia
Action(1:100, :my_circle, (args...)->circ(O, 50, :stroke), Translation(Point(100,100))),
Action(1:100, (args...)->rect(pos(:my_circle)+Point(-10, -100), 20, 20, :fill))
```

In this animation the position of the circle is saved inside `:my_circle` and can be used with `pos(:my_circle)` inside the `rect` function.

