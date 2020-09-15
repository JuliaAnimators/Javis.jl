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

    new_poly_1 = polysample(new_poly_1, l2)
    new_poly_2 = polysample(new_poly_2, l2)

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

    println("Number of non empty polygons")
    println("#From ", length(from_polys))
    println("#To ", length(to_polys))

    if length(from_polys) != length(to_polys)
        try_merge_polygons(from_polys, to_polys)
    end

    println("Number of non empty polygons after merging")
    println("#From ", length(from_polys))
    println("#To ", length(to_polys))



    if length(from_polys) > 1
        from_polys = reorder_match(from_polys, to_polys)
    end

    action.opts[:from_poly] = Vector{Vector{Point}}()
    action.opts[:to_poly] = Vector{Vector{Point}}()
    action.opts[:points] = Vector{Vector{Point}}()

    for (from_poly, to_poly) in zip(from_polys, to_polys)
        if isempty(from_poly) || isempty(to_poly)
            new_from_poly = from_poly
        else
            from_poly, to_poly = match_num_point(from_poly, to_poly)
            smallest_i, smallest_distance =
                compute_shortest_morphing_dist(from_poly, to_poly)

            new_from_poly = circshift(from_poly, length(from_poly) - smallest_i + 1)
        end

        push!(action.opts[:from_poly], new_from_poly)
        push!(action.opts[:to_poly], to_poly)
        push!(action.opts[:points], Vector{Point}(undef, length(new_from_poly)))
    end
end

function try_merge_polygons(from_polys, to_polys)
    for pi in 1:length(to_polys)
        !ispolyclockwise(to_polys[pi]) && continue
        for pj in 1:length(to_polys)
            pi >= pj && continue
            !ispolyclockwise(to_polys[pj]) && continue
            smallest_dist = Inf
            found_Ap = O
            found_Bp = O
            for (pA, pointA) in enumerate(to_polys[pi])
                for (pB, pointB) in enumerate(to_polys[pj])
                    dist = distance(pointA, pointB)
                    if dist < smallest_dist
                        smallest_dist = dist
                        found_Ap = pA
                        found_Bp = pB
                    end
                end
            end
            if smallest_dist <= 3
                println("Found possible merge with $pi and $pj with dist: $smallest_dist")
                # circle.([to_found_A, found_B], 3, :fill)
                println("found_Ap: ", found_Ap)
                println("found_Bp: ", found_Bp)
                tmp_poly = circshift(to_polys[pj], length(to_polys[pj]) - found_Bp + 1)
                to_polys[pi] = vcat(
                    to_polys[pi][1:found_Ap],
                    tmp_poly,
                    to_polys[pi][(found_Ap + 1):end],
                )
                sethue("red")
                poly(to_polys[pi], :fill; close = true)
                sethue("white")
                println("Is still clockwise? ", ispolyclockwise(to_polys[pi]))
                to_polys[pj] = Point[]
                println("to_polys[$pi]: ", to_polys[pi])
            end
        end
    end
    for pi in length(to_polys):-1:1
        if isempty(to_polys[pi])
            splice!(to_polys, pi)
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


function reorder_match(from_polys::Vector{Vector{Point}}, to_polys::Vector{Vector{Point}})
    to_poly_used = zeros(Bool, length(to_polys))
    from_poly_match = zeros(Int, length(from_polys))

    for (fi, from_poly) in enumerate(from_polys)
        smallest_glob_dist = Inf
        smallest_glob_std = Inf
        smallest_glob_to = 1
        for (ti, to_poly) in enumerate(to_polys)
            to_poly_used[ti] && continue
            from_copy = copy(from_poly)
            to_copy = copy(to_poly)
            from_pc = polycentroid(from_copy)
            to_pc = polycentroid(to_copy)

            from_copy, to_copy = match_num_point(from_copy, to_copy)
            # rotate the points for the best fit
            smallest_i, smallest_distance =
                compute_shortest_morphing_dist(from_copy, to_copy)
            x_dir = zeros(length(from_copy))
            y_dir = zeros(length(from_copy))

            for pi in 1:length(from_copy)
                x_dir[pi] = (to_copy[pi] - from_copy[pi]).x
                y_dir[pi] = (to_copy[pi] - from_copy[pi]).y
            end

            x_dir_std = std(x_dir)
            y_dir_std = std(y_dir)

            from_copy = circshift(from_copy, length(from_poly) - smallest_i + 1)

            smallest_distance = distance(to_pc, from_pc)

            # TODO: think about this again :D There must be a compromise between morphing
            # behaviour and moving
            comb_std = clamp(x_dir_std + y_dir_std, 0.01, 1000)

            if comb_std * smallest_distance < smallest_glob_std
                smallest_glob_std = comb_std * smallest_distance
                smallest_glob_dist = smallest_distance
                smallest_glob_to = ti
            end
        end
        to_poly_used[smallest_glob_to] = true
        from_poly_match[fi] = smallest_glob_to
    end
    @show from_poly_match
    new_from_polys = Vector{Vector{Point}}(undef, length(to_polys))
    for i in 1:length(to_polys)
        new_from_polys[i] = Point[]
    end

    for i in 1:length(from_polys)
        new_from_polys[from_poly_match[i]] = from_polys[i]
    end
    return new_from_polys
end
