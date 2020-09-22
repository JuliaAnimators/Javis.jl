using Images
using Javis
using LaTeXStrings
using ReferenceTests
using Test
using VideoIO

@testset "Unit" begin
    include("unit.jl")
end
@testset "SVG LaTeX tests" begin
    include("svg.jl")
end
@testset "Animations" begin
    include("animations.jl")
end
