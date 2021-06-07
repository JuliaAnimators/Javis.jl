# can more settings be defined for a layer?
mutable struct LayerSetting
    hue::String
    line_width::Float64
    mul_line_width::Float64 # the multiplier of line width is between 0 and 1
    opacity::Float64
    mul_opacity::Float64 # the multiplier of opacity is between 0 and 1
    fontsize::Float64
    # scale has three fields instead of just the normal two
    # current scale
    # desired scale and scale multiplier => `desired_scale*mul_scale` is the new desired scale
    # the scale change needs to be computed using `current_scale` and the desired scale
    # current_scale should never be 0 as this breaks scaleto has various other bad effects
    # see: https://github.com/JuliaGraphics/Luxor.jl/issues/114
    # in this case show will be set to false and the object will not be called
    show_object::Bool
    current_scale::Scale
    desired_scale::Scale
    mul_scale::Float64 # the multiplier of scale is between 0 and 1

    LayerSetting() =
        new("", 1.0, 1.0, 1.0, 1.0, 10.0, true, Scale(1.0, 1.0), Scale(1.0, 1.0), 1.0)
end

function update_LayerSetting!(as::LayerSetting, by::LayerSetting)
    as.hue = by.hue
    as.line_width = by.line_width
    as.mul_line_width = by.mul_line_width
    as.opacity = by.opacity
    as.mul_opacity = by.mul_opacity
    as.fontsize = by.fontsize
    as.show_object = by.show_object
    as.current_scale = by.current_scale
    as.desired_scale = by.desired_scale
    as.mul_scale = by.mul_scale
end

function update_ObjectSetting!(as::ObjectSetting, by::LayerSetting)
    as.line_width = by.line_width
    as.mul_line_width = by.mul_line_width
    as.opacity = by.opacity
    as.mul_opacity = by.mul_opacity
    as.fontsize = by.fontsize
    as.show_object = by.show_object
    as.current_scale = by.current_scale
    as.desired_scale = by.desired_scale
    as.mul_scale = by.mul_scale
end

function update_layer_settings!(layer::AbstractObject, setting::LayerSetting)
    update_LayerSetting!(layer.current_setting, setting)
end


function update_object_settings!(object::AbstractObject, setting::LayerSetting)
    update_ObjectSetting!(object.current_setting, setting)
end