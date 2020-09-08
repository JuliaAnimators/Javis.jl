# TODO: Intelligent way of handling slider

function _draw_image(
    video::Video,
    actions::Vector,
    frame::Int,
    canvas::Gtk.Canvas,
    img_dims::Vector,
)
    # Gets the next Javis frame based on textbox entry
    frame_mat = transpose(get_javis_frame(video, actions, frame))
    # Gets the correct Canvas context to draw on
    context = getgc(canvas)
    image(context, CairoImageSurface(frame_mat), 0, 0, img_dims[1], img_dims[2])
end

function _javis_viewer(video::Video, frames::Int, action_list::Vector)

    #####################################################################
    # VIEWER WINDOW AND CONFIGURATION
    #####################################################################

    frame_dims = [video.width, video.height]
    win = GtkWindow("Javis Viewer", frame_dims[1], frame_dims[2])

    set_gtk_property!(win, :title, "Javis Viewer") # Sets title of window
    set_gtk_property!(win, :border_width, 20) # Sets border size of window

    #####################################################################
    # DISPLAY WIDGETS
    #####################################################################

    slide = slider(1:frames) # Creates a slider
    tbox = GtkReactive.textbox(Int; signal = signal(slide)) # Creates a textbox
    push!(tbox, 1) # Sets the first frame shown to one

    forward = GtkButton("==>") # Button for going forward through animation
    backward = GtkButton("<==") # Button for going backward through animation

    #=

    TODO: Enable widgets of window to dynamically resize based on user changing the size of a window.

    I think I can use the `configure-event` signal in GTK3 documentation (link: https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget-configure-event). From there, I can then make a `signal_connect` set-up where I update `set_gtk_property!()` of the windows accordingly using `:width_request` and `height_request`.

    =#

    #####################################################################
    # VIEWER CANVAS AND GRID CONFIGURATION
    #####################################################################

    canvas = Gtk.Canvas(frame_dims[1], frame_dims[2]) # Frame size to be displayed.
    grid = Gtk.Grid() # Grid to allocate widgets

    # Allocate the widgets in the grid.
    grid[1:3, 1] = canvas
    grid[1:3, 2] = slide
    grid[1, 3] = backward
    grid[2, 3] = tbox
    grid[3, 3] = forward

    # Set properties of the grid
    set_gtk_property!(grid, :valign, 4) # center all elements in vertical
    set_gtk_property!(grid, :halign, 4) # center all elements in horizontal
    set_gtk_property!(grid, :column_homogeneous, true) # center all elements in vertical

    push!(win, grid) # Adds grid to current window

    #####################################################################
    # DISPLAY FIRST FRAME
    #####################################################################

    mystring = get_gtk_property(tbox, :text, String)
    @guarded draw(canvas) do widget
        # Gets the first Javis frame
        frame_mat = transpose(get_javis_frame(video, action_list, 1))
        # Gets the correct Canvas context to draw on
        context = getgc(canvas)
        image(context, CairoImageSurface(frame_mat), 0, 0, frame_dims[1], frame_dims[2])
    end

    #####################################################################
    # SIGNAL CONNECTION FUNCTIONS
    #####################################################################

    # When the `Enter` key is pressed, update the frame
    signal_connect(win, "key-press-event") do widget, event
        curr_frame = parse(Int, get_gtk_property(tbox, :text, String))
        if curr_frame > frames && curr_frames < 1
            if event.keyval == 65293
                @guarded draw(canvas) do widget
                    _draw_image(video, action_list, curr_frame, canvas, frame_dims)
                end
            end
        elseif curr_frame > frames
            if event.keyval == 65293
                @guarded draw(canvas) do widget
                    _draw_image(video, action_list, frames, canvas, frame_dims)
                end
            end
        elseif curr_frame < frames
            if event.keyval == 65293
                @guarded draw(canvas) do widget
                    _draw_image(video, action_list, 1, canvas, frame_dims)
                end
            end
        end
    end

    # When the `forward` button is clicked, increment current frame number
    signal_connect(forward, "clicked") do widget
        curr_frame = parse(Int, get_gtk_property(tbox, :text, String))
        if frames > curr_frame
            push!(slide, curr_frame + 1)
            @guarded draw(canvas) do widget
                _draw_image(video, action_list, curr_frame + 1, canvas, frame_dims)
            end
        else
            push!(tbox, 1) # Sets the first frame shown to one
            @guarded draw(canvas) do widget
                _draw_image(video, action_list, 1, canvas, frame_dims)
            end
        end
    end


    # When the `Right Arrow` key is pressed, increment current frame number
    signal_connect(win, "key-press-event") do widget, event
        if event.keyval == 65363
            curr_frame = parse(Int, get_gtk_property(tbox, :text, String))
            if frames > curr_frame
                push!(slide, curr_frame + 1)
                @guarded draw(canvas) do widget
                    _draw_image(video, action_list, curr_frame + 1, canvas, frame_dims)
                end
            else
                push!(tbox, 1) # Sets the first frame shown to one
                @guarded draw(canvas) do widget
                    _draw_image(video, action_list, 1, canvas, frame_dims)
                end
            end
        end
    end

    # When the `backward` button is clicked, decrement the current frame number
    signal_connect(backward, "clicked") do widget
        curr_frame = parse(Int, get_gtk_property(tbox, :text, String))
        if curr_frame > 1
            push!(slide, curr_frame - 1)
            @guarded draw(canvas) do widget
                _draw_image(video, action_list, curr_frame - 1, canvas, frame_dims)
            end
        else
            push!(tbox, frames) # Sets the end frame to the max number of frames
            @guarded draw(canvas) do widget
                _draw_image(video, action_list, frames, canvas, frame_dims)
            end
        end
    end

    # When the `Left Arrow` key is pressed, decrement current frame number
    signal_connect(win, "key-press-event") do widget, event
        if event.keyval == 65361
            curr_frame = parse(Int, get_gtk_property(tbox, :text, String))
            if curr_frame > 1
                push!(slide, curr_frame - 1)
                @guarded draw(canvas) do widget
                    _draw_image(video, action_list, curr_frame - 1, canvas, frame_dims)
                end
            else
                push!(tbox, frames) # Sets the first frame shown to one
                @guarded draw(canvas) do widget
                    _draw_image(video, action_list, frames, canvas, frame_dims)
                end
            end
        end
    end

    #####################################################################

    # Display image viewer
    Gtk.showall(win)

end
