struct Translation <: AbstractTransition
    from::Point
    to::Point
end

anim_translate(x::Real, y::Real) = anim_translate(Point(x, y))
anim_translate(tp::Point) = Translation(O, tp)
anim_translate(fp::Point, tp::Point) = Translation(fp, tp)

struct Rotation{T<:Real} <: AbstractTransition
    from::T
    to::T
    center::Point
end

anim_rotate(ta::Real) = Rotation(0.0, ta, O)
anim_rotate(fa::T, ta::T) where {T<:Real} = Rotation(fa, ta, O)

anim_rotate_around(ta::Real, p::Point) = Rotation(0.0, ta, p)
anim_rotate_around(fa::T, ta::T, p::Point) where {T<:Real} = Rotation(fa, ta, p)

struct Scaling <: AbstractTransition
    from::Scale
    to::Scale
end

anim_scale(ts::Real) =
    Scaling(Scale(1.0, 1.0), Scale(convert(Float64, ts), convert(Float64, ts)))
anim_scale(fs::Real, ts::Real) = Scaling(
    Scale(convert(Float64, fs), convert(Float64, fs)),
    Scale(convert(Float64, ts), convert(Float64, ts)),
)
anim_scale(fs::Tuple{Float64,Float64}, ts::Tuple{Float64,Float64}) =
    Scaling(Scale(fs...), Scale(ts...))
