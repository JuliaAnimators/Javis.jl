#= 
Visualization of the gravities of different bodies around the solar system inspired by Dr. James O'Donoghue visualization here: https://twitter.com/physicsJ/status/1414233142861262855

Planetary data from NASA: https://nssdc.gsfc.nasa.gov/planetary/factsheet/ =#

using Javis # v0.7.1


diameters = Dict(
    "Mercury" => 4879,
    "Venus" => 12104,
    "Earth" => 12756,
    "Moon" => 3475,
    "Mars" => 6792,
    "Jupiter" => 142984,
    "Saturn" => 120536,
    "Uranus" => 51118,
    "Neptune" => 49528,
    "Pluto" => 2370,
)


struct Planet
    position::Int # Position from the sun
    name::String
    gravity::Real # m/s^2
    color::String # total guesstimate
    radius::Real # whatever fake units make the viz pretty
end

# Automatically calculate radius for us. Calculation is totally arbritrary
Planet(pos, name, grav, color) = Planet(pos, name, grav, color, log(diameters[name]) * 2)

planets = [
    Planet(1, "Mercury", 3.7, "snow4")
    Planet(2, "Venus", 8.9, "navajowhite")
    Planet(3, "Earth", 9.8, "lightskyblue")
    Planet(4, "Moon", 1.6, "gainsboro")
    Planet(5, "Mars", 3.7, "orangered")
    Planet(6, "Jupiter", 23.1, "olive")
    Planet(7, "Saturn", 9, "burlywood")
    Planet(8, "Uranus", 8.7, "cyan3")
    Planet(9, "Neptune", 11, "dodgerblue")
    Planet(10, "Pluto", 0.7, "rosybrown4")
]


framerate = 30
height = 1000 # meters | also the amount of pixels the balls will fall

frames = let
    # Get planet with slowest acceleration
    slowest = [p.gravity for p in planets] |> minimum

    # Kinematic equation to determine seconds to fall from height
    time = 2 * height / slowest |> sqrt

    # Calculate total frames and add a few seconds at the end to display final result
    ceil(Int, time * framerate) + framerate * 10
end

function ground(args...)
    background("black")
    sethue("white")
end

font_height = 25
width = 1500

# Give room for header and footer
top_padding = font_height
bottom_padding =
    font_height * 5 + 50 + maximum(ceil.(Int, [p.radius * 5 for p in planets])) + 1
total_height = height + top_padding + bottom_padding
start_height = total_height / 2 - top_padding * 4


myvideo = Video(width, total_height)
Background(1:frames, ground)

# Determine spacing and make some functions to help space the planets and text
spacing = width / (length(planets) + 1)
x_calc(planet::Planet) = (planet.position) * spacing - width / 2 + spacing / 2
y_height(row) = total_height / 2 - font_height / 2 - font_height * row



# 1km and 0km lines have to be drawn first to be under everything
Object(
    1:frames,
    JLine(
        Point(-width / 2, -start_height),
        Point(width, -start_height),
        color="darkgray",
        linewidth=5,
    ),
)
Object(
    1:frames,
    JLine(
        Point(-width / 2, -start_height + height),
        Point(width, -start_height + height),
        color="darkgray",
        linewidth=5,
    ),
)

planet_objects = [
    (
        p,
        Object(
            1:frames,
            JCircle(O, p.radius, color=p.color, action=:fill),
            Point(x_calc(p), -start_height),
        ),
    ) for p in planets
]

function gravity_force(p::Planet, args)
    video, obj, action, frame = args

    time = frame / framerate
    position = 0.5 * p.gravity * time^2

    y_position = min(position, height)

    obj.change_keywords[:center] = Point(0, y_position)

    # Leave trail to give an idea of the acceleration after planet has finished falling
    if frame % framerate * 4 == 0
        Object(
            frame:frames,
            JCircle(O, p.radius / 5, color=p.color, action=:fill),
            Point(x_calc(p), y_position - start_height),
        )
    end



    # Update text for planets current state

    # Determine if planet is finished moving. 
    t_final = sqrt(height / (0.5 * p.gravity))
    v_final = p.gravity * t_final
    if y_position == height
        # Set all the text for after the planet is done moving

        if t_final < time
            Object(
                frame:frame,
                @JShape begin
                fontsize(font_height)
                sethue("springgreen4")
                text(
                        string(round(t_final, digits=1), "s"),
                        Point(x_calc(p), y_height(1)),
                        halign=:center,
                    )
                text(
                        string(round(v_final, digits=2), "m/s"),
                        Point(x_calc(p), y_height(0)),
                        halign=:center,
                    )
            end
            )
        end
    else
        Object(
            frame:frame,
            @JShape begin
                fontsize(font_height)
                text(
                    string(round(time, digits=1), "s"),
                    Point(x_calc(p), y_height(1)),
                    halign=:center,
                )
                text(
                    string(round(p.gravity * time, digits=2), "m/s"),
                    Point(x_calc(p), y_height(0)),
                    halign=:center,
                )
            end
        )
    end
end


for (p, obj) in planet_objects
    act!(obj, Action(1:frames, (args...) -> gravity_force(p, args)))


    # Set text that is static during entire animation for each planet

    # Set planet info
    Object(
        1:frames,
        @JShape begin
            fontsize(font_height)
            sethue(p.color)
            text(p.name, Point(x_calc(p), y_height(3)), halign=:center)
            text(
                string(p.gravity, "m/s^2"),
                Point(x_calc(p), y_height(2)),
                halign=:center,
            )
        end
    )

    Object(
        1:frames,
        JCircle(O, p.radius, color=p.color, action=:fill),
        Point(x_calc(p), y_height(4) - p.radius),
    )
end

# Set the legend text
Object(
    1:frames,
    @JShape begin
        fontsize(font_height)
        x_pt = -width / 2 + 10
        text("1km", Point(x_pt, -start_height - 10), halign=:left)
        text("0km", Point(x_pt, -start_height + height - 10), halign=:left)


        fontsize(font_height * 0.75)
        text("Planet:", Point(x_pt, y_height(3)), halign=:left)
        text("Acceleration:", Point(x_pt, y_height(2)), halign=:left)

        text("Time:", Point(x_pt, y_height(1)), halign=:left)
        text("Velocity:", Point(x_pt, y_height(0)), halign=:left)

        fontsize(font_height * 2)
        sethue("royalblue")
        text(
            "Ball Falling 1km on Bodies in the Solar System",
            Point(0, -total_height / 2 + font_height * 2.5),
            halign=:center,
        )
    end
    )

render(myvideo; liveview=true)
# render(myvideo; pathname="gravities.gif")
