import Cassette: @context, prehook, overdub
@context ctx_strokelength
@context ctx_partial

cur_len_perim = [0.0] #list of length of every stroke
cur_len_partial = 0.0  # current length for draw_partial
target_len_partial = 0.0
draw_state = true

##CONTEXT strokelength 
#strokepath
function overdub(c::ctx_strokelength, ::typeof(Luxor.strokepath), args...)
    polys, co = pathtopoly(true)
    #len = sum(polyperimeter.(polys,closed=false))
    len = sum([polyperimeter(p, closed = co) for (p, co) in zip(polys, co)])
    append!(cur_len_perim, len)
    newpath()
    nothing
end

#strokepreserve
function overdub(c::ctx_strokelength, ::typeof(Luxor.strokepreserve), args...)
    polys, co = pathtopoly(true)
    len = sum([polyperimeter(p, closed = co) for (p, co) in zip(polys, co)])
    append!(cur_len_perim, len)
    nothing
end

#fillpath
function overdub(c::ctx_strokelength, ::typeof(Luxor.fillpath), args...)
    poly1 = pathtopoly()
    if length(vcat(poly1...)) >2
        bbox = BoundingBox(vcat(poly1...))
        push!(cur_len_perim,distance(bbox[1],bbox[2]))
    else
        push!(cur_len_perim,0)
    end
      #push!(cur_len_perim,0.0)
    newpath()
    nothing
end

#fillpreserve
function overdub(c::ctx_strokelength, ::typeof(Luxor.fillpreserve), args...)
    nothing
end

#sethue
function overdub(c::ctx_strokelength, ::typeof(Luxor.sethue), args...)
    nothing
end

#latex
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
    global target_len_parital,cur_len_partial,draw_state
    if draw_state==false
        return 
    else
        #println("dunna FILL")
        poly1 = pathtopoly()
        if length(vcat(poly1...)) > 2
            bbox = BoundingBox(vcat(poly1...))
            dist = distance(bbox[1],bbox[2])
        else
            bbox = BoundingBox([O,O])
            dist = 0
        end
        corner1 = bbox[1]
        corner2 = bbox[2]
        vec = corner2-corner1
        do_action(:clip)
        #box(corner1,corner1+0.8*vec,:fill)
        #fillpath()
        if cur_len_partial >= target_len_partial
            return 
        end
            if target_len_partial - cur_len_partial < dist
                d = (target_len_partial-cur_len_partial)/dist
                #sethue("black")
                gsave()
                setopacity(d^2* get_current_setting().opacity)
                circle(corner1,corner1+d*vec,:fill)
                cur_len_partial = target_len_partial
                grestore()
                #setopacity("red")
                draw_state=false
            else
                circle(corner1,corner1+dist*vec,:fill)
                cur_len_partial += dist
            end
        #fillpath()
        clipreset()
        #newpath()
    end
    newpath()
end

#for some reason cassette doesnt like sethue
function overdub(c::ctx_partial, ::typeof(Luxor.sethue), args...)
    sethue(args...)
end

function overdub(c::ctx_partial, ::typeof(Luxor.fillpreserve), args...)
    if draw_state == false 
        #println("ignoreda fillp")
        return nothing
    else
        #println("dunna FILLp")
        fillpreserve()
    end
end

#strokepath
function overdub(c::ctx_partial, ::typeof(Luxor.strokepath), args...)
    global cur_len_partial, draw_state,target_len_partial
    polys, co_states = pathtopoly(true)
    if draw_state ==false 
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
                if length(poly_i)>=2
                  frac = (target_len_partial - cur_len_partial) / nextpolylength
                  poly(polyportion(poly_i, frac, closed = co))
                else
                  move(last(poly_i))
                end
                cur_len_partial = target_len_partial
                draw_state=false
            end
        end
        strokepath()
    end
end

function overdub(c::ctx_partial, ::typeof(Luxor.strokepreserve), args...)
    global cur_len_partial, draw_state
    if draw_state == false 
        return nothing
    end
    currpath = storepath()
    polys, co_states = pathtopoly(true)
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
                if length(poly_i)>=2
                frac = (target_len_partial - cur_len_partial) / nextpolylength
                poly(polyportion(poly_i, frac, closed = co))
                end
                cur_len_partial = target_len_partial  
                draw_state=false
            end
        end
        strokepath()
    end
    drawpath(currpath)
end
#function get_perimeter(f,args...)
#  prinln("hehe")
#  overdub(ctx_strokelength(), f,args...)
#  retlength = sum(cur_len_perim)
#  #global cur_len_perm = [0,]
#  return retlength
#end

function get_perimeter(v::Video, o::Object)
    global cur_len_perim = [0.0]
    overdub(ctx_strokelength(), o.opts[:original_func], v, o, 1)
    retlength = sum(cur_len_perim)
    global cur_len_perim = [0.0]
    return retlength
end

function _draw_partial(p, perim, f, args...)
    gsave()
    if p>1.0
        @warn "Partial factor $p > 1.0; clipping to 1.0"
        p=1.0
    end
    global draw_state = true
    global target_len_partial = p * perim#get_perimeter(f,args...)
    println(p)
    newpath()
    ret = overdub(ctx_partial(), f, args...)
    global cur_len_partial = 0.0
    global draw_state = true
    grestore()
    ret
end

function _draw_partial(video, object, action, rel_frame)
    orig_func = object.opts[:original_func]
    p = get_interpolation(action, rel_frame)
    if !haskey(object.opts, :perimeter)
        x = get_perimeter(video, object)
        object.opts[:perimeter] = x
    end
    if p!=1.0
        object.func = (v, o, f) -> _draw_partial(p, object.opts[:perimeter], orig_func, v, o, f)
    else
        object.func = orig_func
    end
end

"""
this should probably go into action_animations.jl 
"""
function draw_partial()
    (video, object, action, rel_frame) -> _draw_partial(video, object, action, rel_frame)
end

export draw_partial


## should go to Transitions later
#struct PartialDraw{T<:Real} <: AbstractTransition
#    frac::T
#end
#
#function Action(
#    frames,
#    easing::Union{ReversedEasing,Easing},
#    partialdraw::PartialDraw,
#    keep=true,
#    )
#    anim = Animation
#end
