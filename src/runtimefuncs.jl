"""
a dictionary mapping frameno => Array{Func}
the functions should take 1 argument the frame number

at render time RuntimeFunctionMap[frame] is checked and every Func 
in the array is called with `func(frame)`
"""
RuntimeFunctionDict = Dict{Int,Array{Function}}() 

"""
    calls `func(frame)` at frame number `frame` during rendertime
"""
function act!(frame::Int,func::Function)
    if haskey(RuntimeFunctionDict,frame)
        push!(RuntimeFunctionDict[frame],func)
    else
        RuntimeFunctionDict[frame] = [func,]
    end
end

function act!(frames::UnitRange,func::Function)
    for f in frames
        if haskey(RuntimeFunctionDict,frame)
            push!(RuntimeFunctionDict[frame],func)
        else
            RuntimeFunctionDict[frame] = [func,]
        end
    end
end
