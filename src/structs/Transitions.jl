"""
    InternalTranslation <: InternalTransition

Saves a translation as described by [`Translation`](@ref) for the current frame.
Is part of the [`Object`](@ref) struct.
"""
mutable struct InternalTranslation <: InternalTransition
    by::Point
end

"""
    InternalRotation <: InternalTransition

Saves a rotation as described by [`Rotation`](@ref) for the current frame.
Is part of the [`Object`](@ref) struct.
"""
mutable struct InternalRotation <: InternalTransition
    angle::Float64
    center::Point
end

"""
    InternalScaling <: InternalTransition

Saves a scaling as described by [`Scaling`](@ref) for the current frame.
Is part of the [`Object`](@ref) struct.
"""
mutable struct InternalScaling <: InternalTransition
    scale::Tuple{Float64,Float64}
end

"""
    Translation <: Transition

Stores the `Point` or a link for the start and end position of the translation

# Fields
`from::Union{Point, Symbol}`: The start position or a link to the start position.
    See `:red_ball` in [`javis`](@ref)
`to::Union{Point, Symbol}`: The end position or a link to the end position
"""
struct Translation <: Transition
    from::Union{Point,Symbol}
    to::Union{Point,Symbol}
end

"""
    Translation(p::Union{Point, Symbol})

Create a `Translation(O, p)` such that a translation is done from the origin.
"""
Translation(p::Union{Point,Symbol}) = Translation(O, p)

"""
    Translation(x::Real, y::Real)

Create a `Translation(O, Point(x,y))` such that a translation is done from the origin.
Shorthand for writing `Translation(Point(x,y))`.
"""
Translation(x::Real, y::Real) = Translation(Point(x, y))

"""
    Rotation <: Transition

Stores the rotation similar to [`Translation`](@ref) with `from` and `to`
but also the rotation point.

# Fields
- `from::Union{Float64, Symbol}`: The start rotation or a link to it
- `to::Union{Float64, Symbol}`: The end rotation or a link to it
- `center::Union{Point, Symbol}`: The center of the rotation or a link to it.
"""
struct Rotation <: Transition
    from::Union{Float64,Symbol}
    to::Union{Float64,Symbol}
    center::Union{Point,Symbol}
end

"""
    Rotation(r::Union{Float64, Symbol})

Rotation as a transition from 0.0 to `r` .
Can be used as a short-hand.
"""
Rotation(r::Union{Float64,Symbol}) = Rotation(0.0, r)

"""
    Rotation(r::Union{Float64, Symbol}, center::Union{Point, Symbol})

Rotation as a transition from `0.0` to `r` around `center`.
Can be used as a short-hand for rotating around a `center` point.
"""
Rotation(r::Union{Float64,Symbol}, center::Union{Point,Symbol}) = Rotation(0.0, r, center)

"""
    Rotation(from, to)

Rotation as a transition from `from` to `to` (in radians) around the origin.
"""
Rotation(from, to) = Rotation(from, to, O)

"""
    Scaling <: Transition

Stores the scaling similar to [`Translation`](@ref) with `from` and `to`.

# Example
- Can be called with different constructors like:
```
Scaling(10) -> Scaling(CURRENT_SCALING, (10.0, 10.0))
Scaling(10, :my-scale) -> Scaling((10.0, 10.0), :my_scale)
Scaling(10, 2) -> Scaling((10.0, 10.0), (2.0, 2.0))
Scaling(10, (1,2)) -> Scaling((10.0, 10.0), (1.0, 2.0))
```

# Fields
- `from::Union{Tuple{Float64, Float64}, Symbol}`: The start scaling or a link to it
- `to::Union{Tuple{Float64, Float64}, Symbol}`: The end scaling or a link to it
- `compute_from_once::Bool`: Saves whether the from is computed for the first frame or
    every frame. Is true if from is `:_current_scale`.
"""
mutable struct Scaling <: Transition
    from::Union{Tuple{Float64,Float64},Symbol}
    to::Union{Tuple{Float64,Float64},Symbol}
    compute_from_once::Bool
end

Scaling(to::Tuple) = Scaling(:_current_scale, to, true)
Scaling(to::Real) = Scaling(:_current_scale, convert(Float64, to), true)
Scaling(to::Symbol) = Scaling(:_current_scale, to, true)

function Scaling(from::Real, to::Real, compute_from_once = false)
    from_flt = convert(Float64, from)
    to_flt = convert(Float64, to)
    Scaling((from_flt, from_flt), (to_flt, to_flt), compute_from_once)
end

function Scaling(from::Real, to, compute_from_once = false)
    flt = convert(Float64, from)
    Scaling((flt, flt), to, compute_from_once)
end

function Scaling(from, to::Real, compute_from_once = false)
    flt = convert(Float64, to)
    Scaling(from, (flt, flt), compute_from_once)
end
