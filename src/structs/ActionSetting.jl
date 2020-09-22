"""
    ActionSetting

The current settings of an [`Action`](@ref) which are saved in `action.current_setting`.

# Fields
- `line_width::Float64`: the current line width
- `mul_line_width::Float64`: the current multiplier for line width.
    The actual line width is then: `mul_line_width * line_width`
- `opacity::Float64`: the current opacity
- `mul_opacity::Float64`: the current multiplier for opacity.
    The actual opacity is then: `mul_opacity * opacity`
- `fontsize::Float64` the current font size
- `current_scale::Tuple{Float64, Float64}`: the current scale
- `desired_scale::Tuple{Float64, Float64}`: the new desired scale
- `mul_scale::Float64`: the multiplier for the new desired scale.
    The actual new scale is then: `mul_scale * desired_scale`
"""
mutable struct ActionSetting
    line_width::Float64
    mul_line_width::Float64 # the multiplier of line width is between 0 and 1
    opacity::Float64
    mul_opacity::Float64 # the multiplier of opacity is between 0 and 1
    fontsize::Float64
    # scale has three fields instead of just the normal two
    # current scale
    # desired scale and scale multiplier => `desired_scale*mul_scale` is the new desired scale
    # the scale change needs to be computed using `current_scale` and the desired scale
    current_scale::Tuple{Float64,Float64}
    desired_scale::Tuple{Float64,Float64}
    mul_scale::Float64 # the multiplier of scale is between 0 and 1
end

ActionSetting() = ActionSetting(1.0, 1.0, 1.0, 1.0, 10.0, (1.0, 1.0), (1.0, 1.0), 1.0)

"""
    update_ActionSetting!(as::ActionSetting, by::ActionSetting)

Set the fields of `as` to the same as `by`. Basically copying them over.
"""
function update_ActionSetting!(as::ActionSetting, by::ActionSetting)
    as.line_width = by.line_width
    as.mul_line_width = by.mul_line_width
    as.opacity = by.opacity
    as.mul_opacity = by.mul_opacity
    as.fontsize = by.fontsize
    as.current_scale = by.current_scale
    as.desired_scale = by.desired_scale
    as.mul_scale = by.mul_scale
end

function update_background_settings!(setting::ActionSetting, action::AbstractAction)
    in_global_layer = get(action.opts, :in_global_layer, false)
    if in_global_layer
        update_ActionSetting!(setting, action.current_setting)
    end
end

function update_action_settings!(action::AbstractAction, setting::ActionSetting)
    update_ActionSetting!(action.current_setting, setting)
end
