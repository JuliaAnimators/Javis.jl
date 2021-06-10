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
