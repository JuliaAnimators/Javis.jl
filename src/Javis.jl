module Javis

using Animations
import Cairo: CairoImageSurface, image
using FFMPEG
using Gtk
using GtkReactive
using Hungarian
using Images
import Interact
import Interact: @map, Widget, Widgets, @layout!, hbox, vbox # not exporting textbox & slider due to possible conflicts with Gtk & luxor
using LaTeXStrings
using LightXML
import Luxor
import Luxor: Point, @layer, translate, rotate, @imagematrix
using ProgressMeter
using Random
using Statistics
using VideoIO

const FRAMES_SYMBOL = [:same, :all]

abstract type AbstractAction end
abstract type AbstractObject end
abstract type AbstractTransition end

include("structs/Video.jl")
include("structs/Easing.jl")
include("structs/RFrames.jl")
include("structs/GFrames.jl")
include("structs/Frames.jl")
include("structs/Scale.jl")

"""
    Transformation

Defines a transformation which can be returned by an object to be accessible later.
This is further explained in the Javis tutorials.

# Fields
- `point::Point`: the translation part of the transformation
- `angle::Float64`: the angle component of the transformation (in radians)
- `scale::Tuple{Float64, Float64}`: the scaling component of the transformation
"""
struct Transformation
    point::Point
    angle::Float64
    scale::Scale
end

Transformation(p, a) = Transformation(p, a, 1.0)
Transformation(p, a, s::Float64) = Transformation(p, a, (s, s))
Transformation(p, a, s::Tuple{Float64,Float64}) = Transformation(p, a, Scale(s...))

include("structs/ObjectSetting.jl")
include("structs/Object.jl")
include("structs/Transitions.jl")
include("structs/Action.jl")
include("structs/LayerSetting.jl")
include("structs/Layer.jl")


"""
    Line

A type to define a line by two points. Can be used i.e. in [`projection`](@ref)
We mean the mathematic definition of a continuous line and not a segment of a line.

# Fields
- `p1::Point`: start point
- `p2::Point`: second point to define the line
"""
struct Line
    p1::Point
    p2::Point
end

"""
    Base.:*(m::Array{Float64,2}, transformation::Transformation)

Convert the transformation to a matrix and multiplies m*trans_matrix.
Return a new Transformation
"""
function Base.:*(m::Array{Float64,2}, transformation::Transformation)
    p = transformation.point
    θ = transformation.angle
    s = transformation.scale
    trans_matrix = [
        s.x*cos(θ) -sin(θ) p.x
        sin(θ) s.y*cos(θ) p.y
        0 0 1
    ]
    res = m * trans_matrix
    return Transformation(Point(gettranslation(res)...), getrotation(res), getscale(res))
end

include("util.jl")
include("luxor_overrides.jl")
include("backgrounds.jl")
include("svg2luxor.jl")
include("morphs.jl")
include("action_animations.jl")
include("javis_viewer.jl")
include("latex.jl")
include("object_values.jl")
include("layer_values.jl")

"""
    projection(p::Point, l::Line)

Return the projection of a point to a line.
"""
function projection(p::Point, l::Line)
    # move line to origin and describe it as a vector
    o = l.p1
    v = l.p2 - o
    # point also moved to origin
    x = p - o

    # scalar product <x,v>/<v,v>
    c = (x.x * v.x + x.y * v.y) / (v.x^2 + v.y^2)
    return c * v + o
end

"""
    preprocess_frames!(objects::Vector{<:AbstractObject})

Computes the frames for each object(of both main canvas and layers) and action based on the user defined frames that the
user can provide like [`RFrames`](@ref), [`GFrames`](@ref) and `:same`.

This function needs to be called before calling [`get_javis_frame`](@ref) as it computes
the actual frames for objects and actions.

# Returns
- `frames::Array{Int}` - list of all frames normally 1:...

# Warning
Shows a warning if some frames don't have a background.
"""
function preprocess_frames!(objects::Vector{<:AbstractObject})
    compute_frames!(objects)

    for (i, object) in enumerate(objects)
        compute_frames!(object.actions; parent = object, parent_counter = i)
    end

    # get all frames
    frames = Int[]
    for object in objects
        append!(frames, collect(get_frames(object)))
    end
    frames = unique(frames)
    if !(frames ⊆ CURRENT_VIDEO[1].background_frames)
        @warn(
            "Some of the frames don't have a background. In this case: $(setdiff(frames, CURRENT_VIDEO[1].background_frames)))"
        )
    end

    if isempty(CURRENT_OBJECT)
        push!(CURRENT_OBJECT, objects[1])
    else
        CURRENT_OBJECT[1] = objects[1]
    end
    return frames
end

"""
flatten(layers::Vector{AbstractObject})

Convert a vector of layers to a list of objects withing each layer.

# Returns
- `objects::Vector{AbstractObject}` - list of all objects in each layer
"""
function flatten(layers::Vector{AbstractObject})
    objects = AbstractObject[]
    for layer in layers
        flatten!(objects, layer)
    end
    return objects
end

function flatten!(objects::Array{AbstractObject}, l::Layer)
    for obj in l.children
        flatten!(objects, obj)
    end
end
# finally objects
flatten!(objects::Array{AbstractObject}, object::Object) = push!(objects, object)

"""
    render(
        video::Video;
        framerate=30,
        pathname="javis_GIBBERISH.gif",
        tempdirectory="",
        liveview=false,
        ffmpeg_loglevel="panic"
    )

Renders all previously defined [`Object`](@ref) drawings to the user-defined `Video` as a gif or mp4.

# Arguments
- `video::Video`: The video which defines the dimensions of the output

# Keywords
- `framerate::Int`: The frame rate of the video
- `pathname::String`: The path for the rendered gif or mp4 (i.e `output.gif` or `output.mp4`)
    - **Default:** The animation is rendered as a gif with the `javis_` prefix and some gibberish afterwards
- `tempdirectory::String`: The folder where each frame is stored
    Defaults to a temporary directory when not set
- `liveview::Bool`: Causes a live image viewer to appear to assist with animation development
- `ffmpeg_loglevel::String`:
    - Can be used if there are errors with ffmpeg. Defaults to panic:
    All other options are described here: https://ffmpeg.org/ffmpeg.html
"""
function render(
    video::Video;
    framerate = 30,
    pathname = "javis_$(randstring(7)).gif",
    liveview = false,
    tempdirectory = "",
    ffmpeg_loglevel = "panic",
)
    layers = video.layers
    layer_objects = flatten(layers)
    objects = video.objects
    if isempty(layers)
        frames = preprocess_frames!(objects)
    else
        frames = preprocess_frames!([objects..., layer_objects...])
    end

    if liveview == true
        if isdefined(Main, :IJulia) && Main.IJulia.inited
            return _jupyter_viewer(
                video,
                length(frames),
                objects,
                framerate,
                layers = layers,
            )

        elseif isdefined(Main, :PlutoRunner)
            return _pluto_viewer(video, length(frames), objects, layers = layers)
        else
            _javis_viewer(video, length(frames), objects, layers = layers)
            return "Live Preview Started"
        end
    end

    path, ext = "", ""
    if !isempty(pathname)
        path, ext = splitext(pathname)
    end
    render_mp4 = ext == ".mp4"
    codec_props = [:priv_data => ("crf" => "22", "preset" => "medium")]
    if render_mp4
        video_io = Base.open("temp.stream", "w")
    end
    video_encoder = nothing
    # if we render a gif and the user hasn't set a tempdirectory
    if !render_mp4 && isempty(tempdirectory)
        tempdirectory = mktempdir()
    end

    filecounter = 1
    @showprogress 1 "Rendering frames..." for frame in frames
        frame_image = convert.(RGB, get_javis_frame(video, objects, frame; layers = layers))
        if !isempty(tempdirectory)
            Images.save("$(tempdirectory)/$(lpad(filecounter, 10, "0")).png", frame_image)
        end
        if render_mp4
            if frame == first(frames)
                video_encoder = prepareencoder(
                    frame_image,
                    framerate = framerate,
                    AVCodecContextProperties = codec_props,
                )
            end
            appendencode!(video_encoder, video_io, frame_image, filecounter)
        end
        filecounter += 1
    end

    isempty(pathname) && return
    if ext == ".gif"
        # generate a colorpalette first so ffmpeg does not have to guess it
        ffmpeg_exe(`-loglevel $(ffmpeg_loglevel) -i $(tempdirectory)/%10d.png -vf
                    palettegen $(tempdirectory)/palette.png`)
        # then apply the palette to get better results
        ffmpeg_exe(
            `-loglevel $(ffmpeg_loglevel) -framerate $framerate -i $(tempdirectory)/%10d.png -i
               $(tempdirectory)/palette.png -lavfi paletteuse -y $pathname`,
        )
    elseif ext == ".mp4"
        finishencode!(video_encoder, video_io)
        close(video_io)
        mux("temp.stream", pathname, framerate; silent = true)
    else
        @error "Currently, only gif and mp4 creation is supported. Not a $ext."
    end

    # even if liveview = false, show the rendered gif in the cell output
    if isdefined(Main, :IJulia) && Main.IJulia.inited
        display(MIME("text/html"), """<img src="$(pathname)">""")
    elseif isdefined(Main, :PlutoRunner)
        return PlutoViewer(pathname)
    end
    return pathname
end

"""
    render_objects(objects, video, frame)
Is called inside the [`get_javis_frame`](@ref) function and renders objects(both individual and ones belonging to a layer).
"""
function render_objects(objects, video, frame)
    CURRENT_OBJECT[1] = objects[1]
    background_settings = ObjectSetting()
    origin()
    origin_matrix = cairotojuliamatrix(getmatrix())
    # this frame needs doing, see if each of the scenes defines it
    for object in objects
        # if object is not in global layer this sets the background_settings
        # from the parent background object
        update_object_settings!(object, background_settings)
        CURRENT_OBJECT[1] = object
        if frame in get_frames(object)
            # check if the object should be part of the global layer (i.e Background)
            # or in its own layer (default)
            in_global_layer = get(object.opts, :in_global_layer, false)::Bool
            if !in_global_layer
                @layer begin
                    draw_object(object, video, frame, origin_matrix)
                end
            else
                draw_object(object, video, frame, origin_matrix)
                # update origin_matrix as it's inside the global layer
                origin_matrix = cairotojuliamatrix(getmatrix())
            end
        end
        # if object is in global layer this changes the background settings
        update_background_settings!(background_settings, object)
    end
end

"""
    get_layer_frame(video, layer, frame)

Is called inside [`get_javis_frame`](@ref) and does two things viz.
    - Creates a Luxor Drawing and renders the object of each layer
    - computes the actions applies on the layer and stores them

Returns the Drawing of the layer as an image matrix.
"""
function get_layer_frame(video, layer, frame)
    Drawing(layer.width, layer.height, :image)
    objects = layer.children
    render_objects(objects, video, frame)
    if frame in get_frames(layer)
        # call currently active actions and their transformations for each layer
        actions = layer.actions
        for action in actions
            #actions for layers are handled in a different way
            # we don't calculate the relative frames for that
            # can find out a way to pre_compute frames for actions applie to layers
            # this is not a final fix..
            if frame in get_frames(action)
                action.func(video, layer, action, frame)
            elseif frame > last(get_frames(action)) && action.keep
                # call the action on the last frame i.e. disappeared things stay disappeared
                action.func(video, layer, action, last(get_frames(action)))
            end
        end
    end
    img_layer = image_as_matrix()
    finish()
    return img_layer
end


"""
    apply_layer_settings(layer, pt)

Applies the computed actions to the image matrix of the layer to it's image matrix
Only a few actions are supported. 
It reads and applies the layer settings(computed by [`get_layer_frame`](@ref) function))
"""

function apply_layer_settings(layer_settings, pt)
    # final actions on the layer are applied here
    # currently scale and translate are support
    scale(layer_settings.scale)
    rotate(layer_settings.rotation_angle)
end

"""
    place_layers(video, layers, frame)

Places the layers on an empty drawing
It does 2 things:
- creates an empty Drawing of the same size as video
- calls the [`apply_layer_settings`](@ref)
- places every layer's image matrix on the drawing

Returns the Drawing containing all the layers as an image matrix.
"""
function place_layers(video, layers, frame)
    # create an empty drawing of size same as the main video
    Drawing(video.width, video.height, :image)
    origin()

    for layer in layers
        CURRENT_LAYER[1] = layer
        if frame in get_frames(layer)
            @layer begin
                # any actions on the layer go in this block

                layer_settings = layer.current_setting
                # provide pre-centered points to the place image functions
                # rather than using centered=true 
                # https://github.com/JuliaGraphics/Luxor.jl/issues/155
                pt = Point(
                    layer.position.x - layer.width / 2,
                    layer.position.y - layer.height / 2,
                )

                apply_layer_settings(layer_settings, pt)
                placeimage(layer.image_matrix[1], pt, alpha = layer.current_setting.opacity)
            end
        end
    end
    
    # matrix of a transparent drawing with all the layers 
    img_layers = image_as_matrix()
    finish()
    return img_layers
end

"""
    get_javis_frame(video, objects, frame; layers = Layer[])

Is called inside the [`render`](@ref) function.
It is a 4-step process:
- for each layer fetch it's image matrix and store it into the layer's struct
- place the layers on an empty drawing
- creates the main canvas and renders the independent objects
- places the drawing containing all the layers on the main drawing

Returens the final rendered frame
"""
function get_javis_frame(video, objects, frame; layers = Layer[])
    if !isempty(layers)
        # for each layer render it's objects and store the image matrix
        for layer in layers
            CURRENT_LAYER[1] = layer
            if frame in get_frames(layer)
                mat = get_layer_frame(video, layer, frame)
                layer.image_matrix[1] = mat
            end
        end

        img_layers = place_layers(video, layers, frame)
    end

    # finally render the independent objects
    Drawing(video.width, video.height, :image)
    render_objects(objects, video, frame)

    if !isempty(layers)
        # place the matrix containing all the layers over the global matrix
        placeimage(img_layers, Point(-video.width / 2, -video.height / 2))
    end
    img = image_as_matrix()
    finish()
    return img
end

"""
    draw_object(video, layer, frame, origin_matrix)
Is called inside the [`render`](@ref) and does everything handled for an `AbstractObject`.
It is a 4-step process:
- translate to the start position
- call the relevant actions
- call the object function
- save the result of the object if wanted inside `video.defs`
"""
function draw_object(object, video, frame, origin_matrix)
    # translate the object to it's starting position.
    # It's better to draw the object always at the origin and use `star_pos` to shift it
    translate(get_position(object.start_pos))

    # reset change keywords
    empty!(object.change_keywords)

    # first compute and perform the global transformations of this object
    # relative frame number for actions
    rel_frame = frame - first(get_frames(object)) + 1
    # call currently active actions and their transformations
    for action in object.actions
        if rel_frame in get_frames(action)
            action.func(video, object, action, rel_frame)
        elseif rel_frame > last(get_frames(action)) && action.keep
            # call the action on the last frame i.e. disappeared things stay disappeared
            action.func(video, object, action, last(get_frames(action)))
        end
    end

    # set the defaults for the frame like setline() and setopacity()
    # which can depend on the actions
    set_object_defaults!(object)

    # if the scale would be 0.0 `show_object` is set to false => don't show the object
    # (it wasn't actually scaled to 0 because it would break Cairo :D)
    cs = get_current_setting()
    !cs.show_object && return

    res = object.func(video, object, frame; collect(object.change_keywords)...)
    current_global_matrix = cairotojuliamatrix(getmatrix())
    # obtain current matrix without the initial matrix part
    current_matrix = inv(origin_matrix) * current_global_matrix

    # if a transformation let's save the global coordinates
    if res isa Point
        trans = current_matrix * Transformation(res, 0.0, 1.0)
        object.result[1] = trans
    elseif res isa Transformation
        trans = current_matrix * res
        object.result[1] = trans
    else # just save the result such that it can be used as one wishes
        object.result[1] = res
    end
end

"""
    set_object_defaults!(object)

Set the default object values
- line_width and calls `Luxor.setline`.
- opacity and calls `Luxor.opacity`.
- scale and calls `Luxor.scale`.
"""
function set_object_defaults!(object)
    cs = object.current_setting
    current_line_width = cs.line_width * cs.mul_line_width
    Luxor.setline(current_line_width)
    current_opacity = cs.opacity * cs.mul_opacity
    Luxor.setopacity(current_opacity)

    desired_scale = cs.desired_scale * cs.mul_scale
    scaleto(desired_scale)
end

const LUXOR_DONT_EXPORT = [
    :boundingbox,
    :Boxmaptile,
    :Sequence,
    :setline,
    :setopacity,
    :fontsize,
    :get_fontsize,
    :scale,
    :text,
]

# Export each function from Luxor
for func in names(Luxor; imported = true)
    if !(func in LUXOR_DONT_EXPORT)
        eval(Meta.parse("import Luxor." * string(func)))
        eval(Expr(:export, func))
    end
end

export render, latex
export Video, Object, Background, Action, RFrames, GFrames
export @javis_layer
export Line, Transformation
export val, pos, ang, scl, get_value, get_position, get_angle, get_scale
export projection, morph_to
export appear, disappear, rotate_around, follow_path, change
export rev
export scaleto
export act!
export anim_translate, anim_rotate, anim_rotate_around, anim_scale

# custom override of luxor extensions
export setline, setopacity, fontsize, get_fontsize, scale, text

end
