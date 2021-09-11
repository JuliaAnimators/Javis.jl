"""
    scale_linear(fmin, fmax, tmin, tmax)

Creating a mapping which takes values from `fmin` to `fmax`
and outputs values ranging from `tmin` to `tmax`. 
If the input is outside the range it will be clamped to the `fmin` - `fmax` range.

# Example
```julia
scale = scale_linear(0, 10, 0, 100)
scale(5) # returns 50

scale_point = Javis.scale_linear(O, Point(10, 10), O, Point(100, 100))
scale_point(Point(7,8)) # returns Point(70, 80)
```
"""
function scale_linear(fmin, fmax, tmin, tmax)
    (x) -> begin
        x = clamp(x, fmin, fmax)
        (x - fmin) / (fmax - fmin) * (tmax - tmin) + tmin
    end
end

function scale_linear(fmin::Point, fmax::Point, tmin::Point, tmax::Point)
    (p::Point) -> begin
        px = clamp(p.x, fmin.x, fmax.x)
        py = clamp(p.y, fmin.y, fmax.y)
        nx = (px - fmin.x) / (fmax.x - fmin.x) * (tmax.x - tmin.x) + tmin.x
        ny = (py - fmin.y) / (fmax.y - fmin.y) * (tmax.y - tmin.y) + tmin.y
        return Point(nx, ny)
    end
end
