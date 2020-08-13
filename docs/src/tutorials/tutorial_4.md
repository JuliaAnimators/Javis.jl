# **Tutorial 4:** Do you know our Mascot? - Learn about transitions and subactions!

You have learned a couple of cool features of Javis already. Now you're ready to finally meet our little mascot. Well actually you can't just see him, we have to create him first. :smile:

Let's create a list of what we want first
- a circular head
- some hair
- eyes
- a nose
- a moving mouth
- he should say something

This should show you the power of `SubAction` so we want each of those appear (fade in) one after another.

```julia
using Javis

function ground(args...)
    background("white")
    sethue("black")
end

function title(args...)
    fontsize(20)
    text("Our Mascot", Point(0, -200),
        valign=:middle, halign=:center)
end

function face()
    video = Video(500, 500)
    javis(video, [
        BackgroundAction(1:150, ground),
        Action(title; subactions=[
            SubAction(1:5, appear(:fade)),
        ]),
    ], pathname="jarvis.gif", framerate=15)
end
```

The `ground` function should be familiar to you as well as the general structure of the `javis` function.

A new part is the second `Action` which takes in a function and `subactions` as a keyword argument. 

If you're wondering where the `frames` are specified:
- You can leave the frames blank as here and then the frames from the previous action are used. 

The `subactions` keyword uses a list of [`SubAction`](@ref) structs which are defined in a similar fashion with `frames` and a function but are in some sense simpler than the `Action`. 

A function of a `SubAction` is normally either [`appear`](@ref) or [`disappear`](@ref) at the moment or one of two transformations: [`Translation`](@ref) and [`Rotation`](@ref).

In theory you can define your own but that is way outside of this tutorial.

For the title we want that the text appears in the first 5 frames of the action. More precisely we let it fade in. 

Let's continue with a bit more before we draw part of the mascot.

The following actions will just be added to the `javis` function.

```julia
Action(16:150, (args...)->circle(O, 100, :stroke); subactions=[
    SubAction(1:15, appear(:fade)),
]),
```

This is very similar to the previous action. Here we can see that `SubAction` uses relative frame numbers such that the head appears in the frames `16:30` and then is at full opacity afterwards.

Just a small refresher: We need the anonymous function `(args...)->circle(O, 100, :stroke)` as each function gets called with the three arguments `video, action, frame`.

Okay let's add some hair shall we?

I want to have some randomness in his hair so let's define:

```julia
hair_angle = rand(-0.9:0.1:0.9, 20)
```

at the beginning of the `face` function.

and have a hair function:

```julia
function hair_blob(angle)
    sethue("brown")
    rotate(angle)
    circle(Point(0, -100), 20, :fill)
end
```

It draws one brown hair blob given the angle. We basically rotate the whole canvas and then draw the circle always at the same local position. 

Now how do we draw the hair now without creating an action for each blob?

We can use splatting for that :wink:

```julia
[
    Action(26:150, (args...)->hair_blob(hair_angle[i]); subactions=[
        SubAction(1:25, appear(:fade)),
    ]) for i=1:20
]...,
```

I think you get the idea of how to use `appear` now. Let's add some eyes and a nose quickly before we draw our first gif.

```julia
Action(30:150, (args...)->eyes(eye_centers, 10, "darkblue"); subactions=[
    SubAction(1:15, appear(:fade)),
]),
Action(45:150, (args...)->poly(nose, :fill); subactions=[
    SubAction(1:15, appear(:fade)),
]),
```

with:

```julia
eye_centers = [Point(-40,-30), Point(40,-30)]
nose = [O, Point(-10,20), Point(10, 20), O]
```

and

```julia
function eyes(centers, radius, color)
    sethue(color)
    circle.(centers, radius, :fill)
    setcolor("white")
    circle.(centers, radius/5, :fill)
end
```

![Up to the nose](./assets/jarvis_nose.gif)

Let's give him some moving lips so he can communicate with us:

```julia
upper_lip = [Point(-40, 45), Point(40, 45)]
lower_lip = [Point(-40, 55), Point(40, 55)]
```

These are just the outer points of the lips:

```julia
function lip(p1, p2)
    setline(2)
    move(p1)
    c1 = p1 + Point(10, 10)
    c2 = p2 + Point(-10, 10)
    curve(c1, c2, p2)
    do_action(:stroke)
end
```

This function uses some more functions of the awesome Luxor package.

The lips should be a little thicker than the other lines that we have drawn so far so let's set `setline(2)`. (default is 1).
First we move to the starting point of the lip and create two control points a bit below and to the vertical center.

The `curve` function is used to draw a bezier curve. 
It unfortunately doesn't support the `:stroke` at the end so we have to do this with `do_action(:stroke)` this time.

Now our two actions:

```julia
Action(60:150, (args...)->lip(upper_lip...); subactions=[
    SubAction(1:15, appear(:fade)),
    [SubAction(20i:20i+10, Translation(0, -5)) for i in 1:5]...,
    [SubAction(20i+10:20i+20, Translation(0, 5)) for i in 1:5]...
]),
Action(60:150, (args...)->lip(lower_lip...); subactions=[
    SubAction(1:15, appear(:fade)),
    [SubAction(20i:20i+10, Translation(0, 5)) for i in 1:5]...,
    [SubAction(20i+10:20i+20, Translation(0, -5)) for i in 1:5]...
]),
```

Yeah I like those `...` splatting :smile:

We fade them in at the beginning and then they shall move up and down a couple of times.

Finally let him speak:

```julia
function speak(str)
    fontsize(15)
    text(str, Point(100, 50))
end
```


```julia
Action(80:120, (args...)->speak("I'm Jarvis"); subactions=[
    SubAction(1:5, appear(:fade)),
    SubAction(36:40, disappear(:fade)),
]),
Action(120:150, (args...)->speak("How are you?"); subactions=[
    SubAction(1:5, appear(:fade)),
    SubAction(36:40, disappear(:fade)),
])
```

This time we also use the [`disappear`](@ref) function to fade out the text.

![Jarvis](./assets/jarvis.gif)

Hope you had as much fun reading this tutorial as I had creating our mascot.

You're now ready to create your own big project.

The whole code:

```julia
using Javis

function ground(args...)
    background("white")
    sethue("black")
end

function title(args...)
    fontsize(20)
    text("Our Mascot", Point(0, -200),
        valign=:middle, halign=:center)
end

function hair_blob(angle)
    sethue("brown")
    rotate(angle)
    circle(Point(0, -100), 20, :fill)
end

function eyes(centers, radius, color)
    sethue(color)
    circle.(centers, radius, :fill)
    setcolor("white")
    circle.(centers, radius/5, :fill)
end

function lip(p1, p2)
    setline(2)
    move(p1)
    c1 = p1 + Point(10, 10)
    c2 = p2 + Point(-10, 10)
    curve(c1, c2, p2)
    do_action(:stroke)
end

function speak(str)
    fontsize(15)
    text(str, Point(100, 50))
end

function face()
    eye_centers = [Point(-40,-30), Point(40,-30)]
    nose = [O, Point(-10,20), Point(10, 20), O]
    upper_lip = [Point(-40, 45), Point(40, 45)]
    lower_lip = [Point(-40, 55), Point(40, 55)]
    hair_angle = rand(-0.9:0.1:0.9, 20)

    video = Video(500, 500)
    javis(video, [
        BackgroundAction(1:150, ground),
        Action(title; subactions=[
            SubAction(1:5, appear(:fade)),
        ]),
        Action(16:150, (args...)->circle(O, 100, :stroke); subactions=[
            SubAction(1:15, appear(:fade)),
        ]),
        [
            Action(26:150, (args...)->hair_blob(hair_angle[i]); subactions=[
                SubAction(1:25, appear(:fade)),
            ]) for i=1:20
        ]...,
        Action(30:150, (args...)->eyes(eye_centers, 10, "darkblue"); subactions=[
            SubAction(1:15, appear(:fade)),
        ]),
        Action(45:150, (args...)->poly(nose, :fill); subactions=[
            SubAction(1:15, appear(:fade)),
        ]),
        Action(60:150, (args...)->lip(upper_lip...); subactions=[
            SubAction(1:15, appear(:fade)),
            [SubAction(20i:20i+10, Translation(0, -5)) for i in 1:5]...,
            [SubAction(20i+10:20i+20, Translation(0, 5)) for i in 1:5]...
        ]),
        Action(60:150, (args...)->lip(lower_lip...); subactions=[
            SubAction(1:15, appear(:fade)),
            [SubAction(20i:20i+10, Translation(0, 5)) for i in 1:5]...,
            [SubAction(20i+10:20i+20, Translation(0, -5)) for i in 1:5]...
        ]),
        Action(80:120, (args...)->speak("I'm Jarvis"); subactions=[
            SubAction(1:5, appear(:fade)),
            SubAction(36:40, disappear(:fade)),
        ]),
        Action(120:150, (args...)->speak("How are you?"); subactions=[
            SubAction(1:5, appear(:fade)),
            SubAction(36:40, disappear(:fade)),
        ])
    ], pathname="jarvis.gif", framerate=15)
end
```




