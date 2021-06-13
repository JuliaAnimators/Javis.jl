## Depth First Search

### Points covered
1. Graph creation using `LightGraphs.jl`
2. Demonstrate additional utility functions

### Graph creation

In the previous example, it was shown how a graph can be created and animated for a simple graph data type. To simplify a lot of details one can provide a known graph type i.e. from JuliaGraphs. The candidate types for this are:
* `SimpleGraph`
* `SimpleDiGraph`
* `SimpleWeightedGraph`
* `SimpleWeightedDiGraph`

Here I cover the case when it is represented using `SimpleGraph` from the LightGraphs package.

```julia
using LightGraphs
g = SimpleGraph(6)
add_edge!(g, 1, 2)
add_edge!(g, 1, 3)
add_edge!(g, 2, 4)
add_edge!(g, 3, 5)
add_edge!(g, 4, 6)

ag, nodes, edges = create_graph(g, 300, 300; layout=:spring, mode=:static)
```
`ag` - A Javis object storing some useful meta-data corresponding to the graph. Only the translate operation is supported on it as of now.

`nodes` - list of references to node objects in the order of node id

`edges` - list of references to edge objects in the order of creation

The `layout` defines how the nodes shall be arranged on the canvas. The `mode` argument determines whether the graph is to be considered a static or a dynamic graph.

#### Static graphs
* The layout computation is done only once when the entire graph is known.
* Updates to nodes/edge properties in the input graph are not animated i.e. the final graph state is used for the animation

#### Dynamic graphs
* Addition of each new node leads to recomputation of new layout
* Group animations of nodes/edges are separated across frames using a predefined ordering
* Updates to edges and nodes through properties are animated with the help of action transitions leading to visualisation for time evolving graphs

*Note - Dynamic layout will be much more computationally intensive than static layout*

**Adding or removing nodes and edges**

New nodes and edges can be added to the canvas or existing nodes deleted after the graph creation.
```julia
removeNode!(ag, 2)
addNode!(ag, 7)
addEdge!(ag, 1, 7)
```
or
```julia
addEdge!(ag, 1, 7, 20)
```
The last argument is the edge weight. This mimics the `add_edge!` function provided by the LightGraph interface, where the `weight` parameter is valid if the internal graph type is a `SimpleWeightedGraph`.


### Visualisation and demo utility functions

Rendering the video at this stage would just draw and animate a plain graph based on the underlying `LightGraph` type. It picks up reasonable defaults for these animations for e.g. if the graph is of type `SimpleWeightedGraph` the edge weights are simply centered on the lines drawn.

```julia
current=1
dst=6
path=[]
visited=[false for i in 1:nv(g)]
num_visited=0
```

The `path` variable stores the path to the destination node. The additional variable `num_visited` is needed to organize the animation of the call to the utility functions one after another. Once a relative way to define action frames across different objects is available this variable won't be necessary.

```julia
function dfs_and_animate(node, path)
    if node==dst
        highlightNode(GFrames(20+num_visited*10, 100), ag, current, :border_color, "red")
        return    
    end
    # Highlight the current node
    highlightNode(GFrames(20+num_visited*10, 100), ag, current, :border_color, "yellow")
    visited[current]=true
    num_visited+=1
    push!(path, current)
    # Change node color when highlighting effect ends
    changeNodeProperty!(@Frames(prev_end(), stop=parent_end()), ag, current, :color, "blue")
    for nb in neighbors(g, current)
        if visited[nb]
            continue
        end
        highlightEdge(GFrames(20+num_visited*10, 100), ag, current, nb, :color, "green")
        num_visited+=1
        dfs_and_animate(nb, path)
    end
    # Highlight again to indicate return to parent node
    highlightNode(GFrames(20+num_visited*10, 100), ag, current, :border_color, "yellow")
    num_visited+=1
    pop!(path)
end

dfs_and_animate(1, path)
```

Note - Even though the drawing property `:color` was not explicitly defined by passing it to a drawing function, these are provided as defaults for every node and edges in the case the graph is created using `create_graph`.

The default drawing properties provided are - 
* `fill_color` - for nodes
* `border_color` - for nodes
* `radius` - for nodes 
* `color` - for edges
* `weights` - this property is only available for edges in weighted graphs
* `opacity`, `scale` & `line_width` - defined in [example 1](example1.md)

If frame management becomes an issue, it is possible to skip it completely and let Javis handle the frame management, again through the use of reasonable defaults. For example, skipping frames in `highlightNode` schedules the node highlighting after the end of the previous animation specified on the graph. This animation could be any of the graph utility functions with the exception of `changeNodeProperty` and `changeEdgeProperty` for which the starting frame is used as reference. To avail of this default option, the `default_keyframes=true` option needs to be passed in `create_graph`.

Most utility functions like `changeNodeProperty` or `highlightNode` or `animate_*` use Javis actions underneath in the implementations which makes it easy to arrange them via frames.

**Using `animate_neighbors`**

Animating neighboring nodes and edges can be simplified by using the `animate_neighbors` utlity function

```julia
animate_neighbors(ag, 1; animate_node_on=(:fill_color, "green"), animate_edge_on=(:color, "red"))
```
This internally makes a call to `changeNodeProperty` and `changeEdgeProperty`. If the keyword arguments are not provided, simple switching highlighting is used for the animation. 

**Using `animate_path`**

After the traversal has been done and the shortest path found, show the path by animating it.

```julia
# change back the graph to its original form
changeNodeProperty!(ag, (node)->true, :fill_color, "white")
changeEdgeProperty!(ag, (nodes...)->true, :color, "black")
animate_path(ag, path; animate_node_on=(:fill_color, "green"), animate_edge_on=(:color, "red"))
```

In the default case, when nothing is specified about how to animate nodes/edges in a path simple on/off highlighting is used on the universal property `:opacity`.

## Full Code

```julia
using LightGraphs
g = SimpleGraph(6)
add_edge!(g, 1, 2)
add_edge!(g, 1, 3)
add_edge!(g, 2, 4)
add_edge!(g, 3, 5)
add_edge!(g, 4, 6)

video=Video(300, 300)
Background(1:100, ground)

ag, nodes, edges = create_graph(g, 300, 300; layout=:spring, mode=:static)

current=1
dest=6
path=[]
visited=[false for i in 1:nv(g)]
num_visited=0

function dfs_and_animate(node, path)
    if node==dest
        highlightNode(GFrames(20+num_visited*10, 100), ag, current, :border_color, "red")
        return    
    end
    # Highlight the current node
    highlightNode(GFrames(20+num_visited*10, 100), ag, current, :border_color, "yellow")
    visited[current]=true
    num_visited+=1
    push!(path, current)
    # Change node color when highlighting effect ends
    changeNodeProperty!(@Frames(prev_end(), stop=parent_end()), ag, current, :color, "blue")
    for nb in neighbors(g, current)
        if visited[nb]
            continue
        end
        highlightEdge(GFrames(20+num_visited*10, 100), ag, current, nb, :color, "green")
        num_visited+=1
        dfs_and_animate(nb, path)
    end
    # Highlight again to indicate return to parent node
    highlightNode(GFrames(20+num_visited*10, 100), ag, current, :border_color, "yellow")
    num_visited+=1
    pop!(path)
end

dfs_and_animate(1, path)
changeNodeProperty!(ag, (node)->true, :fill_color, "white")
changeEdgeProperty!(ag, (nodes...)->true, :color, "black")
animate_path(ag, path; animate_node_on=(:fill_color, "green"), animate_edge_on=(:color, "red"))

render(video; pathname="example2.md")
```
