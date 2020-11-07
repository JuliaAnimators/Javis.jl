#=

    This file transforms `anim_X` to a structure that is than used inside `Action`

=#

struct Translation <: AbstractTransition
    from::Union{Object,Point}
    to::Union{Object,Point}
end

"""
    anim_translate

Animate the translation of the attached object (see [`act!`](@ref)).

# Example
```julia
Background(1:100, ground)
obj = Object((args...)) -> circle(O, 50, :fill), Point(100, 0))
act!(obj, Action(1:50, anim_translate(10, 10)))
```

# Possibilities
- `anim_translate(x::Real, y::Real)` define end point of translation
- `anim_translate(tp::Union{Object,Point})` define end point with [`Object`](@ref) or `Point`.
- `anim_translate(fp::Union{Object,Point}, tp::Union{Object,Point})` define from and to point.
"""
anim_translate(x::Real, y::Real) = anim_translate(Point(x, y))
anim_translate(tp::Union{Object,Point}) = Translation(O, tp)
anim_translate(fp::Union{Object,Point}, tp::Union{Object,Point}) = Translation(fp, tp)

struct Rotation{T<:Real} <: AbstractTransition
    from::T
    to::T
    center::Union{Nothing,Point,AbstractObject}
end

"""
    anim_rotate

Animate the rotation of the attached object (see [`act!`](@ref)).

# Example
```julia
Background(1:100, ground)
obj = Object((args...)) -> rect(O, 50, 50, :fill), Point(100, 0))
act!(obj, Action(1:50, anim_rotate(2π)))
```

# Possibilities
- `anim_rotate(ta::Real)` define the end angle of the rotation
- `anim_rotate(fa::T, ta::T)` define the from and end angle

Similiar function: [`anim_rotate_around`](@ref) to rotate around a point
"""
anim_rotate(ta::Real) = Rotation(0.0, ta, nothing)
anim_rotate(fa::T, ta::T) where {T<:Real} = Rotation(fa, ta, nothing)

"""
    anim_rotate_around

Animate the rotation of the attached object (see [`act!`](@ref)) around a point.

# Example
```julia
Background(1:100, ground)
obj = Object((args...)) -> rect(O, 50, 50, :fill), Point(100, 0))
act!(obj, Action(1:50, anim_rotate_around(2π)))
```

# Possibilities
- `anim_rotate_around(ta::Real, p)` define the end angle of the rotation + the rotation center.
- `anim_rotate_around(fa::T, ta::T, p)` define the from and end angle + the rotation center.

Similiar function: [`anim_rotate`](@ref) to rotate or spin an object
"""
anim_rotate_around(ta::Real, p) = Rotation(0.0, ta, p)
anim_rotate_around(fa::T, ta::T, p) where {T<:Real} = Rotation(fa, ta, p)

struct Scaling <: AbstractTransition
    from::Union{Object,Scale,Symbol}
    to::Union{Object,Scale,Symbol}
end

Scaling(fs::Union{Object,Scale,Symbol}, ts) = Scaling(fs, ts)
Scaling(fs::Real, ts) = Scaling(Scale(fs, fs), ts)
Scaling(fs::Tuple, ts) = Scaling(Scale(fs...), ts)

Scaling(fs::Union{Object,Scale,Symbol}, ts::Real) = Scaling(fs, Scale(ts, ts))
Scaling(fs::Union{Object,Scale,Symbol}, ts::Tuple) = Scaling(fs, Scale(ts...))

"""
    anim_scale

Animate the scaling of the attached object (see [`act!`](@ref)).
**Attention:** Scaling is always done from the current origin.

# Example
```julia
Background(1:100, ground)
obj = Object((args...)) -> rect(O, 50, 50, :fill), Point(100, 0))
act!(obj, Action(1:50, anim_scale(1.5)))
```

# Possibilities
- `anim_scale(ts)` scales from the current scale to `ts`.
- `anim_scale(fs, ts)` scales from `fs` to `ts`.
"""
anim_scale(ts) = Scaling(:current_scale, ts)
anim_scale(fs, ts) = Scaling(fs, ts)
