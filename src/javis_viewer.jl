include("structs/Livestream.jl")

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
        frame_mat = transpose(get_javis_frame(video, objects, frame; layers = video.layers))

        # Gets the correct Canvas context to draw on
        context = getgc(canvas)

        # Uses Cairo to draw on Gtk canvas context
        image(context, CairoImageSurface(frame_mat), 0, 0, img_dims[1], img_dims[2])
    end
end

"""
    _increment(video::Video, widgets::Vector, objects::Vector, dims::Vector,
        canvas::Gtk.Canvas, frames::Int, layers=Vector)

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
        canvas::Gtk.Canvas, frames::Int, layers::Vector)

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

    # Create a Gtk label to print the mouse coordinates upon hover
    mouse_coordinates = GtkLabel("")

    # Button for going forward through animation
    forward = GtkButton("==>")

    # Button for going backward through animation
    backward = GtkButton("<==")

    #=
    TODO: Enable widgets of window to dynamically resize based on user changing the size of a window.
    I think I can use the `configure-event` signal in GTK3 documentation
    (link: https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget-configure-event).
    From there, I can then make a `signal_connect` set-up where I update `set_gtk_property!()`
    of the windows accordingly using `:width_request` and `height_request`.
    =#

    #####################################################################
    # VIEWER CANVAS AND GRID CONFIGURATION
    #####################################################################

    # Gtk Canvas object upon which to draw image; sized via frame size
    canvas = Gtk.Canvas(frame_dims[1], frame_dims[2])

    # Add callback to update mouse corrdinates over canvas
    canvas.mouse.motion = @guarded (widget, event) -> begin
        GAccessor.text(
            mouse_coordinates,
            "$(Int(round(event.x-frame_dims[1]/2))), $(Int(round(event.y-frame_dims[2]/2)))",
        )
    end

    # Grid to allocate widgets
    grid = Gtk.Grid()

    # Allocate the widgets in a 4x3 grid
    grid[1:3, 1] = canvas
    grid[2, 2] = mouse_coordinates
    grid[1:3, 3] = slide
    grid[1, 4] = backward
    grid[2, 4] = tbox
    grid[3, 4] = forward

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
    setup_stream(livestreamto=:local; protocol="udp", address="0.0.0.0", port=14015, twitch_key="")

Sets up the livestream configuration.
**NOTE:** Twitch not fully implemented, do not use.
"""
function setup_stream(
    livestreamto::Symbol = :local;
    protocol::String = "udp",
    address::String = "0.0.0.0",
    port::Int = 14015,
    twitch_key::String = "",
)
    StreamConfig(livestreamto, protocol, address, port, twitch_key)
end

"""
    cancel_stream()

Sends a `SIGKILL` signal to the livestreaming process. Though used internally, it can be used stop streaming.
However this method is not guaranted to end the stream on the client side.
"""
function cancel_stream()
    #todo explore better ways of searching and killing processes

    # kill the ffmpeg process
    # ps aux | grep ffmpeg | grep stream_loop | awk '{print $2}' | xargs kill -9
    try
        println("Checking for existing stream....")
        run(
            pipeline(
                `ps aux`,
                pipeline(`grep ffmpeg`, pipeline(`grep stream_loop`, `awk '{print $2}'`)),
            ),
        )
    catch
        return @warn "Not Streaming Anything Currently"
    end

    run(
        pipeline(
            `ps aux`,
            pipeline(
                `grep ffmpeg`,
                pipeline(`grep stream_loop`, pipeline(`awk '{print $2}'`, `xargs kill -9`)),
            ),
        ),
    )
    return "Livestream Cancelled!"
end

"""
    _livestream(streamconfig, framerate, width, height, pathname)

Internal method for livestreaming 
"""
function _livestream(
    streamconfig::StreamConfig,
    framerate::Int,
    width::Int,
    height::Int,
    pathname::String,
)
    cancel_stream()

    livestreamto = streamconfig.livestreamto
    twitch_key = streamconfig.twitch_key

    if livestreamto == :twitch && isempty(twitch_key)
        return error("Please enter your twitch stream key")
    end

    command = [
        "-stream_loop", # loop the stream -1 times i.e. indefinitely
        "-1",
        "-r", # frames per second
        "$framerate",
        "-an",  # Tells FFMPEG not to expect any audio
        "-loglevel", # show only ffmpeg errors
        "error",
        "-re", # read input at native frame rate
        "-i", # input file
        "$pathname",
    ]

    if livestreamto == :twitch
        if isempty(twitch_key)
            error("Please enter your twitch api key")
        end

        # 
        twitch_cmd = [
            "-f",
            "flv", # force the file to flv format
            "rtmp://live.twitch.tv/app/$twitch_key", # stream to the twitch platform using rtmp protocol
        ]
        push!(command, twitch_cmd...)
        @info "Livestreaming to Twitch!"
    elseif livestreamto == :local
        protocol = streamconfig.protocol
        address = streamconfig.address
        port = streamconfig.port
        local_command = ["-f", "mpegts", "$protocol://$address:$port"] # use an mpeg-ts format, and stream to the given address/port using the protocol
        push!(command, local_command...)
        @info "Livestream Started at $protocol://$address:$port"
    end

    # schedule the streaming process and allow it to run asynchronously
    schedule(@task begin
        ffmpeg_exe(`$command`)
    end)
end

_livestream(
    streamconfig::Nothing,
    framerate::Int,
    width::Int,
    height::Int,
    pathname::String,
) = return
