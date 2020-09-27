"""
    ReversedEasing

Will be used to reverse an easing inside [`easing_to_animation`](@ref).
Can be constructed from an easing function using [`rev`](@ref).
"""
struct ReversedEasing
    easing::Easing
end

"""
    rev(e::Easing)

Reverse an easing function such that `easing_to_animation` maps it to `[1.0, 0.0]` instead of `[0.0, 1.0]`.
An example can be seen in [`rotate`](@ref)
"""
rev(e::Easing) = ReversedEasing(e)


"""
    easing_to_animation(easing)

Converts an easing to an Animation with time goes from `0.0` to `1.0` and value from `0` to `1`.
"""
easing_to_animation(easing) = Animation(0.0, 0.0, easing, 1.0, 1.0)

"""
    easing_to_animation(rev_easing::ReversedEasing)

Converts an easing to an Animation with time goes from `0.0` to `1.0` and value from `1` to `0`.
"""
easing_to_animation(rev_easing::ReversedEasing) =
    Animation(0.0, 1.0, rev_easing.easing, 1.0, 0.0)
