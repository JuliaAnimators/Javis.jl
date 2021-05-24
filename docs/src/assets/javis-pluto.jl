### A Pluto.jl notebook ###
# v0.12.21

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ d6c62fb0-bb9d-11eb-33e0-f5de58261376
using PlutoUI, Javis

# ╔═╡ ff1ff714-bb9f-11eb-1dfa-fbfa8c75d19f
begin
    function ground(args...)
        background("white") # canvas background
        sethue("black") # pen color
    end

    function object(p = O, color = "black")
        sethue(color)
        circle(p, 25, :fill)
        return p
    end

    function path!(points, pos, color)
        sethue(color)
        push!(points, pos) # add pos to points
        circle.(points, 2, :fill) # draws a circle for each point using broadcasting
    end

    function connector(p1, p2, color)
        sethue(color)
        line(p1, p2, :stroke)
    end

    myvideo = Video(500, 500)

    path_of_red = Point[]
    path_of_blue = Point[]

    Background(1:70, ground)
    red_ball = Object(1:70, (args...) -> object(O, "red"), Point(100, 0))
    act!(red_ball, Action(anim_rotate_around(2π, O)))
    blue_ball = Object(1:70, (args...) -> object(O, "blue"), Point(200, 80))
    act!(blue_ball, Action(anim_rotate_around(2π, 0.0, red_ball)))
    Object(1:70, (args...) -> connector(pos(red_ball), pos(blue_ball), "black"))
    Object(1:70, (args...) -> path!(path_of_red, pos(red_ball), "red"))
    Object(1:70, (args...) -> path!(path_of_blue, pos(blue_ball), "blue"))

    mygif = render(myvideo; liveview = true)

end

# ╔═╡ fb96b6b6-bb9d-11eb-2861-5dcfbab3e6f1
@bind x Slider(1:1:70)

# ╔═╡ 2664d0b2-bb9e-11eb-1af0-8d1c96dd8c92
mygif[x]

# ╔═╡ Cell order:
# ╠═d6c62fb0-bb9d-11eb-33e0-f5de58261376
# ╠═ff1ff714-bb9f-11eb-1dfa-fbfa8c75d19f
# ╠═fb96b6b6-bb9d-11eb-2861-5dcfbab3e6f1
# ╠═2664d0b2-bb9e-11eb-1af0-8d1c96dd8c92
