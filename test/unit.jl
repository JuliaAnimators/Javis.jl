@testset "unit tests" begin
@testset "projection" begin
    x0 = Line(Point(0, 10), O)
    p = Point(10, 20)
    @test projection(p, x0) == Point(0, 20)

    y0 = Line(Point(10, 0), O)
    @test projection(p, y0) == Point(10, 0)
end

@testset "translation" begin
    video = Video(500, 500)
    # dummy action doesn't need a real function
    action = Action(1:100, ()->1, Translation(Point(1,1), Point(100, 100)))
    # needs internal translation as well
    push!(action.internal_transitions, Javis.InternalTranslation(O))
    Javis.compute_transformation!(action, video, 1)
    @test action.internal_transitions[1].by == Point(1,1)
    Javis.compute_transformation!(action, video, 50)
    @test action.internal_transitions[1].by == Point(50,50)
    Javis.compute_transformation!(action, video, 100)
    @test action.internal_transitions[1].by == Point(100,100)
end
end