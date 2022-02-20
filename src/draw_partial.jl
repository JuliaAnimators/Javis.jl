import Cassette: @context, prehook , overdub
@context ctx_strokelength 
@context ctx_partial

cur_len_perim = [] #list of length of every stroke
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
function overdub(c::ctx_strokelength,::typeof(Luxor.fillpreserve))
  nothing
end

#sethue
function overdub(c::ctx_strokelength,::typeof(Luxor.sethue),args...)
  nothing
end

#latex
function overdub(c::ctx_strokelength,::typeof(latex),args...)
  latex(args...)
end

##CONTEXT partial

#latex
function overdub(c::ctx_partial,::typeof(latex),args...)
  latex(args...)
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
      """
      for point in poly_i[2:end]
        next_length = distance(point , currentpoint())
        if cur_len_partial+next_length < target_len_partial
          line(point)
          cur_len_partial = cur_len_partial + next_length
        else
          Δl = target_len_partial - cur_len_partial
          cp = currentpoint()
          newpoint = cp+ Δl*(point-cp)/distance(point,cp)
          line(newpoint)
          cur_len_partial = target_len_partial
          draw_state = false
        end
      end
      """
    end
  strokepath()
  end
end

function get_perimeter(f,args...)
  overdub(ctx_strokelength(), f,args...)
  retlength = sum(cur_len_perim)
  empty!(cur_len_perim)
  #println("poly dista ",retlength)
  return retlength
end

function draw_partial(p,f,args...)
  gsave()
  @assert p<=1.0
  global target_len_partial = p*get_perimeter(f,args...)
  newpath()
  overdub(ctx_partial(),f,args...)
  global cur_len_partial = 0.0
  global draw_state = true
  grestore()
end
export draw_partial
