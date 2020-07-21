using LightXML

function float_attribute(o, name)
    return parse(Int, attribute(o, name))
end

function draw_obj(::Val{:rect}, o, defs)
    width = float_attribute(o, "width")
    height = float_attribute(o, "height")
    x = float_attribute(o, "x")
    y = float_attribute(o, "y")
    rect(Point(x, y), width, height, :path)
end

function draw_obj(::Val{:g}, o, defs)
    set_attrs(o)
    println(getmatrix())
   
    childs = collect(child_elements(o))
    for child in childs
        sym_name = Symbol(name(child))
        @layer begin
            draw_obj(Val{sym_name}(), child, defs)
        end
    end
end

function draw_obj(::Val{:use}, o, defs)
    set_attrs(o)
    for attribute in attributes(o)
        if name(attribute) == "href"
            id = value(attribute)[2:end]

            if haskey(defs, id)
                def = defs[id]
                sym = Symbol(name(def))
                draw_obj(Val{sym}(), def, defs)
            end
        end
    end
end

function draw_obj(::Val{:path}, o, defs)
    set_attrs(o)
    for attribute in attributes(o)
        if name(attribute) == "d"
            data = value(attribute)
            data_parts = split(data, r"(?=[A-Za-z])")
            # println(data_parts)
            # newpath()
            l_pt = O
            c_pt = O
            for pi in 1:length(data_parts)
                p = data_parts[pi]
                command, args = p[1], p[2:end]
                if command == 'M'
                    c_pt = path_move(parse.(Float64, split(args))...)
                elseif command == 'Q'
                    l_pt, c_pt = path_quadratic(c_pt, parse.(Float64, split(args))...)
                elseif command == 'T'
                    control_pt = l_pt+2*(c_pt-l_pt)
                    l_pt, c_pt = path_quadratic(c_pt, control_pt..., parse.(Float64, split(args))...)
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
                elseif command == 'Z'
                    println("fill")
                    closepath()
                else
                    println("Not parsed command: $command")
                end
            end
        end
    end
end

function path_move(x,y) 
    p = Point(x,y)
    move(p)
    p
end

function path_quadratic(c_pt::Point, x,y, xe, ye) 
    e_pt = Point(xe,ye)
    qc = Point(x,y)
    c1 = c_pt+2/3*(qc-c_pt)
    c2 = e_pt+2/3*(qc-e_pt)
    curve(c1, c2, e_pt)
    return qc, e_pt
end

function set_attrs(o)
    for attribute in attributes(o)
        sym = Symbol(name(attribute))
        set_attr(Val{sym}(), value(attribute))
    end
end

function set_attr(::Val{:transform}, transform_str)
    if transform_str !== nothing
        m = match(r"(.+)\((.+)\)", transform_str)
        type = Symbol(m.captures[1])
        set_transform(Val{type}(), parse.(Float64, strip.(split(m.captures[2],r"[, ]")))...)
    end
end

set_attr(::Val{:x}, x) = translate(parse(Float64,x),0)
set_attr(::Val{:y}, y) = translate(0,parse(Float64,y))
set_attr(::Val{Symbol("stroke-width")}, sw) = setline(parse(Float64, sw))

set_transform(::Val{:translate}, x,y) = translate(x,y)
set_transform(::Val{:scale}, x,y=x) = scale(x,y)
function set_transform(::Val{:matrix}, args...) 
    old = cairotojuliamatrix(getmatrix())
    update = cairotojuliamatrix(collect(args))
    new = old*update
    setmatrix([new[1,1], new[2,1], new[1,2], new[2,2], new[1,3], new[2,3]])
    # scale(0.1)
end

draw_obj(t, o, defs) = println("Can't draw $t")
set_transform(t, args...) = println("Can't transform $t")
set_attr(::Val{:href}, args...) = nothing
set_attr(::Val{:d}, args...) = nothing
set_attr(::Val{:id}, args...) = nothing
set_attr(t, args...) = println("No attr match for $t")

function pathsvg(svg)
    xdoc = parse_string(svg)
    xroot = root(xdoc)
    def_element =  get_elements_by_tagname(xroot, "defs")[1]
    defs = Dict{String, Any}()
    for def in collect(child_elements(def_element))
        defs[attribute(def, "id")] = def
    end
    x, y, width, height = parse.(Float64, split(attribute(xroot, "viewBox")))
    println("x: $x")
    println("y: $y")
    scale(0.1)
    translate(x, -y)

    for child in collect(child_elements(xroot))
        sym_name = Symbol(name(child))
        @layer begin
            draw_obj(Val{sym_name}(), child, defs)                
        end
    end
end