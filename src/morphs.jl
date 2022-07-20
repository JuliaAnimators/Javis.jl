include("Shape.jl")

#old morph func
#function morph_to(to_func::Function; do_action = :stroke)
#    return (video, object, action, frame) ->
#        _morph_to(video, object, action, frame, to_func; do_action = do_action)
#end
#
"""
    morph_to(to_func::Function; samples=100)

A closure for the [`_morph_to`](@ref) function.
To be used with Action. `morph_to` will morph an object into whatever is drawn
by the `to_func` passed to it.


# Arguments
- `to_func::Function`: Function that defines what the object should be morphed into
                       
# Keywords
- `samples` : Number of points to resample every polygon to for the morphing

# Limitations
- cant handle clips inside `to_func` or the `object`
- sethue animation doesnt work with this , since the color's to be morphed into are derived from the `object` and `to_func`. to change hue while morphing , change it in the `to_func`

# Example

This creates a star that morphs into a circle and back.

```julia
astar() = star(O, 50, 5, 0.5, 0)
acirc() = circle(O, 50)

video = Video(500, 500)
back = Background(1:20, ground)
star_obj = Object(1:10,(args...)-> astar())
act!(star_obj, Action(linear(), morph_to(acirc)))
act!(star_obj, Action(11:20, morph_to(astar)))

    morph_to(to_obj::Object; samples=100)

Morphs one object into another object.

# Arguments
- `to_obj::Object`: Object that defines what the object should be morphed into
                       
# Keywords
- `samples` : Number of points to resample every polygon to for the morphing

# Limitations
- cant handle clips inside `to_func` or the `object`
- sethue animation doesnt work with this , since the color's to be morphed into are derived from the `object` and `to_func`. to change hue while morphing , change it in the `to_func`

# Example

This creates a star that morphs into a circle.

```julia
astar() = star(O, 50, 5, 0.5, 0)
acirc() = circle(O, 50)

video = Video(500, 500)
back = Background(1:20, ground)
star_obj = Object(1:10,(args...)-> astar())
circ_obj = Object(1:10,(args...)-> acirc())
act!(star_obj, Action(linear(), morph_to(acirc)))
```
"""
function morph_to(to_obj::Object; samples = 100)
    return (video, object, action, frame) -> begin
        action.keep = false
        # We dont want `keep=true`. The "persistance" of this action 
        # - after its frames is effected by changing the drawing function.
        #
        # `keep=true` continues to apply the action after the action frames are
        # over in the render loop. The consequence of this is that when an
        # object has two morphs applied at different parts of the timeline ,
        # one can potentialy interfere with the other, if the morphs are not
        # called in the right order.
        #
        # TODO For now the implementation does not allow to revert the morph at
        # the end of the action. maybe implement this by checking action.keep
        # before the action starts and setting another flag .
        _morph_to(video, object, action, frame, to_obj, samples)
    end
end

function morph_to(to_func::Function, args = []; samples = 100)
    return (video, object, action, frame) -> begin
        action.keep = false
        _morph_to(video, object, action, frame, to_func, args, samples)
    end
end

"""
 a very small jpath to appear from/disappear into
 has 1 poly of `samples` points in the shape of an ngon 
 black fill 0 alpha, black stroke opaque
 linewidth 2
 """
null_jpath(samples = 100) =
    JPath([ngon(O, 0.1, samples)], [true], [0, 0, 0, 0], [0, 0, 0, 0], :stroke, 2)

"""
    _morph_to( video::Video, object::Object, action::Action, frame, to_obj::Object, samples,)

Internal function used to morph one `object` to another.
"""
function _morph_to(
    video::Video,
    object::Object,
    action::Action,
    frame,
    to_obj::Object,
    samples,
)
    interp_jpaths = JPath[]
    #resample all polys to same number of points at first frame of the action...
    if frame == action.frames.frames[begin]
        isempty(object.jpaths) && getjpaths!(object, object.opts[:original_func])
        isempty(to_obj.jpaths) && getjpaths!(to_obj, to_obj.func)

        for obj in [object, to_obj]
            for jpath in obj.jpaths  #kf.value is an array of jpaths
                for i in 1:length(jpath.polys)
                    jpath.polys[i] = [
                        jpath.polys[i][1]
                        polysample(jpath.polys[i], samples - 1, closed = jpath.closed[i])
                    ]
                end
            end
        end
    end

    #need to handle different number of jpaths
    #for to_obj less jpaths , we can shrink the extras down
    #for to_obj having more jpaths , we need to create extra polys 
    #the jpath it vanishes into has 1 poly with 3 points very close around the objects start_pos. ideally should have been 3 same points but Luxor doesnt like polys with 3 same points on top of each other,
    l1 = length(object.jpaths)
    l2 = length(to_obj.jpaths)
    jpaths1 = vcat(object.jpaths, repeat([null_jpath(samples)], max(0, l2 - l1)))
    jpaths2 = vcat(to_obj.jpaths, repeat([null_jpath(samples)], max(0, l1 - l2)))
    #above lines should make jpaths1 and jpaths2 have the same no of jpaths
    for (jpath1, jpath2) in zip(jpaths1, jpaths2)
        offsets = get_offsets(jpath1, jpath2)
        push!(
            interp_jpaths,
            _morph_jpath(jpath1, jpath2, get_interpolation(action, frame), offsets),
        )
    end

    object.func = (args...) -> begin
        drawjpaths(interp_jpaths)
        global DISABLE_LUXOR_DRAW = true
        ret = object.opts[:original_func](args...)
        global DISABLE_LUXOR_DRAW = false
        newpath()
        ret
    end

    if frame == last(get_frames(action))
        object.jpaths = to_obj.jpaths
    end
end

"""
    get_offsets(jpath1,jpath2)

returns an Array of Tuples , each Tuple is of the form `(s::Symbol,offsetvalue::Int)`

while interpolating polys inside the jpath. Javis tries to find a good offsetvalue
if poly1 is being morphed into poly2 
`poly1[i]` goes to `poly2[i + offsetvalue -1]` (modulo length(poly2) addition).

`s` is either `:former` or `:latter` indicating if the offset should be applied on poly1 or poly2

morphing from closed to closed offsets the former.
morphing from closed to open poly offsets the former.
morphing from open to closed poly offsets the latter.
morphing from open to open poly does no offsetting.

`offset` of 1 means no offset . It should technically be called best starting
indes.
"""
function get_offsets(jpath1, jpath2)
    #calculate offset 
    minl = min(length(jpath1.polys), length(jpath2.polys))
    maxl = max(length(jpath1.polys), length(jpath2.polys))
    offsets = Array{Tuple{Symbol,Int}}([])
    for i in 1:minl
        if i <= length(jpath1.closed) && jpath1.closed[i]
            offset, _ = compute_shortest_morphing_dist(jpath1.polys[i], jpath2.polys[i])
            push!(offsets, (:former, offset))
        elseif i <= length(jpath2.closed) && jpath2.closed[i]
            offset, _ = compute_shortest_morphing_dist(jpath2.polys[i], jpath1.polys[i])
            push!(offsets, (:latter, offset))
        else
            push!(offsets, (:former, 1))
        end
    end
    for i in (minl + 1):maxl
        push!(offsets, (:former, 1))
    end
    return offsets
end


"""
    _morph_to(video::Video, object::Object, action::Action, frame, to_func::Function, args::Array, samples=100)

Internal version of [`morph_to`](@ref) but described there.
"""
function _morph_to(
    video::Video,
    object::Object,
    action::Action,
    frame,
    to_func::Function,
    args::Array,
    samples = 100,
)
    #total number of points is samples+1

    interp_jpaths = JPath[]
    # If first frame ....
    if frame == first(get_frames(action))
        # Get jpaths to morph from and  into
        isempty(object.jpaths) && getjpaths!(object, object.func)
        action.defs[:toJPaths] = getjpaths(to_func, args)
        # Resample all polys in all jpaths to  `samples` number of points
        for jpath in [object.jpaths..., action.defs[:toJPaths]...]
            for i in 1:length(jpath.polys)
                jpath.polys[i] = [
                    jpath.polys[i][1]
                    polysample(jpath.polys[i], samples - 1, closed = jpath.closed[i])
                ] #prepend the first point becauce polysample doesnt
            end
        end
    end
    jpaths1 = object.jpaths
    jpaths2 = action.defs[:toJPaths]
    l1 = length(jpaths1)
    l2 = length(jpaths2)
    # Make jpaths have the same number
    jpaths1 = vcat(jpaths1, repeat([null_jpath(samples)], max(0, l2 - l1)))
    jpaths2 = vcat(jpaths2, repeat([null_jpath(samples)], max(0, l1 - l2)))

    # Interpolate jpaths pairwise and store interp_jpaths
    for (jpath1, jpath2) in zip(jpaths1, jpaths2)
        #calculate offset 
        offsets = get_offsets(jpath1, jpath2)
        push!(
            interp_jpaths,
            _morph_jpath(jpath1, jpath2, get_interpolation(action, frame), offsets),
        )
    end

    # Change drawing function
    object.func = (args...) -> begin
        drawjpaths(interp_jpaths)
        global DISABLE_LUXOR_DRAW = true
        ret = object.opts[:original_func](args...)
        global DISABLE_LUXOR_DRAW = false
        newpath()
        ret
    end
    if frame == action.frames.frames[end]
        object.jpaths = jpaths2
        #object.func = object.opts[:original_func]
    end
end

"""
    _morph_jpath(jpath1::JPath, jpath2::JPath, k)

Returns an interpolated jpath between jpath1 and jpath2 with interpolation factor 0<`k`<1.
"""
function _morph_jpath(jpath1::JPath, jpath2::JPath, k, offsets)
    polys1 = jpath1.polys
    polys2 = jpath2.polys
    retpolys = polymorph_noresample(polys1, polys2, k, offsets, kludge = true)
    # The logic to figure out if intermediate poly should be closed or open.
    # From         To         During Morph (intermediate)
    # --------------------------------------------------
    # open      -> open     : remain open during morph
    # closed    -> closed   : remain closed during morph
    # closed    -> open     : open during morph
    # open      -> closed   : open during morph , but closed when k ≈ 1
    retclosed = ones(Bool, length(retpolys))
    jp2closed_paded =
        [jpath2.closed; ones(Bool, max(0, diff(length.([jpath2.closed, retpolys]))[1]))]
    jp1closed_paded =
        [jpath1.closed; ones(Bool, max(0, diff(length.([jpath1.closed, retpolys]))[1]))]

    for i in 1:length(retclosed)
        if jp2closed_paded[i] && !jp1closed_paded[i]
            # Intermediates are open , but at k=1 they close
            retclosed[i] = isapprox(k, 1) ? true : false
        else
            retclosed[i] = jp2closed_paded[i]
        end
    end
    retfill = k .* jpath2.fill + (1 - k) .* jpath1.fill
    retstroke = k .* jpath2.stroke + (1 - k) .* jpath1.stroke
    retlinewidth = k .* jpath2.linewidth + (1 - k) .* jpath1.linewidth
    @assert length(retpolys) == length(retclosed)
    JPath(retpolys, retclosed, retfill, retstroke, jpath1.lastaction, retlinewidth)
end

"""
    _morph_to(video::Video, object::Object, action::Action, frame, to_func::Function; do_action=:stroke)

Internal version of [`morph_to`](@ref) but described there.
older morph.
"""
function _morph_to(
    video::Video,
    object::Object,
    action::Action,
    frame,
    to_func::Function;
    do_action = :stroke,
)
    if frame == last(get_frames(action))
        object.func = to_func
        push!(object.opts, :previous_morph_action => action)
    else
        if get(object.opts, :previous_morph_action, nothing) == action
            object.func = get(object.opts, :original_func, to_func)
        end
        newpath()
        object.func(video, object, frame; do_action = :none)
        closepath()
        from_polys = pathtopoly()

        newpath()
        to_func(video, object, frame; do_action = :none)
        closepath()
        to_polys = pathtopoly()

        return morph_between(
            video,
            action,
            frame,
            from_polys,
            to_polys;
            do_action = do_action,
        )
    end
end

"""
    morph_between(video::Video, action::Action, frame,
        from_polys::Vector{Vector{Point}}, to_polys::Vector{Vector{Point}};
        do_action=:stroke)

Internal version of [`morph_to`](@ref) after the from poly is defined.
"""
function morph_between(
    video::Video,
    action::Action,
    frame,
    from_polys::Vector{Vector{Point}},
    to_polys::Vector{Vector{Point}};
    do_action = :stroke,
)
    cs = get_current_setting()
    cs.show_object = false

    # computation of the polygons and the best way to morph in the first frame
    if frame == first(get_frames(action))
        save_morph_polygons!(action, from_polys, to_polys)
    end

    # obtain the computed polygons. These polygons have the same number of points.
    number_of_shapes = length(action.defs[:from_shape])
    bool_move = ones(Bool, number_of_shapes)
    bool_appear = zeros(Bool, number_of_shapes)

    for si in 1:number_of_shapes
        from_shape = action.defs[:from_shape][si]
        to_shape = action.defs[:to_shape][si]
        inter_shape = action.defs[:inter_shape][si]

        if isempty(from_shape) || isempty(to_shape)
            if isempty(to_shape)
                action.defs[:inter_shape][si] = from_shape
            else
                action.defs[:inter_shape][si] = to_shape
                bool_appear[si] = true
            end
            bool_move[si] = false
            continue
        end

        # compute the interpolation variable `t` for the current frame
        t = get_interpolation(action, frame)
        interpolate_shape!(inter_shape, from_shape, to_shape, t)
        draw_shape(inter_shape, do_action)
    end

    # let new paths appear
    t = get_interpolation(action, frame)
    setopacity(t)

    shape_ids = [si for si in 1:number_of_shapes if (!bool_move[si] && bool_appear[si])]
    shapes = action.defs[:inter_shape][shape_ids]
    draw_shape.(shapes, do_action)

    # let old paths disappear
    t = get_interpolation(action, frame)
    setopacity(1 - t)

    shape_ids = [si for si in 1:number_of_shapes if (!bool_move[si] && !bool_appear[si])]
    shapes = action.defs[:inter_shape][shape_ids]
    draw_shape.(shapes, do_action)

    setopacity(1)
end


"""
    match_num_points(poly_1::Vector{Point}, poly_2::Vector{Point})

This is a helper function for [`morph_to`](@ref).
Given two polygons `poly_1` and `poly_2` points are added to the polygon with less points
until both polygons have the same number of points.
The polygon with less points gets mutated during this process.

# Arguments
- `poly_1::Vector{Point}`: The points which define the first polygon
- `poly_2::Vector{Point}`: The points which define the second polygon
"""
function match_num_points(poly_1::Vector{Point}, poly_2::Vector{Point})
    l1 = length(poly_1)
    l2 = length(poly_2)
    # if both have the same number of points => we are done
    l1 == l2 && return poly_1, poly_2

    new_poly_1 = simplify(poly_1)
    new_poly_2 = simplify(poly_2)
    l1 = length(new_poly_1)
    l2 = length(new_poly_2)

    # poly_1 should have less points than poly_2 so we flip if this is not the case
    flipped = false
    if l1 > l2
        new_poly_1, new_poly_2 = new_poly_2, new_poly_1
        l1, l2 = l2, l1
        flipped = true
    end
    # the difference of the length of points
    missing_nodes = l2 - l1

    add_points!(new_poly_1, missing_nodes)

    if flipped
        new_poly_1, new_poly_2 = new_poly_2, new_poly_1
    end
    @assert length(new_poly_1) == length(new_poly_2)
    return new_poly_1, new_poly_2
end

"""
    add_points!(poly, missing_nodes)

Add #`missing_nodes` to poly.
"""
function add_points!(poly, missing_nodes)
    pdists = polydistances(poly)
    every_dist = pdists[end] / missing_nodes
    pdiffs = diff(pdists)

    ct = 0.0
    poly_orig = copy(poly)
    npi = 1
    for pi in 1:length(poly_orig)
        add_nodes = convert(Int, round(pdiffs[pi] / every_dist))
        t = pdiffs[pi] / (add_nodes + 1)
        ct_local = ct
        for i in 1:add_nodes
            ct_local += t
            new_point = get_polypoint_at(poly_orig, ct_local / pdists[end]; pdist = pdists)
            npi += 1
            insert!(poly, npi, new_point)
        end
        npi += 1
        missing_nodes -= add_nodes
        ct += pdiffs[pi]
        every_dist = (pdists[end] - ct) / missing_nodes
    end
end

"""
    save_morph_polygons!(action::Action, from_func::Vector{Vector{Point}},
                                         to_func::Vector{Vector{Point}})

Calls the functions to polygons and calls [`match_num_points`](@ref)
such that both polygons have the same number of points.
This is done once inside [`_morph_to`](@ref).
Saves the two polygons inside `action.defs[:from_poly]` and `action.defs[:to_poly]`.

**Assumption:** Both functions create the same number of polygons.
"""
function save_morph_polygons!(
    action::Action,
    from_polys::Vector{Vector{Point}},
    to_polys::Vector{Vector{Point}},
)
    # delete polygons with less than 2 points
    for i in length(from_polys):-1:1
        length(from_polys[i]) <= 1 && splice!(from_polys, i)
    end
    for i in length(to_polys):-1:1
        length(to_polys[i]) <= 1 && splice!(to_polys, i)
    end

    if length(from_polys) != length(to_polys)
        try_merge_polygons(from_polys)
        try_merge_polygons(to_polys)
    end

    from_shapes = create_shapes(from_polys)
    to_shapes = create_shapes(to_polys)

    if length(from_shapes) > 1
        from_shapes, to_shapes = reorder_match(from_shapes, to_shapes)
    end

    action.defs[:from_shape] = Vector{Shape}()
    action.defs[:to_shape] = Vector{Shape}()
    action.defs[:inter_shape] = Vector{Shape}()

    counter = 0
    for (from_shape, to_shape) in zip(from_shapes, to_shapes)
        counter += 1
        if isempty(from_shape) || isempty(to_shape)
            if isempty(from_shape)
                push!(action.defs[:from_shape], EmptyShape())
                push!(action.defs[:to_shape], to_shape)
                push!(
                    action.defs[:inter_shape],
                    Shape(
                        length(to_shape.points),
                        [length(subpath) for subpath in to_shape.subpaths],
                    ),
                )
            else
                push!(action.defs[:from_shape], from_shape)
                push!(action.defs[:to_shape], EmptyShape())
                push!(
                    action.defs[:inter_shape],
                    Shape(
                        length(from_shape.points),
                        [length(subpath) for subpath in from_shape.subpaths],
                    ),
                )
            end
        else
            from_shape, to_shape = prepare_to_interpolate(from_shape, to_shape)

            push!(action.defs[:from_shape], from_shape)
            push!(action.defs[:to_shape], to_shape)
            push!(
                action.defs[:inter_shape],
                Shape(
                    length(from_shape.points),
                    [length(subpath) for subpath in from_shape.subpaths],
                ),
            )
        end
    end
end

"""
    try_merge_polygons(polys)

Try to merge polygons together to match the number of polygons that get morphed.
The only example I encountered is that the `[` of a 3xY matrix consists of 3 parts which
are merged together.
"""
function try_merge_polygons(polys)
    for pi in 1:length(polys)
        !ispolyclockwise(polys[pi]) && continue
        for pj in 1:length(polys)
            pi >= pj && continue
            !ispolyclockwise(polys[pj]) && continue
            smallest_dist = Inf
            found_Ap = O
            found_Bp = O
            start_with_A = true
            for (pA, pointA1, pointA2) in
                zip(1:length(polys[pi]), polys[pi], circshift(polys[pi], -1))
                for (pB, pointB1, pointB2) in
                    zip(1:length(polys[pj]), polys[pj], circshift(polys[pj], -1))
                    dist1 = distance(pointA1, pointB2)
                    dist2 = distance(pointA2, pointB1)
                    if dist1 <= 3 && dist2 <= 3
                        if isinside((pointB1 + pointB2) / 2, polys[pi]; allowonedge = true)
                            pB1 = pB + 1 <= length(polys[pj]) ? pB + 1 : 1
                            polys[pj][pB1] = pointA1 - (pointB2 - pointA1)
                            polys[pj][pB] = pointA2 - (pointB1 - pointA2)
                            pointB2 = polys[pj][pB1]
                            pointB1 = polys[pj][pB]
                        end
                        if ispolyclockwise([pointA1, pointA2, pointB1, pointB2])
                            start_with_A = false
                            smallest_dist = dist1
                            found_Ap = pA
                            found_Bp = pB + 1 <= length(polys[pj]) ? pB + 1 : 1
                        else
                            start_with_A = true
                            smallest_dist = dist2
                            found_Ap = pA + 1 <= length(polys[pi]) ? pA + 1 : 1
                            found_Bp = pB + 1
                        end
                    end
                end
            end
            if smallest_dist <= 3
                if start_with_A
                    tmp_polyA = circshift(polys[pi], length(polys[pi]) - found_Ap + 1)
                    tmp_polyB = circshift(polys[pj], length(polys[pj]) - found_Bp)
                    polys[pi] = vcat(tmp_polyA, tmp_polyB[1:(end - 1)])
                    polys[pj] = Point[]
                else
                    tmp_polyB = circshift(polys[pj], length(polys[pj]) - found_Bp + 1)
                    tmp_polyA = circshift(polys[pi], length(polys[pi]) - found_Ap)
                    polys[pi] = vcat(tmp_polyB, tmp_polyA)
                    polys[pj] = Point[]
                end
            end
        end
    end
    for pi in length(polys):-1:1
        if isempty(polys[pi])
            splice!(polys, pi)
        end
    end
end

"""
    compute_shortest_morphing_dist(from_poly::Vector{Point}, to_poly::Vector{Point})

Rotates `from_poly` internally to check which mapping produces the smallest morphing distance.
It returns the start index of the rotation of `from_poly` as well as the smallest distance.
"""
function compute_shortest_morphing_dist(from_poly::Vector{Point}, to_poly::Vector{Point})
    # find the smallest morphing distance to match the points in a more natural way
    # smallest_i holds the best starting point of from_path
    smallest_i = 1
    smallest_distance = typemax(Float64)

    for i in 1:length(from_poly)
        overall_distance = 0.0
        for j in 1:length(from_poly)
            p1 = from_poly[mod1(j + i - 1, length(from_poly))]
            p2 = to_poly[j]
            overall_distance += distance(p1, p2)
        end
        if overall_distance < smallest_distance
            smallest_distance = overall_distance
            smallest_i = i
        end
    end
    return smallest_i, smallest_distance
end

"""
    reorder_match(from_shapes::Vector{Shape}, to_shapes::Vector{Shape})

Computes the similiarty of the shapes and finds the best mapping such that the sum of similiarty
is maximized.

Additionally it creates empty shapes when needed such that
`reordered_from` and `reordered_to` contain the same number of shapes.

# Returns
- `reordered_from::Vector{Shape}`
- `reordered_to::Vector{Shape}`
"""
function reorder_match(from_shapes::Vector{Shape}, to_shapes::Vector{Shape})
    num_shapes = max(length(from_shapes), length(to_shapes))

    similiarity_matrix = zeros(length(from_shapes), length(to_shapes))
    for fi in 1:length(from_shapes)
        from_shape = from_shapes[fi]
        for ti in 1:length(to_shapes)
            to_shape = to_shapes[ti]
            similiarity_matrix[fi, ti] = -get_similarity(from_shape, to_shape)
        end
    end
    assignment, cost = hungarian(similiarity_matrix)

    new_from_shapes = Vector{Shape}(undef, num_shapes)
    for i in 1:num_shapes
        new_from_shapes[i] = EmptyShape()
    end

    new_to_shapes = Vector{Shape}(undef, num_shapes)
    for i in 1:num_shapes
        if i <= length(to_shapes)
            new_to_shapes[i] = to_shapes[i]
        else
            new_to_shapes[i] = EmptyShape()
        end
    end

    ptr = length(to_shapes) + 1
    for i in 1:length(from_shapes)
        if assignment[i] == 0
            new_from_shapes[ptr] = from_shapes[i]
            ptr += 1
        else
            new_from_shapes[assignment[i]] = from_shapes[i]
        end
    end
    return new_from_shapes, new_to_shapes
end


"""
bunch of methods extending functions in Animations.jl that make morphs possible.
need to find a better place to put these functions, 
this will do for now
"""

import Base
"""
    struct MorphFunction
        func::Function
        args::Array
        jpaths::Vector{JPath}
        

# Fields
  - func::Function : a function with luxor calls to draw something that objects will be morphed into
  - args : args to the function . Object will be morphed into what is drawn by calling `func(args...)`
  - jpaths : The jpaths returned by what is drawn. `JPath[]` by default, this is populated the first instance it encounters a morph/partial draw at render time.

TODO: find a better place(file) to put these functions and structs. 
"""
mutable struct MorphFunction
    func::Function
    args::Array
    jpaths::Vector{JPath}
end

MorphFunction(f::Function, args::Array) = MorphFunction(f, args, JPath[])
Base.convert(::Type{MorphFunction}, f::Function) = MorphFunction(f, [], JPath[])
Base.convert(::Type{MorphFunction}, t::Tuple{Function,Array}) =
    MorphFunction(t[1], t[2], JPath[])

"""
    Animation(timestamps,funcs,easings)

returns an `Animation` from an array of MorphFunctions.
"""
function Animations.Animation(
    timestamps::AbstractVector{<:Real},
    funcs::AbstractVector{MorphFunction},
    easings::AbstractVector{<:Easing},
)
    keyframes = Keyframe{MorphFunction}.(timestamps, funcs)
    Animation(keyframes, easings)
end

"""
    Animations.linear_interpolate(
    fraction::Real,
    jpaths1::Vector{JPath},
    jpaths2::Vector{Jpath}
    )

    A method so that Animations.jl can interpolate between Arrays of JPaths.
    Note that the array of jpaths should be of the same size.
"""
function Animations.linear_interpolate(
    fraction::Real,
    jpaths1::Vector{JPath},
    jpaths2::Vector{JPath},
)
    l1 = length(jpaths1)
    l2 = length(jpaths2)
    @assert l1 == l2
    interp_jpaths = JPath[]
    for (jpath1, jpath2) in zip(jpaths1, jpaths2)
        offsets = get_offsets(jpath1, jpath2)
        push!(interp_jpaths, _morph_jpath(jpath1, jpath2, fraction, offsets))
    end
    return interp_jpaths
end
