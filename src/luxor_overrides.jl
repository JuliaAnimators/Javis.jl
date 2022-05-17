DISABLE_LUXOR_DRAW = false
"""
    setline(linewidth)

Set the line width and multiply it with the current multiplier
which is i.e. set by [`appear`](@ref) and [`disappear`](@ref).

Normal behavior without any animation is the same as `Luxor.setline`.

# Example
```julia
setline(10)
line(O, Point(10, 10))
```

# Arguments:
- `linewidth`: the line width in pixel
"""
function setline(linewidth)
    cs = get_current_setting()
    cs.line_width = linewidth
    current_line_width = cs.line_width * cs.mul_line_width
    Luxor.setline(current_line_width)
end

"""
    setopacity(opacity)

Set the opacity and multiply it with the current multiplier
which is i.e. set by [`appear`](@ref) and [`disappear`](@ref).

Normal behavior without any animation is the same as `Luxor.setopacity`.

# Example
```julia
setopacity(0.5)
circle(O, 20, :fill)
```

# Arguments:
- `opacity`: the opacity between 0.0 and 1.0
"""
function setopacity(opacity)
    cs = get_current_setting()
    cs.opacity = opacity
    current_opacity = cs.opacity * cs.mul_opacity
    Luxor.setopacity(current_opacity)
end

"""
    fontsize(fsize)

Same as `Luxor.fontsize`: Sets the current font size.

# Example
```julia
fontsize(12)
text("Hello World!")
```

# Arguments:
- `fsize`: the new font size
"""
function fontsize(fsize)
    cs = get_current_setting()
    cs.fontsize = fsize
    Luxor.fontsize(fsize)
end

"""
    get_fontsize(fsize)

Same as `Luxor.get_fontsize` but works with every version of Luxor that is supported by Javis.

# Example
```julia
fontsize(12)
fsize = get_fontsize()
text("Hello World! \$fsize")
```

# Returns
- `Float64`: the current font size
"""
function get_fontsize()
    cs = get_current_setting()
    return cs.fontsize
end

"""
    scale(scl)

Set the scale and multiply it with the current multiplier
which is i.e. set by [`appear`](@ref) and [`disappear`](@ref).

Normal behavior without any animation is the same as `Luxor.scale`.

# Example
```julia
scale(0.5)
circle(O, 20, :fill) # the radius would be 10 because of the scaling
```

# Arguments:
- `scl`: the new default scale
"""
function scale(scl::Number)
    scale(scl, scl)
end

function scale(scl::Scale)
    scale(scl.x, scl.y)
end

"""
    scale(scl_x, scl_y)

Same as [`scale`](@ref) but the x scale and y scale can be changed independently.

# Arguments:
- `scl_x`: scale in x direction
- `scl_y`: scale in y direction
"""
function scale(scl_x, scl_y)
    cs = get_current_setting()
    cs.desired_scale = Scale(scl_x, scl_y)
    scale_by = cs.desired_scale * cs.mul_scale
    if scale_by.x ≈ 0.0 || scale_by.y ≈ 0.0
        cs.show_object = false
    else
        Luxor.scale(scale_by.x, scale_by.y)
        cs.current_scale = cs.current_scale * scale_by
    end
end

scaleto(s::Scale) = scaleto(s.x, s.y)
scaleto(xy) = scaleto(xy, xy)

"""
    scaleto(x, y)

Scale to a specific scaling instead of multiplying it with the current scale.
For scaling on top of the current scale have a look at [`scale`](@ref).
"""
function scaleto(x, y)
    cs = get_current_setting()
    cs.desired_scale = Scale(x, y)
    scaling = Scale(x, y) / cs.current_scale
    # we divided by 0 but clearly we want to scale to 0
    # -> we want scaling to be 0 not Inf
    if x ≈ 0 || y ≈ 0
        cs.show_object = false
        return
    end
    Luxor.scale(scaling.x, scaling.y)
    cs.current_scale = Scale(x, y)
end

"""
    animate_text(
        str,
        pos::Point,
        valign::Symbol,
        halign::Symbol,
        angle::Float64,
        t::Float64,
    )

This function is used as a subfunction of [`text`](@ref) and animates the `str` by
clipping the textoutlines and creating a growing circle in the lower left corner to display
the text from left to right in an animated fashion.
"""
function animate_text(
    str,
    pos::Point,
    valign::Symbol,
    halign::Symbol,
    angle::Float64,
    t::Float64,
)
    if t >= 1
        return Luxor.text(str, pos; valign = valign, halign = halign, angle = angle)
    end

    # copied from Luxor.text
    xbearing, ybearing, textwidth, textheight, xadvance, yadvance = textextents(str)
    halignment = findfirst(isequal(halign), [:left, :center, :right, :centre])

    # if unspecified or wrong, default to left, also treat UK spelling centre as center
    if halignment === nothing
        halignment = 1
    elseif halignment == 4
        halignment = 2
    end

    textpointx = pos.x - [0, textwidth / 2, textwidth][halignment]

    valignment = findfirst(isequal(valign), [:top, :middle, :baseline, :bottom])

    # if unspecified or wrong, default to baseline
    if valignment === nothing
        valignment = 3
    end

    textpointy = pos.y - [ybearing, ybearing / 2, 0, textheight + ybearing][valignment]


    gsave()
    translate(Point(textpointx, textpointy))
    rotate(angle)
    # clipping region
    textoutlines(str, O, :clip)
    complete_radius = sqrt(textwidth^2 + textheight^2)
    r = t * complete_radius
    circle(O, r, :fill)
    grestore()
    return Point(textpointx, textpointy)
end

"""
    text(str, pos = O; valign = :baseline, halign = :left, angle = 0.0)

Has bacially the same functionality as Luxor.text but overrides that method to allow to
animate text with [`appear`](@ref).

# Example
```julia
text_obj = Object(1:100, (args...) -> text("Hello Stream!"; halign = :center))
act!(text_obj, Action(1:15, sineio(), appear(:draw_text)))
act!(text_obj, Action(76:100, sineio(), disappear(:draw_text)))
```
draws the text from left to right in the first 15 frames and in the last 15 frames it disappears.

# Arguments
- `str::AbstractString` the string that should be shown
- `pos::Point` defaults to the origin and can be written as `x,y` as well as `Point(x,y)`.

# Keywords
- `valign::Symbol` defaults to `:baseline` and takes `(:top, :middle, :bottom, :baseline)`
- `halign::Symbol` defaults to `:left` and takes `(:left, :center, :centre, :right)`
- `angle::Float64` defaults to `0.0` and specifies the angle of the text
"""
function text(str, pos = O; valign = :baseline, halign = :left, angle = 0.0)
    object = CURRENT_OBJECT[1]
    opts = object.opts
    t = get(opts, :draw_text_t, 1.0)
    return animate_text(str, pos, valign, halign, angle, t)
end

function text(str, x, y; kwargs...)
    text(str, Point(x, y); kwargs...)
end

"""
    background(str)

Has bacially the same functionality as Luxor.background() but overrides that method to allow for
transparent layers.

Checks if a layer should be present, and if a background has been defined or not for the current layer.

# Arguments
- `background_color` background color
"""
function background(background_color)
    # In the case of main video's background, this shouldn't create a problem as long as the CURRENT_LAYER is cleared 
    # before moving to rendering of independent objects in [`get_javis_frame`](@ref)
    if !isempty(CURRENT_LAYER)
        layer_bg =
            filter(x -> get(x.opts, :in_local_layer, false), CURRENT_LAYER[1].layer_objects)
        if isempty(layer_bg) && get(CURRENT_LAYER[1].opts, :transparent, false)
            background_color = RGBA(0, 0, 0, 0)
        end
    end
    Luxor.background(background_color)
end

function apply_transform(transform::Vector{Float64}, poly::Vector{Point})
    retpoly = Point[]
    for pt in poly
        res = cairotojuliamatrix(transform) * [pt[1], pt[2], 1]
        push!(retpoly, Point(res[1], res[2]))
    end
    retpoly
end

function Luxor.strokepath()
    #save path to CURRENT_JPATH
    #TODO 
    #linewidth
    #check for transform , refer TODO comment in the struct definition of JPath.
    #dashstyle
    if CURRENT_FETCHPATH_STATE == true
        #println("test strokepaths")
        cur_polys, cur_costates = pathtopoly(Val(:costate))
        transform = getmatrix()
        cur_polys = [apply_transform(getmatrix(), poly) for poly in cur_polys]
        #cur_polys is of 2 element Tuple 
        #containg 2 arrays 1 with Polygons and one with the bools
        r, g, b, a = map(
            sym -> getfield(Luxor.CURRENTDRAWING[1], sym),
            [:redvalue, :greenvalue, :bluevalue, :alpha],
        )
        fill = [0.0, 0, 0, 0]
        stroke = [r, g, b, a]
        #if polys didnt change we just modify the last JPath in the
        #CURRENT_JPATHS
        #TODO see if the == operator is the right way to compare
        #two polys.
        if length(CURRENT_JPATHS) > 0 && cur_polys == CURRENT_JPATHS[end].polys
            #print("found similar path\n")
            CURRENT_JPATHS[end].stroke = stroke
        else
            #println("adding to CURRENT_JPATH")
            currpath = JPath(cur_polys, cur_costates, fill, stroke, 2)
            push!(CURRENT_JPATHS, currpath)
        end
    end
    if !DISABLE_LUXOR_DRAW
        Luxor.get_current_strokescale() ?
        Luxor.Cairo.stroke_transformed(Luxor.get_current_cr()) :
        Luxor.Cairo.stroke(Luxor.get_current_cr())
    end
end

function Luxor.strokepreserve()
    #TODO
    #linewidth
    #transform
    #dashstyle
    if CURRENT_FETCHPATH_STATE == true
        #println("teststrokepreserves")
        cur_polys, cur_costates = pathtopoly(Val(:costate))
        transform = getmatrix()
        cur_polys = [apply_transform(getmatrix(), poly) for poly in cur_polys]
        r, g, b, a = map(
            sym -> getfield(Luxor.CURRENTDRAWING[1], sym),
            [:redvalue, :greenvalue, :bluevalue, :alpha],
        )
        fill = [0.0, 0, 0, 0]
        stroke = [r, g, b, a]
        #TODO check == 
        if length(CURRENT_JPATHS) > 0 && cur_polys == CURRENT_JPATHS[end].polys
            #print("found similar path\n")
            CURRENT_JPATHS[end].stroke = stroke
        else
            #println("adding to CURRENT_JPATH")
            currpath = JPath(cur_polys, cur_costates, fill, stroke, 2)
            push!(CURRENT_JPATHS, currpath)
        end
    end
    if !DISABLE_LUXOR_DRAW
        Luxor.get_current_strokescale() ?
        Luxor.Cairo.stroke_preserve_transformed(Luxor.get_current_cr()) :
        Luxor.Cairo.stroke_preserve(Luxor.get_current_cr())
    end

end

function Luxor.fillpath()
    #TODO 
    #linewidth
    #transform
    #dashstyle
    if CURRENT_FETCHPATH_STATE == true
        #println("test fillpath")
        cur_polys, cur_costates = pathtopoly(Val(:costate))
        transform = getmatrix()
        cur_polys = [apply_transform(getmatrix(), poly) for poly in cur_polys]
        r, g, b, a = map(
            sym -> getfield(Luxor.CURRENTDRAWING[1], sym),
            [:redvalue, :greenvalue, :bluevalue, :alpha],
        )
        fill = [r, g, b, a]
        stroke = [0.0, 0.0, 0.0, 0.0]
        #TODO check == 
        if length(CURRENT_JPATHS) > 0 && cur_polys == CURRENT_JPATHS[end].polys
            #print("found similar path\n")
            CURRENT_JPATHS[end].fill = fill
        else
            #println("adding to CURRENT_JPATH")
            currpath = JPath(cur_polys, cur_costates, fill, stroke, 2)
            push!(CURRENT_JPATHS, currpath)
        end
    end
    if !DISABLE_LUXOR_DRAW
        Luxor.Cairo.fill(Luxor.get_current_cr())
    end
end

function Luxor.fillpreserve()
    #TODO 
    #linewith
    #transform
    #dashtyle
    if CURRENT_FETCHPATH_STATE == true
        #println("test fill preserve")
        #println("adding to CURRENT_JPATH")
        cur_polys, cur_costates = pathtopoly(Val(:costate))
        transform = getmatrix()
        cur_polys = [apply_transform(getmatrix(), poly) for poly in cur_polys]
        #if polys is 
        r, g, b, a = map(
            sym -> getfield(Luxor.CURRENTDRAWING[1], sym),
            [:redvalue, :greenvalue, :bluevalue, :alpha],
        )
        fill = [r, g, b, a]
        stroke = [0.0, 0.0, 0.0, 0.0]
        #TODO check == 
        if length(CURRENT_JPATHS) > 0 && cur_polys == CURRENT_JPATHS[end].polys
            #print("found similar path\n")
            CURRENT_JPATHS[end].fill = fill
        else
            #print("adding newpath\n")
            currpath = JPath(cur_polys, cur_costates, fill, stroke, 2)
            push!(CURRENT_JPATHS, currpath)
        end
    end
    if !DISABLE_LUXOR_DRAW
        Luxor.Cairo.fill_preserve(Luxor.get_current_cr())
    end
end



function Luxor.pathtopoly(::Val{:costate})
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
                if length(pointslist) == 2
                    insert!(pointslist, 2, sum(pointslist) / 2)#insert midpoint if only 2 points are there
                end
                push!(polygonlist, pointslist)
                pointslist = Point[]
            else
                error("pathtopoly(): unknown CairoPathEntry " * repr(e.element_type))
                error("pathtopoly(): unknown CairoPathEntry " * repr(e.points))
            end
        end
        # the path was never closed, so flush
        if length(pointslist) > 1 #dont flush paths if only 1 point remains
            push!(co_states, false)
            if length(pointslist) == 2
                insert!(pointslist, 2, sum(pointslist) / 2)#insert midpoint if only 2 points are there
            end
            push!(polygonlist, pointslist)
        end
    end
    #"""check if everything went well"""
    @assert length(polygonlist) == length(co_states)
    #"""return polygonlist, and its closed/open state"""
    return polygonlist, co_states
end
