# **Tutorial 1:** Making Your First Javis Animation!

## Introduction

If you are reading this tutorial, I am going to assume this is the first time you are using `Javis` to create an animation. In that case, welcome to `Javis`! 😃 By following this tutorial, we are going to make you a director of your very own animations written in pure Julia! 🎬 🎥

If you have not installed `Javis` yet, please visit the homepage to [read the installation instructions](../index.html#Installation).

## Explanation

[`Luxor.jl`](https://github.com/JuliaGraphics/Luxor.jl) allows you to draw on a canvas. It provides simple functions like `line`, `circle` and one can do simple animations. 

Javis is one abstraction layer above to make animations a little easier.

If you're interested in 2D graphics, you should definitely check out the awesome `Luxor` Tutorial.

## Learning outcomes

In this tutorial you'll learn how to make a basic animation using Javis by using what we call `Action` as well as rotation and learn a couple of Luxor functions if you haven't used Luxor before.

## A simple animation

In order to use `Javis.jl`, you will need to include the following in your file.

```julia
using Javis

javis(
    [[video]], # Video struct
    [[actions]], # Vector
    pathname=[[pathname]] # String
)
```

`javis()` has three parameters: 
* `video`
* `actions`
* `pathname`

### pathname

The `pathname` is a String. In order to get the final result of `javis`, you will need to set `pathname` to the path where the gif will be stored and the gif name. Similar to the following:

```julia
javis(
    [[video]], # Video struct
    [[actions]], # Vector
    pathname="/path/animation.gif"
)
```

### Video

The `video` is a Video struct and its constructor arguments are width and height.

```julia
video = Video(500,500) # 500x500 // width x height
javis(
    video,
    [[actions]], # Vector
    pathname="/path/animation.gif"
)
```

### Actions

The `actions` is a Vector of actions. There are two types of actions:

* `BackgroundAction`
* `Action`

```julia
video = Video(500,500)
javis(
    video,
    [
        ...
    ],
    pathname="/path/animation.gif"
)
```

#### BackgroundAction

`BackgroundAction` is basically the same as an `Action` but it leaks everything to the outside i.e it is able to set defaults like pen color, line width, etc in that action.

```julia
BackgroundAction(
    [[frames]], # Range (Int:Int)
    [[func]] # Function call
)
```

* `frames`: a range of frames it is applied to.
* `func`: the function that is called for each frame (in this example, we will be using `ground`).

##### `ground`

```julia
function ground(args...) 
    background("white") # canvas background
    sethue("black") # pen color
end
```

The `ground` function sets the background to white and the paint brush color to black.

**Why do I need the `args...`?** Each user function gets three arguments `video, action, frame` in order:
* `Video`: Video struct
* `Action`: Action struct
* `frame`: the current frame number

They are irrelevant for the background such that we don't need to write them down explicitly. "Unfortunately" we need to write `args...` such that Julia actually knows that we have a method that accepts those three arguments. The `...` basically stands for as many arguments as you want.

> **Note:** `sethue` is the same as `setcolor` but doesn't mess with the opacity.


To draw a white background use the following:

```julia
BackgroundAction(
    1:70, # 70 frames
    ground # apply ground function for each frame
)
```

#### Action()

```julia
Action(
    [[frames]], # Range (Int:Int)
    :[[variable_name]], # Variable name (optional)
    (args...)->
        [[func]] # Function call
    , 
    [[transition]] # Transition struct (optional)
)
```
* `frames`: Range of frames it is applied to.
* `variable_name` (optional): Variable name for the action to save the result of `func`.
* `func`: Function call to set action.
* `transition` (optional): Transition struct (for this tutorial, we will be using `Rotation()`).

```julia
Action(
    1:70, # 70 frames
    :red_ball, # variable name
    (args...)->
        [[func]] # function call
    , 
    [[transition]] # Transition struct (optional)
)
```

[`sethue`](https://juliagraphics.github.io/Luxor.jl/stable/colors-styles/#Luxor.sethue), [`circle`](https://juliagraphics.github.io/Luxor.jl/stable/simplegraphics/#Luxor.circle), and [`line`](https://juliagraphics.github.io/Luxor.jl/stable/simplegraphics/#Luxor.line) are path of `Luxor.jl`, so we are using them to define `object()`, `path!()`, and `connector()`. These functions will be used in this tutorials to replace `func` in `Action()`.

##### Draw a circle
To draw a circle, use the following:
```julia
# to draw the circle
function object(p=O, color="black")
    sethue(color)
    circle(p, 25, :fill)
    return p
end
```

```julia
javis(
    video,  
    [
        BackgroundAction(1:70, ground),
        Action(1:70,:red_ball, (args...)->object(Point(100,0), "red")),
    ],
    pathname="circle.gif"
)
```

![](assets/circle.gif)

To draw multiple circles, use the following:
```julia
javis(
    video,  
    [
        BackgroundAction(1:70, ground),
        Action(1:70,:red_ball, (args...)->object(Point(100,0), "red")),
        Action(1:70, :blue_ball, (args...)->object(Point(100,80), "blue")
    ],
    pathname="multiple_circles.gif"
)
```

![](assets/multiple_circles.gif)

##### Rotation

```julia
Rotation(
    [[start]], # Radian (optional)
    [[target]],  # Radian
    :[[center]] # Variable name (optional)
)
```

Rotation struct for the rotation animation.

* `start` (optional): where the rotation starts in radian. The default value is `0.0` (the origin).
* `target`: where the rotation ends in radian.
* `center` (optional): you can have the center of rotation of another object.


To draw a circle with rotation, use the following:
```julia
Rotation(
    0.0,
    2π 
)
```

```julia
javis(
    video,  
    [
        BackgroundAction(1:70, ground),
        Action(1:70,:red_ball, (args...)->object(Point(100,0), "red"), Rotation(0.0, 2π)),
    ],
    pathname="rotation.gif"
)
```

![](assets/rotation.gif)

To draw a circle with rotation and dynamic center, use the following:

```julia
Rotation(
    2π,
    0.0, 
    :red_ball
)
```

```julia
javis(
    video,  
    [
        BackgroundAction(1:70, ground),
        Action(1:70,:red_ball, (args...)->object(Point(100,0), "red"), Rotation(0.0, 2π)),
        Action(1:70, :blue_ball, (args...)-> object(Point(100,80), "blue"), Rotation(2π, 0.0, :red_ball))
    ],
    pathname="dynamic_rotation.gif"
)
```

The blue ball now rotates around the red ball. We'll add some more to the animation to see this more clearly.

![](assets/dynamic_rotation.gif)

##### Draw dotted points

Let's draw the path that both of the balls take:

To draw dotted points
```julia
function path!(points, pos, color)
    sethue(color)
    push!(points, pos) # add pos to points
    circle.(points, 2, :fill) # draws a circle for each point using broadcasting
end
```

```julia
path_of_red = Point[]

javis(
    video,  
    [
        BackgroundAction(1:70, ground), 
        Action(1:70,:red_ball, (args...)->object(Point(100,0), "red"), Rotation(0.0, 2π)), 
        Action(1:70, (args...)->path!(path_of_red, pos(:red_ball), "red"))
    ],
    pathname="dotted_points.gif" # path with output file name
)
```

Here the [`pos`](@ref) takes the position of the `:red_ball` and passed it as an argument into our new `path!` function.

![](assets/dotted_points.gif)

It's easier to see that the blue ball we introduced earlier does actually rotate around around the red ball by drawing a line that connects both balls. 

```julia
function connector(p1, p2, color)
    sethue(color)
    line(p1,p2, :stroke)
end
```

```julia
javis(
    video,  
    [
        BackgroundAction(1:70, ground),
        Action(1:70,:red_ball, (args...)->object(Point(100,0), "red"), Rotation(0.0, 2π)), 
        Action(1:70, :blue_ball, (args...)->object(Point(100,80), "blue"), Rotation(2π, 0.0, :red_ball)), 
        Action(1:70, (args...)->connector(pos(:red_ball), pos(:blue_ball), "black"))
    ],
    pathname="connect_two_points.gif" # path with output file name
)
```

![](assets/connect_two_points.gif)

## Everything together!

Let's put everything into one animation:

```julia
using Javis

# applied on every frame
function ground(args...)
    background("white") # canvas background
    sethue("black") # pen color
end

# draw a circle
function object(p=O, color="black")
    sethue(color)
    circle(p, 25, :fill)
    return p
end

# draw dotted points
function path!(points, pos, color)
    sethue(color)
    push!(points, pos)
    circle.(points, 2, :fill)
end

# draw a line to connect two points
function connector(p1, p2, color)
    sethue(color)
    line(p1,p2, :stroke)
end

# center for the two objects
p1 = Point(100,0)
p2 = Point(100,80)

# dotted points vectors
path_of_blue = Point[]
path_of_red = Point[]

# video struct (width, height)
video = Video(500, 500)

javis(
    video,  
    [
        BackgroundAction(1:70, ground), # set background color and pen color
        Action(1:70,:red_ball, (args...)->object(p1, "red"), Rotation(0.0, 2π)), # draw the red ball with rotation
        Action(1:70, :blue_ball, (args...)-> object(p2, "blue"), Rotation(2π, 0.0, :red_ball)), # draw the blue ball with dynamic rotation
        Action(1:70, (args...)->path!(path_of_red, pos(:red_ball), "red")), # draw tracks for red ball
        Action(1:70, (args...)->path!(path_of_blue, pos(:blue_ball), "blue")), # draw track for blue ball
        Action(1:70, (args...)->connector(pos(:red_ball), pos(:blue_ball), "black")) # draw a line that connects both balls
    ],
    pathname="dancing_circles.gif" # path with output file name
)
```

![](assets/dancing_circles.gif)

## Conclusion

To recap, by working through this animation you should now:

1. Know how to make a simple animation in Javis
2. Understand the difference between `Action` and `BackgroundAction`
3. Be able to connect actions together using the variable syntax and the `pos` function

> **Author(s):** Sudomaze, Ole Kröger, Jacob Zelko \
> **Date:** August 14th, 2020 \
> **Tag(s):** action, rotation