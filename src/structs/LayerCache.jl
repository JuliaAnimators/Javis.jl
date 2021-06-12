mutable struct LayerCache
    frames::UnitRange
    frame_counter::Int
    layer_frames::Union{UnitRange,Int}
    matrix_cache::Vector{Base.ReinterpretArray{ARGB32,2,UInt32,Matrix{UInt32},false}}

    LayerCache() = new(0:0, 0, 0, [])
end
