"""
    calls `func(frame)` at frame number `frame` during rendertime
"""
function act!(frame::Int, func::Function, video = CURRENT_VIDEO[1])
    if !haskey(video.defs, :RuntimeFunctionDict)
        video.defs[:RuntimeFunctionDict] = Dict{Int,Array{Function}}()
    end

    if haskey(video.defs[:RuntimeFunctionDict], frame)
        push!(video.defs[:RuntimeFunctionDict][frame], func)
    else
        video.defs[:RuntimeFunctionDict][frame] = [func]
    end
end

function act!(frames::UnitRange, func::Function, video = CURRENT_VIDEO[1])
    if !haskey(video.defs, :RuntimeFunctionDict)
        video.defs[:RuntimeFunctionDict] = Dict{Int,Array{Function}}()
    end
    for f in frames
        if haskey(video.defs[:RuntimeFunctionDict], frame)
            push!(video.defs[:RuntimeFunctionDict][frame], func)
        else
            video.defs[:RuntimeFunctionDict][frame] = [func]
        end
    end
end
