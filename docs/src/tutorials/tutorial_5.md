# **Tutorial 5:** Scaling the Elements

## Introduction

The world is built up of tiny tiny building blocks known as atoms. ⚛️
These atoms come in many different sizes and each has different properties.
Let's visualize these atoms and show their uniqueness!

## Learning Outcomes 📚

In this tutorial you'll learn:

- How to use `change` to change a variable inside of an animation.
- To use `Javis.jl` to interact with the following Julia packages:
    - [`Unitful.jl`](https://github.com/PainterQubits/Unitful.jl)
    - [`PeriodicTable.jl`](https://github.com/JuliaPhysics/PeriodicTable.jl)

- Ways of creating educational gifs

By the end of this tutorial, you will have made the following animation:

![](assets/atomic.gif)

## `PeriodicTable.jl` and `Unitful.jl`

As normal with our tutorials, we need to import first the packages we will be using.
In this tutorial, we are introducing two new packages:

1. `PeriodicTable.jl` - Periodic table render in Julia
2. `Unitful.jl` - Physical quantities with arbitrary units

These are straightforward to add to your Julia installation by executing the following in your Julia REPL:

```julia
julia> ] add Unitful, PeriodicTable
```

You might be wondering what these packages do.
Let's dive into them then!

`PeriodicTable.jl` enables one to look at information quickly related to the periodic table of elements.
One can even print out such a table in their Julia REPL by doing the following:

```julia
julia> using PeriodicTable

julia> elements
 Elements(…119 elements…):
H                                                  He
Li Be                               B  C  N  O  F  Ne
Na Mg                               Al Si P  S  Cl Ar
K  Ca Sc Ti V  Cr Mn Fe Co Ni Cu Zn Ga Ge As Se Br Kr
Rb Sr Y  Zr Nb Mo Tc Ru Rh Pd Ag Cd In Sn Sb Te I  Xe
Cs Ba    Hf Ta W  Re Os Ir Pt Au Hg Tl Pb Bi Po At Rn
Fr Ra    Rf Db Sg Bh Hs Mt Ds Rg Cn Nh Fl Mc Lv Ts Og
Uue
      La Ce Pr Nd Pm Sm Eu Gd Tb Dy Ho Er Tm Yb Lu
      Ac Th Pa U  Np Pu Am Cm Bk Cf Es Fm Md No Lr
```

As the famous Mythbuster, Adam Savage once said, "IT'S SCIENTIFIC!" 🧪 🤓
One can even query `PeriodicTable` to find out information on specific elements.
Let's look up Oxygen (O) here!

```julia
julia> elements[8]
 Oxygen (O), number 8:
        category: diatomic nonmetal
     atomic mass: 15.999 u
         density: 1.429 g/cm³
   melting point: 54.36 K
   boiling point: 90.188 K
           phase: Gas
          shells: [2, 6]
e⁻-configuration: 1s² 2s² 2p⁴
         summary: Oxygen is a chemical element with symbol O and atomic number 8. It is a member of the chalcogen group on the periodic table and is a highly reactive nonmetal and oxidizing agent that readily forms compounds (notably oxides) with most elements. By mass, oxygen is the third-most abundant element in the universe, after hydrogen and helium.
   discovered by: Carl Wilhelm Scheele
        named by: Antoine Lavoisier
          source: https://en.wikipedia.org/wiki/Oxygen
  spectral image: https://en.wikipedia.org/wiki/File:Oxygen_spectre.jpg
```

As fellow Julian, Johann-Tobias Schäg, said, one should learn `Unitful.jl` if they want to interact with the real world.
`Unitful.jl` handles physical quantities such as pounds, meters, mols, etc. with minimal overhead in Julia.
Further, it helps one to keep track of units and easily convert between different measurement systems.

## Setting Up Our Animation

As always, let's import our needed packages:

```julia
using Animations
using Javis
using PeriodicTable
using Unitful
```

> **NOTE:** For this tutorial, we will also use `Animations.jl` to provide what are called "easing functions".
These are used to control the speed at which an animation is drawn.
This is further explained in [Tutorial 6](tutorial_6.md) so for now, don't worry too much about what we are doing with it. 

And let's define our background function.
This background function will also write the current frame being drawn:

```julia
function ground(video, action, frame)
    background("white")
    sethue("black")
end
```

Finally, let's get started with creating our `render` function:

```julia
demo = Video(500, 500)
Background(1:550, ground)
render(demo, liveview = true, framerate = 10)
```

As you can see, the animation we are creating is going to have many frames!
This is the longest animation we have made so far.
Why?
Not only are we going to examine many different elements, this tutorial also serves to illustrate how one can make longer animations to convey ideas.
Think of it as your directoral debut! 🎬 🎥

## Taming the Elements!

Each element has a different atomic mass.
This atomic mass is measured in the unit called a "Dalton" (symbol: u) which is equivalent to 1/12 of the mass of a stationary carbon-12 atom.
We can use the `change` functionality that `Javis.jl` provides to visualize different elements!

To accomplish this, we need to make a function that shows our currently viewed element:

```julia
function element(; radius = 1, color = "black")
    sethue(color)
    circle(O, radius + 4, :fill) # The 4 is to make the circle not so small
end
```

Essentially, all the `element` function does is create a circle in the middle of the frame with a radius of 5.

From there, we need to define one `Object` for our animation to display the element we are viewing and scaling:

```julia
...
atom = Object(1:550, (args...; radius = 1) -> element(; radius = radius, color = "black"))
act!(
    atom,
    [
        Action(101:140, change(:radius, 1 => 12)),
        Action(241:280, change(:radius, 12 => 20)),
        Action(381:420, change(:radius, 20 => 7)),
        Action(521:550, change(:radius, 7 => 1)),
    ],
)
...
```

`change` is used here to change the given radius of the circle in `element` from `1` to `12`, from `12` to `20`, `20` to `7`, and finally `7` to `1`.
This updates the circle being drawn and gives a growing or shrinking effect.
`change` interpolates the values in between what we want to change the value from to what the value we want to change to. 

That scaling looks like this:

![](assets/blank_atom_scaling.gif)

Staring at this somewhat makes me think of a black hole... ⚫
But great!
The only question now is... What are we looking at?
Let's add some more information to this animation! 📝

## How Much Does an Atom Weigh? ⚖️

To get the information about an element that we are currently previewing, we need to get information about our element.
So, how do we do that?

To identify the element and display its information properly, let's create an info box similar to what we made in [Tutorial 2](tutorial_2.md#As-You-Can-See-Here...)!
We do this by creating an `info_box` function that takes in an element:

```julia
function info_box(element)
    fontsize(12)
    box(140, -210, 170, 40, :stroke)
    box(0, 175, 450, 100, :stroke)
    text("Element name: $(element.name)", 140, -220, valign = :middle, halign = :center)
    text(
        "Atomic Mass: $(round(ustrip(element.atomic_mass)))",
        140,
        -200,
        valign = :middle,
        halign = :center,
    )
    textwrap("Description: $(element.summary)", 400, Point(-200, 125))
end
```

To pass the element into the `info_box` function, we need to define an `Object` command to create our boxes.
Then, we can change the element being passed in:

```julia
...
info = Object(1:550, (args...; elem = 1) -> info_box(element = elements[round(Int, elem)]))

act!(info, Action(1:30, sineio(), appear(:fade)))
act!(info, Action(71:100, sineio(), disappear(:fade)))
act!(info, Action(101:101, change(:elem, 1 => 12)))

act!(info, Action(140:170, sineio(), appear(:fade)))
act!(info, Action(210:241, sineio(), disappear(:fade)))
act!(info, Action(280:280, change(:elem, 12 => 20)))

act!(info, Action(280:310, sineio(), appear(:fade)))
act!(info, Action(350:381, sineio(), disappear(:fade)))
act!(info, Action(381:420, change(:elem, 20 => 7)))

act!(info, Action(420:450, sineio(), appear(:fade)))
act!(info, Action(490:521, sineio(), disappear(:fade)))
act!(info, Action(520:550, change(:elem, 7 => 1)))
...
```

Here, `change` is being used to change the element, `elem`, being queried from `PeriodicTable.jl` over one frame.
This gives us the updated information about each atom!
Furthermore, using the method `appear(:fade)` and `disappear(:fade)` and `sineio()`, we get a nice fading effect to easily transition between each element.

> **NOTE:** `sineio()` comes from `Animations.jl` and is an easing function.
More on this in [Tutorial 6](tutorial_6.md).

Now, let's look at that gif shall we?

![](assets/atomic.gif)

Hooray! 🎉🎉🎉
We now have a very educational gif that tells us all about the elements we are viewing.
We are basically physicists at this point. 😉

## Conclusion

Great work getting through this tutorial!
This tutorial was a little more complicated as you learned the following:

- Using `Javis.jl` to `change` animations in progress
- Having `Javis.jl` interact with other Julia packages
- Creating extended animations for use in education

Our hope with this tutorial is that it inspires you to create more comprehensive and informative animations with `Javis.jl`
Good luck and have fun making more animations!

## Full Code

```julia
using Animations
using Javis
using PeriodicTable
using Unitful

function ground(video, action, frame)
    background("white")
    sethue("black")
end

function element(; radius = 1, color = "black")
    sethue(color)
    circle(O, radius + 4, :fill)
end

function info_box(element)
    fontsize(12)
    box(140, -210, 170, 40, :stroke)
    box(0, 175, 450, 100, :stroke)
    text("Element name: $(element.name)", 140, -220, valign = :middle, halign = :center)
    text(
        "Atomic Mass: $(round(ustrip(element.atomic_mass)))",
        140,
        -200,
        valign = :middle,
        halign = :center,
    )
    textwrap("Description: $(element.summary)", 400, Point(-200, 125))
end

demo = Video(500, 500)

Background(1:550, ground)

atom = Object(1:550, (args...; radius = 1) -> element(; radius = radius, color = "black"))
act!(
    atom,
    [
        Action(101:140, change(:radius, 1 => 12)),
        Action(241:280, change(:radius, 12 => 20)),
        Action(381:420, change(:radius, 20 => 7)),
        Action(521:550, change(:radius, 7 => 1)),
    ],
)

info = Object(1:550, (args...; elem = 1) -> info_box(element = elements[round(Int, elem)]))

act!(info, Action(1:30, sineio(), appear(:fade)))
act!(info, Action(71:100, sineio(), disappear(:fade)))
act!(info, Action(101:101, change(:elem, 1 => 12)))

act!(info, Action(140:170, sineio(), appear(:fade)))
act!(info, Action(210:241, sineio(), disappear(:fade)))
act!(info, Action(280:280, change(:elem, 12 => 20)))

act!(info, Action(280:310, sineio(), appear(:fade)))
act!(info, Action(350:381, sineio(), disappear(:fade)))
act!(info, Action(381:420, change(:elem, 20 => 7)))

act!(info, Action(420:450, sineio(), appear(:fade)))
act!(info, Action(490:521, sineio(), disappear(:fade)))
act!(info, Action(520:550, change(:elem, 7 => 1)))

render(demo, liveview = true, framerate = 10)
```

> **Author(s):** Jacob Zelko \
> **Date:** September 10, 2020 \
> **Tag(s):** change, atoms, elements, appear, disappear, fade, unitful, periodictable
