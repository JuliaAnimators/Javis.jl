# **Tutorial 9:** Morphing `Javis` Objects   

There are multiple ways to morph an object in Javis.

- Using the older `morph_to(::Function)` method. Very nice at matching the shapes for morphing . Has limitations on what the morphing function should contain.
- Using (New) `morph_to(::Object)` method. Any Object can be morphed to any other object using this method.
- Using `morph_to_fn(::Function)` method. Similar to `morph_to(::Object)` but morphs to function instead. Can morph an object to a function that contains Luxor calls to draw what it should morphed into.
- Specifying an Action with interpolating Animation along with `morph()`

This tutorial will focus on the last three.

## Morphing one object to another.

Like other animations `morph_to(::Object)` is to be used with action. To learn more about Actions refer to [Tutorial 5](tutorial_5.md)
Here is a simple code snippet on how to use `morph_to`
```julia
using Javis

video = Video(500,500)
nframes = 160 

function circdraw(colo)
    sethue(colo)
    circle(O,100,:fillpreserve)
    setopacity(0.5)
    sethue("white")
    strokepath()
end

function boxdraw(colo)
    sethue(colo)
    box(O,100,100,:fillpreserve)
    setopacity(1.0)
    sethue("white")
    strokepath()
end
Background(1:nframes,(args...)->background("black"))
circobj = Object((v,o,f) -> circdraw("red"))
boxobj  = Object((v,o,f) -> boxdraw("green"))

transform_to_box = Action(20:nframes-20, morph_to(boxobj))
act!(circobj, transform_to_box)
render(video,pathname="circ_to_box.gif")
```
![](assets/circ_to_box.gif)
We created two objects `circobj` and `boxobj` . `circobj` ofcourse is a circle and `boxobj` is a box.
if you aren't familiar with this syntax `(v,o,f)-> circdraw("red")` its an "anonymous" function or sometimes called a lambda function.
Basically a nameless function that is written on the spot in that line of code . One might aswell use any other function `f` in place of it
(which takes atleast 3 arguments v,o,f). Elsewhere in the docs/tutorials you will come across
something of the form `Object( (args...) -> (some;code;here) )`. This is [splatting](https://docs.julialang.org/en/v1/manual/faq/#The-two-uses-of-the-...-operator:-slurping-and-splatting) and is similar to packing `*args` in python. 

This Object function is called repeatedly at render-time at every frame that the object exists to draw this object. The apropriate `video`,`object`, and `frame` are passed to
this function at render time.
Javis then has other tricks up its sleave to scale/move/morph whats going to be drawn depending on the
frame and object to effect out animations through Actions. This is roughly the idea behind Javis's Object-Action mechanism

Couple of things to note the `boxobj` is present throughout as the circobj is morphing.
if you want to hide it you can by setting its opacity to 0 with another action (to make it disappear) and make it appear only for 1 frame (for efficiency).
However you can directly specify a shape an object has to morph to without making an Object , using `morph_to_fn` which is explained later in this tutorial.


