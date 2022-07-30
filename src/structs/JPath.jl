"""
    JPath

a polygon representation of a path, every Object will have a list of JPaths under the
field jpaths.
Object JPaths are calculated and updated using `getjpaths!`,
Every call to stroke/fill in the objects `obj.func` typically adds a JPath to the objects jpaths. 
a JPath can be drawn using drawjpath(jpath). Usually if one were to draw out the `object.jpath`
it would result in the exact same picture/drawing as running `object.func`.
JPaths are typically used for morphing and drawing partially.

Every JPath has the following fields.

- `polys` a list of polygons that makes up the path
- `closed` a list of bools of same length as `polys`. closed[i] 
states if polys[i] is a closed polygon or not
- `fill` a vector of 4 numbers , R, G ,B and A the color it
should be filled with. if the path was not filled its A is set to 0
(along with R,G,B) this way its an "invisible" fill.
- `stroke a vector of 4 numbers just like `fill` for the stroke color.
- linewidth for stroke 
- polylengths , length of every poly in `polys` , usually computed at rendertime
after polys are populated

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

"""
An array to accumulate the JPATHs as the obj.func is being executed to get the objects jpaths
"""
const CURRENT_JPATHS = JPath[] 

"""
	CURRENT_FETCHPATH_STATE::Bool

If true all drawing functions convert the current path to a JPath and append them to the CURRENT_JPATHS
(does not work on `text`).  
"""
const CURRENT_FETCHPATH_STATE = Ref(false)

"""
    getjpaths(func::Function, args = [])

getjpaths runs the function `func`. `func` is usually a function
with some calls to luxor functions inside to draw something onto a
canvas. Although `getjpaths` does call `func` it does not draw on the canvas.
getjpaths will return an array of JPaths that represent what
would be drawn by the `func`. Also see getjpath!(object,func) 
"""
function getjpaths(func::Function, args = [])
    m = getmatrix()
    setmatrix([1.0, 0, 0, 1.0, 0, 0])
    newpath()
    empty!(CURRENT_JPATHS)
    global CURRENT_FETCHPATH_STATE[] = true
    global DISABLE_LUXOR_DRAW = true
    func(args...)
    global CURRENT_FETCHPATH_STATE[] = false
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


"""
    drawjpaths(jpaths::Array{JPath})

draws out the jpaths onto the current canvas
"""
function drawjpaths(jpaths::Array{JPath})
    for jpath in jpaths
        @assert length(jpath.polys) == length(jpath.closed)
        for (polyi, co_state) in zip(jpath.polys, jpath.closed)
            #place the polys
            if length(polyi) > 1
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
