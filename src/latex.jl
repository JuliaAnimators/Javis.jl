# cache such that creating svgs from LaTeX don't need to be created every time
# this is also used for test cases such that `tex2svg` doesn't need to be installed on Github Objects
include("latexsvgfile.jl")
LaTeXusepackages = ["amssymb", "amsmath"]
LaTeXprog = :tex2svg

""" set which backend to use
    default is `:tex2svg`, set to
    `setLaTeXprog(:dvisvgm)` to use pdflatex with dvisvgm
    to generate latex 
"""
function setLaTeXprog(s::Symbol)
    global LaTeXprog
    LaTeXprog = s
end

latex(text::LaTeXString) = latex(text, O)
latex(text::LaTeXString, pos::Point) = latex(text, pos, :stroke)
latex(text::LaTeXString, pos::Point, valign::Symbol, halign::Symbol) =
    latex(text, pos, :stroke, valign = valign, halign = halign)
latex(text::LaTeXString, x, y) = latex(text, Point(x, y), :stroke)
latex(text::LaTeXString, x, y, valign::Symbol, halign::Symbol) =
    latex(text, Point(x, y), :stroke, valign = valign, halign = halign)
"""
    latex(text::LaTeXString, pos::Point, object::Symbol; valign = :top, halign = :left)

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

# Keywords:
  - `valign::Symbol=:top`: vertical alignment with respect to the specified `pos` parameter.
      - Options available are `:top`, `:middle`, `:bottom`
  - `halign::Symbol=:left`: horizontal alignment with respect to the specified `pos` parameter.
      - Options available are `:left`, `:center/:centre`, `:right`

# Throws
- `IOError`: mathjax-node-cli is not installed

# Warning
Shows a warning if either of the alignment options are unrecognised.

# Example

```julia
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
function latex(
    text::LaTeXString,
    pos::Point,
    draw_object::Symbol;
    valign = :top,
    halign = :left,
)
    object = CURRENT_OBJECT[1]
    opts = object.opts
    t = get(opts, :draw_text_t, 1.0)
    return animate_latex(text, pos, t, valign, halign, draw_object)
end

function animate_latex(text, pos::Point, t, valign::Symbol, halign::Symbol, object)
    svg = get_latex_svg(text)
    object == :stroke && (object = :fill)

    w, h = svgwh(svg)
    halignment = findfirst(isequal(halign), (:left, :center, :right, :centre))

    if halignment === nothing
        @warn "Unknown horizontal alignment option: $(halign). Defaulting to left alignment"
        halignment = 1
    elseif halignment == 4
        halignment = 2
    end

    textpointx = pos.x - (0, w / 2, w)[halignment]
    valignment = findfirst(isequal(valign), (:top, :middle, :bottom))

    if valignment === nothing
        @warn "Unknown vertical alignment option: $(valign). Defaulting to top alignment"
        valignment = 1
    end

    textpointy = pos.y - (0, h / 2, h)[valignment]
    upperleft = Point(textpointx, textpointy)

    if t >= 1
        translate(upperleft)
        pathsvg(svg)
        do_action(object)
        translate(-upperleft)
        return
    end

    translate(upperleft)
    pathsvg(svg)
    do_action(:clip)
    r = t * sqrt(w^2 + h^2)
    circle(O, r, :fill)
    translate(-upperleft)
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

# \todo update LaTeXSVG cache to use output of strip_eq as the key. See https://github.com/JuliaAnimators/Javis.jl/pull/307#issuecomment-749616375
function get_latex_svg(text::LaTeXString)
    #check if it's cached
    """ for now the default is to use tex2svg, from mathjax
    pass `Javis.setLaTeXprog(:dvisvgm)` to yse dvisvgm
    """

    if haskey(LaTeXSVG, text)
        svg = LaTeXSVG[text]
    else
        if Javis.LaTeXprog == :tex2svg
            ts = replace(strip_eq(text), "\n" => " ")
            command = if Sys.iswindows()
                `cmd /C tex2svg $ts`
            else
                `tex2svg $ts`
            end
            try
                svg = read(command, String)
            catch e
                @warn "Using LaTeX needs the program `tex2svg` which might not be installed"
                @info "It can be installed using `npm install -g mathjax-node-cli`,or if you have a TeX distribution installed try setting `setLaTeXprog(:dvisvgm)`"
                throw(e)
            end
        elseif Javis.LaTeXprog == :dvisvgm
            println("using dvisvgm")
            svg = tex2svg(text)
        end
        LaTeXSVG[text] = svg
    end
    return svg
end

"""
generates svg from LaTeXString;
"""
function tex2svg(text::LaTeXString;)
    output_dir = mktempdir(cleanup = false)
    packagestring = "{" * join(LaTeXusepackages, ",") * "}"
    pre = "\\documentclass[12pt]{standalone}
      \\usepackage$packagestring

      \\begin{document}
      "
    post = "\\end{document}
    "
    texfilepath, texio = mktemp(output_dir, cleanup = false)
    write(texio, pre * "\n")
    write(texio, text)
    write(texio, "\n" * post)
    flush(texio)
    #sometimes latex returns 1,so we use `success` instead of `run`; but pdf is made so its okay 
    stat = success(
        `latex  --interaction=nonstopmode --output-dir=$output_dir --output-format=pdf $texfilepath`,
    )
    if stat == false
        @warn "there maybe errors in processing latex, check $texfilepath.log for details"
    end
    retstring = read(`dvisvgm -n --bbox=preview --stdout --pdf  $texfilepath.pdf`, String)
    return retstring

end
