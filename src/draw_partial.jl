import Cassette: @context, prehook, overdub
@context ctx_strokelength
@context ctx_partial

# a struct to hold the partially drawn state
# coul'd have used globals but just wanted to wrap it
# for specifying types, and  use a const instance
# of the struct. (not sure, but maybe we'll
# also get better performance since Julia knows
# the types of all these globals?)
mutable struct DrawPartialState
    cur_len_perim::Vector{Float64} #list of length of every stroke
    cur_len_partial::Float64 # current length for _draw_partial
    target_len_partial::Float64 #the target length for _draw_partial
    draw_state::Bool  #functions turn this false 
    #to stop furthur drawing from happening

    #polydistance(poly) returns Vector{Float64}
    #polydistances.(many_polys) returns Vector{Vector{Float64}}
    #stroke_polydists is a vector of this ^, i.e Vector{Vector{Vector{Float64}}}
    stroke_polydists::Vector{Vector{Vector{Float64}}}  #accumulates polydistances
    stroke_count::Int #a counter to keep track of which stroke we are on 
end

#draw partial state
const dp_state = DrawPartialState([0], 0, 0, true, [], 0)

""" 
    pathtopoly(co_state::Symbol)

A slightly modified version of pathtopoly ,
by default `pathtopoly()` will dispatch to Luxors `pathtopoly()`,
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
                    if (last(pointslist) == first(pointslist)) && length(pointslist) > 2
                        #but first lets check if what we flush is closed or open. 
                        push!(co_states, true)
                        pop!(pointslist)
                    else
                        push!(co_states, false)
                    end
                    push!(polygonlist, pointslist)
                    pointslist = Point[]
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
    len = sum([polyperimeter(p, closed = c) for (p, c) in zip(polys, co)])
    push!(dp_state.cur_len_perim, len)
    push!(
        dp_state.stroke_polydists,
        [polydistances(p, closed = c) for (p, c) in zip(polys, co)],
    )
    newpath() #strokepath makes a newpath
    nothing
end

#strokepreserve
function overdub(c::ctx_strokelength, ::typeof(Luxor.strokepreserve), args...)
    polys, co = pathtopoly(:yes)
    len = sum([polyperimeter(p, closed = co) for (p, co) in zip(polys, co)])
    push!(dp_state.cur_len_perim, len)
    push!(
        dp_state.stroke_polydists,
        [polydistances(p, closed = c) for (p, c) in zip(polys, co)],
    )
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
        push!(dp_state.cur_len_perim, distance(bbox[1], bbox[2]))
    else
        push!(dp_state.cur_len_perim, 0)
    end
    newpath() #fillpath makes a new path
end

#fillpreserve
function overdub(c::ctx_strokelength, ::typeof(Luxor.fillpreserve), args...)
    poly1, _ = pathtopoly(:yes)
    if length(vcat(poly1...)) > 2
        bbox = BoundingBox(vcat(poly1...))
        push!(dp_state.cur_len_perim, distance(bbox[1], bbox[2]))
    else
        push!(dp_state.cur_len_perim, 0)
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
    global dp_state
    if dp_state.draw_state == false
        newpath()
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
        if dp_state.cur_len_partial >= dp_state.target_len_partial
            return
        end
        if dp_state.target_len_partial - dp_state.cur_len_partial < dist
            d = (dp_state.target_len_partial - dp_state.cur_len_partial) / dist
            circle(corner1, corner1 + d * vec, :fill)
            dp_state.cur_len_partial = dp_state.target_len_partial
            dp_state.draw_state = false
        else
            circle(corner1, corner1 + dist * vec, :fill)
            dp_state.cur_len_partial += dist
        end
        clipreset()
        newpath()
    end
end


function overdub(c::ctx_partial, ::typeof(Luxor.fillpreserve), args...)
    global dp_state
    current_path = storepath()
    if dp_state.draw_state == false
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
        if dp_state.cur_len_partial >= dp_state.target_len_partial
            return
        end
        if dp_state.target_len_partial - dp_state.cur_len_partial < dist
            d = (dp_state.target_len_partial - dp_state.cur_len_partial) / dist
            circle(corner1, corner1 + d * vec, :fill)
            dp_state.cur_len_partial = dp_state.target_len_partial
            dp_state.draw_state = false
        else
            circle(corner1, corner1 + dist * vec, :fill)
            dp_state.cur_len_partial += dist
        end
        clipreset()
    end
    drawpath(current_path)
end

#strokepath
function overdub(c::ctx_partial, ::typeof(Luxor.strokepath), args...)
    global dp_state
    dp_state.stroke_count += 1

    polys, co_states = pathtopoly(:yes)
    if dp_state.draw_state == false
        newpath()
        return nothing
    end
    newpath()
    pdists = CURRENT_OBJECT[1].opts[:polydistances][dp_state.stroke_count]
    for (poly_i, co, pdist_i) in zip(polys, co_states, pdists)
        if dp_state.cur_len_partial >= dp_state.target_len_partial
            return nothing
        else
            #since its a stroke we dont need path after this
            nextpolylength = polyperimeter(poly_i, closed = co)
            if dp_state.cur_len_partial + nextpolylength < dp_state.target_len_partial
                poly(poly_i, close = co)
                dp_state.cur_len_partial += nextpolylength
            else
                if length(poly_i) >= 2
                    frac =
                        (dp_state.target_len_partial - dp_state.cur_len_partial) /
                        nextpolylength
                    poly(polyportion(poly_i, frac, closed = co, pdist = pdist_i))
                    #poly(polyportion(poly_i, frac, closed = co))
                else
                    move(last(poly_i))
                end
                dp_state.cur_len_partial = dp_state.target_len_partial
                dp_state.draw_state = false
            end
        end
        strokepath()
    end
end


""" Strokepreserve (like Luxor) maintains the path, this can cause
some wonky behaviour if you strokepath after a strokepreserve without
clearing the path, becuase the second strokepath will stroke the entire
path including the path from before the strokepreserve, try to clear 
the path immediatly after a strokepreserve to avoid this. Similar behaviour 
for fillpreserve too"""

function overdub(c::ctx_partial, ::typeof(Luxor.strokepreserve), args...)
    global dp_state
    dp_state.stroke_count += 1
    if dp_state.draw_state == false
        return nothing
    end
    so_far_path = storepath()
    polys, co_states = pathtopoly(:yes)
    newpath()
    pdists = CURRENT_OBJECT[1].opts[:polydistances][dp_state.stroke_count]
    for (poly_i, co, pdist_i) in zip(polys, co_states, pdists)
        if dp_state.cur_len_partial >= dp_state.target_len_partial
            return nothing
        else
            nextpolylength = polyperimeter(poly_i, closed = co)
            if dp_state.cur_len_partial + nextpolylength < dp_state.target_len_partial
                poly(poly_i, close = co)
                dp_state.cur_len_partial += nextpolylength
            else
                if length(poly_i) >= 2
                    frac =
                        (dp_state.target_len_partial - dp_state.cur_len_partial) /
                        nextpolylength
                    poly(polyportion(poly_i, frac, closed = co, pdist = pdist_i))
                end
                dp_state.cur_len_partial = dp_state.target_len_partial
                dp_state.draw_state = false
            end
        end
        strokepath()
    end
    drawpath(so_far_path)
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
    dp_state.cur_len_perim = [0.0]

    empty!(dp_state.stroke_polydists)
    overdub(ctx_strokelength(), f, args...)
    ret_perim = sum(dp_state.cur_len_perim)
    ret_polydists = deepcopy(dp_state.stroke_polydists)
    cur_len_perm = [0.0]
    empty!(dp_state.stroke_polydists)
    return ret_perim, ret_polydists
end

"""
gets the perimeter of the object , overdubs the object func
and calls it on frame 1; if you see any issues with this 
approach do let me know !.
"""

function get_perimeter(v::Video, o::Object)
    dp_state.cur_len_perim = [0.0]
    dp_state.stroke_count = 0

    empty!(dp_state.stroke_polydists)
    overdub(ctx_strokelength(), o.opts[:original_func], v, o, 1)
    ret_perim = sum(dp_state.cur_len_perim)
    ret_polydists = deepcopy(dp_state.stroke_polydists)
    dp_state.cur_len_perim = [0.0]
    empty!(dp_state.stroke_polydists)
    return ret_perim, ret_polydists
end

"""
draws the whatever `f` draws on canvas partially,
upto a fraction `p` of the drawing. perim is the
total stroke length inside f + the diagonals of
all the fills , it can be calculated and passed using 
get_perimeter
"""
function _draw_partial(p, perim, f, args...)
    global dp_state
    dp_state.stroke_count = 0
    dp_state.cur_len_partial = 0.0
    dp_state.draw_state = true
    gsave()
    if p > 1.0
        @warn "Partial factor $p > 1.0; clipping to 1.0"
        p = 1.0
    end
    newpath()
    dp_state.target_len_partial = p * perim
    ret = overdub(ctx_partial(), f, args...)
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
        perim, polyd = get_perimeter(video, object)
        object.opts[:perimeter] = perim
        object.opts[:polydistances] = polyd
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
obj = Object(1:40,(v,o,f) -> circle(O,100,:stroke))
act!( obj , Action( sineio() , show_creation() )
```
check [`rotate`](@ref) for more examples, show_creation can be used in place of `rotate`.
Every path that gets stroked in your object function is stroked incrementally, and every fill
is animated as a growing circle filling from one corner to the other.
Note that the animation occurs in the exact order in which strokes and fills are called 
inside the Object function. 

`strokepreserve` maintains the path, this can cause some wonky behaviour if you `strokepath`
after a strokepreserve without clearing the path, becuase the second strokepath will stroke the entire
path including the path from before the `strokepreserve`, Usually thats
okay because `strokepreserve` is followed by a `fillpath` , if not try
to clear the path immediatly after a strokepreserve to avoid this behaviour.
Do note that Luxors action :fillstroke calls `fillpreserve()` and then 
`strokepath()`. 

Range of values for Animation should be between 0 and 1. 0 is undrawn and 1 is completely drawn.
If values larger than 1 are give it is clipped to 1.
"""
function show_creation()
    (video, object, action, rel_frame) -> _draw_partial(video, object, action, rel_frame)
end

export show_creation
