"""
    Rel

Ability to define frames in a relative fashion.

# Example
```
 Action(1:100, ground; in_global_layer=true),
 Action(1:90, :red_ball, (args...)->circ(p1, "red"), Rotation(from_rot, to_rot)),
 Action(Rel(10), :blue_ball, (args...)->circ(p2, "blue"), Rotation(2π, from_rot, :red_ball)),
 Action((video, args...)->path!(path_of_red, pos(:red_ball), "red"))
```
is the same as
```
Action(1:100, ground; in_global_layer=true),
Action(1:90, :red_ball, (args...)->circ(p1, "red"), Rotation(from_rot, to_rot)),
Action(91:100, :blue_ball, (args...)->circ(p2, "blue"), Rotation(2π, from_rot, :red_ball)),
Action(91:100, (video, args...)->path!(path_of_red, pos(:red_ball), "red"))
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
