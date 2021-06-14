"""
    GraphAnimation

Maintain the graph state comprising of nodes, edges, layout, animation ordering etc.

This will be a part of the Javis [`Object`](@ref) metadata, when a new graph is created.

# Fields
- `graph`: A data structure storing information about nodes, edges, properties, etc.
    - Using a known graph type from the [LightGraphs.jl]() package leads to certain simplicity in usage.
- `width::Int`: The width of the graph on the canvas.
- `height::Int`: The height of the graph on the canvas.
- `mode::Symbol`: The animaition of the graph can be done in two ways.
    - `static`: A lightweight animation which does not try to animate every detail during transitions unless asked to.
    - `dynamic`: Animates almost every single change made to the state of the graph. Can be computationally heavy depending on the use case.
- `layout::Symbol`: The graph layout to be used. Can be one of :-
    - `:spring`: Emphasizes on spacing nodes and edges as far apart as possible.
    - `:radial`: Generates the best radial visualization for the graph.
- `node_attribute_fn`: A function that enables fetching properties defined for nodes in the input graph data structure.
    - Required only when a node property like `cost` needs to be mapped to a drawing property like `radius`.
- `edge_attribute_fn`: Similar to `node_attribute_fn` but for edge properties.
- `adjacency_list`: A light internal representation of the graph structure initialized only when the graph data type in not known.
    - For undirected graphs it is of type `SimpleGraph` from [LightGraphs.jl]() and for directed graphs it is `SimpleDiGraph`
- `ordering`: Store the relative ordering used to add nodes and edges to a graph using [`GraphNode`](@ref) and [`GraphEdge`](@ref)
    - If input graph is of a known type, defaults to a simple BFS ordering starting at the root node.
- `node_property_limits`: The minima and maxima calculated on the node properties in the input graph.
    - This is internally created and updated when [`updateGraph`](@ref) or the final render function is called.
    - This is skipped for node properties of non-numeric types.
    - Used to scale drawing property values within sensible limits.
- `edge_property_limits`: The minima and maxima calculated on the edge properties in the input graph.
    - Similar to `node_attribute_fn`.
"""
struct GraphAnimation
    graph
    width::Int
    height::Int
    mode::Symbol
    layout::Symbol
    start_pos::Union{Point,Object}
    node_attribute_fn::Function
    edge_attribute_fn::Function
    adjacency_list::AbstractGraph
    ordering::Vector{AbstractObject}
    edge_property_limits::Dict{Symbol,Tuple{Real,Real}}
    node_property_limits::Dict{Symbol,Tuple{Real,Real}}
end

GraphAnimation(reference_graph, directed::bool) =
    GraphAnimation(reference_graph, directed, 300, 300, O)
GraphAnimation(width::Int, height::Int, start_pos::Union{Point,Object}) =
    GraphAnimation(LightGraphs.SimpleGraph(), false, width::Int, height::Int, start_pos)

function GraphAnimation(
    reference_graph,
    directed::bool,
    width::Int,
    height::Int,
    start_pos::Union{Point,Object};
    mode::Symbol = :static,
    layout::Symbol = :spring,
    node_attribute_fn::Function = (args...) -> nothing,
    edge_attribute_fn::Function = (args...) -> nothing,
)

end

function _graph_animation_object(mode)
    if mode == :static
        # Invoke the graph layout generation algorithm here
        # That is when the entire graph is already created
        # After that change the start positions of nodes using the info from ordering list
    end
    for j in CURRENT_GRAPH[1].ordering
        # Get object type from some object specific field like metadata
        if j.metadata.type == :graph_node
            for style in keys(get(j.metadata, weight_style_map, Dict()))
                if style in keys(CURRENT_GRAPH[1].node_weight_limits)
                    # Update the limits for this style property on node
                end
            end
        elseif j.metadata.type == :graph_node
            # Do the same computation for edge styles
        end
    end
    # Now update the node and edge object drawing parameters like scale, opacity, 
    # layout weights etc.
end

struct GraphNode
    node_id
    properties_to_style_map::Dict{Any,Symbol}
    draw_fn::Function
end

# For nodes store drawing options as part of the Javis object itself
GraphNode(node_id, draw::Function) = GraphNode(node_id, draw; Dict{Symbol,Symbol}())

function GraphNode(
    node_id,
    draw::Function;
    animate_on::Symbol = :opacity,
    property_style_map::Dict{Symbol,Symbol},
    kwargs...,
)
    # Register new node with Graph Animation metadata
    # IF mode is static simply call the draw function and return
    # ELSE recalculate the network layout based on the current graph structure
    #      and update the positions of nodes through easing translations
end

struct GraphEdge
    from_node
    to_node
    properties_to_style_map::Dict{Any,Symbol}
    draw_fn::Function
end

function GraphEdge(
    node1,
    node2,
    draw::Function;
    animate_on::Symbol = :opacity,
    property_style_map::Dict{Symbol,Symbol},
    kwargs...,
) end
