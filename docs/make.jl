using Javis
using Documenter

makedocs(;
    modules=[Javis],
    authors="Ole Kröger <o.kroeger@opensourc.es> and contributors",
    repo="https://github.com/Wikunia/Javis.jl/blob/{commit}{path}#L{line}",
    sitename="Javis.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Wikunia.github.io/Javis.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Wikunia/Javis.jl",
)
