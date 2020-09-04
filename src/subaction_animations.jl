"""
    appear(s::Symbol)

Appear can be used inside a [`SubAction`](@ref)

# Example
```
Action(101:200, (args...)->house_of_nicholas(); subactions = [
    SubAction(1:20, appear(:fade)),
    SubAction(81:100, disappear(:fade))
])
```
In this case the `house_of_nicholas` will fade in during the first 20 frames
of the [`Action`](@ref) so `101-120`.

# Arguments
- `s::Symbol`: the symbol defines the animation of appearance
    The only symbols that are currently supported are:
    - `:fade_line_width` which increases the line width up to the default value
       or the value specified by [`setline`](@ref)
    - `:fade` which increases the opcacity up to the default value
       or the value specified by [`setopacity`](@ref)
"""
function appear(s::Symbol)
    (video, action, subaction, rel_frame) ->
        _appear(video, action, subaction, rel_frame, Val(s))
end

function _appear(video, action, subaction, rel_frame, symbol::Val{:fade_line_width})
    # t is between 0 and 1
    t = (rel_frame - first(get_frames(subaction))) / (length(get_frames(subaction)) - 1)
    action.current_setting.mul_line_width = t
end

function _appear(video, action, subaction, rel_frame, symbol::Val{:fade})
    # t is between 0 and 1
    t = (rel_frame - first(get_frames(subaction))) / (length(get_frames(subaction)) - 1)
    action.current_setting.mul_opacity = t
end

function _appear(video, action, subaction, rel_frame, symbol::Val{:scale})
    # t is between 0 and 1
    t = (rel_frame - first(get_frames(subaction))) / (length(get_frames(subaction)) - 1)
    action.current_setting.mul_scale = t
end

"""
    disappear(s::Symbol)

Disappear can be used inside a [`SubAction`](@ref)

# Example
```
Action(101:200, (args...)->house_of_nicholas(); subactions = [
    SubAction(1:20, appear(:fade)),
    SubAction(81:100, disappear(:fade))
])
```
In this case the `house_of_nicholas` will fade out during the last 20 frames
of the [`Action`](@ref) so `181-200`.

# Arguments
- `s::Symbol`: the symbol defines the animation of disappearance
    The only symbols that are currently supported are:
    - `:fade_line_width` which decreases the line width up to the default value
        or the value specified by [`setline`](@ref)
    - `:fade` which decreases the opcacity up to the default value
        or the value specified by [`setopacity`](@ref)
"""
function disappear(s::Symbol)
    (video, action, subaction, rel_frame) ->
        _disappear(video, action, subaction, rel_frame, Val(s))
end

function _disappear(video, action, subaction, rel_frame, symbol::Val{:fade_line_width})
    # t is between 0 and 1
    t = (rel_frame - first(get_frames(subaction))) / (length(get_frames(subaction)) - 1)
    action.current_setting.mul_line_width = 1 - t
end

function _disappear(video, action, subaction, rel_frame, symbol::Val{:fade})
    # t is between 0 and 1
    t = (rel_frame - first(get_frames(subaction))) / (length(get_frames(subaction)) - 1)
    action.current_setting.mul_opacity = 1 - t
end

function _disappear(video, action, subaction, rel_frame, symbol::Val{:scale})
    # t is between 0 and 1
    t = (rel_frame - first(get_frames(subaction))) / (length(get_frames(subaction)) - 1)
    action.current_setting.mul_scale = 1 - t
end
