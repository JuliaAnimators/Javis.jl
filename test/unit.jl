@testset "unit tests" begin
@testset "projection" begin
    x0 = Line(Point(0, 10), O)
    p = Point(10, 20)
    @test projection(p, x0) == Point(0, 20)

    y0 = Line(Point(10, 0), O)
    @test projection(p, y0) == Point(10, 0)
end
end