include("Shape.jl")

"""
    match_num_point!(poly_1::Vector{Point}, poly_2::Vector{Point})

This is a helper function for [`morph`](@ref).
Given two polygons `poly_1` and `poly_2` points are added to the polygon with less points
until both polygons have the same number of points.
The polygon with less points gets mutated during this process.

# Arguments
- `poly_1::Vector{Point}`: The points which define the first polygon
- `poly_2::Vector{Point}`: The points which define the second polygon
"""
function match_num_point(poly_1::Vector{Point}, poly_2::Vector{Point})
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
    diff = l2 - l1

    points_per_edge = div(diff, l1)
    # how many extra points do we need
    points_per_edge_extra = rem(diff, l1)
    # => will add them to the first `points_per_edge_extra` edges

    # index is the index where the next point is added
    index = 2
    poly_1_orig = copy(new_poly_1)
    for i in 1:l1
        # p1 is the current point in the original polygon
        p1 = poly_1_orig[i]
        # p2 is the next point (which is the first of the polygon in the last iteration)
        if i + 1 > l1
            p2 = poly_1_orig[1]
        else
            p2 = poly_1_orig[i + 1]
        end
        # if we need 5 points and have only 4 edges we add 2 points for the first edge
        rem = 0
        if i <= points_per_edge_extra
            rem = 1
        end
        for j in 1:(points_per_edge + rem)
            # create the interpolated point between p1 and p2
            t = j / (points_per_edge + rem + 1)
            new_point = p1 + t * (p2 - p1)
            insert!(new_poly_1, index, new_point)
            index += 1
        end
        index += 1
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

Calls the functions to polygons and calls [`match_num_point!`](@ref)
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

    # println("# from shapes: ", length(from_shapes))
    # println("# to shapes: ", length(to_shapes))

    if length(from_shapes) > 1
        from_shapes = reorder_match(from_shapes, to_shapes)
    end

    action.opts[:from_poly] = Vector{Vector{Point}}()
    action.opts[:to_poly] = Vector{Vector{Point}}()
    action.opts[:points] = Vector{Vector{Point}}()

    counter = 0
    for (from_shape, to_shape) in zip(from_shapes, to_shapes)
        counter += 1
        if isempty(from_shape) || isempty(to_shape)
            new_from_poly = from_poly

            push!(action.opts[:from_poly], new_from_poly)
            push!(action.opts[:to_poly], to_poly)
            push!(action.opts[:points], Vector{Point}(undef, length(new_from_poly)))
        else
            from_poly, to_poly = match_num_point(from_shape.points, to_shape.points)
            smallest_i, smallest_distance =
                compute_shortest_morphing_dist(from_poly, to_poly)

            new_from_poly = circshift(from_poly, length(from_poly) - smallest_i + 1)

            push!(action.opts[:from_poly], new_from_poly)
            push!(action.opts[:to_poly], to_poly)
            push!(action.opts[:points], Vector{Point}(undef, length(new_from_poly)))

            # for subpaths
            for (from_subpath, to_subpath) in zip(from_shape.subpaths, to_shape.subpaths)
                from_poly, to_poly = match_num_point(from_subpath, to_subpath)
                smallest_i, smallest_distance =
                    compute_shortest_morphing_dist(from_poly, to_poly)

                new_from_poly = circshift(from_poly, length(from_poly) - smallest_i + 1)

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

    for pi in 1:number_of_poly
        from_poly = action.opts[:from_poly][pi]
        to_poly = action.opts[:to_poly][pi]
        points = action.opts[:points][pi]
        # polygons[pi] = from_poly
        # println("#Points: $pi ", length(polygons[pi]))
        # continue
        if isempty(from_poly) || isempty(to_poly)
            isempty(to_poly) && println("to is empty")
            polygons[pi] = to_poly
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
        got_drawn = false
        if ispolyclockwise(polygons[pi]) &&
           (pi == number_of_poly || ispolyclockwise(polygons[pi + 1]))
            poly(polygons[pi], draw_action; close = true)
            got_drawn = true
        elseif ispolyclockwise(polygons[pi])
            poly(polygons[pi], :path; close = true)
            newsubpath()
        elseif pi == number_of_poly || ispolyclockwise(polygons[pi + 1])
            # is last subpath
            poly(polygons[pi], :path; close = true)
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
            poly(polygons[pi], :path; close = true)
        end
    end

    # let new paths appear
    t = get_interpolation(action, frame)
    setopacity(t)

    for pi in 1:number_of_poly
        bool_move[pi] && continue
        poly(polygons[pi], draw_action; close = true)
    end
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
    to_shape_used = zeros(Bool, length(to_shapes))
    from_shape_match = zeros(Int, length(from_shapes))

    for (fi, from_shape) in enumerate(from_shapes)
        best_similarity = 0
        smallest_to = 1
        for (ti, to_shape) in enumerate(to_shapes)
            to_shape_used[ti] && continue
            similarity = get_similarity(from_shape, to_shape)
            if similarity > best_similarity
                best_similarity = similarity
                smallest_to = ti
            end
        end
        to_shape_used[smallest_to] = true
        from_shape_match[fi] = smallest_to
    end
    new_from_shapes = Vector{Shape}(undef, length(to_shapes))
    for i in 1:length(to_shapes)
        new_from_shapes[i] = EmptyShape()
    end

    for i in 1:length(from_shapes)
        new_from_shapes[from_shape_match[i]] = from_shapes[i]
    end
    return new_from_shapes
end
