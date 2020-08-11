function appear(s::Symbol)
    (video, action, subaction, rel_frame) -> appear(video, action, subaction, rel_frame, Val(s))
end

function appear(video, action, subaction, rel_frame, symbol::Val{:fade})
    # t is between 0 and 1
    t = (rel_frame - first(subaction.frames) + 1)/length(subaction.frames)
    action.current_setting.mul_line_width = t
end

function disappear(s::Symbol)
    (video, action, subaction, rel_frame) -> disappear(video, action, subaction, rel_frame, Val(s))
end

function disappear(video, action, subaction, rel_frame, symbol::Val{:fade})
    # t is between 0 and 1
    t = (rel_frame - first(subaction.frames) + 1)/length(subaction.frames)
    action.current_setting.mul_line_width = 1-t
end
