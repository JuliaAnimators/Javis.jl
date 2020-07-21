module Javis

using Luxor, LaTeXStrings

include("svg2luxor.jl")

function latex(t::LaTeXString)
    # remove the $
    ts = t.s[2:end-1]
    command = `tex2svg $ts`
    svg = read(command, String)
    Javis.pathsvg(svg)
end

function test_draw()
    d = Drawing(400, 150, "test.png")
    background("white")
    latex(L"\mathcal{O}(\log{n})")
    sethue("black")
    fillpath()
    finish()
end

export latex

end
