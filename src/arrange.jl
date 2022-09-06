"""
    BoundingBox(jpaths::Vector{JPath})
    
return BoundingBox enclosing all the jpaths
"""
function Luxor.BoundingBox(jpaths::Vector{JPath})
    allpoints = Point[]
    for jpath in jpaths
        for poly in jpath.polys
            for p in poly
                push!(allpoints, p)
            end
        end
    end
    return Luxor.BoundingBox(allpoints)
end


function Luxor.BoundingBox(obj::Object)
    if isempty(obj.jpaths)
        @warn "obj.jpaths empty, call getjpaths! on obj first"
    end
    return Luxor.BoundingBox(obj.jpaths)
end

"""
    center(bbox::Luxor.BoundingBox)

returns the center of the bounding box
"""
function center(bbox::Luxor.BoundingBox)
    bbox.corner1 + (bbox.corner2 - bbox.corner1) / 2.0
end

"""
    gtranslate(p::Point)

global translate independant of any transformations,
displaces object by a vector specified by `p`

This translation (unlike anim_translate) works by changing the object's start_pos. 

use this if you want to move an object by a certain amount irrespective 
of any other transforming actions that you apply  to an object.

example

act!(obj1, Action!(1:20,gtranslate( Point(10,20) )))
"""
function gtranslate(p::Point)
    return (v, o, a, f) -> begin
        if f == first(get_frames(a))
            a.defs[:now_pos] = o.start_pos
        end
        o.start_pos = a.defs[:now_pos] + get_interpolation(a, f + 1) * (p) #f+1 because action in this frame 
        # results in start_pos for next frame.
    end
end

"""
transform bounding box by m
"""
function Base.:*(m::Matrix, b::Luxor.BoundingBox)
    p1 = Point((m * [b.corner1.x, b.corner1.y, 1])[1:2]...)
    p2 = Point((m * [b.corner2.x, b.corner2.y, 1])[1:2]...)
    return Luxor.BoundingBox(p1, p2)
end

"""
    transformed_bbox(jpaths, m)

transform the object by matrix m and return its bounding box
"""
function transformed_bbox(obj::Object, m::Matrix)
    ps = Point[]
    jpaths = obj.jpaths
    for jpath in jpaths
        for poly in jpath.polys
            for p in poly
                push!(ps, Point((m * [p.x, p.y, 1])[1:2]...))
            end
        end
    end
    Luxor.BoundingBox(ps)
end


"""
    arrange(frames::Unitrange, objects::Vector{Objects}, p::Point, gap::Number, dir::Symbol)

arranges objects 
returns a closure to be used with act!(frames,Function)

frames:: the global frames  during which the arrangment should take place
objects:: array of objects that should be aligned
p:: Point under/to the side of which arranging should take place
    for example if p is `O+10` , the objects are arranged around
    the `Point(10,10)`.
gap:: how much gap between objects while aligning
dir:: direction of alignment either `:vertical` or `:horizontal` 
halign:: :left or :right of the point
valign:: :top or :bottom of the point


example:
```
# arrange returns a function which gets called at frame 5
# that function runs apropriate `act!(object,Action)` which will
# result in `starobj` and `circobj` arranging themselves from wherever they are at frame 5
# to horizontally arranged from `O+10` with a gap of 1 pixel

act!(5 , arrange(5:10,[starobj,circobj],O+10;gap=1,dir=:horizontal)
```

"""
function arrange(
    frames::UnitRange,
    objects::Vector{Object},
    p::Point;
    gap = 10,
    dir = :vertical,
    halign = :right,
    valign = :bottom,
)
    return (v,f) -> begin
        bboxs = []
        #v = CURRENT_VIDEO[1]
        for obj in objects
            isempty(obj.jpaths) && getjpaths!(v, obj, f, obj.opts[:original_func])
            trbbox = transformed_bbox(obj, obj.opts[:pre_matrix])
            push!(bboxs, trbbox)
        end
        ydists = [bbox.corner2.y - bbox.corner1.y for bbox in bboxs] .+ gap
        xdists = [bbox.corner2.x - bbox.corner1.x for bbox in bboxs] .+ gap
        offs = [(bbox.corner2 - bbox.corner1) / 2 for bbox in bboxs]
        cumydists = [0, cumsum(ydists)[1:(end - 1)]...]
        cumxdists = [0, cumsum(xdists)[1:(end - 1)]...]
        if dir == :vertical
            if halign == :right
                if valign == :bottom
                    finalposs = [p + offs[i] + (0, cumydists[i]) for i in 1:length(bboxs)]
                elseif valign == :top
                    finalposs = [
                        p + (offs[i].x, -offs[i].y) - (0, cumydists[i]) for
                        i in 1:length(bboxs)
                    ]
                else
                    @assert valign in (:bottom, :top)
                end
            elseif halign == :left
                if valign == :bottom
                    finalposs = [
                        p + (-offs[i].x, offs[i].y) + (0, cumydists[i]) for
                        i in 1:length(bboxs)
                    ]
                elseif valign == :top
                    finalposs = [p - offs[i] - (0, cumydists[i]) for i in 1:length(bboxs)]
                else
                    @assert valign in (:bottom, :top)
                end
            else
                @assert halign in (:left, :right)
            end
        elseif dir == :horizontal
            if halign == :right
                if valign == :bottom
                    finalposs = [p + offs[i] + (cumxdists[i], 0) for i in 1:length(bboxs)]
                elseif valign == :top
                    finalposs = [
                        p + (offs[i].x, -offs[i].y) + (cumxdists[i], 0) for
                        i in 1:length(bboxs)
                    ]
                end
            elseif halign == :left
                if valign == :bottom
                    finalposs = [
                        p + (-offs[i].x, offs[i].y) - (cumxdists[i], 0) for
                        i in 1:length(bboxs)
                    ]
                elseif valign == :top
                    finalposs = [p - offs[i] - (cumxdists[i], 0) for i in 1:length(bboxs)]
                    #TODO
                else
                    @assert valign in (:top, :bottom)
                end
            end
        else
            @assert dir in (:vertical, :horizontal)
        end
        for (i, obj) in enumerate(objects)
            relframes = frames .- first(get_frames(obj)) .+ 1
            act!(obj, Action(relframes, gtranslate(finalposs[i] - obj.start_pos)))
        end
    end
end

"""
    this method can be used with Actions

arranges objects relative to the target object th Action is applied on.

example usage 
act(obj1, Action(1:10,arrange([obj2,obj3,obj4];gap=1,dir=:vertical))
"""

function arrange(objects::Vector{Object}, gap = 10, dir = :vertical)
    return (v, o, a, f) -> begin end
end
