# Javis

[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://Wikunia.github.io/Javis.jl/dev)
[![Build Status](https://github.com/Wikunia/Javis.jl/workflows/CI/badge.svg)](https://github.com/Wikunia/Javis.jl/actions)
[![Coverage](https://codecov.io/gh/Wikunia/Javis.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Wikunia/Javis.jl)

**Javis:** **J**ulia M**a**thematical **Vis**ualizations and Animations

Mathematical animations in Julia made easy. 

You want to have a look before we provide a proper tutorial?
Check out my blog post [Javis.jl - The beginning](https://opensourc.es/blog/javis-beginning)

---

## Introduction 

For releases, we follow the semantic versioning protocol and enforce the [BlueStyle code style format](https://github.com/invenia/BlueStyle).

## Installation

To install `Javis` into your Julia installation, type into your Julia REPL the following:

```
julia> ] add Javis
```

That's all there is to it! 😃

## Testing

1. Clone the repo to your computer and go into that directory:

`cd Javis`

2. Open your Julia REPL and type the following within the repo:

```
julia> ]
(@v###) pkg> dev .
(@v###) pkg> test Javis
```

This might take a little bit, but if the installation on your computer is successful, it should say all tests passed. 

## How To Develop for Javis

Javis is currently under heavy development. If you would like to contribute, please see the [contributing guidelines](contributing.md).


### Dependencies

To develop Javis, one needs `mathjax-node-cli` for LaTeX support. 

```
npm install -g mathjax-node-cli
```
