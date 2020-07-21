@testset "O(logn)" begin 
    d = Drawing(400, 150, "/tmp/test.png")
    background("white")
    sethue("black")
    latex(L"\mathcal{O}(\log{n})")
    fillpath()
    finish()
    @test_reference "refs/ologn.png" load("/tmp/test.png")
end