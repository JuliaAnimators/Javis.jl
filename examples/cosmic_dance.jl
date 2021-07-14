using Javis

function object(r, p = O, color = "black")
    sethue(color)
    circle(p, r, :fill)
    return p
end

function connector!(connection, p1, p2, color)
    sethue(color)
    push!(connection, [p1, p2])
    map(x -> line(x[1], x[2], :stroke), connection)
end

function ground(args...)
    background("black") # canvas background
    sethue("white") # pen color
end

function circ(p = O, color = "black", action = :fill, radius = 25, edge = "solid")
    sethue(color)
    setdash(edge)
    circle(p, radius, action)
end

function make_animation()

    # to store the connectors
    connection = []

    frames = 1000

    # setup the video
    myvideo = Video(500, 500)
    Background(1:frames, ground)

    # add the objects
    earth = Object(1:frames, (args...) -> object(5, O, "blue"), Point(200, 0))
    venus = Object(1:frames, (args...) -> object(4, O, "red"), Point(144, 0))

    # draw the orbits
    earth_orbit = Object((args...) -> circ(O, "white", :stroke, 200))
    venus_orbit = Object((args...) -> circ(O, "white", :stroke, 144))

    # move the planets
    # We need the planets to revolve according to their time periods.
    # Earth completes its one revolution in 365 days and Venus does that in 224.7 days.
    # Hence, we need to multiply (224.7/365) so that the time period matches properly i.e.,
    # when earth completes its full revolution, Venus has done (224.7/365) th of its revolution.
    act!(earth, Action(anim_rotate_around(12.5 * 2π, O)))
    act!(venus, Action(anim_rotate_around(12.5 * 2π * (224.7 / 365), O)))

    # draw the connectors
    Object(1:frames, (args...) -> connector!(connection, pos(earth), pos(venus), "#f05a4f"))

    # render
    render(myvideo, pathname = "cosmic_dance.gif")
end

make_animation()
