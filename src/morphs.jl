include("Shape.jl")

"""
    morph_to(to_func::Function; object=:stroke)

A closure for the [`_morph_to`](@ref) function.
This makes it easier to write the function inside an `Object`.

Currently morphing is quite simple and only works for basic shapes.
It especially does not work with functions which produce more than one polygon
or which produce filled polygons.
Blending between fills of polygons is definitely coming at a later stage.

**Important:** The functions itself should not draw the polygon
i.e. use `circle(Point(100,100), 50)` instead of `circle(Point(100,100), 50, :stroke)`

# Arguments
- `to_func::Function`: Same as `from_func` but it defines the "result" polygon,
                       which will be displayed at the end of the Object

# Keywords
- `do_action::Symbol` defines whether the object has a fill or just a stroke. Defaults to `:stroke`.

# Example

This creates a star that morphs into a circle and back.

```
astar(args...; do_action=:stroke) = star(O, 50, 5, 0.5, 0, do_action)
acirc(args...; do_action=:stroke) = circle(Point(100,100), 50, do_action)

video = Video(500, 500)
back = Background(1:20, ground)
star_obj = Object(1:10, astar)
act!(star_obj, Action(linear(), morph_to(acirc)))
circle_obj = Object(11:20, acirc)
act!(circle_obj, Action(:same, morph_to(astar)))
```
"""
function morph_to(to_func::Function; do_action = :stroke)
    return (video, object, action, frame) ->
        _morph_to(video, object, action, frame, to_func; do_action = do_action)
end


"""
    _morph_to(video::Video, object::Object, action::Action, frame, to_func::Function; do_action=:stroke)

Internal version of [`morph_to`](@ref) but described there.
"""
function _morph_to(
    video::Video,
    object::Object,
    action::Action,
    frame,
    to_func::Function;
    do_action = :stroke,
)
    newpath()
    object.func(video, object, frame; do_action = :none)
    closepath()
    from_polys = pathtopoly()

    newpath()
    to_func(video, object, frame; do_action = :none)
    closepath()
    to_polys = pathtopoly()

    return morph_between(video, action, frame, from_polys, to_polys; do_action = do_action)
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
