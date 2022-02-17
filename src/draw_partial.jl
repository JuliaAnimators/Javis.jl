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
  polys = pathtopoly()
  len = sum(polyperimeter.(polys,closed=false))
  append!(cur_len_perim,len)
  newpath()
  nothing
end

#strokepreserve
function overdub(c::ctx_strokelength,::typeof(Luxor.strokepreserve),args...)
  polys = pathtopoly()
  len = sum(polyperimeter.(polys,closed=false))
  append!(cur_len_perim,len)
  newpath()
  nothing
end

#fillpath
function overdub(c::ctx_strokelength,::typeof(Luxor.fillpath))
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

##CONTEXT partial
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
  polys = pathtopoly()
  newpath()
  for poly in polys
    if cur_len_partial >= target_len_partial
      return nothing
    else
      #since its a stroke we dont need path after this
      move(poly[1])
      for point in poly[2:end]
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
    end
  end
  strokepath()
end

function get_perimeter(f,args...)
  overdub(ctx_strokelength(), f,)
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
