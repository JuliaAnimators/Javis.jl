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

## How can I show a text being drawn?

A `text` can appear as every other object with `appear(:fade)` and `appear(:scale)` but it also has a special [`appear`](@ref) functionality called 
`:draw_text`.

You can use 
```julia
Action(
    1:100,
    (args...) -> text("Hello World!"; halign = :center);
    subactions = [
        SubAction(1:15, sineio(), appear(:draw_text)),
        SubAction(76:100, sineio(), disappear(:draw_text)),
    ]
)
```

to let the text `"Hello World!"` appear from left to right in an animated way. 

## How can I let an object move along a path?

In this case we need to create a list of points (a path) that the object can follow.
This can be simple object like a `star` or just a list of points. 

An action can look like this:

```julia
Action(
    1:150
    (args...) -> star(O, 20, 5, 0.5, 0, :fill);
    subactions = [
        SubAction(1:150, follow_path(star(O, 300))),
    ],
)
```

in this case a star is following the path of a bigger star. 
> **NOTE:** the star inside [`follow_path`](@ref) should have the `action=:none` which is the default for most Luxor functions.

Unfortunately the above currently only works for some Luxor functions like `ngon` and `star` but not for `circle` and `rect` as they return `true` instead of the points.

In that case you need to define a function like:
```julia
function ground(args...)
    background("white")
    sethue("black")
end

function luxor2poly(func::Function)
    newpath()
    func()
    closepath()
    return pathtopoly()[1]
end

video = Video(600, 400)
javis(video, [
    BackgroundAction(1:150, ground),
    Action(
        1:150,
        (args...) -> star(O, 20, 5, 0.5, 0, :fill);
        subactions = [
            SubAction(1:150, follow_path(luxor2poly(()->rect(O, 100, 100, :path))))
        ]
    )
]; pathname="follow_path.gif")
```

I admit that this is not the nicest syntax so we might choose to return the points by overriding some Luxor functions in the future.

Another possibility is to specify a vector of points like in this example:

```julia
Action(
    1:150
    (args...) -> star(O, 20, 5, 0.5, 0, :fill);
    subactions = [
        SubAction(1:150, sineio(), follow_path([Point(100, 200), Point(-20, -250), Point(-80, -10)]; closed=false)),
    ],
)
```

In this case I want the star to follow a path consisting of two edges and I use `; closed=false` to specify that it's just two edges and not a closed triangle.

An interesting possibility is to define paths using Bézier curves which can be defined with Luxor see: [Polygons to Bézier paths and back again](https://juliagraphics.github.io/Luxor.jl/stable/polygons/#Polygons-to-B%C3%A9zier-paths-and-back-again)

## How can I see a live view of the animation?

A live view of the animation can be useful for creating an animation where one doesn't need the overhead of building a gif or mp4 all the time. It also has the advantage that it's very easy to jump to a specific frame.

The live viewer can be called with adding `; liveview=true` to the [`javis`](@ref) call.

> **NOTE:** If `liveview=true` the `tempdirectory` and `pathname` arguments are ignored.