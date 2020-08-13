# Project Mission

## What is Javis? 

`Javis.jl` is a tool focused on providing an easy to use interface for making animations and developing visualizations quickly - while having fun! :smiley:

That being said, we decided to make this mission statement to clearly explain the scope of this project. That is, to explain what this project _is_ and what it _is not_. Here are the core tenents of `Javis` concisely explained:

- **Javis is not a plotting library.** Though Javis can do many things, we have no intention of turning this package into a complete plotting library. There may be some elements of plotting we use in this package but it will be limited to accomplish different animation functionality (e.g. animating vectors, etc.). If we do expand the project towards plotting, we will most likely seek interoperability with packages such as [`Plots.jl`](https://github.com/JuliaPlots/Plots.jl) or [`Gadfly.jl`](https://github.com/GiovineItalia/Gadfly.jl).

- **Javis focuses on freedom for the user.** We approach Javis in the same way an artist approaches an empty canvas. We provide the basic tools but it is up to the user to create most of the functionality they wish to see. Therefore, we won't provide functions that should be handled by other packages or are generally domain specific (e.g. implementing a logistic regression function, generating sparse matrices, etc.). 

- **Javis seeks to explore and explain.** Javis should enable a user in nearly any domain the ability to better explore and explain the phenomena they are analyzing. If there are core visualization elements of a domain that you think should be added, we are open to discussion. Please open an issue and let us know.

- **Javis is not neccesarilly geared towards data analytics.** Admittedly, there are ways to use Javis to visualize data while creating animations. However, the intent of Javis is not focused on creating functionality to analyze datasets _as of this moment_. This may change in the future.

- **We love documentation and tutorials! :nerd_face:** One of the things we prioritize in each release of Javis is to document functionalities of the tools we add. Furthermore, we like to make tutorials to also show what is possible in Javis. Do you have a cool animation or blog that you have written using Javis? Let us know by making an issue to let us know!

## Summary

In summary, `Javis.jl` focuses on creating an easy to use interface written in Julia to create visualizations and animations. What Javis is, is a tool for exploration that gives great freedom and flexibility to a user. What it is not is a domain specific library for making a limited subset of visualizations or a true data analytics tool.

## Acknowledgements

Our project mission was inspired by the mission, philosophy, and interface of projects such as Fedora, Zotero, Spaceship ZSH, and rclone.
