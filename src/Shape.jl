struct Shape
    points::Vector{Point}
    simplified_points::Vector{Point}
    centroid::Point
    centered_points::Vector{Point}
    subpaths::Vector{Vector{Point}}
    num_acute_angles::Int
    num_obtuse_angles::Int
    num_right_angles::Int
end

function EmptyShape()
    return Shape(Point[], Point[], O, Point[], Vector{Vector{Point}}(), 0, 0, 0)
end

function Shape(num_points::Int, points_of_subpaths::Vector{Int})
    points = Vector{Point}(undef, num_points)
    subpaths = Vector{Vector{Point}}()
    for points_in_subpath in points_of_subpaths
        push!(subpaths, Vector{Point}(undef, points_in_subpath))
    end
    return Shape(points, Point[], O, Point[], subpaths, 0, 0, 0)
end

function Shape(points, subpaths; compute_info = true)
    simplified_points = simplify(points)
    if compute_info
        points, aa, oa, ra = get_angles(simplified_points)
    else
        aa = 0
        oa = 0
        ra = 0
    end
    centroid = polycentroid(points)
    shape =
        Shape(points, simplified_points, centroid, points .- centroid, subpaths, aa, oa, ra)
    return shape
end

function Base.isempty(shape::Shape)
    return length(shape.points) == 0
end


function get_angles(p)
    # TODO: let's assume it's a closed path
    num_acute_angles = 0
    num_obtuse_angles = 0
    num_right_angles = 0
    simplified = Point[]

    for i in 1:length(p)
        pA = p[i]
        if i < length(p) - 1
            u = p[i] - p[i + 1]
            v = p[i + 2] - p[i + 1]
            pB = p[i + 1]
            pC = p[i + 2]
        elseif i == length(p) - 1
            u = p[i] - p[i + 1]
            v = p[1] - p[i + 1]
            pB = p[i + 1]
            pC = p[1]
        else
            u = p[i] - p[1]
            v = p[2] - p[1]
            pB = p[1]
            pC = p[2]
        end
        ang = rad2deg(
            acos(
                clamp(
                    dotproduct(u, v) / (sqrt(u.x^2 + u.y^2) * sqrt(v.x^2 + v.y^2)),
                    -1,
                    1,
                ),
            ),
        )
        if ang < 179.8
            push!(simplified, pB)
        end

        if ang < 160
            if ang > 100 # obtuse
                num_obtuse_angles += 1
            elseif ang < 80 # acute
                num_acute_angles += 1
            else # right
                num_right_angles += 1
            end
        end
    end
    return simplified, num_acute_angles, num_obtuse_angles, num_right_angles
end

function get_similarity(shapeA::Shape, shapeB::Shape)
    if isempty(shapeA) || isempty(shapeB)
        return 0.0
    end
    score_points = 10.0
    score_holes = 500.0
    score_acute_angles = 100.0
    score_right_angles = 100.0
    score_obtuse_angles = 100.0
    score_point_diff = 100.0
    score_centered_point_diff = 100.0

    score = 0.0

    # number of points
    nA = length(shapeA.simplified_points)
    nB = length(shapeB.simplified_points)
    perc = nA < nB ? nA / nB : nB / nA
    perc = isnan(perc) ? 1.0 : perc
    # println("Point score: ", perc*score_points)
    score += perc * score_points

    # number of holes
    nA = length(shapeA.subpaths)
    nB = length(shapeB.subpaths)
    perc = nA < nB ? nA / nB : nB / nA
    perc = isnan(perc) ? 1.0 : perc
    # println("Hole score: ", perc*score_holes)
    score += perc * score_holes

    # number of angles
    num_angles = shapeA.num_acute_angles
    num_angles += shapeB.num_acute_angles
    num_angles += shapeA.num_obtuse_angles
    num_angles += shapeB.num_obtuse_angles
    num_angles += shapeA.num_right_angles
    num_angles += shapeB.num_right_angles

    # TODO: think about how to compare this better
    # Probably dividing by the whole number of angles is dumb
    # Or one might need a score for the difference in number of angles
    # acute
    nA = shapeA.num_acute_angles
    nB = shapeB.num_acute_angles
    perc = 1 - abs(nA - nB) / num_angles
    perc = isnan(perc) ? 1.0 : perc
    score += perc * score_acute_angles
    # println("Acute score: ", perc*score_acute_angles)

    # obtuse
    nA = shapeA.num_obtuse_angles
    nB = shapeB.num_obtuse_angles
    perc = 1 - abs(nA - nB) / num_angles
    perc = isnan(perc) ? 1.0 : perc
    score += perc * score_obtuse_angles
    # println("Obtuse score: ", perc*score_obtuse_angles)

    # right
    nA = shapeA.num_right_angles
    nB = shapeB.num_right_angles
    perc = 1 - abs(nA - nB) / num_angles
    perc = isnan(perc) ? 1.0 : perc
    score += perc * score_right_angles
    # println("right score: ", perc*score_right_angles)

    # difference in centered_points
    pointsA, pointsB = match_num_points(shapeA.centered_points, shapeB.centered_points)
    smallest_i, smallest_distance = compute_shortest_morphing_dist(pointsA, pointsB)
    # TODO: maybe there is a more reasonable denominator
    smallest_distance /= length(pointsA)
    wmin, wmax = extrema(p -> p.x, pointsA)
    hmin, hmax = extrema(p -> p.x, pointsA)
    w = wmax - wmin
    h = hmax - hmin
    perc = clamp(1 - smallest_distance / sqrt(w^2 + h^2), 0, 1)
    score += perc * score_centered_point_diff

    # difference in movement
    pointsA, pointsB = match_num_points(shapeA.points, shapeB.points)
    smallest_i, smallest_distance = compute_shortest_morphing_dist(pointsA, pointsB)
    video = CURRENT_VIDEO[1]
    smallest_distance /= length(pointsA)
    perc = clamp(1 - smallest_distance / sqrt(video.width^2 + video.height^2), 0, 1)
    score += perc * score_centered_point_diff

    return score
end

function create_shapes(polys)
    shapes = Vector{Shape}()

    is_last_subpath = false
    current_points = Point[]
    current_subpaths = Vector{Vector{Point}}()
    for poly in polys
        if ispolyclockwise(poly) && !is_last_subpath
            empty!(current_subpaths)
            if !isempty(current_points)
                shape = Shape(current_points, Vector{Vector{Point}}())
                push!(shapes, shape)
            end
            current_points = poly
            is_last_subpath = false
        elseif ispolyclockwise(poly)
            shape = Shape(current_points, copy(current_subpaths))
            push!(shapes, shape)
            is_last_subpath = false
            current_points = poly
            empty!(current_subpaths)
        else # is a hole
            push!(current_subpaths, poly)
            is_last_subpath = true
        end
    end
    shape = Shape(current_points, copy(current_subpaths))
    push!(shapes, shape)
    return shapes
end

function print_basic(s::Shape)
    println("Shape: #Points: $(length(s.points))")
    println(
        "Angles: #Acute: $(s.num_acute_angles) #Obtuse: $(s.num_obtuse_angles) #Right: $(s.num_right_angles)",
    )
    println("#Holes: $(length(s.subpaths))")
end


function prepare_to_interpolate(from_shape, to_shape, style)
    # match number of points for outer polygon
    from_outer, to_outer = match_num_points(from_shape.points, to_shape.points)

    # for holes
    from_holes = Vector{Vector{Point}}()
    to_holes = Vector{Vector{Point}}()

    for (from_hole, to_hole) in zip(from_shape.subpaths, to_shape.subpaths)
        from_hole_matched, to_hole_matched = match_num_points(from_hole, to_hole)
        push!(from_holes, from_hole_matched)
        push!(to_holes, to_hole_matched)
    end

    # rotate outer polygon
    rotate_i, _ = compute_shortest_morphing_dist(from_outer, to_outer)
    new_from_outer = circshift(from_outer, -rotate_i + 1)

    if style == :long
        new_from_outer =
            circshift(reverse!(new_from_outer), floor(-length(new_from_outer) / 2.6)) # found this to work best
    end

    new_from_holes = Vector{Vector{Point}}()

    # rotate holes
    for (from_hole, to_hole) in zip(from_holes, to_holes)
        rotate_i, _ = compute_shortest_morphing_dist(from_hole, to_hole)
        push!(new_from_holes, circshift(from_hole, -rotate_i + 1))
    end

    from = Shape(new_from_outer, new_from_holes; compute_info = false)
    to = Shape(to_outer, to_holes; compute_info = false)

    return from, to
end

function interpolate_shape!(inter_shape, from, to, t)
    # outer
    for (i, p1, p2) in zip(1:length(from.points), from.points, to.points)
        new_point = p1 + t * (p2 - p1)
        inter_shape.points[i] = new_point
    end

    # for holes
    for hi in 1:length(from.subpaths)
        for (i, p1, p2) in
            zip(1:length(from.subpaths[hi]), from.subpaths[hi], to.subpaths[hi])
            new_point = p1 + t * (p2 - p1)
            inter_shape.subpaths[hi][i] = new_point
        end
    end
end

function draw_shape(shape, draw_action)
    newpath()
    poly(shape.points, :path; close = true)
    for hi in 1:length(shape.subpaths)
        newsubpath()
        poly(shape.subpaths[hi], :path; close = true)
    end
    do_action(draw_action)
end
