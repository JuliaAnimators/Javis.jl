"""
    _draw_image(video::Video, objects::Vector, frame::Int, canvas::Gtk.Canvas,
    img_dims::Vector)

Internal function to create an image that is drawn on a Gtk Canvas.
"""
function _draw_image(
    video::Video,
    objects::Vector,
    frame::Int,
    canvas::Gtk.Canvas,
    img_dims::Vector,
)
    @guarded draw(canvas) do widget
        # Gets a specific frame from graphic; transposed due to returned matrix
        frame_mat = transpose(get_javis_frame(video, objects, frame))

        # Gets the correct Canvas context to draw on
        context = getgc(canvas)

        # Uses Cairo to draw on Gtk canvas context
        image(context, CairoImageSurface(frame_mat), 0, 0, img_dims[1], img_dims[2])
    end
end

"""
    _increment(video::Video, widgets::Vector, objects::Vector, dims::Vector,
        canvas::Gtk.Canvas, frames::Int)

Increments a given value and returns the associated frame.
"""
function _increment(
    video::Video,
    widgets::Vector,
    objects::Vector,
    dims::Vector,
    canvas::Gtk.Canvas,
    frames::Int,
)
    # Get current frame from textbox as an Int value
    curr_frame = parse(Int, get_gtk_property(widgets[2], :text, String))
    if frames > curr_frame
        # `widgets[1]` represents the GtkReactive slider widget
        push!(widgets[1], curr_frame + 1)
        _draw_image(video, objects, curr_frame + 1, canvas, dims)
    else
        # `widgets[2]` represents the GtkReactive textboxwidget
        push!(widgets[2], 1) # Sets the first frame shown to one
        _draw_image(video, objects, 1, canvas, dims)
    end
end

"""
    _decrement(video::Video, widgets::Vector, objects::Vector, dims::Vector,
        canvas::Gtk.Canvas, frames::Int)

Decrements a given value and returns the associated frame.
"""
function _decrement(
    video::Video,
    widgets::Vector,
    objects::Vector,
    dims::Vector,
    canvas::Gtk.Canvas,
    frames::Int,
)
    # Get current frame from textbox as an Int value
    curr_frame = parse(Int, get_gtk_property(widgets[2], :text, String))
    if curr_frame > 1
        # `widgets[1]` represents the GtkReactive slider widget
        push!(widgets[1], curr_frame - 1)
        _draw_image(video, objects, curr_frame - 1, canvas, dims)
    else
        # `widgets[2]` represents the GtkReactive textboxwidget
        push!(widgets[2], frames) # Sets the first frame shown to one
        _draw_image(video, objects, frames, canvas, dims)
    end
end

"""
     _javis_viewer(video::Video, frames::Int, object_list::Vector, show::Bool)

Internal Javis Viewer built on Gtk that is called for live previewing.
"""
function _javis_viewer(
    video::Video,
    total_frames::Int,
    object_list::Vector,
    show::Bool = true,
)
    #####################################################################
    # VIEWER WINDOW AND CONFIGURATION
    #####################################################################

    # Determine frame size of animation
    frame_dims = [video.width, video.height]

    # Creates a GTK window for drawing; sized based on frame size
    win = GtkWindow("Javis Viewer", frame_dims[1], frame_dims[2])

    # Sets border size of window
    set_gtk_property!(win, :border_width, 20)

    #####################################################################
    # DISPLAY WIDGETS
    #####################################################################

    # Create GtkScale internal widget
    _slide = GtkScale(false, 1:total_frames)

    # Create GtkReactive slider widget
    slide = slider(1:total_frames, value = 1, widget = _slide)

    #=
    #
    # NOTE: We must provide a named GtkScale widget named `_slide` to the
    # GtkReactive `slider` widget so as to perform asynchronous calls
    # via signal_connect. Otherwise, we will be unable to update the
    # widget that is automatically created by the slider object.
    #
    # It should be stated that a `slider` object is essentially a
    # GtkScale widget coupled with a Reactive object.
    #
    =#

    # Create a textbox
    tbox = GtkReactive.textbox(Int; signal = signal(slide))

    # Button for going forward through animation
    forward = GtkButton("==>")

    # Button for going backward through animation
    backward = GtkButton("<==")

    #=

    TODO: Enable widgets of window to dynamically resize based on user changing the size of a window.

    I think I can use the `configure-event` signal in GTK3 documentation (link: https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget-configure-event). From there, I can then make a `signal_connect` set-up where I update `set_gtk_property!()` of the windows accordingly using `:width_request` and `height_request`.

    =#

    #####################################################################
    # VIEWER CANVAS AND GRID CONFIGURATION
    #####################################################################

    # Gtk Canvas object upon which to draw image; sized via frame size
    canvas = Gtk.Canvas(frame_dims[1], frame_dims[2])

    # Grid to allocate widgets
    grid = Gtk.Grid()

    # Allocate the widgets in a 3x3 grid
    grid[1:3, 1] = canvas
    grid[1:3, 2] = slide
    grid[1, 3] = backward
    grid[2, 3] = tbox
    grid[3, 3] = forward

    # Center all widgets vertically in grid
    set_gtk_property!(grid, :valign, 3)

    # Center all widgets horizontally in grid
    set_gtk_property!(grid, :halign, 3)

    # Adds grid to previously defined window
    push!(win, grid)

    #####################################################################
    # DISPLAY FIRST FRAME
    #####################################################################

    _draw_image(video, object_list, 1, canvas, frame_dims)

    #####################################################################
    # SIGNAL CONNECTION FUNCTIONS
    #####################################################################

    # When the slider is changed, update currently viewed frame
    signal_connect(_slide, "value-changed") do widget
        # Collects GtkScale as an adjustable bounded value object
        bound_slide = Gtk.GAccessor.adjustment(_slide)

        # Get frame number from bounded value object as Int
        slide_val = Gtk.get_gtk_property(bound_slide, "value", Int)

        _draw_image(video, object_list, slide_val, canvas, frame_dims)
    end

    # When the `Enter` key is pressed, update the frame
    signal_connect(win, "key-press-event") do widget, event
        if event.keyval == 65293
            # Get current frame from textbox as an Int value
            curr_frame = parse(Int, get_gtk_property(tbox, :text, String))
            curr_frame = clamp(curr_frame, 1, total_frames)
            _draw_image(video, object_list, curr_frame, canvas, frame_dims)
        end
    end

    # When the `forward` button is clicked, increment current frame number
    # If at final frame, wrap viewer to first frame
    signal_connect(forward, "clicked") do widget
        _increment(video, [slide, tbox], object_list, frame_dims, canvas, total_frames)
    end

    # When the `Right Arrow` key is pressed, increment current frame number
    # If at final frame, wrap viewer to first frame
    signal_connect(win, "key-press-event") do widget, event
        if event.keyval == 65363
            _increment(video, [slide, tbox], object_list, frame_dims, canvas, total_frames)
        end
    end

    # When the `backward` button is clicked, decrement the current frame number
    # If at first frame, wrap viewer to last frame
    signal_connect(backward, "clicked") do widget
        _decrement(video, [slide, tbox], object_list, frame_dims, canvas, total_frames)
    end

    # When the `Left Arrow` key is pressed, decrement current frame number
    # If at first frame, wrap viewer to last frame
    signal_connect(win, "key-press-event") do widget, event
        if event.keyval == 65361
            _decrement(video, [slide, tbox], object_list, frame_dims, canvas, total_frames)
        end
    end

    #####################################################################

    if show
        # Display image viewer
        Gtk.showall(win)
    else
        return win, frame_dims, slide, tbox, canvas, object_list, total_frames, video
    end

end

"""
_jupyter_viewer(video::Video, frames::Int, actions::Vector)

Creates an interactive viewer in a Jupyter Notebook.
"""
function _jupyter_viewer(video::Video, frames::Int, objects::Vector)
    t = Interact.textbox([1:frames], value = 1)
    f = Interact.slider(1:frames, label = "Frame", value = t)
    output = @map get_javis_frame(video, objects, &f)
    wdg = Widget(["f" => f, "t" => t], output = output)
    @layout! wdg vbox(hbox(:f, :t), output)
end
