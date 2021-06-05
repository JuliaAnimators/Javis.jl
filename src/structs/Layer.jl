mutable struct Layer <:AbstractObject
    frames::Frames
    width::Int
    height::Int
    children::Vector{AbstractObject}
    position::Point
    misc::Dict{Symbol,Any}
end

const CURRENT_LAYER = Array{Layer,1}()

function to_layer!(layer::Layer, frames, obj::Union{AbstractObject, Vector{<:AbstractObject}})
    # orphan objects are the objects that may or maynot be adopted into a layer 
    # Better nomenclature please
    # this is an expensive operation
    # we can get rid of the orphanObjects field and have such objects sit in the layers field in Video
    # but just to have clarity right now let's keep them separate
    orphan_objects = CURRENT_VIDEO[1].orphanObjects
    adopt!(orphan_objects, obj)
    to_layer!(layer, obj)
    # add other properties if any
end

function to_layer!(layer::Layer, obj::Vector{<:AbstractObject}) 
    for o in obj
        to_layer!(layer, o)
    end
end

to_layer!(layer::Layer, obj::Object) = push!(layer.children, obj)

#removes the layer from the children field if that layer is made a child of another layer
function to_layer!(layer::Layer, lyr::Layer)
    filter!(x->x≠lyr,CURRENT_VIDEO[1].layers)
    push!(layer.children, lyr)
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

function Layer(frames, width = CURRENT_VIDEO[1].width, height = CURRENT_VIDEO[1].width, position = O; misc = Dict())
    layer = Layer(frames, width, height, AbstractObject[], position, misc)

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
    










#todo
# figure out if we need a layer setting 
# also in other places instead of fetching the global background layer
# fetch stuff from the CURRENT_LAYER if a layer is defined

# mutable struct LayerSetting
#     line_width::Float64
#     mul_line_width::Float64 # the multiplier of line width is between 0 and 1
#     opacity::Float64
#     mul_opacity::Float64 # the multiplier of opacity is between 0 and 1
#     fontsize::Float64
#     # scale has three fields instead of just the normal two
#     # current scale
#     # desired scale and scale multiplier => `desired_scale*mul_scale` is the new desired scale
#     # the scale change needs to be computed using `current_scale` and the desired scale
#     # current_scale should never be 0 as this breaks scaleto has various other bad effects
#     # see: https://github.com/JuliaGraphics/Luxor.jl/issues/114
#     # in this case show will be set to false and the object will not be called
#     show_object::Bool
#     current_scale::Scale
#     desired_scale::Scale
#     mul_scale::Float64 # the multiplier of scale is between 0 and 1

#     ObjectSetting() =
#         new(1.0, 1.0, 1.0, 1.0, 10.0, true, Scale(1.0, 1.0), Scale(1.0, 1.0), 1.0)
# end

# function update_LayerSetting!(as::LayerSetting, by::LayerSetting)
#     as.line_width = by.line_width
#     as.mul_line_width = by.mul_line_width
#     as.opacity = by.opacity
#     as.mul_opacity = by.mul_opacity
#     as.fontsize = by.fontsize
#     as.show_object = by.show_object
#     as.current_scale = by.current_scale
#     as.desired_scale = by.desired_scale
#     as.mul_scale = by.mul_scale
# end

# function update_background_settings!(setting::LayerSetting, object::AbstractObject)
#     in_global_layer = get(object.opts, :in_global_layer, false)
#     if in_global_layer
#         update_ObjectSetting!(setting, object.current_setting)
#     end
# end

# function update_layer_settings!(layer::AbstractObject, setting::LayerSetting)
#     update_LayerSetting!(layer.current_setting, setting)
# end
