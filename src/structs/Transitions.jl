struct Translation <: AbstractTransition
    from::Union{Object,Point}
    to::Union{Object,Point}
end

anim_translate(x::Real, y::Real) = anim_translate(Point(x, y))
anim_translate(tp::Union{Object,Point}) = Translation(O, tp)
anim_translate(fp::Union{Object,Point}, tp::Union{Object,Point}) = Translation(fp, tp)

struct Rotation{T<:Real} <: AbstractTransition
    from::T
    to::T
    center::Union{Nothing,Point,AbstractObject}
end

anim_rotate(ta::Real) = Rotation(0.0, ta, nothing)
anim_rotate(fa::T, ta::T) where {T<:Real} = Rotation(fa, ta, nothing)

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

anim_scale(ts) = Scaling(:current_scale, ts)
anim_scale(fs, ts) = Scaling(fs, ts)
