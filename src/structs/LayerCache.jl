"""
    LayerCache()
Holds image matrices of layer frames in case [`show_layer_frame`](@ref) is called.

# Arguments
- `frames::UnitRange`:The frame range for which layer's frames are to be viewed
- `frame_counter::Int`: internal counter to keep count of the layer's frame being placed 
- `layer_frames::Union{UnitRange,Int}`: The frame/frames of the layer to be viewed 
- `matrix_cache::Array`: a list that holds the image matrices of the layer frames to be viewed 
"""
mutable struct LayerCache
    frames::UnitRange
    frame_counter::Int
    layer_frames::Union{UnitRange,Int}
    # todo while dropping support for julia 1.5 
    # change type to Base.ReinterpretArray{ARGB32,2,UInt32,Matrix{UInt32},false} 
    matrix_cache::Array


    LayerCache() = new(0:0, 0, 0, [])
end
