"""
    ObjectSetting

The current settings of an [`Object`](@ref) which are saved in `object.current_setting`.

# Fields
- `line_width::Float64`: the current line width
- `mul_line_width::Float64`: the current multiplier for line width.
    The actual line width is then: `mul_line_width * line_width`
- `opacity::Float64`: the current opacity
- `mul_opacity::Float64`: the current multiplier for opacity.
    The actual opacity is then: `mul_opacity * opacity`
- `fontsize::Float64` the current font size
- `show_object::Bool` is set to false if scale would be 0.0 which is forbidden by Cairo
- `current_scale::Tuple{Float64, Float64}`: the current scale
- `desired_scale::Tuple{Float64, Float64}`: the new desired scale
- `mul_scale::Float64`: the multiplier for the new desired scale.
    The actual new scale is then: `mul_scale * desired_scale`
"""
mutable struct ObjectSetting
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
    current_scale::Tuple{Float64,Float64}
    desired_scale::Tuple{Float64,Float64}
    mul_scale::Float64 # the multiplier of scale is between 0 and 1
end

ObjectSetting() = ObjectSetting(1.0, 1.0, 1.0, 1.0, 10.0, true, (1.0, 1.0), (1.0, 1.0), 1.0)

"""
    update_ObjectSetting!(as::ObjectSetting, by::ObjectSetting)

Set the fields of `as` to the same as `by`. Basically copying them over.
"""
function update_ObjectSetting!(as::ObjectSetting, by::ObjectSetting)
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

function update_background_settings!(setting::ObjectSetting, object::AbstractObject)
    in_global_layer = get(object.opts, :in_global_layer, false)
    if in_global_layer
        update_ObjectSetting!(setting, object.current_setting)
    end
end

function update_object_settings!(object::AbstractObject, setting::ObjectSetting)
    update_ObjectSetting!(object.current_setting, setting)
end
