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
include("structs/LayerCache.jl")
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

include("layers.jl")
include("util.jl")
include("luxor_overrides.jl")
include("backgrounds.jl")
include("svg2luxor.jl")
include("morphs.jl")
include("action_animations.jl")
include("javis_viewer.jl")
include("latex.jl")
include("object_values.jl")

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
    centered_point(pos::Point, width::Int, height::Int)
Returns pre-centered points to be used in the place image functions
rather than using centered=true 
https://github.com/JuliaGraphics/Luxor.jl/issues/155
# Returns
- `pt::Point`: the location of the center of a layer wrt global canvas
"""
function centered_point(pos::Point, width::Int, height::Int)
    Point(pos.x - width / 2, pos.y - height / 2)
end

"""
    preprocess_frames!(video::Video)

"""
function preprocess_frames!(video::Video)
    return preprocess_frames!([video.objects..., flatten(video.layers)...])
end

"""
    preprocess_frames!(objects::Vector{<:AbstractObject})

Computes the frames for each object(of both the main canvas and layers) and action based on the user defined frames that the
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

Takes out all the objects from each layer and puts them into a single list.
This makes things easier for the [`preprocess_frames!`](@ref) method
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
    for obj in l.layer_objects
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
        liveview=false,
        streamconfig::Union{StreamConfig, Nothing} = nothing,
        tempdirectory="",
        ffmpeg_loglevel="panic",
        rescale_factor=1.0,
    )

Renders all previously defined [`Object`](@ref) drawings to the user-defined `Video` as a gif or mp4.

# Arguments
- `video::Video`: The video which defines the dimensions of the output

# Keywords
- `framerate::Int`: The frame rate of the video
- `pathname::String`: The path for the rendered gif or mp4 (i.e `output.gif` or `output.mp4`)
    - **Default:** The animation is rendered as a gif with the `javis_` prefix and some gibberish afterwards
- `liveview::Bool`: Causes a live image viewer to appear to assist with animation development
- `streamconfig::Union{StreamConfig, Nothing}`: Contains livestream specific instructions, passed on to [`setup_stream`](@ref).
Streaming to Twitch or other platforms are not yet supported.
- `tempdirectory::String`: The folder where each frame is stored
    Defaults to a temporary directory when not set
- `ffmpeg_loglevel::String`:
    - Can be used if there are errors with ffmpeg. Defaults to panic:
    All other options are described here: https://ffmpeg.org/ffmpeg.html
- `rescale_factor::Float64` factor to which the frames should be rescaled for faster rendering
"""
function render(
    video::Video;
    framerate = 30,
    pathname = "javis_$(randstring(7)).gif",
    liveview = false,
    streamconfig::Union{StreamConfig,Nothing} = nothing,
    tempdirectory = "",
    ffmpeg_loglevel = "panic",
    rescale_factor = 1.0,
)
    layers = video.layers
    objects = video.objects
    frames = preprocess_frames!(video)

    if liveview
        if isdefined(Main, :IJulia) && Main.IJulia.inited
            return _jupyter_viewer(video, length(frames), objects, framerate)

        elseif isdefined(Main, :PlutoRunner)
            return _pluto_viewer(video, length(frames), objects)
        else
            _javis_viewer(video, length(frames), objects)
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
    # if we render a gif and the user hasn't set a tempdirectory => create one
    if !render_mp4 && isempty(tempdirectory)
        tempdirectory = mktempdir()
    end

    filecounter = 1
    @showprogress 1 "Rendering frames..." for frame in frames
        frame_image = convert.(RGB, get_javis_frame(video, objects, frame; layers = layers))
        # rescale the frame for faster rendering if the rescale_factor is not 1
        if !isone(rescale_factor)
            new_size = trunc.(Int, size(frame_image) .* rescale_factor)
            frame_image = imresize(frame_image, new_size)
        end

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

    _livestream(streamconfig, framerate, video.width, video.height, pathname)

    # even if liveview = false, show the rendered gif in the cell output
    if isdefined(Main, :IJulia) && Main.IJulia.inited
        display(MIME("text/html"), """<img src="$(pathname)">""")
    elseif isdefined(Main, :PlutoRunner)
        return PlutoViewer(pathname)
    end
    return pathname
end

"""
    render_objects(objects, video, frame; layer_frames=nothing)
Is called inside the [`get_javis_frame`](@ref) function and renders objects(both individual and ones belonging to a layer).

# Arguments
- `object::Object`: The object to be rendered
- `video::Video`: The video which defines the dimensions of the output
- `frame::Int`: The frame number to be rendered
- `layer_frames::UnitRange`: The frames of the layer to which the object belongs(`nothing` for independent objects)
"""
function render_objects(objects, video, frame; layer_frames = nothing)
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

        # checks if independent object is in the current frame
        # also checks the realtive frame of an object in a layer 
        # if none is true then the object doesn't exist for that frame at all
        if !(
            (layer_frames == nothing && frame in get_frames(object)) ||
            layer_frames isa Frames &&
            (frame - first(layer_frames.frames) + 1) in get_frames(object)
        )
            continue
        end

        # check if the object should be part of the global layer (i.e Background)
        # or in its own layer (default)
        in_global_layer = get(object.opts, :in_global_layer, false)::Bool
        in_local_layer = get(object.opts, :in_local_layer, false)::Bool
        if !in_global_layer && !in_local_layer
            @layer begin
                draw_object(object, video, frame, origin_matrix, layer_frames)
            end
        else
            draw_object(object, video, frame, origin_matrix, layer_frames)
            # update origin_matrix as it's inside the global layer
            origin_matrix = cairotojuliamatrix(getmatrix())
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
    layer_frames = layer.frames
    render_objects(layer.layer_objects, video, frame, layer_frames = layer_frames)

    if frame in get_frames(layer)
        # call currently active actions and their transformations for each layer
        actions = layer.actions
        for action in actions
            get_frames(action) isa Nothing &&
                error("Frame range for the layer's action might be missing")
            rel_frame = frame - first(layer_frames.frames) + 1
            if rel_frame in get_frames(action)
                action.func(video, layer, action, rel_frame)
            elseif rel_frame > last(get_frames(action)) && action.keep
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
    apply_layer_settings(layer_settings, pos)

Applies the computed actions to the image matrix of the layer to it's image matrix
Actions supported:
- `anim_translate`:translates the entire layer to a specified position
- `setopacity`:changes the opacity of the entire layer
- `anim_rotate`:rotates the layer by a given angle 
- `appear(:fade)`:fades in the layer
- `disappear(:fade)`:fades out the layer

It reads and applies the layer settings(computed by [`get_layer_frame`](@ref) function))
"""
function apply_layer_settings(layer_settings, pos)
    # final actions on the layer are applied here
    # currently scale and translate are support

    # translate origin to the center of the layer, apply the settings and
    # translate back to the previous position
    translate(pos)
    scale(layer_settings.scale)

    # routine for anim_rotate_around
    rot_around_settings = layer_settings.misc
    if get(rot_around_settings, :rotate_around, false)
        translate(get(rot_around_settings, :translate, pos))
        rotate(get(rot_around_settings, :angle, pos))
        translate(get(rot_around_settings, :translate_back, pos))
    end

    rotate(layer_settings.rotation_angle)
    translate(-pos)
end

"""
    place_layers(video, layers, frame)

Places the layers on an empty drawing
It does 4 things:
- creates an empty Drawing of the same size as video
- calls the [`apply_layer_settings`](@ref)
- places every layer's image matrix on the drawing
- Repeats the above two steps if the [`show_layer_frame`](@ref) is defined for that layer(and frame)
    But fetches image matrix, position and settings from the layer cache

Returns the Drawing containing all the layers as an image matrix.
"""
function place_layers(video, layers, frame)
    # create an empty drawing of size same as the main video
    Drawing(video.width, video.height, :image)
    origin()

    for layer in layers
        CURRENT_LAYER[1] = layer
        if frame in get_frames(layer)
            pt = centered_point(layer.position, layer.width, layer.height)
            @layer begin
                # any actions on the layer go in this block

                layer_settings = layer.current_setting

                apply_layer_settings(layer_settings, layer.position)
                placeimage(layer.image_matrix, pt, alpha = layer.current_setting.opacity)
            end
        end

        lc = layer.layer_cache
        if frame in lc.frames
            if lc.frame_counter < length(lc.layer_frames)
                lc.frame_counter += 1
            else
                lc.frame_counter = 1
            end
            pt = centered_point(lc.position[lc.frame_counter], layer.width, layer.height)
            @layer begin
                settings = lc.settings_cache[lc.frame_counter]
                apply_layer_settings(settings, lc.position[lc.frame_counter])
                placeimage(lc.matrix_cache[lc.frame_counter], pt, alpha = settings.opacity)
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
It is a 5-step process:
- for each layer fetch it's image matrix and store it into the layer's struct
- if the [`show_layer_frame`](@ref) method is defined for a layer, save the 
position, image matrix and layer settings for that frame of the layer in a [`LayerCache`](@ref)
- place the layers on an empty drawing
- creates the main canvas and renders the independent objects
- places the drawing containing all the layers on the main drawing

Returens the final rendered frame
"""
function get_javis_frame(video, objects, frame; layers = Layer[])

    # check if any layers have been defined
    if !isempty(layers)

        # render each layer's objects and store the layer's Drawing as an image matrix
        for layer in layers
            if isempty(Javis.CURRENT_LAYER)
                push!(Javis.CURRENT_LAYER, layer)
            else
                Javis.CURRENT_LAYER[1] = layer
            end
            if frame in get_frames(layer)
                mat = get_layer_frame(video, layer, frame)
                layer.image_matrix = mat
            end

            # check if the layer's frame needs to be cached for vewing layer  
            lc = layer.layer_cache
            if frame in lc.layer_frames
                push!(lc.position, deepcopy(layer.position))
                push!(lc.settings_cache, deepcopy(layer.current_setting))
                push!(lc.matrix_cache, mat)

            end
        end

        img_layers = place_layers(video, layers, frame)
    end

    empty!(CURRENT_LAYER)

    # now that the layers have been handled
    # finally render the independent objects on a separate/main drawing
    Drawing(video.width, video.height, :image)

    # sends over the independent objects for rendering
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
    draw_object(video, layer, frame, origin_matrix, layer_frames)
Is called inside the [`render`](@ref) and does everything handled for an `AbstractObject`.
It is a 4-step process:
- translate to the start position
- call the relevant actions
- call the object function
- save the result of the object if wanted inside `video.defs`
"""
function draw_object(object, video, frame, origin_matrix, layer_frames)
    # translate the object to it's starting position.
    # It's better to draw the object always at the origin and use `star_pos` to shift it
    translate(get_position(object.start_pos))

    # reset change keywords
    empty!(object.change_keywords)

    # first compute and perform the global transformations of this object
    # relative frame number for actions
    if layer_frames == nothing
        rel_frame = frame - first(get_frames(object)) + 1
    else
        # actions of objects in a layer
        # this is somewhat nested since object and action defined in a layer
        # both have their respective frame ranges that need to be calculated relatively
        rel_frame = frame - first(get_frames(object)) - first(layer_frames.frames) + 1
    end
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
    :background,
]

# Export each function from Luxor
for func in names(Luxor; imported = true)
    if !(func in LUXOR_DONT_EXPORT)
        eval(Meta.parse("import Luxor." * string(func)))
        eval(Expr(:export, func))
    end
end

# shorthands declarations
include("shorthands/JLine.jl")
include("shorthands/JCircle.jl")
include("shorthands/JRect.jl")
include("shorthands/JBox.jl")
include("shorthands/JEllipse.jl")
include("shorthands/JStar.jl")
include("shorthands/JPoly.jl")
include("shorthands/JShape.jl")

export render, latex
export Video, Object, Background, Action, RFrames, GFrames
export @JLayer, background
export Line, Transformation
export val, pos, ang, scl, get_value, get_position, get_angle, get_scale
export projection, morph_to
export appear, disappear, rotate_around, follow_path, change
export rev
export scaleto
export act!
export anim_translate, anim_rotate, anim_rotate_around, anim_scale
export JBox, JCircle, JEllipse, JLine, JPoly, JRect, JStar, @JShape

# custom override of luxor extensions
export setline, setopacity, fontsize, get_fontsize, scale, text
export setup_stream, cancel_stream

end
