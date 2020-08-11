"""
    appear(s::Symbol)

Appear can be used inside a [`SubAction`](@ref) i.e.
```
Action(101:200, (args...)->house_of_nicholas(); subactions = [
            SubAction(1:20, appear(:fade)),
            SubAction(81:100, disappear(:fade))
        ])
```
In this case the `house_of_nicholas` will fade in during the first 20 frames of the [`Action`](@ref) so `101-120`.

# Arguments
- `s::Symbol`: the symbol defines the animation of appearance 
    The only symbol that is currently supported is `:fade` which increases the line width up to the default value or the value specified by [`setline`](@ref)
"""
function appear(s::Symbol)
    (video, action, subaction, rel_frame) -> appear(video, action, subaction, rel_frame, Val(s))
end

function appear(video, action, subaction, rel_frame, symbol::Val{:fade})
    # t is between 0 and 1
    t = (rel_frame - first(subaction.frames) + 1)/length(subaction.frames)
    action.current_setting.mul_line_width = t
end

"""
    disappear(s::Symbol)

Disappear can be used inside a [`SubAction`](@ref) i.e.
```
Action(101:200, (args...)->house_of_nicholas(); subactions = [
            SubAction(1:20, appear(:fade)),
            SubAction(81:100, disappear(:fade))
        ])
```
In this case the `house_of_nicholas` will fade out during the last 20 frames of the [`Action`](@ref) so `181-200`.

# Arguments
- `s::Symbol`: the symbol defines the animation of disappearance 
    The only symbol that is currently supported is `:fade` which decreases the line width up to the default value or the value specified by [`setline`](@ref)
"""
function disappear(s::Symbol)
    (video, action, subaction, rel_frame) -> disappear(video, action, subaction, rel_frame, Val(s))
end

function disappear(video, action, subaction, rel_frame, symbol::Val{:fade})
    # t is between 0 and 1
    t = (rel_frame - first(subaction.frames) + 1)/length(subaction.frames)
    action.current_setting.mul_line_width = 1-t
end
