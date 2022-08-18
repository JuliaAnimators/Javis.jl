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

function center(bbox::Luxor.BoundingBox)
    bbox.corner1 + (bbox.corner2 - bbox.corner1) / 2.0
end

"""
    gtranslate()

global translate independant of any transformations,
displaces object by a vector specified by `p`
"""
function gtranslate(p::Point)
    return (v, o, a, f) -> begin
        if f == first(get_frames(a))
            a.defs[:now_pos] = o.start_pos
        end
        o.start_pos = a.defs[:now_pos] + get_interpolation(a, f) * (p)
        if f == last(get_frames(a))
            o.start_pos = a.defs[:now_pos] + p
        end
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
transform jpaths by m
"""
function transformed_bbox(jpaths::Vector{JPath}, m::Matrix)
    ps = Point[]
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
    arrange()

arranges objects 
returns a closure to be used with act!(frames,Function)

frames:: the global frames  during which the arrangment should take place
objects:: array of objects that should be aligned
p:: Point under/to the side of which arranging should take place
gap:: how much gap between objects while aligning
dir:: direction of alignment either `:vertical` or `:horizontal` 

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
)
    return (f) -> begin
        bboxs = []
        v = CURRENT_VIDEO[1]
        for obj in objects
            isempty(obj.jpaths) && getjpaths!(v, obj, f, obj.opts[:original_func])
            trbbox = transformed_bbox(obj.jpaths, obj.opts[:pre_matrix])
            push!(bboxs, trbbox)
        end
        ydists = [bbox.corner2.y - bbox.corner1.y for bbox in bboxs] .+ gap
        xdists = [bbox.corner2.x - bbox.corner1.x for bbox in bboxs] .+ gap
        offs = [(bbox.corner2 - bbox.corner1) / 2 for bbox in bboxs]
        cumydists = [0, cumsum(ydists)[1:(end - 1)]...]
        cumxdists = [0, cumsum(xdists)[1:(end - 1)]...]
        if dir == :vertical
            finalposs = [p + offs[i] + (0, cumydists[i]) for i in 1:length(bboxs)]
        elseif dir == :horizontal
            finalposs = [p + offs[i] + (cumxdists[i], 0) for i in 1:length(bboxs)]
        else
            @assert dir in [:vertical, :horizontal]
        end
        for (i, obj) in enumerate(objects)
            relframes = frames .- first(get_frames(obj)) .+ 1
            act!(obj, Action(relframes, gtranslate(finalposs[i] - get_position(obj))))
        end
    end
end
