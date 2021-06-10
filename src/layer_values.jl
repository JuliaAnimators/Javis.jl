"""
    get_position(obj::Object)

Get access to the position of a layer.

# Returns
- `Point`: the point stored by the layer.

# Throws
- If the function of Layer didn't return a Point or Transformation
"""
function get_position(l::Layer)
    return get_position(l.position)
end