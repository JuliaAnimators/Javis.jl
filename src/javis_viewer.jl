using Gtk
using GtkReactive

win = GtkWindow("Javis Viewer", 400, 400)

# Frame to set a specific size on the win.
fimg = Frame()
set_gtk_property!(fimg, :height_request, 341) # 341 px according to image size
set_gtk_property!(fimg, :width_request, 512) # the same

img = Image()
b1 = Button("Show Image")
b2 = Button("Clear Image")

input = GtkEntry()
set_gtk_property!(input, :text, "")

signal_connect(b1, :clicked) do widget
    set_gtk_property!(img, :file, "/home/src/Projects/javis/src/question_emoji.png")
end

signal_connect(b2, :clicked) do widget
    empty!(img)
end

signal_connect(win, "key-press-event") do widget, event
    mystring = get_gtk_property(tb, :text, String)
    if event.keyval == 65293
        println(mystring)
        # signal_emit(sl, 5)
    end
end

g1 = Grid() # Grid to allocate widgets
set_gtk_property!(g1, :valign, 4) # center all elements in vertical
set_gtk_property!(g1, :halign, 4) # center all elements in horizontal

# attach image to frame
push!(fimg, img)

sl = slider(1:11)
tb = textbox(Int; signal=signal(sl))

# Allocate the widgets in the grid.
g1[1:2,1] = fimg
g1[1,2] = b1
g1[2,2] = b2
g1[1:2, 3] = sl
g1[1:2, 4] = tb

push!(win, g1)

Gtk.showall(win)
