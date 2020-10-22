"""
    Rel

Ability to define frames in a relative fashion.

# Example
```
BackgroundObject(1:100, ground)
Object(1:90, (args...)->circ("red"))
Object(Rel(10), (args...)->circ("blue"))
Object((args...)->circ("red"))
```
is the same as
```
BackgroundObject(1:100, ground)
Object(1:90, (args...)->circ("red"))
Object(91:100, (args...)->circ("blue"))
Object(91:100, (args...)->circ("red"))
```

# Fields
- rel::UnitRange defines the frames in a relative fashion.
"""
struct Rel
    rel::UnitRange
end

"""
    Rel(i::Int)

Shorthand for Rel(1:i)
"""
Rel(i::Int) = Rel(1:i)
