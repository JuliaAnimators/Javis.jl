import Cassette: @context, prehook, overdub
@context ctx_strokelength
@context ctx_partial

cur_len_perim = [0.0] #list of length of every stroke
cur_len_partial = 0.0  # current length for _draw_partial
target_len_partial = 0.0 # the target length for _draw_partial
draw_state = true #draw state, functions turn this false 
#to stop furthur drawing from happening

"""A slightly modified version of pathtopoly ,
by default pathtopoly() will dispatch to Luxors pathtopoly,
however passing any symbol will dispatch to the following
function. Main difference is a new move command starts
a new subpath, we also return if each subpath is closed or
open in an Array{Bool},
"""
function Luxor.pathtopoly(co_state::Symbol)
    originalpath = getpathflat()
    polygonlist = Array{Point,1}[]
    sizehint!(polygonlist, length(originalpath))
    co_states = Bool[]
    sizehint!(co_states, length(polygonlist))
    if length(originalpath) > 0
        pointslist = Point[]
        for e in originalpath
            if e.element_type == Luxor.Cairo.CAIRO_PATH_MOVE_TO                # 0
                if !isempty(pointslist)
                    #if poinstlist is not empty and we come across a move
                    #we flush and create a new subpath
                    if (last(pointslist) == first(pointslist)) && length(poinstlist) > 2
                        #but first lets check if what we flush is closed or open. 
                        push!(co_states, true)
                        pop!(pointslist)
                    else
                        push!(co_states, false)
                    end
                    push!(polygonlist, pointslist)
                    poinstlist = Point[]
                end
                push!(pointslist, Point(first(e.points), last(e.points)))
            elseif e.element_type == Luxor.Cairo.CAIRO_PATH_LINE_TO            # 1
                push!(pointslist, Point(first(e.points), last(e.points)))
            elseif e.element_type == Luxor.Cairo.CAIRO_PATH_CLOSE_PATH         # 3
                push!(co_states, true)
                if last(pointslist) == first(pointslist)
                    # don’t repeat first point, we can close it ourselves
                    if length(pointslist) > 2
                        pop!(pointslist)
                    end
                end
                push!(polygonlist, pointslist)
                pointslist = Point[]
            else
                error("pathtopoly(): unknown CairoPathEntry " * repr(e.element_type))
                error("pathtopoly(): unknown CairoPathEntry " * repr(e.points))
            end
        end
        # the path was never closed, so flush
        if length(pointslist) > 0
            push!(co_states, false)
            push!(polygonlist, pointslist)
        end
    end
    #"""check if everything went well"""
    @assert length(polygonlist) == length(co_states)
    #"""return polygonlist, and its closed/open state"""
    return polygonlist, co_states
end

##CONTEXT strokelength 
"""here are a bunch of overdubs to calculate strokelength"""
#strokepath
function overdub(c::ctx_strokelength, ::typeof(Luxor.strokepath), args...)
    polys, co = pathtopoly(:yes)
    #len = sum(polyperimeter.(polys,closed=false))
    len = sum([polyperimeter(p, closed = co) for (p, co) in zip(polys, co)])
    append!(cur_len_perim, len)
    newpath() #strokepath makes a newpath
    nothing
end

#strokepreserve
function overdub(c::ctx_strokelength, ::typeof(Luxor.strokepreserve), args...)
    polys, co = pathtopoly(:yes)
    len = sum([polyperimeter(p, closed = co) for (p, co) in zip(polys, co)])
    append!(cur_len_perim, len)
    nothing
end

#fillpath
"""
fillpath will be animated by "painting" in the path 
a growing circle starting at one corner of the path's
bounding box to the other end, therefore the diagonal
of the BoudingBox is added to the perimeter 
"""
function overdub(c::ctx_strokelength, ::typeof(Luxor.fillpath), args...)
    poly1, _ = pathtopoly(:yes)
    if length(vcat(poly1...)) > 2
        bbox = BoundingBox(vcat(poly1...))
        push!(cur_len_perim, distance(bbox[1], bbox[2]))
    else
        push!(cur_len_perim, 0)
    end
    newpath() #fillpath makes a new path
end

#fillpreserve
function overdub(c::ctx_strokelength, ::typeof(Luxor.fillpreserve), args...)
    poly1, _ = pathtopoly(:yes)
    if length(vcat(poly1...)) > 2
        bbox = BoundingBox(vcat(poly1...))
        push!(cur_len_perim, distance(bbox[1], bbox[2]))
    else
        push!(cur_len_perim, 0)
    end
end

#hue
"""for some reason parsing colors fails to furthur overdub , so we just
return as is"""
function overdub(c::ctx_strokelength, ::typeof(Colors.parse), args...)
    parse(args...)
end

function overdub(c::ctx_strokelength, ::typeof(Luxor.HueShift), args...)
    #the problematic part is somewhere inside Colors i think 
    #but i'll just block this out for now
    Luxor.HueShift(args...)
end
#latex
"""we manually override this to slightly speed up compilation
when overdubbing latex. Since get_latex_svg does not stroke or fill
we dont want to overdub furthur"""
function overdub(c::ctx_strokelength, ::typeof(get_latex_svg), args...)
    get_latex_svg(args...)
end

##CONTEXT partial

#latex
function overdub(c::ctx_partial, ::typeof(get_latex_svg), args...)
    get_latex_svg(args...)
end
#fillpath
function overdub(c::ctx_partial, ::typeof(Luxor.fillpath), args...)
    global target_len_parital, cur_len_partial, draw_state
    if draw_state == false
        return
    else
        poly1, _ = pathtopoly(:yes)
        if length(vcat(poly1...)) > 2
            bbox = BoundingBox(vcat(poly1...))
            dist = distance(bbox[1], bbox[2])
        else
            bbox = BoundingBox([O, O])
            dist = 0
        end
        corner1 = bbox[1]
        corner2 = bbox[2]
        vec = corner2 - corner1
        do_action(:clip)
        if cur_len_partial >= target_len_partial
            return
        end
        if target_len_partial - cur_len_partial < dist
            d = (target_len_partial - cur_len_partial) / dist
            circle(corner1, corner1 + d * vec, :fill)
            cur_len_partial = target_len_partial
            draw_state = false
        else
            circle(corner1, corner1 + dist * vec, :fill)
            cur_len_partial += dist
        end
        clipreset()
        #newpath()
    end
    newpath()
end


function overdub(c::ctx_partial, ::typeof(Luxor.fillpreserve), args...)
    #if draw_state == false 
    #    #println("ignoreda fillp")
    #    return nothing
    #else
    #    #println("dunna FILLp")
    #    fillpreserve()
    #end
    global target_len_parital, cur_len_partial, draw_state
    if draw_state == false
        return
    else
        current_path = storepath()
        poly1, _ = pathtopoly(:yes)
        newpath()
        if length(vcat(poly1...)) > 2
            bbox = BoundingBox(vcat(poly1...))
            dist = distance(bbox[1], bbox[2])
        else
            bbox = BoundingBox([O, O])
            dist = 0
        end
        corner1 = bbox[1]
        corner2 = bbox[2]
        vec = corner2 - corner1
        do_action(:clip)
        if cur_len_partial >= target_len_partial
            return
        end
        if target_len_partial - cur_len_partial < dist
            d = (target_len_partial - cur_len_partial) / dist
            circle(corner1, corner1 + d * vec, :fill)
            cur_len_partial = target_len_partial
            draw_state = false
        else
            circle(corner1, corner1 + dist * vec, :fill)
            cur_len_partial += dist
        end
        #fillpath()
        clipreset()
        drawpath(current_path)
        #newpath()
    end
end

#strokepath
function overdub(c::ctx_partial, ::typeof(Luxor.strokepath), args...)
    global cur_len_partial, draw_state, target_len_partial
    polys, co_states = pathtopoly(:yes)
    if draw_state == false
        return nothing
    end
    newpath()
    for (poly_i, co) in zip(polys, co_states)
        if cur_len_partial >= target_len_partial
            return nothing
        else
            #since its a stroke we dont need path after this
            #move(poly_i[1])
            nextpolylength = polyperimeter(poly_i, closed = co)
            if cur_len_partial + nextpolylength < target_len_partial
                poly(poly_i, close = co)
                cur_len_partial += nextpolylength
            else
                if length(poly_i) >= 2
                    frac = (target_len_partial - cur_len_partial) / nextpolylength
                    poly(polyportion(poly_i, frac, closed = co))
                else
                    move(last(poly_i))
                end
                cur_len_partial = target_len_partial
                draw_state = false
            end
        end
        strokepath()
    end
end


""" Strokepreserve (like Luxor) maintains the path, this can cause
some wonky behaviour if you strokepath after a strokepreserve without
clearing the path, becuase the second strokepath will stroke the entire
path including the path from before the strokepreserve, try to clear 
the path immediatly after a strokepreserve to avoid this."""

function overdub(c::ctx_partial, ::typeof(Luxor.strokepreserve), args...)
    global cur_len_partial, draw_state
    if draw_state == false
        return nothing
    end
    currpath = storepath()
    polys, co_states = pathtopoly(:yes)
    newpath()
    for (poly_i, co) in zip(polys, co_states)
        if cur_len_partial >= target_len_partial
            return nothing
        else
            nextpolylength = polyperimeter(poly_i, closed = co)
            if cur_len_partial + nextpolylength < target_len_partial
                poly(poly_i, close = co)
                cur_len_partial += nextpolylength
            else
                if length(poly_i) >= 2
                    frac = (target_len_partial - cur_len_partial) / nextpolylength
                    poly(polyportion(poly_i, frac, closed = co))
                end
                cur_len_partial = target_len_partial
                draw_state = false
            end
        end
        strokepath()
    end
    drawpath(currpath)
end

#naughty functions which dont play well with Cassette
function overdub(c::ctx_partial, ::typeof(Colors.parse), args...)
    parse(args...)
end

function overdub(c::ctx_partial, ::typeof(Luxor.HueShift), args...)
    #the problematic part is somewhere inside Colors i think 
    #but i'll just block this out for now
    Luxor.HueShift(args...)
end

"""
not really used , but just kept it incase
one wants to evaluate perimeter of a function
"""
function get_perimeter(f, args...)
    global cur_len_perim = [0.0]
    overdub(ctx_strokelength(), f, args...)
    retlength = sum(cur_len_perim)
    global cur_len_perm = [0.0]
    return retlength
end

"""
gets the perimeter of the object , overdubs the object func
and calls it on frame 1; if you see any issues with this 
approach do let me know !.
"""

function get_perimeter(v::Video, o::Object)
    global cur_len_perim = [0.0]
    overdub(ctx_strokelength(), o.opts[:original_func], v, o, 1)
    retlength = sum(cur_len_perim)
    global cur_len_perim = [0.0]
    return retlength
end

"""
draws the whatever `f` draws on canvas partially,
upto a fraction `p` of the drawing. perim is the
total stroke length inside f + the diagonals of
all the fills , it can be calculated and passed using 
get_perimeter
"""
function _draw_partial(p, perim, f, args...)
    gsave()
    if p > 1.0
        @warn "Partial factor $p > 1.0; clipping to 1.0"
        p = 1.0
    end
    #global draw_state = true
    global target_len_partial = p * perim#get_perimeter(f,args...)
    #println(p)
    newpath()
    ret = overdub(ctx_partial(), f, args...)
    global cur_len_partial = 0.0
    global draw_state = true
    grestore()
    ret
end

"""
replaces object.func with a _draw_partial on
object.func , partial fraction is got by 
using action and the rel_frame interpolation.
"""
function _draw_partial(video, object, action, rel_frame)
    orig_func = object.opts[:original_func]
    p = get_interpolation(action, rel_frame)
    #save perimter , we dont want to recalculate it every frame
    if !haskey(object.opts, :perimeter)
        x = get_perimeter(video, object)
        object.opts[:perimeter] = x
    end
    if p != 1.0
        object.func =
            (v, o, f) -> _draw_partial(p, object.opts[:perimeter], orig_func, v, o, f)
    else
        object.func = orig_func #replace with orignal func once p=1.0
    end
end

#this should probably go into action_animations.jl, if PR goes through
"""
    show_creation()

Draw an [`Object`](@ref) (Not checked: or a [`Layer`](@ref)) using an [`Action`](@ref) and an Animation defined
with Animations.jl.

#Example
```julia
obj = Object(1:40,(v,o,f) -> circle(O,100,:fillstroke))
act!( obj , Action( sineio() , show_creation() )
```
check [`rotate`](@ref) for more examples, show_creation can be used in place of `rotate`
"""
function show_creation()
    (video, object, action, rel_frame) -> _draw_partial(video, object, action, rel_frame)
end

export show_creation
