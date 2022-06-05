
"""
    JPath

a polygon representation of a path, every Object will have a list of JPaths under the
field jpaths.

Every JPath has the following fields.

- `polys` a list of polygons that makes up the path
- `closed` a list of bools of same length as `polys`. closed[i] 
states if polys[i] is a closed polygon or not
- `fill` a vector of 4 numbers , R, G ,B and A the color it
should be filled with. if the path was not filled its A is set to 0
(along with R,G,B) this way its an "invisible" fill.
- `stroke a vector of 4 numbers just like `fill` for the stroke color.
- linewidth for stroke 
"""
mutable struct JPath
    polys::Vector{Vector{Point}}
    closed::Vector{Bool}
    fill::Vector{Number}
    stroke::Vector{Number}
    lastaction::Symbol #last action was fill or stroke 
    linewidth::Number
    polylengths::Union{Nothing,Vector{Real}}
    #TODO transform and dashstyle
    #maybe dont have to store the transform here, just apply the transform
    #on the polys before storing it ?. This way things like bounding
    #boxes of the object can be computed easily at compute time.
end

JPath(polys, closed, fill, stroke, lastaction, linewidth) =
    JPath(polys, closed, fill, stroke, lastaction, linewidth, nothing)

CURRENT_JPATHS = JPath[] #TODO change to const later
CURRENT_FETCHPATH_STATE = false

function getjpaths(func::Function, args = [])
    m = getmatrix()
    setmatrix([1.0, 0, 0, 1.0, 0, 0])
    newpath()
    empty!(CURRENT_JPATHS)
    global CURRENT_FETCHPATH_STATE = true
    global DISABLE_LUXOR_DRAW = true
    try
        func(args...)
    catch e
        if e isa MethodError
            #@warn "Could not extract jpath for object,\nperhaps 
            #Object.func depends on rendertime variables"
            println("Could not Extract jpath for some objects. Morphs may not work ")
            #TODO MethodError is too broad , should narrow this down.
        else
            throw(e)
        end
    end
    global CURRENT_FETCHPATH_STATE = false
    global DISABLE_LUXOR_DRAW = false
    newpath()#clear all the paths
    retpaths = JPath[]
    jpath_polylengths!.(CURRENT_JPATHS)
    append!(retpaths, CURRENT_JPATHS)
    empty!(CURRENT_JPATHS)
    setmatrix(m)
    return retpaths
end

"""
    jpath_polylengths!(jpath::JPath)
    
updates the polylengths field in jpath with the lengths of the polys
"""
function jpath_polylengths!(jp::JPath)
    jp.polylengths =
        [polyperimeter(jp.polys[i], closed = jp.closed[i]) for i in 1:length(jp.polys)]
end


function drawjpaths(jpaths::Array{JPath})
    for jpath in jpaths
        for (polyi, co_state) in zip(jpath.polys, jpath.closed)
            #place the polys
            if length(polyi) > 1
                #TODO maybe prune all single-point polys before they are added to obj.jpaths
                poly(polyi; action = :path, close = co_state)
            end
        end
        if jpath.lastaction == :stroke
            Luxor.setcolor(jpath.fill[1:3]...)
            Luxor.setopacity(jpath.fill[4])
            Luxor.fillpreserve()
            Luxor.setcolor(jpath.stroke[1:3]...)
            Luxor.setopacity(jpath.stroke[4])
            Luxor.strokepath()
        else
            Luxor.setcolor(jpath.stroke[1:3]...)
            Luxor.setopacity(jpath.stroke[4])
            Luxor.strokepreserve()
            Luxor.setcolor(jpath.fill[1:3]...)
            Luxor.setopacity(jpath.fill[4])
            Luxor.fillpath()
        end
    end
    newpath()
end
