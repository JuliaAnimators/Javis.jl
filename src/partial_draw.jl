#code to enable partially drawing an object
#and animate its creation . 
#
#Move these function to appropriate files later
#
function showcreation(frac = 1)
    return (video, object, action, rel_frame) -> begin
        fraction = get_interpolation(action, rel_frame) * frac
        _drawpartial(video, action, object, rel_frame, fraction)
    end
end

function showdestruction()
    return (video, object, action, rel_frame) -> begin
        fraction = get_interpolation(action, rel_frame)
        _drawpartial(video, action, object, rel_frame, 1.0 - fraction)
        if rel_frame == last(get_frames(action))
            object.func = (args...) -> nothing
        end
    end
end

function drawpartial(fraction::Real)
    return (video, object, action, rel_frame) ->
        _drawpartial(video, action, object, rel_frame, fraction::Real)
end

function _drawpartial(video, action, object, rel_frame, fraction::Real)
    isempty(object.jpaths) && getjpaths!(object, object.opts[:original_func])
    rel_frame == first(get_frames(action)) && jpath_polylengths!.(object.jpaths)
    partialjpaths = getpartialjpaths(object, fraction)
    object.func = (args...) -> begin
        drawjpaths(partialjpaths)
        global DISABLE_LUXOR_DRAW = true
        object.opts[:original_func](args...)
        global DISABLE_LUXOR_DRAW = false
    end
    isapprox(fraction, 1) && (object.func = object.opts[:original_func])
end

len_jpath(jpath::JPath) = sum([
    polydistances(jpath.polys[i], closed = jpath.closed[i])[end] for
    i in 1:length(jpath.polys)
])
"""
    getpartialjpaths(object,fraction)

returns an array of jpaths , that if drawn will look like partially drawn `object`
partially drawn upto `fraction`
"""
function getpartialjpaths(object, fraction)
    # there are 3 layers to this
    # first we need to figure out which JPath the fraction is in
    # then we need to figure out which poly of that JPath it is in
    # then we need to figure out how much of that poly to draw, (use polyportion on that poly with an appropriate fraction)
    # naming variables is a @#*!$ :(

    ret_jpaths = JPath[]
    lengths_of_jpaths = len_jpath.(object.jpaths)
    #fraction cumulative sum of lengths of jpaths
    frac_cs_len_jp = (cumsum(lengths_of_jpaths) ./ sum(lengths_of_jpaths))
    jp_idx = 1 #index at which the fraction lies
    for i in 1:length(object.jpaths)
        jp_idx = i
        if frac_cs_len_jp[i] > fraction
            break
        end
    end
    #@assert jp_idx != 1
    #we got which jpath , 


    append!(ret_jpaths, object.jpaths[1:(jp_idx - 1)])
    #now which poly in this jpath ?...
    fin_jpath = deepcopy(object.jpaths[jp_idx]) #the jpath we determined the fraction is in.
    #this is a deepcopy because we will change this jpath's polys appropriatly and append to ret_jpaths 

    #cumsum of final jpath poly distances
    cs_fin_jpd = cumsum([
        polydistances(poly, closed = close)[end] for
        (poly, close) in zip(fin_jpath.polys, fin_jpath.closed)
    ])
    cs_fin_jpd = cs_fin_jpd ./ cs_fin_jpd[end]
    #fraction in this final jpath that we should stop at.
    prevfrac = jp_idx == 1 ? 0 : frac_cs_len_jp[jp_idx - 1]
    currfrac = frac_cs_len_jp[jp_idx]
    fraction_jpath = (fraction - prevfrac) / (currfrac - prevfrac)
    p_idx = 1 #index for poly in fin_jpath
    for i in 1:length(fin_jpath.polys)
        p_idx = i
        if cs_fin_jpd[i] > fraction_jpath
            break
        end
    end
    prevfrac = p_idx == 1 ? 0 : cs_fin_jpd[p_idx - 1]
    currfrac = cs_fin_jpd[p_idx]
    fraction_poly = (fraction_jpath - prevfrac) / (currfrac - prevfrac)

    fin_jpath.polys = [
        fin_jpath.polys[1:(p_idx - 1)]...,
        polyportion(
            fin_jpath.polys[p_idx],
            fraction_poly,
            closed = fin_jpath.closed[p_idx],
        ),
    ]
    fin_jpath.closed = [fin_jpath.closed[1:(p_idx - 1)]..., false]
    #fin_jpath.closed = fin_jpath.closed[1:p_idx]#... , false]
    push!(ret_jpaths, fin_jpath)
    return ret_jpaths
end

# 
# _drawpartial(v,o,a,f,frac)
#
# showcreation()
#  _drawpartial([0,1],[0,1],anim_drawpartial())
#
# return (v,o,a,f)-> 
# #what would morphing at the time of showing creation mean ?
# needn't worry about morphin g and creation at the same time
