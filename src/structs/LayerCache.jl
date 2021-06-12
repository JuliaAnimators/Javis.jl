"""
    LayerCache()
Holds image matrices of layer frames in case [`show_layer_frame`](@ref) is called
"""
mutable struct LayerCache
    frames::UnitRange
    frame_counter::Int
    layer_frames::Union{UnitRange,Int}
    matrix_cache::Vector

    LayerCache() = new(0:0, 0, 0, [])
end
