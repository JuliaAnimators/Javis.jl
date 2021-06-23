function show_creation(Line, obj::Object, action, t)
    metadata = obj.result[1]
    initial_pos = metadata["initial_pos"]
    final_pos =  metadata["final_pos"]
    if t == 1
        obj.current_setting.mul_opacity = t
        action.keep = false
    else
        obj.current_setting.mul_opacity = 0
        current_pos = metadata["current_pos"]
        new_pos = initial_pos + t * (final_pos - initial_pos)
        line(current_pos, new_pos,:stroke)
        metadata["current_pos"] = new_pos
    end
end
