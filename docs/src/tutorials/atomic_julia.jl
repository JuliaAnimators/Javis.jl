using Javis
using PeriodicTable
using Unitful

function ground(args...)
    background("white")
    sethue("black")
end

function circ(p = O, color = "black")
    sethue(color)
    c = circle(p, 1, :fill)
    return val(:_current_scale)
end

function info_box(args...; value = 0)
    fontsize(12)
    box(140, -210, 170, 40, :stroke)
    # box(0, 200, 100, 100, :stroke)
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
                "Atomic Mass: $(round(ustrip(element.atomic_mass)))",
                140,
                -200,
                valign = :middle,
                halign = :center,
            )
            textwrap(
                "Description: $(element.summary)",
                400,
                Point(-200, 125),
            )
        end
    end
end

demo = Video(500, 500)
javis(
    demo,
    [
        BackgroundAction(1:500, ground),
        Action(
            :atom,
            (args...) -> circ(),
            subactions = [
                SubAction(1:300, Scaling(1, 30)),
                SubAction(301:350, Scaling(30, 16)),
            ],
        ),
        Action(1:300, (args...) -> info_box(value = round(val(:atom)[1]))),
        Action(
            351:500,
            (args...) -> info_box(value = round(val(:atom)[1])),
        ),
    ],
    pathname = "atomic.gif",
    framerate = 10,
)

