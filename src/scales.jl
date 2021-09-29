"""
    scale_linear(fmin, fmax, tmin, tmax; clamp=true)

Creating a mapping which takes values from `fmin` to `fmax`
and outputs values ranging from `tmin` to `tmax`. 
If the input is outside the range it will be by default clamped to the `fmin` - `fmax`.
This can be prevented by setting `clamp=false`.

# Example
```julia
scale = scale_linear(0, 10, 0, 100)
scale(5) # returns 50

scale_point = scale_linear(O, Point(10, 10), O, Point(100, 100))
scale_point(Point(7,8)) # returns Point(70, 80)
```
"""
function scale_linear(fmin, fmax, tmin, tmax; clamp = true)
    return LinearScale(fmin, fmax, tmin, tmax, clamp)
end

function scale_linear(fmin, fmax, cs::CoordinateSystem; kwargs...)
    tmin = Point(cs.left.x, cs.bottom.y)
    tmax = Point(cs.right.x, cs.top.y)
    return scale_linear(fmin, fmax, tmin, tmax; kwargs...)
end

function (ls::LinearScale)(x; clamp = true)
    if ls.clamp && clamp
        # clamp needs the values in low high order
        x = Base.clamp(x, min(ls.fmin, ls.fmax), max(ls.fmin, ls.fmax))
    end
    return (x - ls.fmin) / (ls.fmax - ls.fmin) * (ls.tmax - ls.tmin) + ls.tmin
end

function (ls::LinearScale{T})(p::Point; clamp = true) where {T<:Point}
    px = p.x
    py = p.y
    if ls.clamp && clamp
        # clamp needs the values in low high order
        px = Base.clamp(px, min(ls.fmin.x, ls.fmax.x), max(ls.fmin.x, ls.fmax.x))
        py = Base.clamp(py, min(ls.fmin.y, ls.fmax.y), max(ls.fmin.y, ls.fmax.y))
    end
    nx = (px - ls.fmin.x) / (ls.fmax.x - ls.fmin.x) * (ls.tmax.x - ls.tmin.x) + ls.tmin.x
    ny = (py - ls.fmin.y) / (ls.fmax.y - ls.fmin.y) * (ls.tmax.y - ls.tmin.y) + ls.tmin.y
    return Point(nx, ny)
end

function scaling_factors(ls::LinearScale)
    sx = (ls.tmax.x - ls.tmin.x) / (ls.fmax.x - ls.fmin.x)
    sy = (ls.tmax.y - ls.tmin.y) / (ls.fmax.y - ls.fmin.y)
    return sx, sy
end

macro scale_layer(scale_mapping, body)
    return esc(quote
        @layer begin
            # compute the center of both rectangles
            fcenterx = ($scale_mapping.fmax.x + $scale_mapping.fmin.x) / 2
            fcentery = ($scale_mapping.fmax.y + $scale_mapping.fmin.y) / 2

            tcenterx = ($scale_mapping.tmax.x + $scale_mapping.tmin.x) / 2
            tcentery = ($scale_mapping.tmax.y + $scale_mapping.tmin.y) / 2

            # scale in x and y
            sx, sy = Javis.scaling_factors($scale_mapping)
            Luxor.scale(sx, sy)

            # translate such that inputting the center from the "from mapping" is at 0,0
            Luxor.translate(-fcenterx, -fcentery)

            # shift center of canvas to center of new region
            Luxor.translate(tcenterx / sx, tcentery / sy)
            $body
        end
    end)
end
