# **Tutorial 2:** What Are Objects?

In this tutorial, we are going to learn how to make a brain! 🧠 
Well, not _exactly_ making a brain. 
Instead, we are going to animate brain activity by simulating a [10-20 EEG Electrode Array](https://en.wikipedia.org/wiki/10%E2%80%9320_system_(EEG)?oldformat=true) using random data. 

When you are done with this tutorial, you will have created the following animation:

![](assets/eeg.gif)

## Learning Outcomes

From this project tutorial you will:

- Clearly understand how to use `Object` types to create an animation
- Be able to create more complex animations
- Display meaningful information on your animations

## Setting Up Our Animation

As demonstrated in prior tutorials, we will use `Javis` to create a `Video` object:

```julia
using Javis

video = Video(500, 500)
```

Let's define our background function to create the backdrop of our frames:

```julia
function ground(args...)
    background("white")
    sethue("black")
end
```

If we were to execute the `render` command now, this is what would appear as an output of the following execution:

```julia
video = Video(500, 500)
anim_background = Background(1:10, ground)
render(video, pathname = "eeg.gif", framerate = 1)
```

![](assets/blank.gif)

As you can see, we have generated a blank gif.
Not exactly what we want but it is a start!
We used a special type of object called [`Background`](@ref).
This applies whatever function that is provided to it as the default background of any future animations produced by a future object.

> **NOTE:** For this animation, we will be using a framerate of 1 frame per second.
> Thus, why `framerate` is set to the value of `1` in `render`.

## Getting A - _head_

Now that we have created our default background via the `Background`, let's move onto making the head that we will attach our electrodes to!

First, we define an additional function that allows us to draw a circle.
This will be used extensively later:

```julia
function circ(p = O, color = "black", action = :fill, radius = 25, edge = "solid")
    sethue(color)
    setdash(edge)
    circle(p, radius, action)
end
```

We can now do the exciting part -- using an [`Object`](@ref)!
Objects are at the very heart of the entire `Javis` library and are the foundational building blocks to make animations.
Objects are what is used to draw on a frame!

Using the `circ` function we defined, we can use an `Object` to draw a head.
The following invocation will create the head:

```julia
...
head = Object((args...) -> circ(O, "black", :stroke, 170))
...
```

An `Object` consists of at least one part, namely calling a function which draws something on to the canvas. 
`Objects` are comprised of `Frames` (which can be optionally defined), a drawing function `func`, and an optional `Animation` (this functionality is explained more in future tutorials).

### Frames

The default of an `Object` is to use the same frames as a previous `Object`. 
Besides that there are three other options:

- Define the range explicitly i.e. `1:100`.
- Use the default or explicitly write `:same` into the unit range location which means the same frames as before
- Use [`RFrames`](@ref) to specify it relative to the previously defined frame range
  - `RFrames(10)` which is short for `RFrames(1:10)` after an `Object` which is defined for `1:100` would mean `101:110`.
  You just want to make sure that you don't define a frame range greater than the frame range defined for `Background`.

### Function

The most important part of each [`Object`](@ref) is the drawing function `func` that defines what should be drawn in these frames. 
Under the hood, Javis calls `func` with three arguments (`video`, `object`, and `framenumber`) but you do not need to preoccupy yourself with these.
Just make `func` an anonymous function and define the output being drawn in the canvas:

```julia
(args...) -> my_drawing_function(my_drawing_arguments...)
```

(The `args...` don't even need to be part of the output!)

In [Tutorial 1](tutorial_1.md), we saw that `my_drawing_function` could either be a Luxor function or a function which calls some Luxor functions to draw on the canvas. 

Now that those explanations are out of the way, back to the brain! 

The code

```julia
...
head = Object((args...) -> circ(O, "black", :stroke, 170))
...
```

creates

![](assets/head.gif)

Now we are getting a - _head_! 😃

## Placing the Electrodes

To draw our electrodes, it would be useful to have a frame of reference for where the electrodes are supposed to go.
Let's draw some axes for our electrode locations!

We will need to define a new function that allows us to draw lines.
This is accomplished by the following function definition:

```julia
function draw_line(p1 = O, p2 = O, color = "black", action = :stroke, edge = "solid")
    sethue(color)
    setdash(edge)
    line(p1, p2, action)
end
```

Now, we can add in some grid lines for our electrode array. 
The following code places a vertical and horizontal axis as well as an inscribed circle to represent polar placement of the electrodes:

```julia
...
inside_circle = Object((args...) -> circ(O, "black", :stroke, 140, "longdashed"))
vert_line = Object(
    (args...) ->
        draw_line(Point(0, -170), Point(0, 170), "black", :stroke, "longdashed"),
)
horiz_line = Object(
    (args...) ->
        draw_line(Point(-170, 0), Point(170, 0), "black", :stroke, "longdashed"),
)
...
```

![](assets/head_gridlines.gif)

Great!
Now that we have the gridlines, let's add in our electrodes!

We have to define our own function to create an electrode.
The following code accomplishes this goal:

```julia
function electrode(
    p = O,
    fill_color = "white",
    outline_color = "black",
    action = :fill,
    radius = 25,
    circ_text = "",
)
    sethue(fill_color)
    circle(p, radius, :fill)
    sethue(outline_color)
    circle(p, radius, :stroke)
    text(circ_text, p, valign = :middle, halign = :center)
end
```

Essentially, all the `electrode` function does is draws two circles on top of each other.
One circle creates a white circle for the backdrop of text provided to it and the other circle provides a black outline. 

From there, we need to position our electrodes!
I already went through and created a named tuple which defines an electrode's name and its position. 

Go ahead and copy this to save yourself the time to place these perfectly.
I already did this for you - aren't I great? 😉

```julia
electrodes_list = [
    (name = "Cz", position = O),
    (name = "C3", position = Point(-70, 0)),
    (name = "C4", position = Point(70, 0)),
    (name = "T3", position = Point(-140, 0)),
    (name = "T4", position = Point(140, 0)),
    (name = "Pz", position = Point(0, 70)),
    (name = "P3", position = Point(-50, 70)),
    (name = "P4", position = Point(50, 70)),
    (name = "Fz", position = Point(0, -70)),
    (name = "F3", position = Point(-50, -70)),
    (name = "F4", position = Point(50, -70)),
    (name = "F8", position = Point(115, -80)),
    (name = "F7", position = Point(-115, -80)),
    (name = "T6", position = Point(115, 80)),
    (name = "T5", position = Point(-115, 80)),
    (name = "Fp2", position = Point(40, -135)),
    (name = "Fp1", position = Point(-40, -135)),
    (name = "A1", position = Point(-190, -10)),
    (name = "A2", position = Point(190, -10)),
    (name = "O1", position = Point(-40, 135)),
    (name = "O2", position = Point(40, 135)),
]
```

Finally, we can broadcast these points and names to our previously defined `electrode` function.
Also, we need to define the radius of our electrodes; we will set that to 15:

```julia
...
radius = 15 # Radius of the electrodes
for num in 1:length(electrodes_list)
    Object(
        (args...) ->
            electrode.(
                electrodes_list[num].position,
                "white",
                "black",
                :fill,
                radius,
                electrodes_list[num].name,
            ),
    )
end
...
```

Now, executing this code block with our previously defined functions, we get this output:

![](assets/electrodes.gif)

## "If Only I Had a Brain..." 🎵

I think this is starting to come together quite nicely!
It would appear that our subject however has no brain activity - quite alarming! 😱
Like the scarecrow from the film, _The Wizard of Oz_, let's give him a brain!

To simulate brain activity, we are going to add one more package from Julia base.
This package is the `Random` package and it needs to be added like such:

```julia
using Javis
using Random
```

From there, we need to define colors to represent no, low, medium, and high brain activity.
Feel free to change up the colors!
I chose these colors that need to be added to your code:

```julia
indicators = ["white", "gold1", "darkolivegreen1", "tomato"]
```

From there, we also need to change the code block that defined the electrode locations.
The previous electrode code looked like this

```julia
...
for num in 1:length(electrodes_list)
    Object(
        (args...) ->
            electrode.(
                electrodes_list[num].position,
                rand(indicators, length(electrodes_list)),
                "black",
                :fill,
                radius,
                electrodes_list[num].name,
            ),
    )
end
...
```

However, what we now need to change is `"white"` to `rand(indicators, length(electrodes_list))` for each electrode.
The `rand` function allows proper broadcasting such that a new color is chosen for each electrode between frames.
Without having the `length(electrodes_list)` random colors would be generated but only for the first frame.
The next frame would then keep these colors for the rest of the animation.

An example resulting electrode configuration with random colors looks like this:

```julia
...
for num in 1:length(electrodes_list)
    Object(
        (args...) ->
            electrode.(
                electrodes_list[num].position,
                rand(indicators, length(electrodes_list)),
                "black",
                :fill,
                radius,
                electrodes_list[num].name,
            ),
    )
end
...
```

Once all these modifications were made, execute your EEG and you should get something that looks like this:

![](assets/eeg_colors.gif)

IT'S ALIVE!!! 🔬
We could finish this now, but let's add just a little bit more polish to it.

## As You Can See Here...

Let's add some information to our animation. 
We can create an info box using the following function:

```julia
function info_box(video, object, frame)
    fontsize(12)
    box(140, -210, 170, 40, :stroke)
    text("10-20 EEG Array Readings", 140, -220, valign = :middle, halign = :center)
    text("t = $(frame)s", 140, -200, valign = :middle, halign = :center)
end
```

It's invocation in the code looks like this:

```julia
...
info = Object(info_box)
...
```

> **NOTE:** The function for `info_box` is a little different!
> Each `Object` receives three additional variables being a `Video` object, which was previously defined outside of the `render` function, an `Object`, and the current frame number. 

Once everything is executed, we get this very nice and clean looking animation which shows what this animation is and when parts of the brain are activated:

![](assets/eeg.gif)

## Conclusion

Congratulations! 🎉 🎉 🎉 
You made a brain! 
To recap, by working through this animation you should now:

1. Clearly understand how to use an `Object` 
2. Be able to create your own `Object`
3. Know how to approach complex animations
4. Make meaningful information displayed easily on your animations

Great job leveling up your `Javis` skills! 💪

## Full Code

In case you ran into any issues or confusion, here is the full code:

```julia
using Javis
using Random

function ground(args...)
    background("white")
    sethue("black")
end

function draw_line(p1 = O, p2 = O, color = "black", action = :stroke, edge = "solid")
    sethue(color)
    setdash(edge)
    line(p1, p2, action)
end

function circ(p = O, color = "black", action = :fill, radius = 25, edge = "solid")
    sethue(color)
    setdash(edge)
    circle(p, radius, action)
end

function info_box(video, object, frame)
    fontsize(12)
    box(140, -210, 170, 40, :stroke)
    text("10-20 EEG Array Readings", 140, -220, valign = :middle, halign = :center)
    text("t = $(frame)s", 140, -200, valign = :middle, halign = :center)
end

function electrode(
    p = O,
    fill_color = "white",
    outline_color = "black",
    action = :fill,
    radius = 25,
    circ_text = "",
)
    sethue(fill_color)
    circle(p, radius, :fill)
    sethue(outline_color)
    circle(p, radius, :stroke)
    text(circ_text, p, valign = :middle, halign = :center)
end

electrodes_list = [
    (name = "Cz", position = O),
    (name = "C3", position = Point(-70, 0)),
    (name = "C4", position = Point(70, 0)),
    (name = "T3", position = Point(-140, 0)),
    (name = "T4", position = Point(140, 0)),
    (name = "Pz", position = Point(0, 70)),
    (name = "P3", position = Point(-50, 70)),
    (name = "P4", position = Point(50, 70)),
    (name = "Fz", position = Point(0, -70)),
    (name = "F3", position = Point(-50, -70)),
    (name = "F4", position = Point(50, -70)),
    (name = "F8", position = Point(115, -80)),
    (name = "F7", position = Point(-115, -80)),
    (name = "T6", position = Point(115, 80)),
    (name = "T5", position = Point(-115, 80)),
    (name = "Fp2", position = Point(40, -135)),
    (name = "Fp1", position = Point(-40, -135)),
    (name = "A1", position = Point(-190, -10)),
    (name = "A2", position = Point(190, -10)),
    (name = "O1", position = Point(-40, 135)),
    (name = "O2", position = Point(40, 135)),
]

radius = 15
indicators = ["white", "gold1", "darkolivegreen1", "tomato"]
demo = Video(500, 500)

anim_background = Background(1:10, ground)
head = Object((args...) -> circ(O, "black", :stroke, 170))
inside_circle = Object((args...) -> circ(O, "black", :stroke, 140, "longdashed"))
vert_line = Object(
    (args...) ->
        draw_line(Point(0, -170), Point(0, 170), "black", :stroke, "longdashed"),
)
horiz_line = Object(
    (args...) ->
        draw_line(Point(-170, 0), Point(170, 0), "black", :stroke, "longdashed"),
)

for num in 1:length(electrodes_list)
    Object(
        (args...) ->
            electrode.(
                electrodes_list[num].position,
                rand(indicators, length(electrodes_list)),
                "black",
                :fill,
                radius,
                electrodes_list[num].name,
            ),
    )
end
info = Object(info_box)

render(demo, pathname = "eeg.gif", framerate = 1)
```

---
---

> **Author(s):** Jacob Zelko, Ole Kröger \
> **Date:** August 11th, 2020 \
> **Tag(s):** brain, EEG, project, tutorial, electrodes, Object, Background
