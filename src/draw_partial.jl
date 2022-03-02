import Cassette: @context, prehook , overdub
@context ctx_strokelength 
@context ctx_partial

cur_len_perim = [0.0,] #list of length of every stroke
cur_len_partial = 0.0  # current length for draw_partial
target_len_partial = 0.0
draw_state = true

##CONTEXT strokelength 
#strokepath
function overdub(c::ctx_strokelength,::typeof(Luxor.strokepath),args...)
  polys,co = pathtopoly(true)
  #len = sum(polyperimeter.(polys,closed=false))
  len = sum([polyperimeter(p,closed=co) for (p,co) in zip(polys,co)])
  append!(cur_len_perim,len)
  newpath()
  nothing
end

#strokepreserve
function overdub(c::ctx_strokelength,::typeof(Luxor.strokepreserve),args...)
  polys,co = pathtopoly(true)
  len = sum([polyperimeter(p,closed=co) for (p,co) in zip(polys,co)])
  append!(cur_len_perim,len)
  newpath()
  nothing
end

#fillpath
function overdub(c::ctx_strokelength,::typeof(Luxor.fillpath),args...)
  nothing
end

#fillpreserve
function overdub(c::ctx_strokelength,::typeof(Luxor.fillpreserve),args...)
  nothing
end

#sethue
function overdub(c::ctx_strokelength,::typeof(Luxor.sethue),args...)
  nothing
end

#latex
function overdub(c::ctx_strokelength,::typeof(get_latex_svg),args...)
  get_latex_svg(args...)
end

##CONTEXT partial

#latex
function overdub(c::ctx_partial,::typeof(get_latex_svg),args...)
  get_latex_svg(args...)
end
#fillpath
function overdub(c::ctx_partial,::typeof(Luxor.fillpath),args...)
  if draw_state==false
    return nothing
  else
    fillpath()
  end
end

#for some reason cassette doesnt like sethue
function overdub(c::ctx_partial,::typeof(Luxor.sethue),args...)
  sethue(args...)
end

function overdub(c::ctx_partial,::typeof(Luxor.fillpreserve),args...)
  if draw_state==false
    return nothing
  else
    fillpreserve()
  end
end

#strokepath
function overdub(c::ctx_partial,::typeof(Luxor.strokepath),args...)
  global cur_len_partial,draw_state
  if draw_state == false
    return nothing
  end
  polys,co_states = pathtopoly(true)
  newpath()
  for (poly_i,co) in zip(polys,co_states)
    if cur_len_partial >= target_len_partial
      return nothing
    else
      #since its a stroke we dont need path after this
      #move(poly_i[1])
      nextpolylength = polyperimeter(poly_i,closed=co)
      if cur_len_partial + nextpolylength < target_len_partial
        poly(poly_i,close=co) 
        cur_len_partial += nextpolylength
      else
        frac = (target_len_partial - cur_len_partial)/nextpolylength
        poly(polyportion(poly_i,frac,closed=co))
        cur_len_partial = target_len_partial
      end
    end
  strokepath()
  end
end

#function get_perimeter(f,args...)
#  prinln("hehe")
#  overdub(ctx_strokelength(), f,args...)
#  retlength = sum(cur_len_perim)
#  #global cur_len_perm = [0,]
#  return retlength
#end

function get_perimeter(v::Video,o::Object)
  global cur_len_perim = [0.0,]
  overdub(ctx_strokelength(),o.opts[:original_func],v,o,1)
  retlength = sum(cur_len_perim)
  global cur_len_perim = [0.0,]
  return retlength
end

function _draw_partial(p,perim,f,args...)
  gsave()
  @assert p<=1.0
  global target_len_partial = p*perim#get_perimeter(f,args...)
  newpath()
  ret = overdub(ctx_partial(),f,args...)
  global cur_len_partial = 0.0
  global draw_state = true
  grestore()
  ret
end

function _draw_partial(video,object,action,rel_frame)
  orig_func = object.opts[:original_func]
  p = get_interpolation(action,rel_frame)
  if !haskey(object.opts,:perimeter)
    x= get_perimeter(video,object)
    object.opts[:perimeter]  = x
  end
  object.func = (v,o,f)-> _draw_partial(p,object.opts[:perimeter],orig_func,v,o,f) 
end

#this should probably go into action_animations.jl 
function draw_partial()
  (video,object,action,rel_frame) ->
  _draw_partial(video,object,action,rel_frame)
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

