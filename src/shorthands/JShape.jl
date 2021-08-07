"""
    @JShape(body, args...)

Macro that creates a user-defined shape based on `Luxor` instructions within its `begin...end` block

# Example

```julia
Object(@JShape begin
    sethue(color)
    poly(points, action, close = true)
end action = :stroke color = "red" radius = 8)
```

In this example, the arguments after the `end` (i.e. `action = :stroke color = "red" radius = 8`)
can be used inside the `bgein...end` block and animated using the [`change`](@ref) action.
"""
macro JShape(body::Expr, expr...)
    leftside = Expr(
        :tuple,
        Expr(:parameters, [Expr(:kw, e.args[1], e.args[2]) for e in expr]...),
        Expr(:(...), :args),
    )
    out = Expr(:(->), leftside, body)
    esc(out)
end
