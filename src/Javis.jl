module Javis

using Animations
using Cairo: CairoImageSurface, image
using ColorTypes: ARGB32
using FFMPEG
using Images
using LaTeXStrings
using LightXML
import Luxor
import Luxor: Point, @layer
using ProgressMeter
using Random
using Requires
using VideoIO

const FRAMES_SYMBOL = [:same]

abstract type Transition end
abstract type InternalTransition end

abstract type AbstractAction end

include("structs/Video.jl")
include("structs/Easing.jl")
include("structs/Rel.jl")
include("structs/Frames.jl")


"""
    Transformation

Defines a transformation which can be returned by an action to be accessible later.
See the `circ` function inside the [`javis`](@ref) as an example.

It can be accessed by another [`Action`])(@ref) using the symbol notation
like `:red_ball` in the example.

# Fields
- `p::Point`: the translation part of the transformation
- `angle::Float64`: the angle component of the transformation (in radians)
"""
mutable struct Transformation
    p::Point
    angle::Float64
end

include("structs/SubAction.jl")
include("structs/ActionSetting.jl")
include("structs/Action.jl")
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
include("subaction_animations.jl")

Gtk = ""
GtkReactive = ""

function __init__()
    @require Gtk="4c0ca9eb-093a-5379-98c5-f87ac0bbbf44" begin
        @require GtkReactive="27996c0f-39cd-5cc1-a27a-05f136f946b6" include("javis_viewer.jl")
    end
end

include("latex.jl")
include("transition2transformation.jl")
include("symbol_values.jl")

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
    javis(
        video::Video,
        actions::Vector{AbstractAction};
        framerate=30,
        pathname="",
        tempdirectory="",
        liveview=false
    )

Similar to `animate` in Luxor with a slightly different structure.
Instead of using actions and a video instead of scenes in a movie.

# Arguments
- `video::Video`: The video which defines the dimensions of the output
- `actions::Vector{Action}`: All actions that are performed

# Keywords
- `framerate::Int`: The frame rate of the video
- `pathname::String`: The path for the rendered gif or mp4 (i.e `output.gif` or `output.mp4`)
- `tempdirectory::String`: The folder where each frame is stored
    Defaults to a temporary directory when not set
- `liveview::Bool`: Causes a live image viewer to appear to assist with animation development

# Example
```
function ground(args...)
    background("white")
    sethue("black")
end

function circ(p=O, color="black")
    sethue(color)
    circle(p, 25, :fill)
    return Transformation(p, 0.0)
end

from = Point(-200, -200)
to = Point(-20, -130)
p1 = Point(0,-100)
p2 = Point(0,-50)
from_rot = 0.0
to_rot = 2π

demo = Video(500, 500)
javis(demo, [
    Action(1:100, ground),
    Action(1:100, :red_ball, (args...)->circ(p1, "red"), Rotation(from_rot, to_rot)),
    Action(1:100, (args...)->circ(p2, "blue"), Rotation(to_rot, from_rot, :red_ball))
], tempdirectory="images", pathname="rotating.gif")
```

This structure makes it possible to refer to positions of previous actions
i.e :red_ball is an id for the position or the red ball which can be used in the
rotation of the next ball.
"""
function javis(
    video::Video,
    actions::Vector{AA};
    framerate = 30,
    pathname = "javis_$(randstring(7)).gif",
    liveview = false,
    tempdirectory = "",
) where {AA<:AbstractAction}
    compute_frames!(actions)

    for action in actions
        compute_frames!(action.subactions; last_frames = get_frames(action))
    end

    # get all frames
    frames = Int[]
    for action in actions
        append!(frames, collect(get_frames(action)))
    end
    frames = unique(frames)

    # create internal transition objects
    for action in actions
        create_internal_transitions!(action)
        for subaction in action.subactions
            create_internal_transitions!(subaction)
        end
    end

    # create defs object
    for action in actions
        if action.id !== nothing
            video.defs[action.id] = Transformation(O, 0.0)
        end
    end

    if isempty(CURRENT_ACTION)
        push!(CURRENT_ACTION, actions[1])
    else
        CURRENT_ACTION[1] = actions[1]
    end

    if liveview == true
        _javis_viewer(video, length(frames), actions)
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
        frame_image = convert.(RGB, get_javis_frame(video, actions, frame))
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
    get_javis_frame(video, actions, frame)

Get a frame from an animation given a video object, its actions, and frame.

# Arguments
- `video::Video`: The video which defines the dimensions of the output
- `actions::Vector{Action}`: All actions that are performed
- `frame::Int`: Specific frame to be returned

# Returns
- `Array{ARGB32, 2}` - request frame as a matrix
"""
function get_javis_frame(video, actions, frame)
    background_settings = ActionSetting()
    Drawing(video.width, video.height, :image)
    origin()
    origin_matrix = cairotojuliamatrix(getmatrix())
    # this frame needs doing, see if each of the scenes defines it
    for action in actions
        # if action is not in global layer this sets the background_settings
        # from the parent background action
        update_action_settings!(action, background_settings)
        CURRENT_ACTION[1] = action
        if frame in get_frames(action)
            # check if the action should be part of the global layer (i.e BackgroundAction)
            # or in its own layer (default)
            in_global_layer = get(action.opts, :in_global_layer, false)::Bool
            if !in_global_layer
                @layer begin
                    perform_action(action, video, frame, origin_matrix)
                end
            else
                perform_action(action, video, frame, origin_matrix)
                # update origin_matrix as it's inside the global layer
                origin_matrix = cairotojuliamatrix(getmatrix())
            end
        end
        # if action is in global layer this changes the background settings
        update_background_settings!(background_settings, action)
    end
    img = image_as_matrix()
    finish()
    return img
end

"""
    perform_action(action, video, frame, origin_matrix)

Is called inside the `javis` and does everything handled for an `AbstractAction`.
It is a 4-step process:
- compute the transformation for this action (translation, rotation, scale)
- do the transformation
- call the action function
- save the result of the action if wanted inside `video.defs`
"""
function perform_action(action, video, frame, origin_matrix)
    # first compute and perform the global transformations of this action
    compute_transition!(action, video, frame)
    perform_transformation(action)

    # relative frame number for subactions
    rel_frame = frame - first(get_frames(action)) + 1
    # call currently active subactions and their transformations
    for subaction in action.subactions
        if rel_frame in get_frames(subaction)
            subaction.func(video, action, subaction, rel_frame)
            compute_transition!(subaction, video, rel_frame)
            perform_transformation(subaction)
        elseif rel_frame > last(get_frames(subaction))
            # call the subaction on the last frame i.e. disappeared things stay disappeared
            subaction.func(video, action, subaction, last(get_frames(subaction)))
            # have the transformation from the last active frame
            compute_transition!(subaction, video, last(get_frames(subaction)))
            perform_transformation(subaction)
        end
    end

    # set the defaults for the frame like setline() and setopacity()
    # which can depend on the subactions
    set_action_defaults!(action)

    # if the scale would be 0.0 `show_action` is set to false => don't show the action
    # (it wasn't actually scaled to 0 because it would break Cairo :D)
    cs = get_current_setting()
    !cs.show_action && return

    res = action.func(video, action, frame)
    if action.id !== nothing
        current_global_matrix = cairotojuliamatrix(getmatrix())
        # obtain current matrix without the initial matrix part
        current_matrix = inv(origin_matrix) * current_global_matrix

        # if a transformation let's save the global coordinates
        if res isa Point
            vec = current_matrix * [res.x, res.y, 1.0]
            video.defs[action.id] = Point(vec[1], vec[2])
        elseif res isa Transformation
            trans = current_matrix * res
            video.defs[action.id] = trans
        else # just save the result such that it can be used as one wishes
            video.defs[action.id] = res
        end
    end
end

"""
    set_action_defaults!(action)

Set the default action values
- line_width and calls `Luxor.setline`.
- opacity and calls `Luxor.opacity`.
- scale and calls `Luxor.scale`.
"""
function set_action_defaults!(action)
    cs = action.current_setting
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

export javis, latex
export Video, Action, BackgroundAction, SubAction, Rel
export Line, Translation, Rotation, Transformation, Scaling
export val, pos, ang, get_value, get_position, get_angle
export projection, morph
export appear, disappear, rotate_around, follow_path
export rev
export scaleto

# custom override of luxor extensions
export setline, setopacity, fontsize, get_fontsize, scale, text

end
