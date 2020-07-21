@testset "O(logn)" begin 
    d = Drawing(400, 200, "test.png")
    background("white")
    sethue("black")
    latex(L"\mathcal{O}(\log{n})", 50)
    translate(50, 70)
    orangeblue = blend(O, Point(0, 50), "orange", "blue")
    setblend(orangeblue)
    latex(L"\mathcal{O}\left(\frac{\log{x}}{2}\right)", 20)
    finish()
    @test_reference "refs/ologn.png" load("test.png")
    rm("test.png")
end