function _JLine(p1, p2, color)
    sethue(color)
    line(p1, p2,:stroke)
end

function JLine(p1, p2; color="black") 
    push!(CURRENT_OBJECT_META, Dict("shapetype"=>Line, "initial_pos" => p1, "final_pos" => p2))
    return (args...) -> _JLine(p1, p2, color)
end
JLine(p2) = JLine(O, p2)
