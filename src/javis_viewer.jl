using Gtk
using GtkReactive
using GtkUtilities

function on_button_clicked(w)
    println("The Button has been clicked!")
end

mycanvas = @GtkCanvas()
sl = slider(1:11)
win = GtkWindow("Javis Viewer", 400, 400)
bx = GtkBox(:v)
push!(win, bx)

push!(bx, sl)
tb = textbox(Int; signal = signal(sl))

@guarded Gtk.draw(mycanvas) do widget
    ctx = Gtk.getgc(mycanvas)
    GtkUtilities.copy!(ctx, "/home/src/Projects/javis/src/hug_emoji.jpg")
end

push!(bx, tb);

Gtk.showall(win)
