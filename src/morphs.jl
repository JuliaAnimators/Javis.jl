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
function match_num_point!(poly_1::Vector{Point}, poly_2::Vector{Point})
    l1 = length(poly_1)
    l2 = length(poly_2)
    # if both have the same number of points => we are done
    l1 == l2 && return 

    # poly_1 should have less points than poly_2 so we flip if this is not the case
    flipped = false
    if l1 > l2
        poly_1, poly_2 = poly_2, poly_1
        l1, l2 = l2, l1
        flipped = true
    end

    # the difference of the length of points
    diff = l2-l1
    
    points_per_edge = div(diff, l1)
    # how many extra points do we need 
    points_per_edge_extra = rem(diff, l1)
    # => will add them to the first `points_per_edge_extra` edges

    # index is the index where the next point is added 
    index = 2
    poly_1_orig = copy(poly_1)
    for i in 1:l1
        # p1 is the current point in the original polygon
        p1 = poly_1_orig[i]
        # p2 is the next point (which is the first of the polygon in the last iteration)
        if i+1 > l1
            p2 = poly_1_orig[1]
        else
            p2 = poly_1_orig[i+1]
        end
        # if we need 5 points and have only 4 edges we add 2 points for the first edge
        rem = 0
        if i <= points_per_edge_extra
            rem = 1
        end
        for j in 1:points_per_edge+rem
            # create the interpolated point between p1 and p2
            t = j/(points_per_edge+rem+1)
            new_point = p1+t*(p2-p1)
            insert!(poly_1, index, new_point)
            index += 1
        end
        index += 1
    end

    if flipped 
        poly_1, poly_2 = poly_2, poly_1
    end
    @assert length(poly_1) == length(poly_2)
end

"""
    morph(from_func::Function, to_func::Function)

A closure for the [`morph_internal`](@ref) function. This makes it easier to write the function inside an `Action`.

Currently morphing is quite simple and only works for basic shapes. It especially does not work with
functions which produce more than one polygon or which produce filled polygons. 
Blending between fills of polygons is definitely coming at a later stage. 

**Important:** The functions itself should not draw the polygon
i.e. use `circle(Point(100,100), 50)` instead of `circle(Point(100,100), 50, :stroke)`

# Arguments
- `from_func::Function`: The function that creates the path for the first polygon. 
- `to_func::Function`: Same as `from_func` but it defines the "result" polygon,
                       which will be displayed at the end of the Action

# Example

This creates a star that morphs into a circle and back.

```
using Javis
using Luxor

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
function morph(from_func::Function, to_func::Function)
    return (video, action, frame) -> morph_internal(video, action, frame, from_func, to_func)
end

"""
    save_morph_polygons!(action::Action, from_func::Function, to_func::Function)

Converts the paths created by the functions to polygons and calls [`match_num_point!`](@ref) such that both polygons
have the same number of points. This is done once inside [`morph_internal`](@ref).
Saves the two polygons inside `action.opts[:from_poly]` and `action.opts[:to_poly]`.

**Assumption:** Both functions create only a single polygon each.
"""
function save_morph_polygons!(action::Action, from_func::Function, to_func::Function)
    newpath()
    from_func()
    closepath()
    from_poly = pathtopoly()[1]

    newpath()
    to_func()
    closepath()
    to_poly = pathtopoly()[1]
    
    match_num_point!(from_poly, to_poly)

    # find the smallest morphing distance to match the points in a more natural way
    # smallest_i holds the best starting point of from_path
    smallest_i = 1
    smallest_distance = typemax(Float64)

    for i in 1:length(from_poly)
        overall_distance = 0.0
        for j = 1:length(from_poly)
            p1 = from_poly[(j+i-1) % length(from_poly) + 1]
            p2 = to_poly[j]
            overall_distance += distance(p1, p2)
        end
        if overall_distance < smallest_distance
            smallest_distance = overall_distance
            smallest_i = i
        end
    end
    new_from_poly = copy(from_poly)
    for i in 1:length(from_poly)
        new_from_poly[i] = from_poly[(i+smallest_i-1) % length(from_poly) + 1]
    end

    action.opts[:from_poly] = new_from_poly
    action.opts[:to_poly] = to_poly
    action.opts[:points] = Vector{Point}(undef, length(new_from_poly))
end

"""
    morph_internal(video::Video, action::Action, frame, from_func::Function, to_func::Function)

Internal version of [`morph`](@ref) but described there.
"""
function morph_internal(video::Video, action::Action, frame, from_func::Function, to_func::Function)
    # computation of the polygons and the best way to morph in the first frame
    if frame == first(action.frames)
        save_morph_polygons!(action, from_func, to_func)
    end

    # obtain the computed polygons. These polygons have the same number of points.
    from_poly = action.opts[:from_poly]
    to_poly = action.opts[:to_poly]
    points = action.opts[:points]

    # compute the interpolation variable `t` for the current frame
    t = (frame-first(action.frames))/(length(action.frames)-1)
    
    for (i, p1, p2) in zip(1:length(from_poly), from_poly, to_poly)
        new_point = p1+t*(p2-p1)
        points[i] = new_point
    end

    poly(points, :stroke; close=true)
end