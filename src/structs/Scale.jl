struct Scale
    x::Float64
    y::Float64
end

Base.:+(s1::Scale, s2::Scale) = Scale(s1.x + s2.x, s1.y + s2.y)
Base.:-(s1::Scale, s2::Scale) = Scale(s1.x - s2.x, s1.y - s2.y)
Base.:*(s1::Scale, f::Number) = f * s1
Base.:*(f, s1::Scale) = Scale(f * s1.x, f * s1.y)
