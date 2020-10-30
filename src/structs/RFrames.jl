"""
    RFrames

Ability to define frames in a relative fashion.

# Example
```
Background(1:100, ground)
Object(1:90, (args...)->circ("red"))
Object(RFrames(10), (args...)->circ("blue"))
Object((args...)->circ("red"))
```
is the same as
```
Background(1:100, ground)
Object(1:90, (args...)->circ("red"))
Object(91:100, (args...)->circ("blue"))
Object(91:100, (args...)->circ("red"))
```

# Fields
- frames::UnitRange defines the frames in a relative fashion.
"""
struct RFrames
    frames::UnitRange
end

"""
    RFrames(i::Int)

Shorthand for RFrames(1:i)
"""
RFrames(i::Int) = RFrames(1:i)
