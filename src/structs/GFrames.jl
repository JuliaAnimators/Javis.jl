"""
    GFrames

Ability to define frames in a global fashion inside [`Action`](@ref).

# Example
```
red_circ = Object(1:90, (args...)->circ("red"))
blue_circ = Object(21:90, (args...)->circ("blue"))
act!([red_circ, blue_circ], Action(GFrames(85:90), disappear(:fade)))
```
is the same as
```
red_circ = Object(1:90, (args...)->circ("red"))
blue_circ = Object(21:90, (args...)->circ("blue"))
act!(red_circ, Action(85:90, disappear(:fade)))
act!(blue_circ, Action(65:70), disappear(:fade))
```

# Fields
- frames::UnitRange defines the frames in a global fashion.
"""
struct GFrames
    frames::UnitRange
end
