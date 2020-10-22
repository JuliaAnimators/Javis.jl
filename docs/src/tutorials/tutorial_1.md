# **Tutorial 1:** Making Your First Javis Animation!

## Introduction

If you are reading this tutorial, I am going to assume this is the first time you are using `Javis` to create an animation. 
In that case, welcome to `Javis`! 😃 
By following this tutorial, we are going to make you a director of your very own animations written in pure Julia! 🎬 🎥

If you have not installed `Javis` yet, please visit the homepage to [read the installation instructions](../index.md#Installing-Javis.jl).

## Learning Outcomes

In this tutorial you'll learn:

- What `Javis.jl` is.
- How to make a basic animation using [`Object`](@ref).
- Move objects created by `Javis` using [`Action`](@ref).
- Elements of `Luxor.jl`.

By the end of this tutorial, you will have made the following animation:

![](assets/dancing_circles.gif)

With all that said, let's dive into this tutorial! ✨

## So... What Is `Javis.jl`?

`Javis.jl` is an abstraction on top of powerful graphics tools to make animations and visualizations easy to create.
It is built on top of the fantastic Julia drawing packages, [`Luxor.jl`](https://github.com/JuliaGraphics/Luxor.jl) and [`Cairo.jl`](https://github.com/JuliaGraphics/Cairo.jl).
`Cairo.jl` is much too complex to explain here, but `Luxor.jl` gives one the ability to define and draw on a canvas.
`Luxor.jl` provides simple functions like `line`, `circle` and `poly` by which one can make animations. 

> **NOTE:** If you're interested in 2D graphics, you should definitely check out the awesome `Luxor.jl` package.
> It has a [great tutorial](https://juliagraphics.github.io/Luxor.jl/stable/tutorial/) that will give you an even greater understanding of how `Javis.jl` works.

## Prerequisites 

In order to use `Javis`, we will start with the following import:

```julia
using Javis
```

Then we need to define a [`Video`](@ref) 

```julia
myvideo = Video(500,500) # 500 x 500 // width x height
```

Every object and action that we create afterwards is added to `myvideo`.

## Making Our Animation

We need to set-up a few functions that will be able to make our animation! 

Our first function is the `ground` function.
The `ground` function sets the background to white and the "pen" color to black. 

```julia
function ground(args...) 
    background("white") # canvas background
    sethue("black") # pen color
end
```

> **NOTE:** One may wonder, "why is `args...` needed in the `ground` function?"
> Each user-defined function gets three arguments `video`, `object`, and `frame` provided by Javis
> These arguments are defined below:
>
> - `video`: Video struct
> - `object`: Object struct
> - `frame`: the current frame number
>
> Although these arguments are irrelevant for the `ground` function, we need to write `args...` such that Julia actually knows that we have a method that accepts those three arguments.
> The `...` basically stands for as many arguments as you want.

Although `Luxor.jl` provides the functionality to draw circles, `Javis` does not. 
We use `Luxor.jl` to create a function that defines a color for circles and draws the circles accordingly.
Here is how that code looks:

```julia
function object(p=O, color="black")
    sethue(color)
    circle(p, 25, :fill)
    return p
end
```

## Let's Draw a Circle!

Using our newly found `Javis` knowledge, we can now draw a circle and render it!
We do the following after importing the `Javis.jl` package and defining our own functions (don't worry if you don't understand the syntax here - it is too advanced for this tutorial but will be explained in future tutorials):

```julia
myvideo = Video(500, 500)
BackgroundObject(1:70, ground)
red_ball = Object(1:70, (args...) -> object(Point(100,0), "red"))

render(
    myvideo;
    pathname="circle.gif"
)
```

![](assets/circle.gif)

We used `BackgroundObject` instead of `Object` to specify that the ground function is applied to all objects afterwards.

You did it! 🎉 You created your first drawing with `Javis`! 🔴

The `render` command that you saw in the previous code snippet renders all the objects defined onto the `Video` object we defined (`myvideo`) and outputs it as a `gif` file.

> **NOTE:** Other formats are supported besides `gif`.
Check this out by running `julia> ?render` in your Julia REPL.

Let's go crazy and draw another object:

```julia
myvideo = Video(500, 500)
BackgroundObject(1:70, ground)
red_ball = Object(1:70, (args...) -> object(Point(100,0), "red"))
blue_ball = Object(1:70, (args...) -> object(Point(100,80), "blue"))

render(
    myvideo;
    pathname="circle.gif"
)
```

![](assets/multiple_circles.gif)

So, this drawing - it's all nice and all, but perhaps a little...
Dull? 
This is supposed to be an animation!
Let's make these balls dance. 💃

## It Takes Two to Tango 💃

Let's use the special modifier, `Rotation`, to produce a ball that rotates in a circle:

```julia
BackgroundObject(1:70, ground)
red_ball = Object(1:70, (args...)->object(Point(100,0), "red"))
act!(red_ball, Action(Rotation(0.0, 2π)))
```

The `render` function stays the same for the rest of this tutorial. Same is true for the `myvideo = Video(500, 500)` line.

![](assets/rotation.gif)

Now that's what I call dancing!
However, I think our red ball is a bit lonely, don't you think?
It needs a partner!

To make another ball appear, execute the following code snippet:

```julia
BackgroundObject(1:70, ground)
red_ball = Object(1:70, (args...)->object(Point(100,0), "red"))
act!(red_ball, Action(Rotation(0.0, 2π)))
blue_ball = Object(1:70, (args...)-> object(Point(100,80), "blue"))
act!(blue_ball, Action(Rotation(2π, 0.0, red_ball)))
```

![](assets/dynamic_rotation.gif)

There we go! 

## Mapping an Orbit 🚀

Now, imagine we are astronomers and we model these balls as planets.
It would be important to know their orbital trajectories!
To do so, let's draw the path that both of the balls take with this new function:

```julia
function path!(points, pos, color)
    sethue(color)
    push!(points, pos) # add pos to points
    circle.(points, 2, :fill) # draws a circle for each point using broadcasting
end
```

> **NOTE:** The [`pos`](@ref) takes the **pos**ition of the `:red_ball` and passes it as an argument into the `path!` function. 

Then, using this function, we can execute the following block:

```julia
BackgroundObject(1:70, ground)
red_ball = Object(1:70, (args...)->object(Point(100,0), "red"))
act!(red_ball, Action(Rotation(0.0, 2π)))
Object(1:70, (args...)->path!(path_of_red, pos(red_ball), "red"))
```

![](assets/dotted_points.gif)

Fantastic!
That's a pretty regular orbit I must say!

Now, to easily visualize our two "planets" (the red and blue balls), let's connect them together. 
We can do so by drawing a line that connects both balls:

```julia
function connector(p1, p2, color)
    sethue(color)
    line(p1,p2, :stroke)
end
```

And to show this link:

```julia
BackgroundObject(1:70, ground)
red_ball = Object(1:70, (args...)->object(Point(100,0), "red"))
act!(red_ball, Action(Rotation(0.0, 2π)))
blue_ball = Object(1:70, (args...)->object(Point(100,80), "blue"))
act!(blue_ball, Action(Rotation(2π, 0.0, red_ball)))
Object(1:70, (args...)->connector(pos(red_ball), pos(blue_ball), "black"))
```

![](assets/connect_two_points.gif)

Perfect! Now, let's put everything together to see our orbiting planets' trajectories:

```julia
using Javis

function ground(args...)
    background("white") # canvas background
    sethue("black") # pen color
end

function object(p=O, color="black")
    sethue(color)
    circle(p, 25, :fill)
    return p
end

function path!(points, pos, color)
    sethue(color)
    push!(points, pos) # add pos to points
    circle.(points, 2, :fill) # draws a circle for each point using broadcasting
end

function connector(p1, p2, color)
    sethue(color)
    line(p1,p2, :stroke)
end

myvideo = Video(500, 500)

path_of_red = Point[]
path_of_blue = Point[]

BackgroundObject(1:70, ground)
red_ball = Object(1:70, (args...)->object(Point(100,0), "red"))
act!(red_ball, Action(Rotation(0.0, 2π)))
blue_ball = Object(1:70, (args...)->object(Point(100,80), "blue"))
act!(blue_ball, Action(Rotation(2π, 0.0, red_ball)))
Object(1:70, (args...)->connector(pos(red_ball), pos(blue_ball), "black"))
Object(1:70, (args...)->path!(path_of_red, pos(red_ball), "red"))
Object(1:70, (args...)->path!(path_of_blue, pos(blue_ball), "blue"))

render(myvideo; pathname="tutorial_1.gif")
```

![](assets/dancing_circles.gif)

Do you see any little green men on these planets? 👽 

## Conclusion

Amazing!!!
You have just made your first animation using `Javis.jl` and we are so proud!
I hope you feel like you accomplished something!

To recap, by working through this animation you should now:

1. Know how to make a simple animation in Javis
2. Understand the difference between `Object` and `BackgroundObject`
3. Be able to connect actions together using the object variable

If you want to know more and experiment with `Javis`, go onto the following tutorials!
We wish you the best on your `Javis` journey!

> **Author(s):** @sudomaze, Ole Kröger, Jacob Zelko \
> **Date:** October 16th, 2020 \
> **Tag(s):** action, rotation, object
