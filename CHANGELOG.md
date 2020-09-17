# Javis.jl - Changelog

## Unreleased v0.2
- Ability to use [Animations.jl](https://github.com/jkrumbiegel/Animations.jl) 
  - for Transformations and `appear` and `disappear`
- Show progress of rendering using [ProgressMeter.jl](https://github.com/timholy/ProgressMeter.jl)
- Use [VideoIO](https://github.com/JuliaIO/VideoIO.jl) for faster rendering without temporary images
- Ability to draw text in an animated way
- Ability to morph with `fill` or `stroke` and using `SubAction` to specify changes in color
- An object described by an action can follow a path (a vector of points). See `follow_path`
  
## 0.1.5 (14th of September 2020)
- Bugfix in svg parser when a layer gets both transformed and scaled

## 0.1.4 (13th of September 2020)
- Bugfix in svg parser when a reflected Bézier curve followed a move operation

### Removed
- `latex` no longer takes the `fontsize` as an argument [PR #180](https://github.com/Wikunia/Javis.jl/pull/180)

## 0.1.3 (11th of September 2020)
- First `SubAction` for an `Action` no longer requires explicit frame range and will default to the frames of the `Action`
- Ability to scale an object with `Scaling`. Works similar to `Translation` and `Rotation` 
- Added JuliaFormatter GitHub Action
- Updated Contributing guidelines
- Added `.JuliaFormatter.toml` for automatic formatting

## 0.1.2 (24th of August 2020)
- Added capabilities for generating `.mp4` files
- Updated testing scheme for `Javis.jl`

## 0.1.1 (21st of August 2020)
- Define frames in `SubAction` with `Rel` and `Symbol`
- `latex` now uses font size specified with `fontsize`
- Ability to access font size with `get_fontsize`

## 0.1.0 (19th of August 2020)
Initial implementation with
- `BackgroundAction`, `Action` and `SubAction`
- frames for `Action` can be defined using a `UnitRange`, `Symbol` or `Rel`
- `Translation`, `Rotation` 
- `appear`/`disappear` using opacity and linewidth in `SubAction`
- render `latex` using a basic svg parser
