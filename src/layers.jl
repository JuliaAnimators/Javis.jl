"""
PUSH_TO_LAYER

A setinel to aid the creation of layers.
If set to true, all the objects are pushed to the current layer.
Can be accessed using PUSH_TO_LAYER[1]
"""
const PUSH_TO_LAYER = Array{Any,1}()
# by default push all the objects to the video
push!(PUSH_TO_LAYER, false)

"""
    @JLayer(frames, width, height, position, body)
Calls the [`to_layer_m`](@ref) method to create a [`Layer`](@ref) out of the arguments given. 

# Arguments
- `frames`:a `UnitRange` that defines for which frames the layer is active
- `width`: defines the width of the layer
- `height`: defines the height of the layer
- `position`: location of the center of the layer on the main canvas
- `transparent` : Whether the layer should have a transparent background(:transparent or :opaque)
- `body`
    - It contains all the objects(and thier respective actions) definitions for a layer
    - A layer can have it's own separate background
    - Anything defined within the `begin...end` block stays in the layer
    - A Layer has it's own coordinate reference sysstem, i.e. it has it's own origin 
    So eg : `Point(100, 100)` is different when defined in a layer and doesn't represent
    the location 100, 100 on the main canvas 

`width`, `height`, `position` and `transparent` are optional and default to the video's width, height, origin and :opaque respectively.
Layer declaration should take place before pushing objects to it if one is not using the macro

# Example
```julia
function ground(args...)
    background("white")
    sethue("black")
end

video = Video(500, 500)
Background(1:100, ground)
object((args...)->circle(O, 50, :fill))

l1 = @JLayer 10:70 100 100 Point(150, 150) begin
    red_ball = Object(20:60, (args...)->object(O, "red"), Point(50,0))
    act!(red_ball, Action(anim_rotate_around(2π, O)))
end
render(video; pathname="test.gif")
```
"""
macro JLayer(
    frames::Expr,
    width::Int,
    height::Int,
    position,
    transparent::QuoteNode,
    body::Expr,
)
    # frame range 1:50 is an expr
    # transparent -> Symbol is a QuoteNode
    esc(
        to_layer_m(
            frames,
            body,
            width = width,
            height = height,
            position = position,
            transparent = transparent,
        ),
    )
end

macro JLayer(frames::Expr, width::Int, height::Int, position, body::Expr)
    esc(to_layer_m(frames, body, width = width, height = height, position = position))
end

macro JLayer(frames::Expr, body::Expr)
    esc(to_layer_m(frames, body))
end

macro JLayer(frames::Expr, position::Expr, body::Expr)
    esc(to_layer_m(frames, position = position, body))
end

macro JLayer(frames::Expr, position::Expr, transparent::QuoteNode, body::Expr)
    esc(to_layer_m(frames, position = position, transparent = transparent, body))
end

macro JLayer(frames::Expr, transparent::QuoteNode, body::Expr)
    esc(to_layer_m(frames, transparent = transparent, body))
end

macro JLayer(frames::Expr, width::Int, height::Int, body)
    esc(to_layer_m(frames, body, width = width, height = height))
end

macro JLayer(frames::Expr, width::Int, height::Int, transparent::QuoteNode, body::Expr)
    esc(to_layer_m(frames, body, width = width, height = height, transparent = transparent))
end

"""
    to_layer_m( frames, body; width, height, position)
Helper method for the [`JLayer`](@ref) macro
Returns an expression that creates a layer and pushes the objects defined withing the body to the layer
:transparent is the default while the other :opaque copies the video's background
"""
function to_layer_m(
    frames,
    body;
    width = CURRENT_VIDEO[1].width,
    height = CURRENT_VIDEO[1].height,
    position = Point(0, 0),
    transparent = QuoteNode(:transparent),
)
    quote
        layer = Javis.Layer($frames, $width, $height, $position)

        if $transparent == :transparent
            push!(layer.opts, :transparent => true)
        end

        # by default fetch the video's background as a layer's background
        # this is overriden by passing another ground to the layer explicity in the begin end block
        # if no background is needed :transparent flag should be passed
        video_backgrounds =
            filter(x -> get(x.opts, :in_global_layer, false), $CURRENT_VIDEO[1].objects)
        push!(layer.layer_objects, video_backgrounds...)

        if isempty(Javis.CURRENT_LAYER)
            push!(Javis.CURRENT_LAYER, layer)
        else
            Javis.CURRENT_LAYER[1] = layer
        end
        Javis.PUSH_TO_LAYER[1] = true
        eval($body)
        Javis.PUSH_TO_LAYER[1] = false

        # not a problem now but a todo for later
        # remove duplicate backgrounds
        # if layer's background is defined, delete the first object 
        # which is the video's background
        layer
    end
end

"""
    show_layer_frame(frames::UnitRange, layer_frame::Union{UnitRange,Int}, layer::Layer)
Repeat a layer's frame/frames for a given frame range.

# Arguments
- `frames::UnitRange`: The frame range for which the layer should be repeated
- `layer_frame::Union{UnitRange,Int}`: The layer frame range to repeat
- `layer::Layer`:the layer to be repeated
"""
function show_layer_frame(
    frames::UnitRange,
    layer_frame::Union{UnitRange,Int},
    layer::Layer,
)
    lc = layer.layer_cache
    lc.frames = frames
    if layer_frame isa Int
        lc.layer_frames = layer_frame + first(get_frames(layer)) - 1
    else
        lc.layer_frames =
            (first(layer_frame) + first(get_frames(layer)) - 1):(last(
                layer_frame,
            ) + first(get_frames(layer)) - 1)
    end
end

"""
    get_position(obj::Object)

Get access to the position of a layer.

# Returns
- `Point`: the point stored by the layer.

# Throws
- If the function of Layer didn't return a Point or Transformation
"""
function get_position(l::Layer)
    return get_position(l.position)
end

"""
    to_layer!(l::Layer, object::Object)

Pushes an object into the layer and out of the list of independent objects.
This method is helpful in case one doesn't want to include an object in the 
`begin...end` block of [`@JLayer`](@ref).    
"""
function to_layer!(l::Layer, object::Object)
    remove_from_video(object)
    push!(l.layer_objects, object)
end

"""
    to_layer!(l::Layer, objects::Vector{Object})

Pushes a list of objects into the layer,
This method is helpful in case one doesn't want to include an object in the 
`begin...end` block of [`@JLayer`](@ref).    
"""
function to_layer!(l::Layer, objects::Vector{Object})
    remove_from_video(objects)
    push!(l.layer_objects, objects...)
end


"""
    remove_from_video(object::Object)

Removes an object or a list of objects from the main video.
This is a helper method for the [`@to_layer!`](@ref) method and is supposed to be used internally
"""
function remove_from_video(object::Object)
    filter!(x -> x != object, CURRENT_VIDEO[1].objects)
end

function remove_from_video(objects::Vector{Object})
    filter!(x -> x ∉ objects, CURRENT_VIDEO[1].objects)
end
