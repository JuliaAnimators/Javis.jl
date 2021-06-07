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

#the frames specified in the to_layer! method are a bit 
#too much since we already define the frame range for objects and layers
#let's make this optional and have the default fetch that the object's frame range
function to_layer!(layer::Layer, lifetime, objects::Union{AbstractObject, Vector{<:AbstractObject}})
    # orphan objects are the objects that may or maynot be adopted into a layer 
    # Needs a Better nomenclature
    # this is an expensive operation
    # we can get rid of the orphanObjects field and have such objects sit in the layers field in Video
    # but just to have clarity right now let's keep them separate
    
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
    # add other properties if any
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

# make width and height Optional
# fetch from video by default
# if width and height are different from that in the video
# specify the position of the layer

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




# if width != CURRENT_VIDEO[1].width || height != CURRENT_VIDEO[1].height
    #     @warn(
    #         "You didn't specify the position of layer on the canvas. Translating to origin."
    #     )
    # end
