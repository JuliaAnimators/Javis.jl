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
- `body`
    - It contains all the objects(and thier respective actions) definitions for a layer
    - A layer can have it's own separate background
    - Anything defined within the `begin...end` block stays in the layer
    - A Layer has it's own coordinate reference sysstem, i.e. it has it's own origin 
    So eg : `Point(100, 100)` is different when defined in a layer and doesn't represent
    the location 100, 100 on the main canvas 

`width`, `height` and `position` are optional and default to the video's width, height and origin respectively.
Layer declaration should take place before pushing objects to it if one is not using the macro

# Example
```julia
function ground(args...)
    background("white")
    sethue("black")
end

function layer_ground(args...)
    background("red")
    sethue("white")
end

video = Video(500, 500)
Background(1:100, ground)
object((args...)->circle(O, 50, :fill))

l1 = @Javis.Layer 10:70 100 100 Point(150, 150) begin
    Background(10:70, layer_ground)
    red_ball = Object(20:60, (args...)->object(O, "red"), Point(50,0))
    act!(red_ball, Action(anim_rotate_around(2π, O)))
end
render(video; pathname="test.gif")
```
"""
macro JLayer(frames, width, height, position, body)
    esc(to_layer_m(frames, body, width = width, height = height, position = position))
end

macro JLayer(frames, body)
    esc(to_layer_m(frames, body))
end

macro JLayer(frames, width, height, body)
    esc(to_layer_m(frames, body, width = width, height = height))
end

"""
    to_layer_m( frames, body; width, height, position)
Helper method for the [`JLayer`](@ref) macro
Returns an expression that creates a layer and pushes the objects defined withing the body to the layer
"""
function to_layer_m(
    frames,
    body;
    width = CURRENT_VIDEO[1].width,
    height = CURRENT_VIDEO[1].height,
    position = Point(0, 0),
)
    quote
        layer = Javis.Layer($frames, $width, $height, $position)
        if isempty(Javis.CURRENT_LAYER)
            push!(Javis.CURRENT_LAYER, layer)
        else
            Javis.CURRENT_LAYER[1] = layer
        end
        Javis.PUSH_TO_LAYER[1] = true
        eval($body)
        Javis.PUSH_TO_LAYER[1] = false
        layer
    end
end

"""
    show_layer_frame(frames::UnitRange, layer_frame::Union{UnitRange,Int}, layer::Layer)
Repeat a layer's frame/frames for a given frame range.

# Arguments
`frames::UnitRange`: The frame range for which the layer should be repeated
`layer_frame::Union{UnitRange,Int}`: The layer frame range to repeat
`layer::Layer`:the layer to be repeated
"""
function show_layer_frame(
    frames::UnitRange,
    layer_frame::Union{UnitRange,Int},
    layer::Layer,
)
    lc = layer.layer_cache
    lc.frames = frames
    lc.layer_frames = layer_frame
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
