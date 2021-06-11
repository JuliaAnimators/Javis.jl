# """
#     Object

# Defines what is drawn in a defined frame range.

# # Fields
# - `frames::Frames`: A range of frames for which the `Object` is called
# - `func::Function`: The drawing function which draws something on the canvas.
#     It gets called with the arguments `video, object, frame`
# - `start_pos::Union{Object, Point}` defines the origin of the object. It gets translated to this point
# - `actions::Vector{AbstractAction}` a list of actions applied to this object
# - `current_setting`:: The current state of the object see [`ObjectSetting`](@ref)
# - `opts::Any` can hold any options defined by the user
# - `change_keywords::Dict{Symbol,Any}` the modified keywords changed by `change`
# - `result::Vector` the result of the object (if something gets returned)
# """
# struct Object <: AbstractObject
#     frames::Frames
#     func::Function
#     start_pos::Union{Object,Point}
#     actions::Vector{AbstractAction}
#     current_setting::ObjectSetting
#     opts::Dict{Symbol,Any}
#     change_keywords::Dict{Symbol,Any}
#     result::Vector
# end

"""
    CURRENT_OBJECT

holds the current object in an array to be declared as a constant
The current object can be accessed using CURRENT_OBJECT[1]
"""


mutable struct Layer <: AbstractObject
    frames::Frames
    width::Int
    height::Int
    position::Point
    children::Vector{AbstractObject}
    actions::Vector{AbstractAction}
    current_setting::LayerSetting
    misc::Dict{Symbol,Any}
    image_matrix::Vector{Any}
end

const CURRENT_LAYER = Array{Layer,1}()

const PUSH_TO_LAYER = Array{Any,1}()
push!(PUSH_TO_LAYER, false)

function Layer(
    frames;
    width = CURRENT_VIDEO[1].width,
    height = CURRENT_VIDEO[1].height,
    position = O,
    children = AbstractObject[],
    actions = AbstractAction[],
    setting = LayerSetting(),
    misc = Dict{Symbol,Any}(),
    mat = Any[nothing],
)
    layer = Layer(frames, width, height, position, children, actions, setting, misc, mat)

    if isempty(CURRENT_LAYER)
        push!(CURRENT_LAYER, layer)
    else
        CURRENT_LAYER[1] = layer
    end
    push!(CURRENT_VIDEO[1].layers, layer)

    empty!(CURRENT_LAYER)
    return layer
end

"""
    @javis_layer(frames, width, height, position, body)

# Arguments
- frames:a `UnitRange` that defines for which frames the layer is active
- width: defines the width of the layer
- height: defines the height of the layer
- position: location of the center of the layer on the main canvas
- body
    - It contains all the objects(and thier respective actions) definitions for a layer
    - A layer can have it's own separate background
    - Anything defined within the `begin...end` block stays in the layer
    - A Layer has it's own coordinate reference sysstem, i.e. it has it's own origin 
    So eg : `Point(100, 100)` is different when defined in a layer and doesn't represent
    the location 100, 100 on the main canvas 

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

l1 = @javis_layer 1:70 100 100 Point(150, 150) begin
    Background(1:100, ground)

end
render(video; pathname="test.gif")
```

Here the [`Background`](@ref) uses the named way of defining the function whereas
the circle object is defined in the anonymous function `(args...)->circle(O, 50, :fill)`.
It basically depends whether you want to have a simple Luxor object or something more complex.
"""
macro javis_layer(frames, width, height, position, body)
    quote
        layer = Javis.Layer($frames, width = $width, height = $height, position = $position)
        if isempty(Javis.CURRENT_LAYER)
            push!(Javis.CURRENT_LAYER, layer)
        else
            Javis.CURRENT_LAYER[1] = layer
        end
        PUSH_TO_LAYER[1] = true
        $(esc(body))
        PUSH_TO_LAYER[1] = false
        layer
    end
end
