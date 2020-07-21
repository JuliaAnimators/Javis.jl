function test_draw()
    d = Drawing(400, 200, "test.png")
    background("white")
    sethue("black")

    latex(L"\begin{equation}
            \left[
            \begin{array}{cc}
            2 & 3 \\
            4 & \sqrt{5} \\
            \end{array}
            \right]
            \end{equation}
            ", 50)
    finish()
    preview()
end