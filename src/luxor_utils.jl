"""
	javis_do_action(action::Symbol)

`action` is either of the four `:fill,:stroke,:fillpreserve,:strokepreserve`.
and it executes the respective Luxor action . Behaviour depends on two globals
if CURRENT_FETCHPATH_STATE is true it converts the current path to a JPath and 
appends to CURRENT_JPATH. 
if DISABLE_LUXOR_DRAW is true , does not draw anything on to the canvas.

This function is called from Luxor (check luxors source of `strokepath`).
"""
function javis_do_action(action::Symbol)
    if CURRENT_FETCHPATH_STATE
        if action == :fill || action == :fillpreserve
            update_currentjpath(:fill)
        elseif action == :stroke || action == :strokepreserve
            update_currentjpath(:stroke)
        end
    end
    if !DISABLE_LUXOR_DRAW
        if action == :stroke
            Luxor.get_current_strokescale() ?
            Cairo.stroke_transformed(Luxor.get_current_cr()) :
            stroke(Luxor.get_current_cr())
        elseif action == :strokepreserve
            Luxor.get_current_strokescale() ?
            Luxor.Cairo.stroke_preserve_transformed(Luxor.get_current_cr()) :
            Luxor.Cairo.stroke_preserve(Luxor.get_current_cr())
        elseif action == :fill
            Luxor.Cairo.fill(Luxor.get_current_cr())
        elseif action == :fillpreserve
            Luxor.Cairo.fill_preserve(Luxor.get_current_cr())
        end
    elseif action == :fill || action == :stroke
        newpath()
    end
end

"""
    apply_transform(transform::Vector{Float64} , poly::Vector{Point})

applies the transform , got by getmatrix() on every point in the poly
and returns a new poly.

move this to luxor_overrides_util.jl later.
"""
function apply_transform(transform::Vector{Float64}, poly::Vector{Point})
    retpoly = Point[]
    for pt in poly
        res = cairotojuliamatrix(transform) * [pt[1], pt[2], 1]
        push!(retpoly, Point(res[1], res[2]))
    end
    retpoly
end

"""
    update_currentjpath(action::Symbol)

Updates the CURRENT_JPATHS
This function is used  inside the strokepath/strokepreserve/fillpath/fillpreserve.
Converts the current Path and other drawing states into a JPath and appends to the CURRENT_JPATHS global.

the argument is a symbol either `:stroke` or `:fill` , to change behaviour
for stroke vs fill.
"""
function update_currentjpath(action::Symbol)
    #println("test strokepaths")
    cur_polys, cur_costates = pathtopoly(Val(:costate))#this pathtopoly is defined in javis
    @assert length(cur_polys) == length(cur_costates)
    transform = getmatrix()
    cur_polys = [apply_transform(transform, poly) for poly in cur_polys]
    #cur_polys is of 2 element Tuple 
    #containg 2 arrays 1 with Polygons and one with the bools
    r = get_current_redvalue()
    g = get_current_greenvalue()
    b = get_current_bluevalue()
    a = get_current_alpha()
    #by default they are black transparent 
    fillstroke = Dict(:fill => [0.0, 0, 0, 0], :stroke => [0.0, 0, 0, 0])
    fillstroke[action] .= [r, g, b, a]
    #if polys didnt change we just modify the last JPath in the CURRENT_JPATHS
    if length(CURRENT_JPATHS) > 0 && cur_polys == CURRENT_JPATHS[end].polys
        setproperty!(CURRENT_JPATHS[end], action, fillstroke[action])
        setproperty!(CURRENT_JPATHS[end], :lastaction, action)
    else
        currpath = JPath(
            cur_polys,
            cur_costates,
            fillstroke[:fill],
            fillstroke[:stroke],
            action,
            2,
        )
        push!(CURRENT_JPATHS, currpath)
    end
end
