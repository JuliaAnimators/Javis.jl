# Javis.jl - Changelog

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