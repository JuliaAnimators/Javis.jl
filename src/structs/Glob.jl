"""
    Glob

Ability to define frames in a gloabl fashion inside [`Action`](@ref).

# Example
```
red_circ = Object(1:90, (args...)->circ("red"))
blue_circ = Object(21:90, (args...)->circ("blue"))
act!([red_circ, blue_circ], Action(Glob(85:90), disappear(:fade)))
```
is the same as
```
red_circ = Object(1:90, (args...)->circ("red"))
blue_circ = Object(20:90, (args...)->circ("blue"))
act!(red_circ, Action(85:90, disappear(:fade)))
act!(blue_circ, Action(65:70), disappear(:fade))
```

# Fields
- frames::UnitRange defines the frames in a global fashion.
"""
struct Glob
    frames::UnitRange
end
