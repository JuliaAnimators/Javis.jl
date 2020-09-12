using Javis
using Documenter

makedocs(;
    modules = [Javis],
    authors = "Ole Kröger <o.kroeger@opensourc.es> and contributors",
    repo = "https://github.com/Wikunia/Javis.jl/blob/{commit}{path}#L{line}",
    sitename = "Javis.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://Wikunia.github.io/Javis.jl",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Tutorials" => [
            "tutorials.md",
            "tutorials/tutorial_1.md",
            "tutorials/tutorial_2.md",
            "tutorials/tutorial_3.md",
            "tutorials/tutorial_4.md",
            "tutorials/tutorial_5.md",
        ],
        "HowTo" => "howto.md",
        "Mission" => "mission.md",
        "References" => "references.md",
        "Contributing" => "contributing.md",
    ],
)

deploydocs(; repo = "github.com/Wikunia/Javis.jl")
