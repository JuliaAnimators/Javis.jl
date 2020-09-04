using Cairo: CairoImageSurface, image
using Gtk
using GtkReactive
using Javis

# TODO: Finely label each code chunk
# TODO: Better way of getting the get_javis_frame
# TODO: How to send video to Javis viewer from main code
# TODO: Intelligent way of handling slider

###############################################################################
# TODO: Delete this code when ready for adding to main Javis
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

demo = Video(800, 800)
action_list = [
    Action(1:20, ground),
    Action(1:20, :red_ball, (args...) -> circ(p1, "red"), Rotation(from_rot, to_rot)),
    Action(1:20, (args...) -> circ(p2, "blue"), Rotation(to_rot, from_rot, :red_ball)),
]

javis(demo, action_list, pathname = "rotating.gif")

###############################################################################

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

# Get dimensions of frame size corresponding to a javis animation
frame_dims = size(Javis.get_javis_frame(demo, action_list, 1))

# Create GtkWindow for making Javis Viewer based on `frame_dims`
win = GtkWindow("Javis Viewer", frame_dims[1], frame_dims[2])

# Create widgets for Javis Viewer
slide = slider(1:20) # Creates a slider
tbox = GtkReactive.textbox(Int; signal = signal(slide)) # Creates a textbox
forward = GtkButton("==>") # Button for going forward through animation
backward = GtkButton("<==") # Button for going backward through animation

# Setting various properties of the Javis Viewer
set_gtk_property!(win, :title, "Javis Viewer") # Sets title of window
set_gtk_property!(win, :border_width, 20) # Sets border size of window

#=

TODO: Enable widgets of window to dynamically resize based on user changing the size of a window.

I think I can use the `configure-event` signal in GTK3 documentation (link: https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget-configure-event). From there, I can then make a `signal_connect` set-up where I update `set_gtk_property!()` of the windows accordingly using `:width_request` and `height_request`.

=#

# Sets the dimensions of the frame to be displayed.
can = Gtk.Canvas(frame_dims[1], frame_dims[2])

g1 = Gtk.Grid() # Grid to allocate widgets

# Allocate the widgets in the grid.
g1[1:3, 1] = can
g1[1:3, 2] = slide
g1[1, 3] = backward
g1[2, 3] = tbox
g1[3, 3] = forward

# Set properties of the grid
set_gtk_property!(g1, :valign, 4) # center all elements in vertical
set_gtk_property!(g1, :halign, 4) # center all elements in horizontal
set_gtk_property!(g1, :column_homogeneous, true) # center all elements in vertical

push!(win, g1)

#####################################################################
# SIGNAL CONNECTION FUNCTIONS
#####################################################################

# When the `Enter` key is pressed, update the frame
signal_connect(win, "key-press-event") do widget, event
    mystring = get_gtk_property(tbox, :text, String)
    if event.keyval == 65293
        @guarded draw(can) do widget
            # Gets a Javis frame to display based on textbox entry
            frame_mat = Javis.get_javis_frame(demo, action_list, parse(Int, mystring))
            # Gets the correct Canvas context to draw on
            context = getgc(can)
            image(
                context,
                CairoImageSurface(frame_mat),
                0,
                0,
                frame_dims[1],
                frame_dims[2],
            )
        end
    end
end

# When the `forward` button is clicked, increment the current frame number
signal_connect(forward, "clicked") do widget
    curr_frame = parse(Int, get_gtk_property(tbox, :text, String))
    push!(slide, curr_frame + 1)
    @guarded draw(can) do widget
        frame_mat = Javis.get_javis_frame(demo, action_list, curr_frame + 1)
        context = getgc(can)
        image(
            context,
            CairoImageSurface(frame_mat),
            0,
            0,
            frame_dims[1],
            frame_dims[2],
        )
    end
end

# When the `forward` button is clicked, decrement the current frame number
signal_connect(backward, "clicked") do widget
    curr_frame = parse(Int, get_gtk_property(tbox, :text, String))
    push!(slide, curr_frame - 1)
    @guarded draw(can) do widget
        frame_mat = Javis.get_javis_frame(demo, action_list, curr_frame - 1)
        context = getgc(can)
        image(
            context,
            CairoImageSurface(frame_mat),
            0,
            0,
            frame_dims[1],
            frame_dims[2],
        )
    end
end

#####################################################################

Gtk.showall(win)
