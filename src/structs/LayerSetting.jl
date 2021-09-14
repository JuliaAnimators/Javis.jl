"""
    LayerSetting

The current settings of an [`Layer`](@ref) which are saved in `layer.current_setting`.

# Fields
- `opacity::Float64`: the current opacity
- `current_scale::Tuple{Float64, Float64}`: the current scale
- `rotation_angle::Float64`: the angle of rotation of a layer.
- `misc::Dict{Symbol, Any}`: any other misc metadata
"""
mutable struct LayerSetting
    opacity::Float64
    scale::Scale
    rotation_angle::Float64
    misc::Dict{Symbol,Any}

    LayerSetting() = new(1.0, Scale(1.0, 1.0), 0.0, Dict())
end
