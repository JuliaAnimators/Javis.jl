mutable struct LayerSetting
    opacity::Float64
    scale::Scale
    rotation_angle::Float64

    LayerSetting() = new(1.0, Scale(1.0, 1.0), 0.0)
end
