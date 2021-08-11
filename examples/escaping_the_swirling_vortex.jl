# "Escaping the swirling vortex"
#
# Nonautonomous ODE from pg 121 of Hale's ODE book, credited to
# Markus, L. and H. Yamabe "Global stability criteria for diferential systems",
# Osaka Math. J. 12 (1960), 305-317.
#
# A nonautonomous linear ODE of the form `du/dt = A(t)u`, with all the eigenvalues
# of `A(t)` being complex with negative real part.
#
# However, origin is an unstable fixed point!
#
# The vector field visualization was based on 
# https://gist.github.com/Wikunia/4ca58b4c08da90978c0dcdee5b0c908a

using Javis
using Colors
using LinearAlgebra

"""
    ground(args...)

Define the background and the initial "foreground" color.
"""
function ground(args...)
    background("black")
    sethue("white")
    return nothing
end

"""
dudt(x, y, t)

Return the right hand side of the linear equation `u'=A(t)u`,
where u=[x,y]. In this case, the equation takes the from
    x' = (-1 + 1.5cos(t)^2)x + (1 - 1.5cos(t)sin(t))y
    y' = (-1 - 1.5sin(t)cos(t))x + (-1 + 1.5sin(t)^2)y
"""
function dudt(x, y, t)
    ct = cos(t)
    st = sin(t)
    dxdt = (-1.0 + 1.5 * ct^2) * x + (1.0 - 1.5 * ct * st) * y
    dydt = (-1.0 - 1.5 * st * ct) * x + (-1.0 + 1.5 * st^2) * y
    return dxdt, dydt
end

"""
    jacobian!(mat, t)

Return (and modify in place) the linear part `A(t)` of the equation `u'=A(t)u`
(see [`dudt`](@ref)). This is also seen as the Jacobian of `u -> f(t,u) = A(t)u`.
"""
function jacobian!(mat, t)
    ct = cos(t)
    st = sin(t)
    mat[1, 1] = -1.0 + 1.5 * ct^2
    mat[1, 2] = 1.0 - 1.5 * ct * st
    mat[2, 1] = -1.0 - 1.5 * st * ct
    mat[2, 2] = -1.0 + 1.5 * st^2
    return mat
end

"""
    solution!(u,t)

Return a particular solution of the equation `u'=A(t)u`, given by
`u = exp(t/2)  * [-cos(t), sin(t)] / 20.0` corresponding to the initial condition
`u(0) = [-0.05, 0.0]`
"""
function solution!(u, t)
    et2 = exp(t / 2) / 20.0
    u[1] = -et2 * cos(t)
    u[2] = et2 * sin(t)
    return u
end

"""
    space_to_frame_coordinates(u, frm_scl)

Transform a point in xy coordinates to the frame coordinates XY.
They are related according to `X = frm_scl * x` and `Y = - frm_scl * y`,
for a given scale factor `frm_scl`.
"""
space_to_frame_coordinates(u, frm_scl) = frm_scl * Point(u[1], -u[2])
space_to_frame_coordinates(x, y, frm_scl) = space_to_frame_coordinates([x, y], frm_scl)

"""
    ellipse_level_set!(u, t, mat, σ₁, σ₂, frm_scl)

Draw a "level-set"-like ellipse associated with the solution at time `t`.

For a given time `t`, the solutions `w=w(s)` of the autonomous equation
`dw(s)/ds = A(t)w(s)` spiral towards the origin, decreasing along the level
sets of an elliptic paraboloid. This function computes and draws the ellipse
level set containing the solution `u(t)`. Note, however, that `u=u(t)` is
the solution of the nonautonomous equation `du(t)/dt = A(t)u(t)` given
by [`solution!`](@ref), which spirals away from the origin.

The ellipse is computed by finding the complex eigenvector `v=v(t)` of the
complex eigenvalue `α + iβ` of `A(t)` and considering the real and invertible
matrix `P(t) = [Re(v(t)) Im(v(t))]` which transforms `A(t)` into its real
Jordan form `P(t)^-1 * A(t) P(t) = [α β, -β α]`. In this particular case, the
eigenvalues `α ± iβ` are time-independent. The ellipse is obtained from the
SVD decomposition `P = UΣVᵗ`, where `Σ = diag(σ₁, σ₂)` is diagonal with
nonnegative elements `σ₁ ≥ σ₂ ≥ 0`, and `U` and `V` are orthogonal matrices.
In general, all these terms may change in time, but in the particular
example we are considering, only `U=U(t)` and `V=V(t)` are time-dependent,
with `σ₁ > σ₂ > 0` being constant. The elements `σ₁` and `σ₂` are, precisely,
the semi-major and semi-minor axes of the ellipse associated with the level
set of the elliptic paraboloid at level one. It determines the eccentricity
of the ellipse. The orientation of the ellipse is given by the rotation
determined by the orthogonal matrix `U=U(t)`.

At each time `t`, we find and draw the level set that contains the solution `u(t)`
as follows. We rotate `u(t)` via `Uᵗ = inv(U)`, compute the semi-major
and semi-minor axis of the ellipse that has the same level as `Uᵗu(t)`, compute
the foci of this ellipse, rotate the foci back to the right orientation by applying
the orthogonal matrix `U`, and then find the ellipse, in frame coordinates, that
defined by the foci, in frame coordinates, and passing by the solution `u(t)`, in
frame coordinates.
"""
function ellipse_level_set!(u, t, mat, σ₁, σ₂, frm_scl)
    sethue("white")
    jacobian!(mat, t)
    v = eigen(mat).vectors[:, 1]
    U = svd([real(v) imag(v)]).U
    x, y = transpose(U) * solution!(u, t)
    γ = sqrt(x^2 / σ₁^2 + y^2 / σ₂^2) # level
    σ̃₁ = γ * σ₁ # semi-major
    σ̃₂ = γ * σ₂ # semi-minor
    fd = sqrt(abs(σ̃₁^2 - σ̃₂^2)) # focal distance to the origin/center
    f = U * [fd, 0.0] # one focus point; the other is -f
    poly(
        ellipse(
            space_to_frame_coordinates(f, frm_scl), # focus in frame coordinates
            -space_to_frame_coordinates(f, frm_scl), # the other focus
            space_to_frame_coordinates(u, frm_scl), # ellipse/level containing u(t)
        ),
        :stroke,
        close = true,
    )
    return nothing
end

"""
    ball(p=O, size=4, color="red")

Draw a filled circle of size `size` and color `color` around the point `p`
"""
function ball(p = O, size = 4, color = "red")
    sethue(color)
    circle(p, size, :fill)
    return p
end

"""
    path!(points, pos, color)

Update and draw the trail of the solution.

Add the point `pos` to the vector `points` containing the trail of the trajectory
and draw the trail.
"""
function path!(points, pos, color)
    sethue(color)
    push!(points, pos) # add pos to points
    prettypoly(points) # draw dotted path with circles
    return nothing
end

"""
    ode_arrow(x, y, t, frm_scl, color_min, color_max)

Create one arrow at the base point `(x,y)` and arrow vector given by `dudt(x, y, t)`.
The arrow is properly scaled by the factor `frm_scl` and the orientation takes into
account that the vertical coordinate increases downwards. Depending on the magnitude
of the vector field at that point, the color ranges from `color_min` to `color_max`.
"""
function ode_arrow(x, y, t, frm_scl, color_min, color_max)
    @JShape begin
        translate(space_to_frame_coordinates(x, y, frm_scl))
        dx, dy = dudt(x, y, t)
        delta_t = 0.1
        ξ = dx * delta_t
        η = dy * delta_t
        l = sqrt(ξ^2 + η^2)
        len_colors = 100
        color_range = range(color(color_min), stop = color(color_max), length = len_colors)
        idx = clamp(floor(Int, l * len_colors), 1, len_colors)
        sethue(color_range[idx])
        if ξ != 0 || η != 0
            arrow(
                O,
                space_to_frame_coordinates(ξ, η, frm_scl);
                linewidth = 2,
                arrowheadlength = 8,
            )
        end
    end x = x y = y t = t frm_scl = frm_scl
end

"""
    horizontal_grid_line(video, c, frm_scl)

Create an horizontal grid line at `y=c`
"""
function horizontal_grid_line(video, r, frm_scl)
    if r == 0
        setline(1.5)
    end
    sethue("gray")
    line(Point(-video.width / 2, r * frm_scl), Point(video.width / 2, r * frm_scl), :stroke)
    return nothing
end

"""
    vertical_grid_line(video, c, frm_scl)

Create a vertical grid line at `x=c`.
"""
function vertical_grid_line(video, c, frm_scl)
    if c == 0
        setline(1.5)
    end
    sethue("gray")
    line(
        Point(c * frm_scl, -video.height / 2),
        Point(c * frm_scl, video.height / 2),
        :stroke,
    )
    return nothing
end

"""
    animate()

Create the animation. 😃
"""
function animate()
    # initial setup
    vid = Video(500, 500)
    nframes = 200
    xgrid = -2.0:0.25:2.0 # grid for bars and arrow base points
    ygrid = -2.0:0.25:2.0 # grid for bars and arrow base points
    t₀, tf = 0.0, 5π / 2 # time interval for the simulation
    u = [0.0, 0.0] # dummy initizaliation of the solution vector
    solution!(u, t₀) # initial vector
    mat = zeros(2, 2) # dummy initialization of the jacobian
    jacobian!(mat, t₀) # jacobian at time t₀  
    v = eigen(mat).vectors[:, 1] # first eigenvector
    svd_P = svd([real(v) imag(v)]) # P = [real(v) imag(v)] => inv(P) * mat * P = [α β; -β α]
    σ₁, σ₂ = svd_P.S # the semi-major and semi-minor axes are constant in this problem
    t = t₀ # set t to initial time
    frm_scl = 120 # frame scale
    solution_trail = Point[] # initialize history vector for the solution path

    # objects
    ## set background for all frames
    Background(1:nframes, ground)
    ## grids
    [
        Object(1:nframes, (args...) -> horizontal_grid_line(args[1], x, frm_scl)) for
        x in xgrid
    ]
    [Object(1:nframes, (args...) -> vertical_grid_line(args[1], y, frm_scl)) for y in ygrid]
    ## vector field
    arrows = [
        Object(1:nframes, ode_arrow(x, y, t, frm_scl, "yellow", "red")) for x in xgrid,
        y in ygrid
    ]
    ## solution at time t
    sol_pos = Object(
        1:nframes,
        (args...; t) -> ball(
            space_to_frame_coordinates(solution!(u, t), frm_scl),
            6,
            "lightskyblue",
        ),
    )
    ## solution trail
    Object(1:nframes, (args...) -> path!(solution_trail, pos(sol_pos), "lightskyblue"))
    ## ellipse
    obj_ellipse =
        Object(1:nframes, (args...; t) -> ellipse_level_set!(u, t, mat, σ₁, σ₂, frm_scl))

    # animation
    ## update solution, vector field and ellipse
    ## rmk: animation of the solution trail is a byproduct of updating solution
    act!(sol_pos, Action(1:nframes, change(:t, t₀ => tf)))
    act!(arrows, Action(1:nframes, change(:t, t₀ => tf)))
    act!(obj_ellipse, Action(1:nframes, change(:t, t₀ => tf)))

    # rendering
    ## render and generate gif
    render(
        vid;
        framerate = 15,
        pathname = joinpath(@__DIR__, "gifs/escaping_the_swirling_vortex.gif"),
    )

    return nothing
end

animate()
