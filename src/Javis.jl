module Javis

using Luxor, LaTeXStrings

"""
    Video

Defines the video canvas for an animation.

# Fields
- `width::Int` the width in pixel
- `height::Int` the height in pixel
- `defs::Dict{Symbol, Any}` Some definitions which should be accessible throughout the video.
"""
mutable struct Video
    width   :: Int
    height  :: Int
    defs    :: Dict{Symbol, Any}
end
"""
    Video(width, height)

Create a video with a certain `width` and `height` in pixel.
"""
Video(width, height) = Video(width, height, Dict{Symbol, Any}())

"""
    Transformation

Defines a transformation which can be returned by an action to be accessible later. 
See the `circ` function inside the [`javis`](@ref) as an example. 
It can be accessed by another [`Action`])(@ref) using the symbol notation like `:red_ball` in the example.

# Fields
- `p::Point`: the translation part of the transformation
- `angle::Float64`: the angle component of the transformation (in radians)
"""
mutable struct Transformation
    p       :: Point
    angle   :: Float64
end

abstract type Transition end
abstract type InternalTransition end

"""
    Action

Defines what is drawn in a defined frame range. 

# Fields
- `frames`: A range of frames for which the `Action` is called
- `id::Union{Nothing, Symbol}`: An id which can be used to save the result of `func`
- `func::Function`: The drawing function which draws something on the canvas. 
    It gets called with the arguments `video, action, frame`
- `transitions::Vector{Transition}` a list of transitions that can be performed before the function gets called.
- `internal_transitions::Vector{InternalTransition}`: Similar to `transitions` but holds the concrete information 
    whereas `Transition` can hold links to other actions which need to be computed first. See [`compute_transformation!`](@ref)
- `opts::Any` can hold any options defined by the user
"""
mutable struct Action
    frames                  :: UnitRange{Int}
    id                      :: Union{Nothing, Symbol}
    func                    :: Function
    transitions             :: Vector{Transition}
    internal_transitions    :: Vector{InternalTransition}
    opts                    :: Any
end

"""
    Action(frames, func::Function, args...)

The most simple form of an action (if there are no `args`) just calls
`func(video, action, frame)` for each of the frames it is defined for. 
`args` are defined it the next function definition and can be seen in action in this example [`javis`](@ref)
"""
Action(frames, func::Function, args...) = Action(frames, nothing, func, args...)

"""
    Action(frames, id::Union{Nothing,Symbol}, func::Function, transitions::Transition...)

# Arguments
- `frames`: defines for which frames this action is called
- `id::Symbol`: Is used if the `func` returns something which shell be accessible by other actions later
- `func::Function` the function that is called after the `transitions` are performed
- `transitions::Transition...` a list of transitions that are performed before the function `func` itself is called
"""
Action(frames, id::Union{Nothing,Symbol}, func::Function, transitions::Transition...) = 
    Action(frames, id, func, collect(transitions), [], nothing)

mutable struct InternalTranslation <: InternalTransition
    by :: Point
end

mutable struct InternalRotation <: InternalTransition
    angle   :: Float64
    center  :: Point
end

"""
    Translation <: Transition

Stores the `Point` or a link for the start and end position of the translation

# Fields
`from::Union{Point, Symbol}`: The start position or a link to the start position. See `:red_ball` in [`javis`](@ref) 
`to::Union{Point, Symbol}`: The end position or a link to the end position
"""
struct Translation <: Transition
    from :: Union{Point, Symbol}
    to   :: Union{Point, Symbol}
end

"""
    Rotation <: Transition

Stores the rotation similar to [`Translation`](@ref) with `from` and `to` but also the rotation point.

# Fields
- `from::Union{Float64, Symbol}`: The start rotation or a link to it
- `to::Union{Float64, Symbol}`: The end rotation or a link to it
- `center::Union{Point, Symbol}`: The center of the rotation or a link to it.
"""
struct Rotation <: Transition
    from    :: Union{Float64, Symbol}
    to      :: Union{Float64, Symbol}
    center  :: Union{Point, Symbol}
end

"""
    Rotation(from, to)

Rotation as a transition from `from` to `to` (in radians) around the origin.
"""
Rotation(from, to) = Rotation(from, to, O)

"""
    Line

A type to define a line by two points. Can be used i.e. in [`projection`](@ref)
We mean the mathematic definition of a continuous line and not a segment of a line.

# Fields
- `p1::Point`: start point
- `p2::Point`: second point to define the line)
"""
struct Line 
    p1 :: Point
    p2 :: Point
end

"""
    Base.:*(m::Array{Float64,2}, transformation::Transformation)

Convert the transformation to a matrix and multiplies m*trans_matrix.
Return a new Transformation
"""
function Base.:*(m::Array{Float64,2}, transformation::Transformation)
    θ = transformation.angle
    p = transformation.p
    trans_matrix = [
        cos(θ) -sin(θ) p.x;
        sin(θ)  cos(θ) p.y;
        0            0   1
    ]
    res = m*trans_matrix
    return Transformation(
        Point(gettranslation(res)...),
        getrotation(res)
    )
end

# cache such that creating svgs from LaTeX don't need to be created every time
# this is also used for test cases such that `tex2svg` doesn't need to be installed on Github Actions
const LaTeXSVG = Dict{LaTeXString, String}(
    L"\mathcal{O}(\log{n})" => "<svg xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"8.413ex\" height=\"2.843ex\" style=\"vertical-align: -0.838ex;\" viewBox=\"0 -863.1 3622.2 1223.9\" role=\"img\" focusable=\"false\" xmlns=\"http://www.w3.org/2000/svg\" aria-labelledby=\"MathJax-SVG-1-Title\">\n<title id=\"MathJax-SVG-1-Title\">script upper O left-parenthesis log n right-parenthesis</title>\n<defs aria-hidden=\"true\">\n<path stroke-width=\"1\" id=\"E1-MJCAL-4F\" d=\"M308 428Q289 428 289 438Q289 457 318 508T378 593Q417 638 475 671T599 705Q688 705 732 643T777 483Q777 380 733 285T620 123T464 18T293 -22Q188 -22 123 51T58 245Q58 327 87 403T159 533T249 626T333 685T388 705Q404 705 404 693Q404 674 363 649Q333 632 304 606T239 537T181 429T158 290Q158 179 214 114T364 48Q489 48 583 165T677 438Q677 473 670 505T648 568T601 617T528 636Q518 636 513 635Q486 629 460 600T419 544T392 490Q383 470 372 459Q341 430 308 428Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-28\" d=\"M94 250Q94 319 104 381T127 488T164 576T202 643T244 695T277 729T302 750H315H319Q333 750 333 741Q333 738 316 720T275 667T226 581T184 443T167 250T184 58T225 -81T274 -167T316 -220T333 -241Q333 -250 318 -250H315H302L274 -226Q180 -141 137 -14T94 250Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-6C\" d=\"M42 46H56Q95 46 103 60V68Q103 77 103 91T103 124T104 167T104 217T104 272T104 329Q104 366 104 407T104 482T104 542T103 586T103 603Q100 622 89 628T44 637H26V660Q26 683 28 683L38 684Q48 685 67 686T104 688Q121 689 141 690T171 693T182 694H185V379Q185 62 186 60Q190 52 198 49Q219 46 247 46H263V0H255L232 1Q209 2 183 2T145 3T107 3T57 1L34 0H26V46H42Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-6F\" d=\"M28 214Q28 309 93 378T250 448Q340 448 405 380T471 215Q471 120 407 55T250 -10Q153 -10 91 57T28 214ZM250 30Q372 30 372 193V225V250Q372 272 371 288T364 326T348 362T317 390T268 410Q263 411 252 411Q222 411 195 399Q152 377 139 338T126 246V226Q126 130 145 91Q177 30 250 30Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-67\" d=\"M329 409Q373 453 429 453Q459 453 472 434T485 396Q485 382 476 371T449 360Q416 360 412 390Q410 404 415 411Q415 412 416 414V415Q388 412 363 393Q355 388 355 386Q355 385 359 381T368 369T379 351T388 325T392 292Q392 230 343 187T222 143Q172 143 123 171Q112 153 112 133Q112 98 138 81Q147 75 155 75T227 73Q311 72 335 67Q396 58 431 26Q470 -13 470 -72Q470 -139 392 -175Q332 -206 250 -206Q167 -206 107 -175Q29 -140 29 -75Q29 -39 50 -15T92 18L103 24Q67 55 67 108Q67 155 96 193Q52 237 52 292Q52 355 102 398T223 442Q274 442 318 416L329 409ZM299 343Q294 371 273 387T221 404Q192 404 171 388T145 343Q142 326 142 292Q142 248 149 227T179 192Q196 182 222 182Q244 182 260 189T283 207T294 227T299 242Q302 258 302 292T299 343ZM403 -75Q403 -50 389 -34T348 -11T299 -2T245 0H218Q151 0 138 -6Q118 -15 107 -34T95 -74Q95 -84 101 -97T122 -127T170 -155T250 -167Q319 -167 361 -139T403 -75Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMATHI-6E\" d=\"M21 287Q22 293 24 303T36 341T56 388T89 425T135 442Q171 442 195 424T225 390T231 369Q231 367 232 367L243 378Q304 442 382 442Q436 442 469 415T503 336T465 179T427 52Q427 26 444 26Q450 26 453 27Q482 32 505 65T540 145Q542 153 560 153Q580 153 580 145Q580 144 576 130Q568 101 554 73T508 17T439 -10Q392 -10 371 17T350 73Q350 92 386 193T423 345Q423 404 379 404H374Q288 404 229 303L222 291L189 157Q156 26 151 16Q138 -11 108 -11Q95 -11 87 -5T76 7T74 17Q74 30 112 180T152 343Q153 348 153 366Q153 405 129 405Q91 405 66 305Q60 285 60 284Q58 278 41 278H27Q21 284 21 287Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-29\" d=\"M60 749L64 750Q69 750 74 750H86L114 726Q208 641 251 514T294 250Q294 182 284 119T261 12T224 -76T186 -143T145 -194T113 -227T90 -246Q87 -249 86 -250H74Q66 -250 63 -250T58 -247T55 -238Q56 -237 66 -225Q221 -64 221 250T66 725Q56 737 55 738Q55 746 60 749Z\"></path>\n</defs>\n<g stroke=\"currentColor\" fill=\"currentColor\" stroke-width=\"0\" transform=\"matrix(1 0 0 -1 0 0)\" aria-hidden=\"true\">\n <use xlink:href=\"#E1-MJCAL-4F\" x=\"0\" y=\"0\"></use>\n <use xlink:href=\"#E1-MJMAIN-28\" x=\"796\" y=\"0\"></use>\n<g transform=\"translate(1186,0)\">\n <use xlink:href=\"#E1-MJMAIN-6C\"></use>\n <use xlink:href=\"#E1-MJMAIN-6F\" x=\"278\" y=\"0\"></use>\n <use xlink:href=\"#E1-MJMAIN-67\" x=\"779\" y=\"0\"></use>\n</g>\n <use xlink:href=\"#E1-MJMATHI-6E\" x=\"2632\" y=\"0\"></use>\n <use xlink:href=\"#E1-MJMAIN-29\" x=\"3232\" y=\"0\"></use>\n</g>\n</svg>",
    L"\mathcal{O}\left(\frac{\log{x}}{2}\right)" => "<svg xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"11.183ex\" height=\"6.176ex\" style=\"vertical-align: -2.505ex;\" viewBox=\"0 -1580.7 4814.8 2659.1\" role=\"img\" focusable=\"false\" xmlns=\"http://www.w3.org/2000/svg\" aria-labelledby=\"MathJax-SVG-1-Title\">\n<title id=\"MathJax-SVG-1-Title\">script upper O left-parenthesis StartFraction log x Over 2 EndFraction right-parenthesis</title>\n<defs aria-hidden=\"true\">\n<path stroke-width=\"1\" id=\"E1-MJCAL-4F\" d=\"M308 428Q289 428 289 438Q289 457 318 508T378 593Q417 638 475 671T599 705Q688 705 732 643T777 483Q777 380 733 285T620 123T464 18T293 -22Q188 -22 123 51T58 245Q58 327 87 403T159 533T249 626T333 685T388 705Q404 705 404 693Q404 674 363 649Q333 632 304 606T239 537T181 429T158 290Q158 179 214 114T364 48Q489 48 583 165T677 438Q677 473 670 505T648 568T601 617T528 636Q518 636 513 635Q486 629 460 600T419 544T392 490Q383 470 372 459Q341 430 308 428Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-28\" d=\"M94 250Q94 319 104 381T127 488T164 576T202 643T244 695T277 729T302 750H315H319Q333 750 333 741Q333 738 316 720T275 667T226 581T184 443T167 250T184 58T225 -81T274 -167T316 -220T333 -241Q333 -250 318 -250H315H302L274 -226Q180 -141 137 -14T94 250Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-6C\" d=\"M42 46H56Q95 46 103 60V68Q103 77 103 91T103 124T104 167T104 217T104 272T104 329Q104 366 104 407T104 482T104 542T103 586T103 603Q100 622 89 628T44 637H26V660Q26 683 28 683L38 684Q48 685 67 686T104 688Q121 689 141 690T171 693T182 694H185V379Q185 62 186 60Q190 52 198 49Q219 46 247 46H263V0H255L232 1Q209 2 183 2T145 3T107 3T57 1L34 0H26V46H42Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-6F\" d=\"M28 214Q28 309 93 378T250 448Q340 448 405 380T471 215Q471 120 407 55T250 -10Q153 -10 91 57T28 214ZM250 30Q372 30 372 193V225V250Q372 272 371 288T364 326T348 362T317 390T268 410Q263 411 252 411Q222 411 195 399Q152 377 139 338T126 246V226Q126 130 145 91Q177 30 250 30Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-67\" d=\"M329 409Q373 453 429 453Q459 453 472 434T485 396Q485 382 476 371T449 360Q416 360 412 390Q410 404 415 411Q415 412 416 414V415Q388 412 363 393Q355 388 355 386Q355 385 359 381T368 369T379 351T388 325T392 292Q392 230 343 187T222 143Q172 143 123 171Q112 153 112 133Q112 98 138 81Q147 75 155 75T227 73Q311 72 335 67Q396 58 431 26Q470 -13 470 -72Q470 -139 392 -175Q332 -206 250 -206Q167 -206 107 -175Q29 -140 29 -75Q29 -39 50 -15T92 18L103 24Q67 55 67 108Q67 155 96 193Q52 237 52 292Q52 355 102 398T223 442Q274 442 318 416L329 409ZM299 343Q294 371 273 387T221 404Q192 404 171 388T145 343Q142 326 142 292Q142 248 149 227T179 192Q196 182 222 182Q244 182 260 189T283 207T294 227T299 242Q302 258 302 292T299 343ZM403 -75Q403 -50 389 -34T348 -11T299 -2T245 0H218Q151 0 138 -6Q118 -15 107 -34T95 -74Q95 -84 101 -97T122 -127T170 -155T250 -167Q319 -167 361 -139T403 -75Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMATHI-78\" d=\"M52 289Q59 331 106 386T222 442Q257 442 286 424T329 379Q371 442 430 442Q467 442 494 420T522 361Q522 332 508 314T481 292T458 288Q439 288 427 299T415 328Q415 374 465 391Q454 404 425 404Q412 404 406 402Q368 386 350 336Q290 115 290 78Q290 50 306 38T341 26Q378 26 414 59T463 140Q466 150 469 151T485 153H489Q504 153 504 145Q504 144 502 134Q486 77 440 33T333 -11Q263 -11 227 52Q186 -10 133 -10H127Q78 -10 57 16T35 71Q35 103 54 123T99 143Q142 143 142 101Q142 81 130 66T107 46T94 41L91 40Q91 39 97 36T113 29T132 26Q168 26 194 71Q203 87 217 139T245 247T261 313Q266 340 266 352Q266 380 251 392T217 404Q177 404 142 372T93 290Q91 281 88 280T72 278H58Q52 284 52 289Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-32\" d=\"M109 429Q82 429 66 447T50 491Q50 562 103 614T235 666Q326 666 387 610T449 465Q449 422 429 383T381 315T301 241Q265 210 201 149L142 93L218 92Q375 92 385 97Q392 99 409 186V189H449V186Q448 183 436 95T421 3V0H50V19V31Q50 38 56 46T86 81Q115 113 136 137Q145 147 170 174T204 211T233 244T261 278T284 308T305 340T320 369T333 401T340 431T343 464Q343 527 309 573T212 619Q179 619 154 602T119 569T109 550Q109 549 114 549Q132 549 151 535T170 489Q170 464 154 447T109 429Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-29\" d=\"M60 749L64 750Q69 750 74 750H86L114 726Q208 641 251 514T294 250Q294 182 284 119T261 12T224 -76T186 -143T145 -194T113 -227T90 -246Q87 -249 86 -250H74Q66 -250 63 -250T58 -247T55 -238Q56 -237 66 -225Q221 -64 221 250T66 725Q56 737 55 738Q55 746 60 749Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJSZ3-28\" d=\"M701 -940Q701 -943 695 -949H664Q662 -947 636 -922T591 -879T537 -818T475 -737T412 -636T350 -511T295 -362T250 -186T221 17T209 251Q209 962 573 1361Q596 1386 616 1405T649 1437T664 1450H695Q701 1444 701 1441Q701 1436 681 1415T629 1356T557 1261T476 1118T400 927T340 675T308 359Q306 321 306 250Q306 -139 400 -430T690 -924Q701 -936 701 -940Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJSZ3-29\" d=\"M34 1438Q34 1446 37 1448T50 1450H56H71Q73 1448 99 1423T144 1380T198 1319T260 1238T323 1137T385 1013T440 864T485 688T514 485T526 251Q526 134 519 53Q472 -519 162 -860Q139 -885 119 -904T86 -936T71 -949H56Q43 -949 39 -947T34 -937Q88 -883 140 -813Q428 -430 428 251Q428 453 402 628T338 922T245 1146T145 1309T46 1425Q44 1427 42 1429T39 1433T36 1436L34 1438Z\"></path>\n</defs>\n<g stroke=\"currentColor\" fill=\"currentColor\" stroke-width=\"0\" transform=\"matrix(1 0 0 -1 0 0)\" aria-hidden=\"true\">\n <use xlink:href=\"#E1-MJCAL-4F\" x=\"0\" y=\"0\"></use>\n<g transform=\"translate(963,0)\">\n <use xlink:href=\"#E1-MJSZ3-28\"></use>\n<g transform=\"translate(736,0)\">\n<g transform=\"translate(120,0)\">\n<rect stroke=\"none\" width=\"2138\" height=\"60\" x=\"0\" y=\"220\"></rect>\n<g transform=\"translate(60,726)\">\n <use xlink:href=\"#E1-MJMAIN-6C\"></use>\n <use xlink:href=\"#E1-MJMAIN-6F\" x=\"278\" y=\"0\"></use>\n <use xlink:href=\"#E1-MJMAIN-67\" x=\"779\" y=\"0\"></use>\n <use xlink:href=\"#E1-MJMATHI-78\" x=\"1446\" y=\"0\"></use>\n</g>\n <use xlink:href=\"#E1-MJMAIN-32\" x=\"819\" y=\"-687\"></use>\n</g>\n</g>\n <use xlink:href=\"#E1-MJSZ3-29\" x=\"3115\" y=\"-1\"></use>\n</g>\n</g>\n</svg>"
)

# holds the current video (Array to be declared as constant :D)
# only holds one video at a time 
const CURRENT_VIDEO = Array{Video, 1}()

include("svg2luxor.jl")

latex(text::LaTeXString) = latex(text, 10, :stroke)
latex(text::LaTeXString, font_size::Real) = latex(text, font_size, :stroke)
latex(text::LaTeXString, action::Symbol) = latex(text, 10, action)

"""

`latex(text::LaTeXString, font_size::Real, action::Symbol)`

Add the latex string `text` to the top left corner of the LaTeX path. Can be added to `Luxor.jl` graphics such as `Video` or `Drawing`.

**NOTE: This only works if `tex2svg` is installed.**
**It can be installed using the following command (you may have to prefix this command with `sudo` depending on your installation):**

> `npm install -g mathjax-node-cli`

# Arguments
- `text::LaTeXString`: a LaTeX string to render.
- `font_size::Real`: integer font size of LaTeX string. Default `10`.
- `action::Symbol`: graphics actions defined by `Luxor.jl`. Default `:stroke`. Available actions:
  - `:fill` - See `Luxor.fillpath`.
  - `:stroke` - See `Luxor.strokepath`.
  - `:clip` - See `Luxor.clip`.
  - `:fillstroke` - See `Luxor.fillstroke`.
  - `:fillpreserve` - See `Luxor.fillpreserve`.
  - `:strokepreserve` - See `Luxor.strokepreserve`.
  - `:none` - Does nothing.
  - `:path` - See Luxor docs for `polygons.md`

# Throws
- `IOError`: mathjax-node-cli is not installed

# Example

```
using Luxor
using Javis
using LaTeXStrings

my_drawing = Drawing(400, 200, "test.png")
background("white")
sethue("black")
latex(L"\\sum \\phi", 100)
finish()
```

"""
function latex(text::LaTeXString, font_size::Real, action::Symbol)
    # check if it's cached 
    if haskey(LaTeXSVG, text)
        svg = LaTeXSVG[text]
    else
        # remove the $
        ts = text.s[2:end-1]
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
    Javis.pathsvg(svg, font_size)
    if action != :path
        # stroke is also fill for letters
        do_action(:fill)
    end
end

"""
    compute_transformation!(action::Action, video::Video, frame::Int) 

Update action.internal_transitions for the current frame number
"""
function compute_transformation!(action::Action, video::Video, frame::Int)
    for (trans,internal_trans) in zip(action.transitions, action.internal_transitions)
        compute_transition!(internal_trans, trans, video, action, frame)
    end
end

"""
    compute_transition!(internal_rotation::InternalRotation, rotation::Rotation, video, action::Action, frame)

Computes the rotation transformation for the `action`.
If the `Rotation` is given directly it uses the frame number for interpolation.
If `rotation` includes symbols the current definition of that look up is used for computation.
"""
function compute_transition!(internal_rotation::InternalRotation, rotation::Rotation, video, action::Action, frame)
    t = (frame-first(action.frames))/(length(action.frames)-1)
    from, to, center = rotation.from, rotation.to, rotation.center
    
    center isa Symbol && (center = video.defs[center].p)
    from isa Symbol && (from = video.defs[from].angle)
    to isa Symbol && (to = video.defs[to].angle)
        
    internal_rotation.angle = from+t*(to-from)
    internal_rotation.center = center
end

"""
    compute_transition!(internal_translation::InternalTranslation, translation::Translation, video, action::Action, frame)

Computes the translation transformation for the `action`.
If the `translation` is given directly it uses the frame number for interpolation.
If `translation` includes symbols the current definition of that look up is used for computation.
"""
function compute_transition!(internal_translation::InternalTranslation, translation::Translation, video, action::Action, frame)
    t = (frame-first(action.frames))/(length(action.frames)-1)
    from, to = translation.from, translation.to

    from isa Symbol && (from = video.defs[from].angle)
    to isa Symbol && (to = video.defs[to].angle)
        
    internal_translation.by = from+t*(to-from)
end

"""
    perform_transformation(action::Action) 

Perform the transformations as described in action.internal_transitions
"""
function perform_transformation(action::Action) 
    for trans in action.internal_transitions
        perform_transformation(trans)
    end
end

"""
    perform_transformation(trans::InternalTranslation)

Translate as described in `trans`.
"""
function perform_transformation(trans::InternalTranslation)
    translate(trans.by)
end

"""
    perform_transformation(trans::InternalRotation)

Translate and rotate as described in `trans`.
"""
function perform_transformation(trans::InternalRotation)
    translate(trans.center)
    rotate(trans.angle)
end

function pos(s::Symbol)
    defs = CURRENT_VIDEO[1].defs
    if haskey(defs, s)
        defs[s].p
    else
        error("The symbol $s is not defined.")
    end
end

function angle(s::Symbol)
    defs = CURRENT_VIDEO[1].defs
    if haskey(defs, s)
        defs[s].angle
    else
        error("The symbol $s is not defined.")
    end
end

"""
    projection(p::Point, l::Line)

Return the projection of a point to a line.
"""
function projection(p::Point, l::Line)
    # move line to origin and describe it as a vector
    o = l.p1
    v = l.p2 - o
    # point also moved to origin
    x = p - o
    
    # scalar product <x,v>/<v,v>
    c = (x.x * v.x + x.y * v.y) / (v.x^2 + v.y^2)
    return c*v+o 
end

"""
    javis(
        video::Video,
        actions::Vector{Action};
        creategif=false,
        framerate=30,
        pathname="",
        tempdirectory="",
        usenewffmpeg=true
    )

Similar to `animate` in Luxor with a slightly different structure.
Instead of using actions and a video instead of scenes in a movie.

# Arguments
- `video::Video`: The video which defines the dimensions of the output
- `actions::Vector{Action}`: All actions that are performed
# Keywords
- `creategif::Bool`: defines whether the images should be rendered to a gif
- `framerate::Int`: The frame rate of the video
- `pathname::String`: The path for the gif if `creategif = true`
- `tempdirectory::String`: The folder where each frame is stored 
- `deletetemp::Bool`: If true and `creategif` is true => tempdirectory is emptied after the gif is created

# Example
```
function ground(args...) 
    background("white")
    sethue("black")
end

function circ(p=O, color="black")
    sethue(color)
    circle(p, 25, :fill)
    return Transformation(p, 0.0)
end

from = Point(-200, -200)
to = Point(-20, -130)
p1 = Point(0,-100)
p2 = Point(0,-50)
from_rot = 0.0
to_rot = 2π

demo = Video(500, 500)
javis(demo, [
    Action(1:100, ground),
    Action(1:100, :red_ball, (args...)->circ(p1, "red"), Rotation(from_rot, to_rot)),
    Action(1:100, (args...)->circ(p2, "blue"), Rotation(to_rot, from_rot, :red_ball))
], tempdirectory="images", creategif=true, pathname="rotating.gif")
```

This structure makes it possible to refer to positions of previous actions
i.e :red_ball is an id for the position or the red ball which can be used in the Rotation of the next ball.

"""
function javis(
    video::Video,
    actions::Vector{Action};
    creategif=false,
    framerate=30,
    pathname="",
    tempdirectory="",
    usenewffmpeg=true
)
    # get all frames
    frames = Int[]
    for action in actions
        append!(frames, collect(action.frames))
    end
    frames = unique(frames)

    # create internal transition objects
    for action in actions
        for trans in action.transitions
            if trans isa Translation
                push!(action.internal_transitions, InternalTranslation(O))
            elseif trans isa Rotation
                push!(action.internal_transitions, InternalRotation(0.0, O))
            end
        end
    end

    # create defs object
    for action in actions
        if action.id !== nothing
            video.defs[action.id] = Transformation(O, 0.0)
        end
    end

    if isempty(CURRENT_VIDEO)
        push!(CURRENT_VIDEO, video)
    else
        CURRENT_VIDEO[1] = video
    end
    
    filecounter = 1
    for frame in frames
        Drawing(video.width, video.height, "$(tempdirectory)/$(lpad(filecounter, 10, "0")).png")
        origin()
        start_translation = Point(gettranslation()...)
        # this frame needs doing, see if each of the scenes defines it
        for action in actions
            if frame in action.frames
                @layer begin
                    compute_transformation!(action, video, frame)
                    perform_transformation(action)
                    res = action.func(video, action, frame)
                    if action.id !== nothing
                        # if a transformation let's save the global coordinates
                        if res isa Transformation
                            trans = cairotojuliamatrix(getmatrix())*res
                            trans.p -= start_translation
                            video.defs[action.id] = trans
                        else # just save the result such that it can be used as one wishes
                            video.defs[action.id] = res
                        end
                    end
                end
            end
        end
        finish()
        filecounter += 1
    end

    !creategif && return 
    run(`ffmpeg -loglevel panic -framerate $(framerate) -f image2 -i $(tempdirectory)/%10d.png -filter_complex "[0:v] split [a][b]; [a] palettegen=stats_mode=full:reserve_transparent=on:transparency_color=FFFFFF [p]; [b][p] paletteuse=new=1:alpha_threshold=128" -y $(pathname)`)
    nothing
end

export javis, latex
export Video, Action
export Line, Translation, Rotation, Transformation
export pos, angle
export projection

end
