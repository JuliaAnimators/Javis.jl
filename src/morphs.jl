include("Shape.jl")

"""
    match_num_points(poly_1::Vector{Point}, poly_2::Vector{Point})

This is a helper function for [`morph`](@ref).
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

    pdists = polydistances(new_poly_1)
    every_dist = pdists[end] / missing_nodes
    pdiffs = diff(pdists)

    ct = 0.0
    poly_1_orig = copy(new_poly_1)
    npi = 1
    for pi in 1:length(poly_1_orig)
        add_nodes = convert(Int, round(pdiffs[pi] / every_dist))
        t = pdiffs[pi] / (add_nodes + 1)
        ct_local = ct
        for i in 1:add_nodes
            ct_local += t
            new_point =
                get_polypoint_at(poly_1_orig, ct_local / pdists[end]; pdist = pdists)
            npi += 1
            insert!(new_poly_1, npi, new_point)
        end
        npi += 1
        missing_nodes -= add_nodes
        ct += pdiffs[pi]
        every_dist = (pdists[end] - ct) / missing_nodes
    end

    if flipped
        new_poly_1, new_poly_2 = new_poly_2, new_poly_1
    end
    @assert length(new_poly_1) == length(new_poly_2)
    return new_poly_1, new_poly_2
end

"""
    morph(from_func, to_func; action=:stroke)

A closure for the [`_morph`](@ref) function.
This makes it easier to write the function inside an `Action`.

Currently morphing is quite simple and only works for basic shapes.
It especially does not work with functions which produce more than one polygon
or which produce filled polygons.
Blending between fills of polygons is definitely coming at a later stage.

**Important:** The functions itself should not draw the polygon
i.e. use `circle(Point(100,100), 50)` instead of `circle(Point(100,100), 50, :stroke)`

# Arguments
- `from_func::Union{Vector{Vector{Point}}, Function}`:
    The function that creates the path for the first polygons or the paths as vector of points.
- `to_func::Union{Vector{Vector{Point}}, Function}`:
    Same as `from_func` but it defines the "result" polygons,
    which will be displayed at the end of the Action

# Keywords
- `action::Symbol` defines whether the object has a fill or just a stroke. Defaults to stroke.

# Example

This creates a star that morphs into a circle and back.

```
using Javis

astar(args...) = star(O, 50)
acirc(args...) = circle(Point(100,100), 50)

video = Video(500, 500)
javis(video, [
    Action(1:100, ground),
    Action(1:50, morph(astar, acirc)),
    Action(51:100, morph(acirc, astar))
], creategif=true, tempdirectory="images",
    pathname="star2circle.gif", deletetemp=true)
```
"""
function morph(
    from_func::Union{Vector{Vector{Point}},Function},
    to_func::Union{Vector{Vector{Point}},Function};
    action = :stroke,
)
    return (video, scene_action, frame) ->
        _morph(video, scene_action, frame, from_func, to_func; draw_action = action)
end

"""
    save_morph_polygons!(action::Action, from_func::Vector{Vector{Point}},
                                         to_func::Vector{Vector{Point}})

Calls the functions to polygons and calls [`match_num_points!`](@ref)
such that both polygons have the same number of points.
This is done once inside [`_morph`](@ref).
Saves the two polygons inside `action.opts[:from_poly]` and `action.opts[:to_poly]`.

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

    # println("Number of non empty polygons")
    # println("#From ", length(from_polys))
    # println("#To ", length(to_polys))

    if length(from_polys) != length(to_polys)
        try_merge_polygons(from_polys)
        try_merge_polygons(to_polys)
    end

    from_shapes = create_shapes(from_polys)
    to_shapes = create_shapes(to_polys)

    if length(from_shapes) > 1
        from_shapes, to_shapes = reorder_match(from_shapes, to_shapes)
    end

    #=
    println("Shape info after reoder")
    println("Num shapes A: ", length(from_shapes))
    println("Num shapes B: ", length(to_shapes))
    for (shapeA, shapeB) in zip(from_shapes, to_shapes)
        println("Matched")
        print_basic(shapeA)
        println("with")
        print_basic(shapeB)
        println("Similarity: ", get_similarity(shapeA, shapeB))
        println("=================================")
    end
    =#

    action.opts[:from_shape] = Vector{Shape}()
    action.opts[:to_shape] = Vector{Shape}()
    action.opts[:points] = Vector{Shape}()

    counter = 0
    for (from_shape, to_shape) in zip(from_shapes, to_shapes)
        counter += 1
        if isempty(from_shape) || isempty(to_shape)
            if isempty(from_shape)
                push!(action.opts[:from_shape], EmptyShape())
                push!(action.opts[:to_shape], to_shape)
                push!(
                    action.opts[:points],
                    Shape(
                        length(to_shape.points),
                        [length(subpath) for subpath in to_shape.subpaths],
                    ),
                )
            else
                push!(action.opts[:from_shape], from_shape)
                push!(action.opts[:to_shape], EmptyShape())
                push!(
                    action.opts[:points],
                    Shape(
                        length(from_shape.points),
                        [length(subpath) for subpath in from_shape.subpaths],
                    ),
                )
            end
        else
            from_poly, to_poly = match_num_points(from_shape.points, to_shape.points)
            smallest_i, smallest_distance =
                compute_shortest_morphing_dist(from_poly, to_poly)

            new_from_poly = circshift(from_poly, length(from_poly) - smallest_i + 1)

            push!(action.opts[:from_poly], new_from_poly)
            push!(action.opts[:to_poly], to_poly)
            push!(action.opts[:points], Vector{Point}(undef, length(new_from_poly)))

            # for subpaths
            for (from_subpath, to_subpath) in zip(from_shape.subpaths, to_shape.subpaths)
                from_poly, to_poly = match_num_points(from_subpath, to_subpath)
                smallest_i, smallest_distance =
                    compute_shortest_morphing_dist(from_poly, to_poly)

                new_from_poly = circshift(from_poly, length(from_poly) - smallest_i + 1)
                @assert !ispolyclockwise(new_from_poly) && !ispolyclockwise(to_poly)

                push!(action.opts[:from_poly], new_from_poly)
                push!(action.opts[:to_poly], to_poly)
                push!(action.opts[:points], Vector{Point}(undef, length(new_from_poly)))
            end
        end
    end
end



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

function draw_polygon(polygon, next_polygon, draw_action)
    got_drawn = false
    if ispolyclockwise(polygon) && ispolyclockwise(next_polygon)
        poly(polygon, draw_action; close = true)
        got_drawn = true
    elseif ispolyclockwise(polygon)
        poly(polygon, :path; close = true)
        newsubpath()
    elseif ispolyclockwise(next_polygon)
        # is last subpath
        poly(polygon, :path; close = true)
        if draw_action == :stroke
            got_drawn = true
            strokepath()
        elseif draw_action == :fill
            got_drawn = true
            fillpath()
        else
            closepath()
        end
    else
        newsubpath()
        poly(polygon, :path; close = true)
    end
    return got_drawn
end

"""
    _morph(video::Video, action::Action, frame, from_func::Function, to_func::Function; draw_action=:stroke)

Internal version of [`morph`](@ref) but described there.
"""
function _morph(
    video::Video,
    action::Action,
    frame,
    from_polys::Vector{Vector{Point}},
    to_polys::Vector{Vector{Point}};
    draw_action = :stroke,
)
    # computation of the polygons and the best way to morph in the first frame
    if frame == first(get_frames(action))
        save_morph_polygons!(action, from_polys, to_polys)
    end

    # obtain the computed polygons. These polygons have the same number of points.
    number_of_poly = length(action.opts[:from_poly])
    polygons = Vector{Vector{Point}}(undef, number_of_poly)
    bool_move = ones(Bool, number_of_poly)
    bool_appear = zeros(Bool, number_of_poly)

    for pi in 1:number_of_poly
        from_poly = action.opts[:from_poly][pi]
        to_poly = action.opts[:to_poly][pi]
        points = action.opts[:points][pi]
        # polygons[pi] = from_poly
        # println("#Points: $pi ", length(polygons[pi]))
        # continue
        if isempty(from_poly) || isempty(to_poly)
            if isempty(to_poly)
                polygons[pi] = from_poly
            else
                polygons[pi] = to_poly
                bool_appear[pi] = true
            end
            bool_move[pi] = false
            continue
        end

        # compute the interpolation variable `t` for the current frame
        t = get_interpolation(action, frame)

        for (i, p1, p2) in zip(1:length(from_poly), from_poly, to_poly)
            new_point = p1 + t * (p2 - p1)
            points[i] = new_point
        end

        polygons[pi] = points
        @assert !xor(ispolyclockwise(polygons[pi]), ispolyclockwise(from_poly))
    end

    got_drawn = true
    for pi in 1:number_of_poly
        if !bool_move[pi]
            if !got_drawn
                if draw_action == :stroke
                    strokepath()
                elseif draw_action == :fill
                    fillpath()
                else
                    closepath()
                end
            end
            continue
        end
        # if last polygon the next is a clockwise one
        next_polygon =
            pi == number_of_poly ? [O, Point(-1, 0), Point(-1, -1)] : polygons[pi + 1]
        got_drawn = draw_polygon(polygons[pi], next_polygon, draw_action)
    end
    # let new paths appear
    t = get_interpolation(action, frame)
    setopacity(t)

    polygon_ids = [pi for pi in 1:number_of_poly if (!bool_move[pi] && bool_appear[pi])]
    polys = polygons[polygon_ids]
    for pi in 1:length(polys)
        next_polygon =
            pi == length(polys) ? [O, Point(-1, 0), Point(-1, -1)] : polys[pi + 1]
        got_drawn = draw_polygon(polys[pi], next_polygon, draw_action)
    end

    # let old paths disappear
    t = get_interpolation(action, frame)
    setopacity(1 - t)

    polygon_ids = [pi for pi in 1:number_of_poly if (!bool_move[pi] && !bool_appear[pi])]
    polys = polygons[polygon_ids]
    for pi in 1:length(polys)
        next_polygon =
            pi == length(polys) ? [O, Point(-1, 0), Point(-1, -1)] : polys[pi + 1]
        got_drawn = draw_polygon(polys[pi], next_polygon, draw_action)
    end
    setopacity(1)
end

"""
    _morph(video::Video, action::Action, frame, from_func::Function, to_func::Function; draw_action=:stroke)

Internal version of [`morph`](@ref) but described there.
"""
function _morph(
    video::Video,
    action::Action,
    frame,
    from_func::Function,
    to_func::Function;
    draw_action = :stroke,
)
    newpath()
    from_func()
    closepath()
    from_polys = pathtopoly()

    newpath()
    to_func()
    closepath()
    to_polys = pathtopoly()

    return _morph(video, action, frame, from_polys, to_polys; draw_action = draw_action)
end


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
    # println("assignment: $assignment")
    # println("similarity: $(-cost)")
    # display("text/plain", similiarity_matrix)

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
