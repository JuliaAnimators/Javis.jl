using Javis, Random, LinearAlgebra

function ground(args...)
  background("black")
  sethue("white")
end

function ptdraw(point, vertices)
  return (args...) -> begin
      maxnorm = norm(vertices[1] - O)
      colors = norm.(point .- vertices)
      colors = (maxnorm .- colors) .* (colors .== minimum(colors)) ./ maxnorm
      sethue(colors...)
      circle(point, 2, :fill)
  end
end

AL = 500
video = Video(500, 500)
Background(1:AL, ground)

# Main triangle
pts = ngon(Point(0, 40), 240, 3, deg2rad(30), vertices=true)
dpts = ngon(Point(0, 40), 245, 3, deg2rad(30), vertices=true) # draw a slightly bigger triangle to avoid drawing points on it.
Object(1:AL, (args...) -> poly(dpts, :stroke, close=true))

dots = []
points = [O]
for i in 1:AL-3
    curr = rand(pts)
    nx = (curr.x + points[end].x)/2
    ny = (curr.y + points[end].y)/2
    push!(points, Point(nx, ny))
    push!(
        dots,
        Object(i:AL, ptdraw(points[end], pts))
    )
    Object(i:i+3, JLine(points[end], points[end-1], color="white", linewidth=0.5))
end

render(video, pathname="chaosgame.gif")