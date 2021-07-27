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
Background(1:100, ground)
# The provided snippets!

render(video; pathname="how_to.gif")
```

## Why are all my `Javis` functions undefined? 

If you have worked with the Julia drawing package [`Luxor.jl`](https://github.com/JuliaGraphics/Luxor.jl), you will be happy to see that it provides all the drawing functions that `Javis` uses.
`Javis` is basically an abstraction layer built on on top of `Luxor.jl` which provides functions to animate the static images you can create with `Luxor` more easily.
As one can't use `Javis` without using Luxor we decided to reexport all functions that `Luxor` exports.

This means you **should not** call `using Luxor` in scripts that use `Javis`.
Otherwise it will result in ambiguity errors such as all the `Javis` functions becoming undefined when you try to run a Julia script with `Javis` in it or other strange conflicts.
Another reason we reexport all functions from `Luxor` is that we sometimes need to add additional `Javis` functionality around certain `Luxor` functions to create better animations.

## How can I move a circle from A to B?

First of all you need to define an [`Object`](@ref) which draws a circle.

```julia
circ = Object(1:100, (args...)->circle(O, 50, :fill))
```

and then you need the a translation with [`anim_translate`](@ref) to move the circle.

```julia
act!(circ, Action(anim_translate(O, Point(100, 100))))
```

The circle then moves from the origin (center of frame) 100 px down and to the right.

## How can I define frames?

There are currently three different ways to define frames inside Javis.
The simplest one is to define the `UnitRange` like `1:100` as above such that the action is called for every frame from `1` to `100`.

**Examples:**
```julia
Object(1:100, (args...)->circle(O, 50, :fill))
Object(1:50, (args...)->circle(O, 70, :stroke))
```

It is relatively often the case that the following action should work with the same frames as the previous action this can be done with.

**Examples:**
```julia
Object(1:100, (args...)->circle(O, 50, :fill))
Object(:same, (args...)->circle(O, 20, :stroke), Point(100, 100))
Object((args...)->circle(O, 20, :stroke), Point(-100, 100))
```

so either use the symbol `:same` or just don't mention frames.

The last option is to define frames relative to the previous frame. More precisely the end of the last frame.

**Examples:**
```julia
Object(1:50, (args...)->circle(O, 50, :fill))
Object(RFrames(1:50), (args...)->circle(O, 20, :stroke), Point(100, 100))
```

This is the same as:
```julia
Object(1:50, (args...)->circle(O, 50, :fill))
Object(51:100, (args...)->circle(O, 20, :stroke), Point(100, 100))
```

## How can I make an object fade in from the background?

Let's make the standard circle we used before appear from the background.

```julia
circ = Object(1:100, (args...)->circle(O, 50, :fill))
act!(circ, Action(1:50, appear(:fade)))
```

this is using a change in opacity to show the circle.

There are two other options `:scale` and `:fade_line_width`. `:scale` also works for every kind of [`Object`](@ref) whereas `:fade_line_width` only works if you only draw the stroke instead of using fill.

**Example:**
```julia
circ = Object(1:100, (args...)->circle(O, 50, :stroke))
act!(circ, Action(1:50, appear(:fade_line_width)))
```

Additionally you can use all of these three options for the [`disappear`](@ref) functionality.

> **NOTE:** An [`Action`](@ref) gets also called for frames after the last specified action frame such that disappeared objects stay disappeared.
> This can be turned off by using `; keep = false` as an argument to the [`Action`](@ref).

## How can I move one object based on another object?

In this case we need to define our own `circ` function which draws the circle and returns the center point of the circle.

```julia
function circ(point, radius, action)
    circle(point, radius, action)
    return point
end
```

Now we define two actions:
1. Drawing a circle and saving the position `my_circle`
2. Drawing a rectangle above the circle

```julia
my_circle = Object(1:100, (args...)->circ(O, 50, :stroke))
act!(my_circle, Action(anim_translate(100, 100)))
Object(1:100, (args...)->rect(pos(my_circle)+Point(-10, -100), 20, 20, :fill))
```

In this animation the position of the circle is saved inside `my_circle` and can be used with `pos(my_circle)` inside the `rect` function.

## How can I show a text being drawn?

A `text` or [`latex`](@ref) rendering can appear as *any* other object with `appear(:fade)` and `appear(:scale)`, However, it also has a special [`appear`](@ref) functionality called 
`:draw_text`.

You can use 
```julia
my_text = Object(1:100, (args...) -> text("Hello World!"; halign = :center))
act!(my_text, Action(1:15, sineio(), appear(:draw_text)))
act!(my_text, Action(76:100, sineio(), disappear(:draw_text)))
```

to let the text `"Hello World!"` appear from left to right in an animated way. 

## How can I have an object follow a path?

We need to create a path by providing a list of points that the object can follow.
All objects that return a list of points can be used directly like `star` and `poly` for others a list of points must be provided as the input.

An action can look like this:

```julia
my_star = Object(1:100, (args...) -> star(O, 20, 5, 0.5, 0, :fill))
act!(my_star, Action(1:100, follow_path(star(O, 200))))
```

in this case a star is following the path of a bigger star. 
> **NOTE:** the star inside [`follow_path`](@ref) should have the `action=:none` which is the default for most Luxor functions.

> **NOTE:** Unfortunately the above currently only works for some Luxor functions like `ngon` and `star` but not for `circle` and `rect` as they return `true` instead of the points.

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
Background(1:100, ground)
my_star = Object(1:100, (args...) -> star(O, 20, 5, 0.5, 0, :fill))
act!(my_star, Action(1:100, follow_path(luxor2poly(()->rect(O, 100, 100, :path)))))
render(video; pathname="follow_path.gif")
```


Another possibility is to specify a vector of points like this:

```julia
act!(
    my_star,
    Action(
        1:100,
        sineio(),
        follow_path([Point(100, 100), Point(-20, -150), Point(-80, -10)]; closed = false),
    ),
)
```

In this case I want the star to follow a path consisting of two edges and I use `; closed=false` to specify that it's just two edges and not a closed triangle.

An interesting possibility is to define paths using Bézier curves which can be defined with Luxor (see: [Polygons to Bézier paths and back again](https://juliagraphics.github.io/Luxor.jl/stable/polygons/#Polygons-to-B%C3%A9zier-paths-and-back-again))

One example of this can be seen in our [example section](examples.md)

## How can I see a live view of the animation?

A live view of the animation can be useful for creating an animation where one doesn't need the overhead of building a gif or mp4 all the time. It also has the advantage that it's very easy to jump to a specific frame.

The live viewer can be called with adding `; liveview=true` to the [`render`](@ref) call.

> **NOTE:** If `liveview=true` the `tempdirectory` and `pathname` arguments are ignored and no file is created.

## How to speed up rendering?

For longer videos in can happen that rendering takes quite some time. It's often nice to render a scaled version of the video first to see whether everything looks perfectly animated.

By using `render(video; pathname="how_to.gif", rescale_factor=0.5)` you'll often speed up the rendering by a factor of 2. This will scale the frames down by a factor of 2 such that a `Video(1000, 1000)` will be shown as a 500x500 rendered video. 

> **Note:** You might want to experience with rendering to `mp4` instead of `gif` as well.