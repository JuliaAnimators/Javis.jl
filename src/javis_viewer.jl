"""
    _draw_image(video::Video, actions::Vector, frame::Int, canvas::Gtk.Canvas,
    img_dims::Vector)

Internal function to create an image that is drawn on a Gtk Canvas.
"""
function _draw_image(
    video::Video,
    actions::Vector,
    frame::Int,
    canvas::Gtk.Canvas,
    img_dims::Vector,
)
    # Gets a specific frame from graphic; transposed due to returned matrix
    frame_mat = transpose(get_javis_frame(video, actions, frame))

    # Gets the correct Canvas context to draw on
    context = getgc(canvas)

    # Uses Cairo to draw on Gtk canvas context
    image(context, CairoImageSurface(frame_mat), 0, 0, img_dims[1], img_dims[2])
end

"""
     _javis_viewer(video::Video, frames::Int, action_list::Vector)

Internal Javis Viewer built on Gtk that is called for live previewing.
"""
function _javis_viewer(video::Video, frames::Int, action_list::Vector)

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
    _slide = GtkScale(false, 1:frames)

    # Create GtkReactive slider widget
    slide = slider(1:frames, value = 1, widget = _slide)

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
    tbox = GtkReactive.textbox(Int; signal = signal(slide)) # Creates a textbox

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

    # Draws image
    @guarded draw(canvas) do widget
        _draw_image(video, action_list, 1, canvas, frame_dims)
    end

    #####################################################################
    # SIGNAL CONNECTION FUNCTIONS
    #####################################################################

    # When the slider is changed, update currently viewed frame
    signal_connect(_slide, "value-changed") do widget
        # Draws current frame
        @guarded draw(canvas) do widget
            # Collects GtkScale as an adjustable bounded value object
            bound_slide = Gtk.GAccessor.adjustment(_slide)

            # Get frame number from bounded value object as Int
            slide_val = Gtk.get_gtk_property(bound_slide, "value", Int)

            _draw_image(video, action_list, slide_val, canvas, frame_dims)
        end
    end

    # When the `Enter` key is pressed, update the frame
    signal_connect(win, "key-press-event") do widget, event
        if event.keyval == 65293
            # Get current frame from textbox as an Int value
            curr_frame = parse(Int, get_gtk_property(tbox, :text, String))
            if 1 <= curr_frame && curr_frame <= frames
                # Draws current frame
                @guarded draw(canvas) do widget
                    _draw_image(video, action_list, curr_frame, canvas, frame_dims)
                end
            elseif curr_frame > frames
                # Draws current frame
                @guarded draw(canvas) do widget
                    _draw_image(video, action_list, frames, canvas, frame_dims)
                end
            elseif curr_frame < frames
                # Draws current frame
                @guarded draw(canvas) do widget
                    _draw_image(video, action_list, 1, canvas, frame_dims)
                end
            end
        end
    end

    # When the `forward` button is clicked, increment current frame number
    # If at final frame, wrap viewer to first frame
    signal_connect(forward, "clicked") do widget
        # Get current frame from textbox as an Int value
        curr_frame = parse(Int, get_gtk_property(tbox, :text, String))
        if frames > curr_frame
            # Increments the slider by 1
            push!(slide, curr_frame + 1)

            # Draws current frame
            @guarded draw(canvas) do widget
                _draw_image(video, action_list, curr_frame + 1, canvas, frame_dims)
            end
        else
            # If at final frame, wrap viewer to first frame
            push!(tbox, 1)

            # Draws current frame
            @guarded draw(canvas) do widget
                _draw_image(video, action_list, 1, canvas, frame_dims)
            end
        end
    end

    # When the `Right Arrow` key is pressed, increment current frame number
    # If at final frame, wrap viewer to first frame
    signal_connect(win, "key-press-event") do widget, event
        if event.keyval == 65363
            # Get current frame from textbox as an Int value
            curr_frame = parse(Int, get_gtk_property(tbox, :text, String))
            if frames > curr_frame
                # Increments the slider by 1
                push!(slide, curr_frame + 1)

                # Draws current frame
                @guarded draw(canvas) do widget
                    _draw_image(video, action_list, curr_frame + 1, canvas, frame_dims)
                end
            else
                # Sets the first frame shown to one
                push!(tbox, 1)

                # Draws current frame
                @guarded draw(canvas) do widget
                    _draw_image(video, action_list, 1, canvas, frame_dims)
                end
            end
        end
    end

    # When the `backward` button is clicked, decrement the current frame number
    # If at first frame, wrap viewer to last frame
    signal_connect(backward, "clicked") do widget
        # Get current frame from textbox as an Int value
        curr_frame = parse(Int, get_gtk_property(tbox, :text, String))
        if curr_frame > 1
            # Decrements the slider by 1
            push!(slide, curr_frame - 1)

            # Draws current frame
            @guarded draw(canvas) do widget
                _draw_image(video, action_list, curr_frame - 1, canvas, frame_dims)
            end
        else
            # Sets the end frame to the max number of frames
            push!(tbox, frames)

            # Draws current frame
            @guarded draw(canvas) do widget
                _draw_image(video, action_list, frames, canvas, frame_dims)
            end
        end
    end

    # When the `Left Arrow` key is pressed, decrement current frame number
    # If at first frame, wrap viewer to last frame
    signal_connect(win, "key-press-event") do widget, event
        if event.keyval == 65361
            # Get current frame from textbox as an Int value
            curr_frame = parse(Int, get_gtk_property(tbox, :text, String))
            if curr_frame > 1
                push!(slide, curr_frame - 1)
                # Draws current frame
                @guarded draw(canvas) do widget
                    _draw_image(video, action_list, curr_frame - 1, canvas, frame_dims)
                end
            else
                push!(tbox, frames) # Sets the first frame shown to one
                # Draws current frame
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
