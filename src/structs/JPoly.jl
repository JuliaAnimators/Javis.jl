using Luxor
using Colors

struct JPoly
    points::Array{Points}
    closed::Bool
    fill::RGB{FixedPointNumbers,N0f8}
    stroke::RGB{FixedPointNumbers,N0f8}
    linewidth::Number
end
