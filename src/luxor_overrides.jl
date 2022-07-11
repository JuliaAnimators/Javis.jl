DISABLE_LUXOR_DRAW = false
CURRENT_FETCHPATH_STATE = false

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
    CURRENTLY_RENDERING[1] || return Luxor.setline(linewidth)
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
    CURRENTLY_RENDERING[1] || return Luxor.setopacity(opacity)
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
    CURRENTLY_RENDERING[1] || return Luxor.fontsize(fsize)
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
    CURRENTLY_RENDERING[1] || return Luxor.get_fontsize()
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
    CURRENTLY_RENDERING[1] || return Luxor.scale(scl_x, scl_y)
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
    CURRENTLY_RENDERING[1] ||
        return Luxor.text(str, pos; valign = valign, halign = halign, angle = angle)
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

"""
   pathtopoly(::Val{:costate})

Method similar to Luxors `pathtopoly()`. Converts the current path to an array of polygons
and returns them. This function also returns an array of Bool (`co_states::Array{Bool}`) of exactly the same length as number of polygons that are being returned .
`co_states[i]` is `true/false` means `polygonlist[i]` is a closed/open polygon respectively.

Another minor change from luxors `pathtopoly()`  is when a CAIRO_PATH_MOVE_TO is encountered , a new poly is started.

Returns Tuple(Array{Point},Array{Bool})
"""
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
            if length(pointslist) == 2
                insert!(pointslist, 2, sum(pointslist) / 2)#insert midpoint if only 2 points are there
            end
            if (last(pointslist) == first(pointslist)) && length(pointslist) > 2
                #but first lets check if what we flush is closed or open. 
                push!(co_states, true)
                pop!(pointslist)
            else
                push!(co_states, false)
            end
            push!(polygonlist, pointslist)
        end
    end
    #"""check if everything went well"""
    @assert length(polygonlist) == length(co_states)
    #"""return polygonlist, and its closed/open state"""
    return polygonlist, co_states
end


"""
    _betweenpoly_noresample(loop1,loop2,k; easingfunction = easingflat)

Just like _betweenpoly from Luxor , but expects polygons `loop1` and `oop2` to be of same size , and
therefore does not resample them to be of same size.

From Luxor Docs:
Find a simple polygon between the two simple polygons loop1 and loop2 corresponding to k,
  where 0.0 < k < 1.0.

Arguments
loop1: first polygon 
loop2: second polygon 
k: interpolation factor
"""
function _betweenpoly_noresample(
    loop1,
    loop2,
    k,
    offset = (:former, 1);
    easingfunction = easingflat,
)
    @assert length(loop1) == length(loop2)
    result = Point[]
    eased_k = easingfunction(k, 0.0, 1.0, 1.0)
    for j in 1:length(loop1)
        indj = mod1(j + offset[2] - 1, length(loop1))
        if offset[1] == :former
            push!(result, between(loop1[indj], loop2[j], eased_k))
        else
            push!(result, between(loop1[j], loop2[indj], eased_k))
        end
    end
    return result
end
#this is lifted from luxor, we should ask cormullion if its okay
"""

        polymorph_noresample(
            pgon1::Array{Array{Point,1}},
            pgon2::Array{Array{Point,1}},
            k;
            easingfunction = easingflat,
            kludge = true,
        )

like luxors `polymorph` , but does not resample the polygon , therefore every
polygon in `pgon1` and `pgon2` should have the same number of points. used by
`_morph_jpath`.

From Luxor Docs:

"morph" is to gradually change from one thing to another. This function changes one polygon
  into another.

  It returns an array of polygons, [p_1, p_2, p_3, ... ], where each polygon p_n is the
  intermediate shape between the corresponding shape in pgon1[1...n] and pgon2[1...n] at k,
  where 0.0 < k < 1.0. If k ≈ 0.0, the pgon1[1...n] is returned, and if `k ≈ 1.0,
  pgon2[1...n] is returned.

  pgon1 and pgon2 can be either simple polygons or arrays of one or more polygonal shapes (eg
  as created by pathtopoly()). For example, pgon1 might consist of two polygonal shapes, a
  square and a triangular shaped hole inside; pgon2 might be a triangular shape with a square
  hole.

  It makes sense for both arguments to have the same number of polygonal shapes. If one has
  more than another, some shapes would be lost when it morphs. But the suggestively-named
  kludge keyword argument, when set to (the default) true, tries to compensate for this.

  By default, easingfunction = easingflat, so the intermediate steps are linear. If you use
  another easing function, intermediate steps are determined by the value of the easing
  function at k.

"""
function polymorph_noresample(
    pgon1::Array{Array{Point,1}},
    pgon2::Array{Array{Point,1}},
    k,
    offsets = Array{Int};
    easingfunction = easingflat,
    kludge = true,
)
    isapprox(k, 0.0) && return pgon1
    isapprox(k, 1.0) && return pgon2
    loopcount1 = length(pgon1)
    loopcount2 = length(pgon2)
    result = Array{Point,1}[]
    centroid1 = centroid2 = O # kludge-y eh?
    for i in 1:max(loopcount1, loopcount2)
        from_ok = to_ok = false
        not_empty1 = i <= loopcount1
        not_empty2 = i <= loopcount2
        if (not_empty1 && length(pgon1[i]) >= 3)
            from_ok = true
        end
        if (not_empty2 && length(pgon2[i]) >= 3)
            to_ok = true
        end
        if from_ok && to_ok
            # a simple morph should suffice
            push!(
                result,
                _betweenpoly_noresample(
                    pgon1[i],
                    pgon2[i],
                    k,
                    offsets[i],
                    easingfunction = easingfunction,
                ),
            )
            centroid1 = polycentroid(pgon1[i])
            centroid2 = polycentroid(pgon2[i])
        elseif from_ok && !to_ok && kludge
            # nothing to morph to, so make something up
            pdir = !ispolyclockwise(pgon1[i])
            loop2 =
                ngon(centroid2, 0.1, reversepath = pdir, length(pgon1[i]), vertices = true)
            push!(
                result,
                _betweenpoly_noresample(
                    pgon1[i],
                    loop2,
                    k,
                    offsets[i],
                    easingfunction = easingfunction,
                ),
            )
            centroid1 = polycentroid(pgon1[i])
        elseif !from_ok && to_ok && kludge
            # nothing to morph from, so make something up
            pdir = !ispolyclockwise(pgon2[i])
            loop1 =
                ngon(centroid1, 0.1, reversepath = pdir, length(pgon2[i]), vertices = true)
            push!(
                result,
                _betweenpoly_noresample(
                    loop1,
                    pgon2[i],
                    k,
                    offsets[i],
                    easingfunction = easingfunction,
                ),
            )
            centroid2 = polycentroid(pgon2[i])
        end
    end
    return result
end

#Luxor.DISPATCHER is assigned this type in `render` 
abstract type JavisLuxorDispatcher end

for funcname in [:strokepath,:strokepreserve,:fillpath,:fillpreserve]
    expr = quote 
        function Luxor.$funcname(::Type{JavisLuxorDispatcher})
            if CURRENT_FETCHPATH_STATE
                occursin("stroke",string($funcname)) ? update_currentjpath(:stroke) : update_currentjpath(:fill)
            end
            if !DISABLE_LUXOR_DRAW
                $funcname(Luxor.DefaultLuxor)
            elseif !occursin("preserve",string($funcname))
                newpath()
            end
        end
    end
    eval(expr)
end
