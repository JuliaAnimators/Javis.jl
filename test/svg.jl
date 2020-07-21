@testset "O(logn)" begin 
    d = Drawing(400, 150, "test.png")
    background("white")
    sethue("black")
    latex(L"\mathcal{O}(\log{n})", 50)
    fillpath()
    finish()
    @test_reference "refs/ologn.png" load("test.png")
    rm("test.png")
end