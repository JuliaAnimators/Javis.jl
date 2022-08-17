"""
    BoundingBox(jpaths::Vector{JPath})
    
return BoundingBox enclosing all the jpaths
"""
function Luxor.BoundingBox(jpaths::Vector{JPath})
    allpoints=Point[]
    for jpath in jpaths
        for poly in jpath.polys
            for p in poly
                push!(allpoints,p)
            end
        end
    end
    #m = cairotojuliamatrix(getmatrix())
    ##@show m
    #for i in 1:length(allpoints)
    #    newpoint =  m^-1 * [ allpoints[i].x , allpoints[i].y , 1] 
    #    allpoints[i] = Point(newpoint[1],newpoint[2])
    #end
    return Luxor.BoundingBox(allpoints)
end


function Luxor.BoundingBox(obj::Object)
    if isempty(obj.jpaths)
        @warn "obj.jpaths empty, call getjpaths! on obj first"
    end
    return Luxor.BoundingBox(obj.jpaths)
end

function center(bbox::Luxor.BoundingBox)
    bbox.corner1 + (bbox.corner2-bbox.corner1)/2.0
end

"""
    gtranslate()

global translate independant of any transformations,
displaces object by a vector specified by `p`
"""
function gtranslate(p::Point)
    return (v,o,a,f)-> begin
        if f==first(get_frames(a))
            o.opts[:now_pos] = o.start_pos
        end
        o.start_pos = o.opts[:now_pos] + get_interpolation(a,f)*(p)
    end
end

"""
transform bounding box by m
"""
function Base.:*(m::Matrix,b::Luxor.BoundingBox)
    p1 = Point((m * [b.corner1.x,b.corner1.y,1])[1:2]...)
    p2 = Point((m * [b.corner2.x,b.corner2.y,1])[1:2]...)
    return Luxor.BoundingBox(p1,p2)
end

"""
transform jpaths by m
"""
function transformed_bbox(jpaths::Vector{JPath},m::Matrix)
    ps = Point[]
    for jpath in jpaths
        for poly in jpath.polys
            for p in poly
                push!(ps,Point((m * [p.x,p.y,1])[1:2]...))
            end
        end
    end
    Luxor.BoundingBox(ps)
end


"""
    arrange()

arranges objects 
"""
function arrange(objects::Vector{Object},p::Point;gap=10,dir=:vertical)
    return (v,o,a,f) -> begin
        bboxs = []
        if f == first(get_frames(a)) 
            #@show length(v.objects[end-1].actions)
            for obj in objects
                isempty(obj.jpaths) && getjpaths!(v,obj,f,obj.opts[:original_func])
                trbbox = transformed_bbox(obj.jpaths,obj.opts[:object_matrix])
                push!(bboxs,trbbox)
            end
            display(bboxs[end])
            ydists = [ bbox.corner2.y-bbox.corner1.y for bbox in bboxs] .+ gap 
            xdists = [ bbox.corner2.x-bbox.corner1.x for bbox in bboxs] .+ gap 
            offs = [(bbox.corner2 - bbox.corner1)/2 for bbox in bboxs]
            cumydists = [0 , cumsum(ydists)[1:end-1]...] # .+ get_position(objects[1]).y 
            cumxdists = [0, cumsum(xdists)[1:end-1]...] #.+ get_position(objects[1]).x 
            if dir==:vertical
                finalposs = [p + offs[i] + (0,cumydists[i]) for i in 1:length(bboxs) ]
            elseif dir==:horizontal
                finalposs = [p + offs[i] + (cumxdists[i], 0) for i in 1:length(bboxs) ]
            end
            for (i,obj) in enumerate(objects)
                @show get_position(obj) 
                @show finalposs[i]
                #act!(obj,Action(a.frames,anim_translate(finalposs[i] - get_position(obj) )))
                act!(obj,Action(a.frames,gtranslate(finalposs[i] - get_position(obj))))
                #act!(obj,Action(a.frames,Animation([0,1.0],[O,finalposs[i]-O]),translate()))
                i==2 ? act!(obj,Action(a.frames,(v,o,a,f)->println("getpos ",get_position(o)),keep=false)) : nothing 
                #i==3 ? act!(obj,Action(a.frames,(v,o,a,f)->println("finpos ",finalposs[i]),keep=false)) : nothing 
            end
            #@show length(v.objects[end-1].actions)
        end
    end
end

#function arrange2(objects::Vector{Object},p::Point;gap=0,dir=:vertical)
#    for obj in objects
#        nothing
#    end
#end
