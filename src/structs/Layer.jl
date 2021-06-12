"""
    Layer

Defines a new layer withing the video.

# Fields
- `frames::Frames`: A range of frames for which the `Layer` exists
- `width::Int`: Width of the layer
- `height::Int`: hegiht of the layer
- `position::Point`: initial positon of the center of the layer on the main canvas
- `children::Vector{AbstractObject}`: Objects defined under the layer
- `actions::Vector{AbstractAction}`: a list of actions applied to the entire layer 
- `current_setting::LayerSetting`: The current state of the layer see [`LayerSetting`](@ref)
- `opts::Dict{Symbol,Any}`: can hold any options defined by the user
- `image_matrix::Vector`: Hold the Drwaing of the layer as a Luxor image matrix
"""
mutable struct Layer <: AbstractObject
    frames::Frames
    width::Int
    height::Int
    position::Point
    children::Vector{AbstractObject}
    actions::Vector{AbstractAction}
    current_setting::LayerSetting
    opts::Dict{Symbol,Any}
    image_matrix::Union{Base.ReinterpretArray{ARGB32,2,UInt32,Matrix{UInt32},false},Nothing}
    layer_cache::LayerCache
end

"""
    CURRENT_LAYER

holds the current layer in an array to be declared as a constant
The current layer can be accessed using CURRENT_LAYER[1]
"""
const CURRENT_LAYER = Array{Layer,1}()

"""
    PUSH_TO_LAYER

A setinel to aid the creation of layers.
If set to true, all the objects are pushed to the current layer.
Can be accessed using PUSH_TO_LAYER[1]
"""
const PUSH_TO_LAYER = Array{Any,1}()
# by default push all the objects to the video
push!(PUSH_TO_LAYER, false)

# for width, height and position defaults are defined in the to_layer_m function
function Layer(
    frames,
    width,
    height,
    position;
    children = AbstractObject[],
    actions = AbstractAction[],
    setting = LayerSetting(),
    misc = Dict{Symbol,Any}(),
    mat = nothing,
    layer_cache = LayerCache(),
)
    layer = Layer(
        frames,
        width,
        height,
        position,
        children,
        actions,
        setting,
        misc,
        mat,
        layer_cache,
    )

    if isempty(CURRENT_LAYER)
        push!(CURRENT_LAYER, layer)
    else
        CURRENT_LAYER[1] = layer
    end
    push!(CURRENT_VIDEO[1].layers, layer)

    return layer
end

"""
    Javis.@Layer(frames, width, height, position, body)

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

``width`, `height` and `position` are optional and defualt to the video's width, height and origin respectively.
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
Object((args...)->circle(O, 50, :fill))

l1 = @Javis.Layer 10:70 100 100 Point(150, 150) begin
    Background(10:70, layer_ground)
    red_ball = Object(20:60, (args...)->object(O, "red"), Point(50,0))
    act!(red_ball, Action(anim_rotate_around(2π, O)))
end
render(video; pathname="test.gif")
```
"""
macro Layer(frames, width, height, position, body)
    esc(to_layer_m(frames, body, width = width, height = height, position = position))
end

macro Layer(frames, body)
    esc(to_layer_m(frames, body))
end

macro Layer(frames, width, height, body)
    esc(to_layer_m(frames, body, width = width, height = height))
end

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
