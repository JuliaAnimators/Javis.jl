# cache such that creating svgs from LaTeX don't need to be created every time
# this is also used for test cases such that `tex2svg` doesn't need to be installed on Github Objects
include("latexsvgfile.jl")
latex(text::LaTeXString) = latex(text, O)
latex(text::LaTeXString, pos::Point) = latex(text, pos, :stroke)
latex(text::LaTeXString, x, y) = latex(text, Point(x, y), :stroke)

"""
    latex(text::LaTeXString, pos::Point, object::Symbol)

Add the latex string `text` to the top left corner of the LaTeX path.
Can be added to `Luxor.jl` graphics via [`Video`](@ref).

**NOTES:**
- **This only works if `tex2svg` is installed.**
    It can be installed using the following command (you may have to prefix this command with `sudo` depending on your installation):

        npm install -g mathjax-node-cli

- **The `latex` method must be called from within an [`Object`](@ref).**

# Arguments
- `text::LaTeXString`: a LaTeX string to render.
- `pos::Point`: position of the upper left corner of the latex text. Default: `O`
    - can be written as `x, y` instead of `Point(x, y)`
- `object::Symbol`: graphics objects defined by `Luxor.jl`. Default `:stroke`.
Available objects:
  - `:stroke` - Draws the latex string on the canvas. For more info check `Luxor.strokepath`
  - `:path` - Creates the path of the latex string but does not render it to the canvas.

# Throws
- `IOError`: mathjax-node-cli is not installed

# Example

```
using Javis
using LaTeXStrings

function ground(args...)
    background("white")
    sethue("black")
end

function draw_latex(video, object, frame)
    fontsize(50)
    x = 100
    y = 120
    latex(L"\\sqrt{5}", x, y)
end

demo = Video(500, 500)
Background(1:2, ground)
Object(draw_latex)
render(demo; pathname = "latex.gif")
```

"""
function latex(text::LaTeXString, pos::Point, draw_object::Symbol)
    object = CURRENT_OBJECT[1]
    opts = object.opts
    t = get(opts, :draw_text_t, 1.0)
    return animate_latex(text, pos, t, draw_object)
end

function animate_latex(text, pos::Point, t, object)
    svg = get_latex_svg(text)
    object == :stroke && (object = :fill)
    if t >= 1
        translate(pos)
        pathsvg(svg)
        do_action(object)
        translate(-pos)
        return
    end

    pathsvg(svg)
    polygon = pathtopoly()
    w, h = polywh(polygon)

    translate(pos)
    pathsvg(svg)
    do_action(:clip)
    r = t * sqrt(w^2 + h^2)
    circle(O, r, :fill)
    translate(-pos)
end

"""
    strip_eq(text::LaTeXString)

Strips `\$\$` from `text.s` if present and returns the resulting string. 

# Arguments
- `text::LaTeXString`: a LaTeX string
"""
function strip_eq(text::LaTeXString)
    ts = text.s
    if ts[1] == '$'
        ts = ts[2:(end - 1)]
    end
    ts
end

# \todo update LaTeXSVG cache to use output of strip_eq as the key. See https://github.com/Wikunia/Javis.jl/pull/307#issuecomment-749616375
function get_latex_svg(text::LaTeXString)
    # check if it's cached
    if haskey(LaTeXSVG, text)
        svg = LaTeXSVG[text]
    else
        ts = strip_eq(text)
        command = `tex2svg $ts`
        try
            svg = read(command, String)
        catch e
            @warn "Using LaTeX needs the program `tex2svg` which might not be installed"
            @info "It can be installed using `npm install -g mathjax-node-cli`"
            throw(e)
        end
        LaTeXSVG[text] = svg
    end
    return svg
end
