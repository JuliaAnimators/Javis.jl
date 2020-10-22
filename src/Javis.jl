module Javis

using Animations
using Cairo: CairoImageSurface, image
using ColorTypes: ARGB32
using FFMPEG
using Gtk
using GtkReactive
using Images
using LaTeXStrings
using LightXML
import Luxor
import Luxor: Point, @layer
using ProgressMeter
using Random
using VideoIO

const FRAMES_SYMBOL = [:same]

abstract type Transition end
abstract type InternalTransition end

abstract type AbstractAction end
abstract type AbstractObject end

include("structs/Video.jl")
include("structs/Easing.jl")
include("structs/Rel.jl")
include("structs/Frames.jl")


"""
    Transformation

Defines a transformation which can be returned by an object to be accessible later.
See the `circ` function inside the [`javis`](@ref) as an example.

It can be accessed by another [`Object`])(@ref) using the symbol notation
like `:red_ball` in the example.

# Fields
- `p::Point`: the translation part of the transformation
- `angle::Float64`: the angle component of the transformation (in radians)
"""
mutable struct Transformation
    p::Point
    angle::Float64
end

include("structs/Action.jl")
include("structs/ObjectSetting.jl")
include("structs/Object.jl")
include("structs/Transitions.jl")


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
    θ = transformation.angle
    p = transformation.p
    trans_matrix = [
        cos(θ) -sin(θ) p.x
        sin(θ) cos(θ) p.y
        0 0 1
    ]
    res = m * trans_matrix
    return Transformation(Point(gettranslation(res)...), getrotation(res))
end

include("util.jl")
include("luxor_overrides.jl")
include("backgrounds.jl")
include("svg2luxor.jl")
include("morphs.jl")
include("action_animations.jl")
include("javis_viewer.jl")
include("latex.jl")
include("transition2transformation.jl")
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
    render(
        video::Video;
        framerate=30,
        pathname="javis_GIBBERISH.gif",
        tempdirectory="",
        liveview=false
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
"""
function render(
    video::Video;
    framerate = 30,
    pathname = "javis_$(randstring(7)).gif",
    liveview = false,
    tempdirectory = "",
)
    objects = video.objects
    compute_frames!(objects)

    for object in objects
        compute_frames!(object.actions; last_frames = get_frames(object))
    end

    # get all frames
    frames = Int[]
    for object in objects
        append!(frames, collect(get_frames(object)))
    end
    frames = unique(frames)

    for object in objects
        for action in object.actions
            create_internal_transition!(action)
        end
    end

    if isempty(CURRENT_OBJECT)
        push!(CURRENT_OBJECT, objects[1])
    else
        CURRENT_OBJECT[1] = objects[1]
    end

    if liveview == true
        _javis_viewer(video, length(frames), objects)
        return "Live preview started."
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
        frame_image = convert.(RGB, get_javis_frame(video, objects, frame))
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
        ffmpeg_exe(`-loglevel panic -i $(tempdirectory)/%10d.png -vf
                    "palettegen=stats_mode=diff" -y "$(tempdirectory)/palette.bmp"`)
        # then apply the palette to get better results
        ffmpeg_exe(`-loglevel panic -framerate $framerate -i $(tempdirectory)/%10d.png -i
                    "$(tempdirectory)/palette.bmp" -lavfi
                    "paletteuse=dither=sierra2_4a" -y $pathname`)
    elseif ext == ".mp4"
        finishencode!(video_encoder, video_io)
        close(video_io)
        mux("temp.stream", pathname, framerate; silent = true)
    else
        @error "Currently, only gif and mp4 creation is supported. Not a $ext."
    end
    return pathname
end

"""
    get_javis_frame(video, objects, frame)

Get a frame from an animation given a video object, its objects, and frame.

# Arguments
- `video::Video`: The video which defines the dimensions of the output
- `objects::Vector{Object}`: All objects that are performed
- `frame::Int`: Specific frame to be returned

# Returns
- `Array{ARGB32, 2}` - request frame as a matrix
"""
function get_javis_frame(video, objects, frame)
    background_settings = ObjectSetting()
    Drawing(video.width, video.height, :image)
    origin()
    origin_matrix = cairotojuliamatrix(getmatrix())
    # this frame needs doing, see if each of the scenes defines it
    for object in objects
        # if object is not in global layer this sets the background_settings
        # from the parent background object
        update_object_settings!(object, background_settings)
        CURRENT_OBJECT[1] = object
        if frame in get_frames(object)
            # check if the object should be part of the global layer (i.e BackgroundObject)
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
    img = image_as_matrix()
    finish()
    return img
end

"""
    draw_object(object, video, frame, origin_matrix)

Is called inside the `javis` and does everything handled for an `AbstractObject`.
It is a 4-step process:
- translate to the start position
- call the relevant actions
- call the object function
- save the result of the object if wanted inside `video.defs`
"""
function draw_object(object, video, frame, origin_matrix)
    # translate the object to it's starting position.
    # It's better to draw the object always at the origin and use `star_pos` to shift it
    translate(object.start_pos)

    # first compute and perform the global transformations of this object
    # relative frame number for actions
    rel_frame = frame - first(get_frames(object)) + 1
    # call currently active actions and their transformations
    for action in object.actions
        if rel_frame in get_frames(action)
            action.func(video, object, action, rel_frame)
            compute_transition!(action, video, rel_frame)
            perform_transformation(action)
        elseif rel_frame > last(get_frames(action))
            # call the action on the last frame i.e. disappeared things stay disappeared
            action.func(video, object, action, last(get_frames(action)))
            # have the transformation from the last active frame
            compute_transition!(action, video, last(get_frames(action)))
            perform_transformation(action)
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
        vec = current_matrix * [res.x, res.y, 1.0]
        object.result[1] = Point(vec[1], vec[2])
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

    desired_scale = cs.desired_scale .* cs.mul_scale
    scaleto(desired_scale...)
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
export Video, Object, BackgroundObject, Action, Rel
export Line, Translation, Rotation, Transformation, Scaling
export val, pos, ang, get_value, get_position, get_angle
export projection, morph_to
export appear, disappear, rotate_around, follow_path, change
export rev
export scaleto
export act!

# custom override of luxor extensions
export setline, setopacity, fontsize, get_fontsize, scale, text

end
