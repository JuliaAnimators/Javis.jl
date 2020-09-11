using Javis
using PeriodicTable
using Unitful

function ground(args...)
    background("white")
    sethue("black")
end

function element(;color = "black")
    sethue(color)
    circle(O, 4, :fill)
    return val(:_current_scale)[1]
end

function info_box(args...; value = 0)
    fontsize(12)
    box(140, -210, 170, 40, :stroke)
    box(0, 175, 450, 100, :stroke)
    for element in elements
        if value == round(ustrip(element.atomic_mass))
            text(
                "Element name: $(element.name)",
                140,
                -220,
                valign = :middle,
                halign = :center,
            )
            text(
                "Atomic Radius: $(round(ustrip(element.atomic_mass)))",
                140,
                -200,
                valign = :middle,
                halign = :center,
            )
            textwrap("Description: $(element.summary)", 400, Point(-200, 125))
        end
    end
end

demo = Video(500, 500)
javis(
    demo,
    [
        BackgroundAction(1:550, ground),
        Action(1:550,
            :atom,
            (args...) -> element(),
            subactions = [ 
                SubAction(101:140, Scaling(1, 12)),
                SubAction(241:280, Scaling(12, 20)),
                SubAction(381:420, Scaling(20, 7)),
                SubAction(521:550, Scaling(7, 1))
            ]
        ),
        Action(1:100, (args...) -> info_box(value = val(:atom))),
        Action(141:240, (args...) -> info_box(value = val(:atom))),
        Action(281:380, (args...) -> info_box(value = val(:atom))),
        Action(421:520, (args...) -> info_box(value = val(:atom))),
    ],
    pathname = "atomic.gif",
    framerate = 10,
)
