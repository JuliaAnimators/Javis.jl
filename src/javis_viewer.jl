using Gtk
using GtkReactive

function on_button_clicked(w)
    println("The Button has been clicked!")
end

sl = slider(1:11)
win = GtkWindow("Javis Viewer", 400, 400)
bx = GtkBox(:v)
push!(win, bx)

push!(bx, sl)
tb = textbox(Int; signal = signal(sl))
push!(bx, tb);

Gtk.showall(win)
