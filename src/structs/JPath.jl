
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
    #TODO transform and dashstyle
    #maybe dont have to store the transform here, just apply the transform
    #on the polys before storing it ?. This way things like bounding
    #boxes of the object can be computed easily at compute time.
end

CURRENT_JPATHS = JPath[] #TODO change to const later
CURRENT_FETCHPATH_STATE = false

function getjpaths!(obj::Object, func::Function, args = [])
    try
        Drawing()
        empty!(CURRENT_JPATHS)
        global CURRENT_FETCHPATH_STATE = true
        v, o, f = nothing, nothing, nothing
        #for now just make it nothing,
        #this will cause problems if the user defines  
        #the Object.func with types for the arguments
        #TODO discuss a solution for this.
        func(v, o, f, args...)
        global CURRENT_FETCHPATH_STATE = false
        finish()
        append!(obj.jpaths, CURRENT_JPATHS)
        empty!(CURRENT_JPATHS)
    catch e
        if e isa MethodError
            #@warn "Could not extract jpath for object,\nperhaps 
            #Object.func depends on rendertime variables"
            println("Could not Extract jpath for some objects. Morphs may not work ")
        else
            throw(e)
        end
    end
end

function drawobj_jpaths(obj::Object)
    drawjpaths(obj.jpaths)
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
end
