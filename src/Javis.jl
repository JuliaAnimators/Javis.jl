module Javis

using Luxor, LaTeXStrings

# cache such that creating svgs from LaTeX don't need to be created every time
# this is also used for test cases such that `tex2svg` doesn't need to be installed on Github Actions
const LaTeXSVG = Dict{LaTeXString, String}(
    L"\mathcal{O}(\log{n})" => "<svg xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"8.413ex\" height=\"2.843ex\" style=\"vertical-align: -0.838ex;\" viewBox=\"0 -863.1 3622.2 1223.9\" role=\"img\" focusable=\"false\" xmlns=\"http://www.w3.org/2000/svg\" aria-labelledby=\"MathJax-SVG-1-Title\">\n<title id=\"MathJax-SVG-1-Title\">script upper O left-parenthesis log n right-parenthesis</title>\n<defs aria-hidden=\"true\">\n<path stroke-width=\"1\" id=\"E1-MJCAL-4F\" d=\"M308 428Q289 428 289 438Q289 457 318 508T378 593Q417 638 475 671T599 705Q688 705 732 643T777 483Q777 380 733 285T620 123T464 18T293 -22Q188 -22 123 51T58 245Q58 327 87 403T159 533T249 626T333 685T388 705Q404 705 404 693Q404 674 363 649Q333 632 304 606T239 537T181 429T158 290Q158 179 214 114T364 48Q489 48 583 165T677 438Q677 473 670 505T648 568T601 617T528 636Q518 636 513 635Q486 629 460 600T419 544T392 490Q383 470 372 459Q341 430 308 428Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-28\" d=\"M94 250Q94 319 104 381T127 488T164 576T202 643T244 695T277 729T302 750H315H319Q333 750 333 741Q333 738 316 720T275 667T226 581T184 443T167 250T184 58T225 -81T274 -167T316 -220T333 -241Q333 -250 318 -250H315H302L274 -226Q180 -141 137 -14T94 250Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-6C\" d=\"M42 46H56Q95 46 103 60V68Q103 77 103 91T103 124T104 167T104 217T104 272T104 329Q104 366 104 407T104 482T104 542T103 586T103 603Q100 622 89 628T44 637H26V660Q26 683 28 683L38 684Q48 685 67 686T104 688Q121 689 141 690T171 693T182 694H185V379Q185 62 186 60Q190 52 198 49Q219 46 247 46H263V0H255L232 1Q209 2 183 2T145 3T107 3T57 1L34 0H26V46H42Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-6F\" d=\"M28 214Q28 309 93 378T250 448Q340 448 405 380T471 215Q471 120 407 55T250 -10Q153 -10 91 57T28 214ZM250 30Q372 30 372 193V225V250Q372 272 371 288T364 326T348 362T317 390T268 410Q263 411 252 411Q222 411 195 399Q152 377 139 338T126 246V226Q126 130 145 91Q177 30 250 30Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-67\" d=\"M329 409Q373 453 429 453Q459 453 472 434T485 396Q485 382 476 371T449 360Q416 360 412 390Q410 404 415 411Q415 412 416 414V415Q388 412 363 393Q355 388 355 386Q355 385 359 381T368 369T379 351T388 325T392 292Q392 230 343 187T222 143Q172 143 123 171Q112 153 112 133Q112 98 138 81Q147 75 155 75T227 73Q311 72 335 67Q396 58 431 26Q470 -13 470 -72Q470 -139 392 -175Q332 -206 250 -206Q167 -206 107 -175Q29 -140 29 -75Q29 -39 50 -15T92 18L103 24Q67 55 67 108Q67 155 96 193Q52 237 52 292Q52 355 102 398T223 442Q274 442 318 416L329 409ZM299 343Q294 371 273 387T221 404Q192 404 171 388T145 343Q142 326 142 292Q142 248 149 227T179 192Q196 182 222 182Q244 182 260 189T283 207T294 227T299 242Q302 258 302 292T299 343ZM403 -75Q403 -50 389 -34T348 -11T299 -2T245 0H218Q151 0 138 -6Q118 -15 107 -34T95 -74Q95 -84 101 -97T122 -127T170 -155T250 -167Q319 -167 361 -139T403 -75Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMATHI-6E\" d=\"M21 287Q22 293 24 303T36 341T56 388T89 425T135 442Q171 442 195 424T225 390T231 369Q231 367 232 367L243 378Q304 442 382 442Q436 442 469 415T503 336T465 179T427 52Q427 26 444 26Q450 26 453 27Q482 32 505 65T540 145Q542 153 560 153Q580 153 580 145Q580 144 576 130Q568 101 554 73T508 17T439 -10Q392 -10 371 17T350 73Q350 92 386 193T423 345Q423 404 379 404H374Q288 404 229 303L222 291L189 157Q156 26 151 16Q138 -11 108 -11Q95 -11 87 -5T76 7T74 17Q74 30 112 180T152 343Q153 348 153 366Q153 405 129 405Q91 405 66 305Q60 285 60 284Q58 278 41 278H27Q21 284 21 287Z\"></path>\n<path stroke-width=\"1\" id=\"E1-MJMAIN-29\" d=\"M60 749L64 750Q69 750 74 750H86L114 726Q208 641 251 514T294 250Q294 182 284 119T261 12T224 -76T186 -143T145 -194T113 -227T90 -246Q87 -249 86 -250H74Q66 -250 63 -250T58 -247T55 -238Q56 -237 66 -225Q221 -64 221 250T66 725Q56 737 55 738Q55 746 60 749Z\"></path>\n</defs>\n<g stroke=\"currentColor\" fill=\"currentColor\" stroke-width=\"0\" transform=\"matrix(1 0 0 -1 0 0)\" aria-hidden=\"true\">\n <use xlink:href=\"#E1-MJCAL-4F\" x=\"0\" y=\"0\"></use>\n <use xlink:href=\"#E1-MJMAIN-28\" x=\"796\" y=\"0\"></use>\n<g transform=\"translate(1186,0)\">\n <use xlink:href=\"#E1-MJMAIN-6C\"></use>\n <use xlink:href=\"#E1-MJMAIN-6F\" x=\"278\" y=\"0\"></use>\n <use xlink:href=\"#E1-MJMAIN-67\" x=\"779\" y=\"0\"></use>\n</g>\n <use xlink:href=\"#E1-MJMATHI-6E\" x=\"2632\" y=\"0\"></use>\n <use xlink:href=\"#E1-MJMAIN-29\" x=\"3232\" y=\"0\"></use>\n</g>\n</svg>"
)

include("svg2luxor.jl")

latex(t::LaTeXString, action::Symbol=:none) = latex(t, 10, action)

function latex(t::LaTeXString, font_size::Real=10, action::Symbol=:none)
    # check if it's cached 
    if haskey(LaTeXSVG, t)
        svg = LaTeXSVG[t]
    else
        # remove the $
        ts = t.s[2:end-1]
        command = `tex2svg $ts`
        svg = read(command, String)
        LaTeXSVG[t] = svg
    end
    Javis.pathsvg(svg, font_size)
    if action != :path && action != :none
        do_action(:fill)
    end
end

function test_draw()
    d = Drawing(400, 150, "test.png")
    background("white")
    sethue("black")
    latex(L"\mathcal{O}(\log{x})", 20, :stroke)
    finish()
    preview()
end

export latex

end
