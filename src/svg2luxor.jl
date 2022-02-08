#=
    This file handles the conversion from svg produced by `tex2svg` to Luxor commands.
    It currently misses a lot of possible commands that svg supports.
    Warnings are thrown if this happens such that one can easily grasp whether it
    should have worked or whether there is something missing
=#

"""
    float_attribute(o, name)

Get the attribute `name` of the XMLElement and parse it as a Float64
"""
float_attribute(o::LightXML.XMLElement, name) = parse(Float64, attribute(o, name))

#=
    draw_obj functions have a type which is the type of the svg element.
    i.e <rect calls the `draw_obj(::Val{:rect}, o, defs)` command or `::Val{:path}` for `<path`
=#

"""
    draw_obj(::Val{:rect}, o, defs)

Draw the rectangle defined by the object `o`.
"""
function draw_obj(::Val{:rect}, o, defs)
    width = float_attribute(o, "width")
    height = float_attribute(o, "height")
    x = float_attribute(o, "x")
    y = float_attribute(o, "y")
    # TODO: draw it anti clockwise as it gets scaled to clockwise :/
    move(Point(x + width, y))
    line(Point(x, y))
    line(Point(x, y + height))
    line(Point(x + width, y + height))
    closepath()
end

"""
    draw_obj(::Val{:g}, o, defs)

Draws a group by setting the attributes (like transformations)
and then calls `draw_obj` for all child elements.
"""
function draw_obj(::Val{:g}, o, defs)
    set_attrs(o)

    childs = collect(child_elements(o))
    for child in childs
        sym_name = Symbol(name(child))
        @layer begin
            draw_obj(Val{sym_name}(), child, defs)
        end
    end
end

"""
    draw_obj(::Val{:use}, o, defs)

Calls the command specified in `defs`.
"""
function draw_obj(::Val{:use}, o, defs)
    set_attrs(o)
    id = attribute(o, "href")[2:end]

    if haskey(defs, id)
        def = defs[id]
        sym = Symbol(name(def))
        draw_obj(Val{sym}(), def, defs)
    else
        @warn "There is no definition for $id"
    end
end

"""
    draw_obj(::Val{:path}, o, defs)

Calls the commands specified in the path data.
Currently supports only a subset of possible SVG commands.
"""
function draw_obj(::Val{:path}, o, defs)
    set_attrs(o)
    data = attribute(o, "d")
    counter = 0

    # split without loosing the command
    stroke_width = check_stroke(o)
    """if stroke_width is nothing , we are parsing a poly, else we are parsing a stroke
    we will go along the stroke path and make an offset poly of stroke-width around the poly, the we traverse a path on that poly """

    """This way svg-strokes with certain width are drawn in luxor"""
    if stroke_width != nothing
        path_so_far = storepath()
        newpath()
    end


    data_parts = split(data, r"(?=[A-Za-z])")
    # needs to keep track of the current point `c_pt` and the last point `l_pt`
    l_pt = O
    c_pt = O
    circle_pts = []
    for pi in 1:length(data_parts)
        p = data_parts[pi]
        command, args = p[1], p[2:end]
        args = replace(args, "-" => " -")
        if command != 'T'
            counter = 0
        end
        # using if else statements instead of dispatching here. Maybe it's faster :D
        if command == 'M'
            c_pt = path_move(parse.(Float64, split(args))...)
            # need to set the last control point as the current point for 'T'
            l_pt = c_pt
        elseif command == 'Q'
            l_pt, c_pt = path_quadratic(c_pt, parse.(Float64, split(args))...)
        elseif command == 'T'
            # the control point is a reflection based on the current and last point
            control_pt = l_pt + 2 * (c_pt - l_pt)
            l_pt, c_pt =
                path_quadratic(c_pt, control_pt..., parse.(Float64, split(args))...)
            push!(circle_pts, Point(parse.(Float64, split(args))...))
            counter += 1
        elseif command == 'L'
            new_pt = Point(parse.(Float64, split(args))...)
            line(new_pt)
            l_pt, c_pt = c_pt, new_pt
        elseif command == 'H'
            new_pt = Point(parse(Float64, args), c_pt.y)
            line(new_pt)
            l_pt, c_pt = c_pt, new_pt
        elseif command == 'V'
            new_pt = Point(c_pt.x, parse(Float64, args))
            line(new_pt)
            l_pt, c_pt = c_pt, new_pt
        elseif command == 'C'
            #println("processing command C with args ", args...)
            control_pt1 = parse.(Float64, split(args))[1:2]
            control_pt2 = parse.(Float64, split(args))[3:4]
            endpt = parse.(Float64, split(args))[5:6]
            curve(control_pt1..., control_pt2..., endpt...)
            l_pt, c_pt = Point(control_pt2...), Point(endpt...)
        elseif command == 'S'
            control_pt1 = l_pt + 2 * (c_pt - l_pt)
            control_pt2 = parse.(Float64, split(args))[1:2]
            endpt = parse.(Float64, split(args))[3:4]
            curve(control_pt1..., control_pt2..., endpt...)
            l_pt, c_pt = Point(control_pt2...), Point(endpt...)
        elseif command == 'Z'
            closepath()
        else
            @warn "Couldn't parse the svg command: $command"
        end
    end

    if stroke_width != nothing
        """if stroke_width! is nothing , we had a stroke attr in the path
        which also means there was no Z command and our path exists
        """
        polyp = poly(pathtopoly()..., :none)
        if length(polyp) == 2
            insert!(polyp, 2, (polyp[1] + polyp[2]) / 2)
        end
        #@infiltrate 
        offsetp = offsetpoly(polyp, startoffset = stroke_width, endoffset = stroke_width)
        drawpath(path_so_far, :path)
        poly(offsetp, :path, close = true)
    end

end


#=
    All kinds of commands for creating a path. The commands need to return the current point
    some of them also a previous point
=#

"""
    path_move(x,y)

Moving to the specified point
"""
function path_move(x, y)
    p = Point(x, y)
    move(p)
    p
end

"""
    path_quadratic(c_pt::Point, x,y, xe, ye)

Drawing a quadratic bezier curve by computing a cubic one as that is supported by Luxor
"""
function path_quadratic(c_pt::Point, x, y, xe, ye)
    e_pt = Point(xe, ye)
    qc = Point(x, y)
    # compute the control points of a cubic bezier curve
    c1 = c_pt + 2 / 3 * (qc - c_pt)
    c2 = e_pt + 2 / 3 * (qc - e_pt)
    curve(c1, c2, e_pt)
    return qc, e_pt
end

#=
    All kinds of setting attribute functions
=#

"""
    set_attrs(o)

Setting the attributes of the object `o` by calling `set_attr` methods.
"""
function set_attrs(o)
    for attribute in attributes(o)
        sym = Symbol(name(attribute))
        set_attr(Val{sym}(), LightXML.value(attribute))
    end
end

function check_stroke(o)
    """checks for stroke attribute , if exists and a stroke-width exists returns
    value of stroke-width, else returns nothing
    (although we probably could directly check for stroke-width???)
    """
    attrs = name.(attributes(o))
    if "stroke" in attrs && "stroke-width" in attrs
        return float_attribute(o, "stroke-width")
    else
        return nothing
    end
end

"""
    set_attr(::Val{:transform}, transform_strs)

Call the corresponding `set_transform` method i.e `matrix`, `scale` and `translate`
"""
function set_attr(::Val{:transform}, transform_strs)
    if transform_strs !== nothing
        transform_parts = split(transform_strs, r"(?<=[)]) ")
        for transform_str in transform_parts
            m = match(r"(.+)\((.+)\)", transform_str)
            type = Symbol(m.captures[1])
            set_transform(
                Val{type}(),
                parse.(Float64, strip.(split(m.captures[2], r"[, ]")))...,
            )
        end
    end
end

set_attr(::Val{:x}, x) = translate(parse(Float64, x), 0)
set_attr(::Val{:y}, y) = translate(0, parse(Float64, y))
set_attr(::Val{Symbol("stroke-width")}, sw) = setline(parse(Float64, sw))

set_transform(::Val{:translate}, x, y) = translate(x, y)
set_transform(::Val{:scale}, x, y = x) = scale(x, y)

"""
    set_transform(::Val{:matrix}, args...)

Multiply the new matrix with the current matrix and set it.
"""
function set_transform(::Val{:matrix}, args...)
    old = cairotojuliamatrix(getmatrix())
    update = cairotojuliamatrix(collect(args))
    new = old * update
    # only the first two rows are considered
    setmatrix(vec(new[1:2, :]))
end

#=
    General fallbacks
=#
draw_obj(::Union{Val{:title},Val{:defs}}, o, defs) = nothing
# no support for colors at this point
set_attr(t::Union{Val{:stroke},Val{:fill},Val{Symbol("aria-hidden")}}, args...) = nothing

draw_obj(t, o, defs) = @warn "Can't draw $t"
set_transform(t, args...) = @warn "Can't transform $t"
set_attr(::Val{:href}, args...) = nothing
set_attr(::Val{:d}, args...) = nothing
set_attr(::Val{:id}, args...) = nothing
let shown_warning = []
    """warn user only once of missing attr"""
    global function set_attr(t, args...)
        if t in shown_warning
            nothing
        else
            @warn "No attr match for $t"
            push!(shown_warning, t)
        end
    end
end

"""
    svgwh(svg)

Return the width and height of svg displayed scaled to half the font size. 
"""
function svgwh(svg)
    fsize = get_current_setting().fontsize
    xdoc = parse_string(svg)
    xroot = root(xdoc)
    # remove ex in the end , or pt in the case of dvisvgm
    ex_width = parse(Float64, attribute(xroot, "width")[1:(end - 2)])
    ex_height = parse(Float64, attribute(xroot, "height")[1:(end - 2)])


    #width and height are different in tex2svg and dvisvgm
    #tex2svg uses em while dvisvgm uses pt
    if LaTeXprog == :tex2svg
        return (fsize / 2) .* (ex_width, ex_height)
    elseif LaTeXprog == :dvisvgm
        return (fsize / 12) .* (ex_width, ex_height)
    end
end

"""
    pathsvg(svg)

Convert an svg to a path using Luxor. Normally called via the `latex` command.
It handles only a subset of the full power of svg.
"""
function pathsvg(svg)
    fsize = get_current_setting().fontsize
    xdoc = parse_string(svg)
    xroot = root(xdoc)
    defs = Dict{String,Any}()
    try
        def_element = get_elements_by_tagname(xroot, "defs")[1]
        #create a dict for all the definitions
        for def in collect(child_elements(def_element))
            defs[attribute(def, "id")] = def
        end
    catch e
        #@warn "no defs"
    end
    x, y, width, height = parse.(Float64, split(attribute(xroot, "viewBox")))
    # remove ex in the end
    ex_width = parse(Float64, attribute(xroot, "width")[1:(end - 2)])
    ex_height = parse(Float64, attribute(xroot, "height")[1:(end - 2)])
    # everything capsulated in a layer
    @layer begin
        # unit ex: half of font size
        # such that we can scale half of a font size (size of a lower letter)
        # with the corresponding height of the svg canvas
        # and the ex_height given in it's description
        if LaTeXprog == :tex2svg
            scale((fsize / 2) / (height / ex_height))
        elseif LaTeXprog == :dvisvgm
            #12 here (and in svgwh) is from \dcoumentclass[12pt] in  tex2svg function
            scale((fsize / 12) / (height / ex_height))
        end

        translate(-x, -y)

        for child in collect(child_elements(xroot))
            sym_name = Symbol(name(child))
            @layer begin
                draw_obj(Val{sym_name}(), child, defs)
            end
        end
    end
end
