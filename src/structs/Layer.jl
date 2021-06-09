mutable struct Layer <:AbstractObject
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
const PUSH_TO_LAYER = Array{Any, 1}()
push!(PUSH_TO_LAYER, false)
function Layer(frames; width = CURRENT_VIDEO[1].width, height = CURRENT_VIDEO[1].height, position = O, children = AbstractObject[], actions = AbstractAction[], setting = LayerSetting(), misc = Dict{Symbol, Any}(), mat = Any[nothing])
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

# function javis_layer(frames, width, height, position, objects)
#     filter!(x->x∉objects, CURRENT_VIDEO[1].objects) # remove objects that belong to a layer from video.objects
#     return Layer(frames, width = width, height = height, position = position, children = objects)    
# end

macro javis_layer(frames, width, height, position, body)
    quote
        layer = Javis.Layer($frames,width = $width, height = $height, position = $position)
        if isempty(Javis.CURRENT_LAYER)
            push!(Javis.CURRENT_LAYER, layer)
        else
            Javis.CURRENT_LAYER[1] =  layer
        end
        PUSH_TO_LAYER[1] = true 
        $(esc(body))
        PUSH_TO_LAYER[1] = false
        layer
    end  
end

# julia> @imagematrix begin
#     sethue(1., 0.5, 0.0)
# paint()
# end 2 2
# 2×2 reinterpret(ARGB32, ::Array{UInt32,2}):
# ARGB32(1.0,0.502,0.0,1.0)  ARGB32(1.0,0.502,0.0,1.0)
# ARGB32(1.0,0.502,0.0,1.0)  ARGB32(1.0,0.502,0.0,1.0)
# ```
# picks up the default alpha of 1.0.
# """
# macro imagematrix(body, width=256, height=256)
# quote
#  Drawing($(esc(width)), $(esc(height)), :image)
#  origin()
#  $(esc(body))
#  m = image_as_matrix()
#  finish()
#  m
# end
# end

# macro javis_layer(frames, width, height, position, objects)

#     filter!(x->x∉esc(objects), CURRENT_VIDEO[1].objects) # remove objects that belong to a layer from video.objects
#     l = Layer(frames, width = width, height = height, position = position, children = objects)
#     return l    
# end


# function to_layer!(layer::Layer, lifetime, objects::Union{AbstractObject, Vector{<:AbstractObject}})
#     # orphan objects may or may not be adopted into a layer 
#     orphan_objects = CURRENT_VIDEO[1].orphanObjects
#     adopt!(orphan_objects, objects)
    
#     layer_frames = layer.frames.frames
#     if layer_frames.start > lifetime.start || layer_frames.stop < lifetime.stop
#         @warn "Object/Layer exists outside the frame range of the layer. Using the layer framerange as the Object lifetime" 
#         lifetime = layer_frames
#     end

#     for object in objects
#         to_layer!(layer, lifetime, object)
#     end
# end

# function to_layer!(layer::Layer, lifetime, object::Object)
#     push!(layer.children, object)
#     push!(object.opts, (:lifetime => lifetime))
# end

# function to_layer!(layer::Layer, lifetime, lyr::Layer)
#     filter!(x->x≠lyr,CURRENT_VIDEO[1].layers)
#     update_layer_settings!(lyr, layer.current_setting)
#     push!(layer.children, lyr)
#     push!(layer.misc, (:lifetime => lifetime))
# end

# removes the object from orphanObjects
# function adopt!(orphan_objects::Vector{AbstractObject}, obj::AbstractObject)
#     filter!(x->x≠obj,orphan_objects)
# end
# function adopt!(orphan_objects::Vector{AbstractObject}, obj::Vector{<:AbstractObject})
#     filter!(x->x∉obj,orphan_objects)
# end

