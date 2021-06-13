"""
    LayerCache()
Holds image matrices of layer frames in case [`show_layer_frame`](@ref) is called
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
