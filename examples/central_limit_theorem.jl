#=
Visualisation of a the central limit theorem convergence, (https://en.wikipedia.org/wiki/Central_limit_theorem).

The mean of n samples from "any" Independent Identically Distributed random variable converges towards a gaussian for n -> Inf
=#


using Javis
using Colors

# Following modules don't belong to Javis dependencies so to run them 
# one needs to add them to the enviroment used to run this script
using StatsBase
using Distributions

"""
    ground(args...)

Function defining the background of the animation.
"""
function ground(args...)
    background("black")
    sethue("white")
end

"""
    fixed_gaussian(loc_hist; color)

Returns an anonymous function to be given to barchart as labelfunction.
It takes care of normalizing the values of the limit gaussian distribution according
to the ```loc_hist``` histogram and render these values as circles. Also draws the
bottom tickline.
"""
function fixed_gaussian(loc_hist; color)
    (values, i, lowpos, highpos, barwidth, scaledvalue) -> begin

        minvalue, maxvalue = extrema(loc_hist.weights)
        barchartheight = boxheight(boundingbox) - 2margin
        minbarrange = minvalue - abs(minvalue)
        maxbarrange = maxvalue + abs(maxvalue)
        @layer begin

            sethue(color)
            if i <= length(loc_hist.edges[1])
                scaledgaussvalue =
                    rescale(
                        pdf(
                            gauss,
                            loc_hist.edges[1][i + 1] - loc_hist.edges[1].step.hi / 2,
                        ),
                        minbarrange,
                        maxbarrange,
                    ) * barchartheight
                circle(lowpos - (0, scaledgaussvalue), 3, :fill)
            end
        end

        tickline(
            boxbottomleft(boundingbox) - Point(0, margin),
            boxbottomright(boundingbox) - Point(0, margin),
            startnumber = loc_hist.edges[1][1],
            finishnumber = loc_hist.edges[1][end],
        )
    end
end

"""
    hist_bar

Utility function only used to change the histogram bars color.
"""
function hist_bar(; color)
    (values, i, lowpos, highpos, barwidth, scaledvalue) -> begin
        @layer begin
            sethue(color)
            Luxor.setline(barwidth)
            line(lowpos, highpos, :stroke)
        end
    end
end

# This can be changed to any distribution from Distribtuions.jl
dist = Bernoulli(0.3)

# Parameters for the barchart function 
boundingbox = BoundingBox(O + (-250, -120), O + (250, 120))
margin = 5


# number of frames
n_frames = 700

# Number of histograms shown. To make the animation
# slower set this to a lower value, less histograms
# will be shown but they will reach the same n for 
# convergence as set by n_frames
n_hists = 700

# number of samples at each n 
n_samples = 10000

# Change to adjust bar colors and gauss colors
barcolor = HSV(colorant"goldenrod1")
gausscolor = HSV(240, barcolor.s, barcolor.v)

# Sample the mean r.v. for increasing values of n (1 to n_hists)
samples = map(1:n_hists) do n
    map(1:n_samples) do _
        (mean(rand(dist, n)) - mean(dist)) * sqrt(n)
    end
end

finalmin, finalmax = extrema(samples[end])

# Turn the samples into histograms
steps = map(samples) do sampling
    hist = fit(
        Histogram,
        sampling,
        weights(ones(length(sampling))),
        range(finalmin, finalmax, length = 100),
    )
    hist = StatsBase.normalize(hist, mode = :pdf)
    hist
end

# Define the gaussian distribution where they should converge
gauss = Normal(0, StatsBase.std(dist))

my_video = Video(600, 500)
Background(1:n_frames, ground)

step_size = n_frames ÷ n_hists
frame_brakes = 1:step_size:n_frames

# Fix some point where whritings will be shown
titlepoint = Point(0, -100)
distpoint = Point(-200, 0)
counterpoint = Point(200, 0)

# The last and thus hopefully most closely converged histogram in our sequence
final_hist = steps[end]

for (frame_n, hist) in zip(frame_brakes, steps[1:end])

    Object(
        frame_n:(frame_n + step_size - 1),
        @JShape begin
            barchart(
                hist.weights,
                boundingbox = boundingbox,
                labels = true,

                # Provide the hist_bar we defined as the barfunction 
                barfunction = hist_bar(color = barcolor),

                # Provide the fixed_gaussian we defined as the labelfunction
                # it will plot the gaussian dots and the ticks on the bottom
                labelfunction = fixed_gaussian(final_hist, color = gausscolor),
            )
        end
    )

    # The counter digits
    Object(
        frame_n:(frame_n + step_size - 1),
        @JShape begin
            @layer begin
                sethue(barcolor)
                fontsize(15)
                text(string(frame_n ÷ step_size), counterpoint, halign = :center)
            end
        end
    )
end

# All the writings except the changing digit.
Object(
    1:n_frames,
    @JShape begin
        fontsize(40)
        text("Central Limit Theorem", titlepoint, halign = :center)

        fontsize(20)
        label("N", :N, counterpoint, offset = 20)
        label("Distribution", :N, distpoint, offset = 20)

        sethue(barcolor)
        fontsize(15)
        text(
            # Gather the distribution name and parameters
            # only works if dist is from Distributions.jl
            join([string(typeof(dist).name.name); string(params(dist))], ""),
            distpoint,
            halign = :center,
        )
    end
)

render(my_video, framerate = 100, pathname = "central_limit_theorem.gif")
