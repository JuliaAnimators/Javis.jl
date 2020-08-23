using Javis
using LaTeXStrings

function ground(args...)
    background("white")
    sethue("black")
end

function draw_latex(video, action, frame)
    translate(video.width / -2, video.height / -2)
    black_red = blend(O, Point(0, 150), "black", "red")
    setblend(black_red)
    fontsize(50)
    latex(
        L"""\begin{equation}
        \left[\begin{array}{cc} 
        2 & 3 \\  4 & \sqrt{5} \\  
        \end{array} \right] 
        \end{equation}"""
    )
end

demo = Video(500, 500)
javis(demo, [BackgroundAction(1:2, ground), Action(draw_latex)], pathname = "latex.gif")
