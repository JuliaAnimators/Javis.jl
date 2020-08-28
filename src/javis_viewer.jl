using Gtk

function on_button_clicked(w)
    println("The Button has been clicked!")
end

win = GtkWindow("My First GTK.jl Program", 400, 200)

b = GtkButton("Click Me!")
push!(win, b)

signal_connect(on_button_clicked, b, "clicked")

showall(win)
