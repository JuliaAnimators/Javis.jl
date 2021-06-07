mutable struct Layer <:AbstractObject
    frames::Frames
    width::Int
    height::Int
    children::Vector{AbstractObject}
    position::Point
    current_setting::LayerSetting
    misc::Dict{Symbol,Any} # rename this to opts
end

const CURRENT_LAYER = Array{Layer,1}()

function to_layer!(layer::Layer, lifetime, objects::Union{AbstractObject, Vector{<:AbstractObject}})
    # orphan objects may or may not be adopted into a layer 
    orphan_objects = CURRENT_VIDEO[1].orphanObjects
    adopt!(orphan_objects, objects)
    
    layer_frames = layer.frames.frames
    if layer_frames.start > lifetime.start || layer_frames.stop < lifetime.stop
        @warn "Object/Layer exists outside the frame range of the layer. Using the layer framerange as the Object lifetime" 
        lifetime = layer_frames
    end

    for object in objects
        to_layer!(layer, lifetime, object)
    end
end

function to_layer!(layer::Layer, lifetime, object::Object)
    push!(layer.children, object)
    push!(object.opts, (:lifetime => lifetime))
end

function to_layer!(layer::Layer, lifetime, lyr::Layer)
    filter!(x->x≠lyr,CURRENT_VIDEO[1].layers)
    update_layer_settings!(lyr, layer.current_setting)
    push!(layer.children, lyr)
    push!(layer.misc, (:lifetime => lifetime))
end

# removes the object from orphanObjects
function adopt!(orphan_objects::Vector{AbstractObject}, obj::AbstractObject)
    filter!(x->x≠obj,orphan_objects)
end
function adopt!(orphan_objects::Vector{AbstractObject}, obj::Vector{<:AbstractObject})
    filter!(x->x∉obj,orphan_objects)
end

function Layer(frames; width = CURRENT_VIDEO[1].width, height = CURRENT_VIDEO[1].width, position = O, layer_setting::LayerSetting = LayerSetting(), misc = Dict{Symbol, Any}())
    layer = Layer(frames, width, height, AbstractObject[], position, layer_setting, misc)

    if isempty(CURRENT_LAYER)
        push!(CURRENT_LAYER, layer)
    else
        CURRENT_LAYER[1] = layer
    end
    push!(CURRENT_VIDEO[1].layers, layer)

    empty!(CURRENT_OBJECT)
    return layer
end

# """
# Removes objects from the layer
# also from the video
# todo: clear other fields too
# """
# function clear_layer!()
#     Javis.CURRENT_VIDEO[1].layers[1].children = AbstractObject[]
#     Javis.CURRENT_LAYER[1].children = AbstractObject[]
# end
