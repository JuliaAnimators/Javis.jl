# to get a flash traversing the path...pass the last position instead of initial

function show_creation(::Type{Line}, obj::Object, action, t)
    metadata = obj.metadata[1]
    initial_pos = metadata["initial_pos"]
    final_pos =  metadata["final_pos"]
    if t == 1
        restore_object(t, obj, action)
    else
        obj.current_setting.mul_opacity = 0
        new_pos = initial_pos + t * (final_pos - initial_pos)
        line(initial_pos, new_pos,:stroke)
    end
end

function show_creation(::Type{Circle}, obj::Object, action, t)
    metadata = obj.metadata[1]
    center = metadata["center"]
    radius =  metadata["radius"]

    if t == 1
        restore_object(t, obj, action)
    else
        current_angle = metadata["current_angle"]
        obj.current_setting.mul_opacity = 0
        new_angle = t * 6
        pie(center, radius+10, 0, new_angle, :clip)
        circle(center, radius, :stroke)
        obj.metadata[1]["current_angle"] = new_angle
    end
end

function restore_object(t, obj, action)
    obj.current_setting.mul_opacity = t
    action.keep = false
end