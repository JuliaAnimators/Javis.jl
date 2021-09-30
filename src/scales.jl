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
    return LinearScale(Interval(fmin, fmax), Interval(tmin, tmax), clamp)
end

function scale_linear(fmin, fmax, cs::CoordinateSystem; kwargs...)
    tmin = Point(cs.left.x, cs.bottom.y)
    tmax = Point(cs.right.x, cs.top.y)
    return scale_linear(fmin, fmax, tmin, tmax; kwargs...)
end

function oned_linear_scale(
    input::Interval{T},
    output::Interval{T},
    x::T;
    clamp = true,
) where {T}
    if clamp
        # clamp needs the values in low high order
        imin = min(input.from, input.to)
        imax = max(input.from, input.to)
        x = Base.clamp(x, imin, imax)
    end
    return (x - input.from) / (input.to - input.from) * (output.to - output.from) +
           output.from
end

function (ls::LinearScale{T})(x::T; clamp = true) where {T}
    return oned_linear_scale(ls.input, ls.output, x; clamp = clamp && ls.clamp)
end

function (ls::LinearScale{T})(p::T; clamp = true) where {T<:Point}
    int_xinput = Interval(ls.input.from.x, ls.input.to.x)
    int_yinput = Interval(ls.input.from.y, ls.input.to.y)

    int_xoutput = Interval(ls.output.from.x, ls.output.to.x)
    int_youtput = Interval(ls.output.from.y, ls.output.to.y)

    xoutput = oned_linear_scale(int_xinput, int_xoutput, p.x; clamp = clamp && ls.clamp)
    youtput = oned_linear_scale(int_yinput, int_youtput, p.y; clamp = clamp && ls.clamp)

    return Point(xoutput, youtput)
end

function scaling_factors(ls::LinearScale)
    sx = (ls.output.to.x - ls.output.from.x) / (ls.input.to.x - ls.input.from.x)
    sy = (ls.output.to.y - ls.output.from.y) / (ls.input.to.y - ls.input.from.y)
    return sx, sy
end

macro scale_layer(scale_mapping, body)
    return esc(
        quote
            @layer begin
                # compute the center of both rectangles
                fcenterx = ($scale_mapping.input.to.x + $scale_mapping.input.from.x) / 2
                fcentery = ($scale_mapping.input.to.y + $scale_mapping.input.from.y) / 2

                tcenterx = ($scale_mapping.output.to.x + $scale_mapping.output.from.x) / 2
                tcentery = ($scale_mapping.output.to.y + $scale_mapping.output.from.y) / 2

                # scale in x and y
                sx, sy = Javis.scaling_factors($scale_mapping)
                Luxor.scale(sx, sy)

                # translate such that inputting the center from the "from mapping" is at 0,0
                Luxor.translate(-fcenterx, -fcentery)

                # shift center of canvas to center of new region
                Luxor.translate(tcenterx / sx, tcentery / sy)
                $body
            end
        end,
    )
end
