using Gtk
using GtkReactive
using Javis
using Cairo

# TODO: Finely label each code chunk
# TODO: Modularize code into functions
# TODO: Explore `hexpand` and `vexpand` and `expand` key words
# TODO: Intelligent way of handling slider

function ground(args...)
    background("white")
    sethue("black")
end

function circ(p = O, color = "black")
    sethue(color)
    Javis.circle(p, 25, :fill)
    return Transformation(p, 0.0)
end

from = Javis.Point(-200, -200)
to = Javis.Point(-20, -130)
p1 = Javis.Point(0, -100)
p2 = Javis.Point(0, -50)
from_rot = 0.0
to_rot = 2π

#=
FIXME:
Fascinating bug I found.
Apparently to create a list of actions anywhere, you must first define a Video object.
Else, you get an error like this:

```
ERROR: LoadError: BoundsError: attempt to access 0-element Array{Video,1} at index [1]
Stacktrace:
 [1] getindex at ./array.jl:809 [inlined]
 [2] Action(::UnitRange{Int64}, ::Nothing, ::Function; kwargs::Base.Iterators.Pairs{Union{},Union{},Tuple{},NamedTuple{(),Tuple{}}}) at /home/src/Projects/javis/src/Javis.jl:397
 [3] Action at /home/src/Projects/javis/src/Javis.jl:397 [inlined]
 [4] #Action#3 at /home/src/Projects/javis/src/Javis.jl:350 [inlined]
 [5] Action(::UnitRange{Int64}, ::Function) at /home/src/Projects/javis/src/Javis.jl:350
 [6] top-level scope at /home/src/Projects/javis/src/javis_viewer.jl:34
 [7] include(::String) at ./client.jl:457
 [8] top-level scope at REPL[1]:1
in expression starting at /home/src/Projects/javis/src/javis_viewer.jl:34
```

=#

demo = Video(800, 800)
action_list = [
    Action(1:20, ground),
    Action(1:20, :red_ball, (args...) -> circ(p1, "red"), Rotation(from_rot, to_rot)),
    Action(1:20, (args...) -> circ(p2, "blue"), Rotation(to_rot, from_rot, :red_ball)),
]

javis(demo, action_list, pathname = "rotating.gif")

frame_dims = size(Javis.get_javis_frame(demo, action_list, 1))

#=

TODO:
Discuss with Ole about reasonable defaults for generating the dimensions of a image viewer.

=#

win = GtkWindow("Javis Viewer", frame_dims[1] + 100, frame_dims[2] + 100)

fimg = Gtk.Canvas(frame_dims[1], frame_dims[2])
# set_gtk_property!(fimg, :width_request, frame_dims[1])
# set_gtk_property!(fimg, :height_request, frame_dims[2])
# img = Gtk.Image()

signal_connect(win, "key-press-event") do widget, event
    mystring = get_gtk_property(tb, :text, String)
    if event.keyval == 65293
        @guarded draw(fimg) do widget
            frame_mat = Javis.get_javis_frame(demo, action_list, parse(Int, mystring))
            frame_mat = convert.(Cairo.ARGB32, frame_mat)
            ctx = getgc(fimg)
            image(
                ctx,
                CairoImageSurface(frame_mat),
                0,
                0,
                frame_dims[1] + 100,
                frame_dims[2] + 100,
            )
        end
    end
end


# NOTE: To put an image into a frame, `push!()` it into it!

g1 = Gtk.Grid() # Grid to allocate widgets

sl = slider(1:20)
tb = GtkReactive.textbox(Int; signal = signal(sl))
forward = GtkButton("==>")
backward = GtkButton("<==")

fast_forward = GtkButton(">>>")
rewind = GtkButton("<<<")

signal_connect(forward, "clicked") do widget
    curr_frame = parse(Int, get_gtk_property(tb, :text, String))
    push!(sl, curr_frame + 1)
    @guarded draw(fimg) do widget
        frame_mat = Javis.get_javis_frame(demo, action_list, curr_frame + 1)
        frame_mat = convert.(Cairo.ARGB32, frame_mat)
        ctx = getgc(fimg)
        image(
            ctx,
            CairoImageSurface(frame_mat),
            0,
            0,
            frame_dims[1] + 100,
            frame_dims[2] + 100,
        )
    end
end

signal_connect(backward, "clicked") do widget
    curr_frame = parse(Int, get_gtk_property(tb, :text, String))
    push!(sl, curr_frame - 1)
    @guarded draw(fimg) do widget
        frame_mat = Javis.get_javis_frame(demo, action_list, curr_frame - 1)
        frame_mat = convert.(Cairo.ARGB32, frame_mat)
        ctx = getgc(fimg)
        image(
            ctx,
            CairoImageSurface(frame_mat),
            0,
            0,
            frame_dims[1] + 100,
            frame_dims[2] + 100,
        )
    end
end

# Allocate the widgets in the grid.
g1[1:3, 1] = fimg
g1[1:3, 2] = sl
g1[1, 3] = backward
g1[2, 3] = tb
g1[3, 3] = forward

set_gtk_property!(g1, :valign, 4) # center all elements in vertical
set_gtk_property!(g1, :halign, 4) # center all elements in horizontal
set_gtk_property!(g1, :column_homogeneous, true) # center all elements in vertical

push!(win, g1)

Gtk.showall(win)
