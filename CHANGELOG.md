# Javis.jl - Changelog

## v0.3.2 (22th of November)
- added `ffmpeg_loglevel` option for debugging purposes

## v0.3.1 (18th of November 2020)
- removed `ColorTypes` as a dependency
- docstring fixes for `morph_to`

## v0.3 (10th of November 2020)
- Morphing with several shapes
- Changed `Action` to `Object` syntax
- Ability to use `setopactity()` in an `Action`
- Ability to disable an `Action` after its last defined frame. See `? Action` and the keyword `; keep`
- Moved from `Translation`, `Scaling` and `Rotation` to `anim_translate` etc
- Changed `Rel` to `RFrames` and added `GFrames` for defining actions with global frames
- A warning is shown if some frames don't have a background
- A warning is shown if an `Action` is defined outside the parental `Object`

## v0.2.2 (20th of October 2020)
- Ability to change a keyword using `change`

## v0.2.1 (11th of October 2020)
- Ability to draw animated LaTeX via `appear(:draw_text)`
- Support for Images v0.23
- various documentation updates

## 0.2.0 (25th of September 2020)
- Ability to use [Animations.jl](https://github.com/jkrumbiegel/Animations.jl) 
  - for Transformations and `appear` and `disappear`
- Show progress of rendering using [ProgressMeter.jl](https://github.com/timholy/ProgressMeter.jl)
- Use [VideoIO](https://github.com/JuliaIO/VideoIO.jl) for faster rendering without temporary images
- Ability to draw animated text via `appear(:draw_text)`
  - Must be called inside a `SubAction` 
- Ability to morph with `fill` or `stroke` and using `SubAction` to specify changes in color
- Added live viewer based on `Gtk.jl` in the `javis` function
  - Activate in `javis` by setting `liveview = true`
- Prototype returning single frame of Javis animation with `get_javis_frame`
  - Currently must be invoked after `javis` function call
  - Can be called via `Javis.get_javis_frame` as it is not exported yet
- An object described by an action can follow a path (a vector of points). See `follow_path`
- Bugfix when scaling to 0. Before this every object on that frame would disappear even in a different layer
- Bugfix in interpolation: Interpolation of a single frame like `1:1` returns `1.0` now instead of `NaN`.

  
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
