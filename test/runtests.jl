using Images
using Javis
using LaTeXStrings
using ReferenceTests
using Test
using VideoIO

EXCLUDE_FILES = [".keep"]
for f in readdir("images")
    !(f in EXCLUDE_FILES) && rm("images/$f")
end

@testset "Unit" begin
    include("unit.jl")
end
@testset "SVG LaTeX tests" begin
    include("svg.jl")
end
@testset "Animations" begin
    include("animations.jl")
end
