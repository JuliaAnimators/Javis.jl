## Minimum cost path problem

In this example, we shall cover visualising the minimum-cost path finding algorithm for weighted graphs. The graph shall be represented using a custom data type. However, one could use the `MetaGraph` package from `JuliaGraphs`, where extra node properties can be stored and managed.

### Djikstra's Algorithm

This is one of the most famous graph algorithms concieved by computer scientist Edsger W. Dijkstra in 1956. It exists in many variants i.e. finding the shortest path from a node to another node in a weighted graph or to all other nodes. In this demo we will look at the the former variant only.

The algorithm proceeds as follows:
1. Mark all nodes as unvisited and group them into an *unvisited* set.
2. Assign an initial weight of infinity to all nodes except the initial node which gets a weight 0. Mark this node as currrent.
3. For every unvisited neighbour of the current node, update its weight to the minimum of its current value and the new tentative weight computed. The tentative weight is computed as the sum of the parent node value and the edge weight between the two nodes.
4. Mark the current node as visited and remove it from unvisited set.
5. When the destination node is marked visited, stop.
6. Otherwise, mark the node from the nieghbouring set with the minimum weight as current and repeat step 3.

### Demo

**Graph creation**

Create an example graph using a custom data type. For simplicity, the graph is assumed to be connected.
```julia
# The weights are used later in the algorithm. Storing it here avoids requiring any additional data structures. The neighbor list elements are read as (node_id, edge_weight)
g = [Dict(:weight=>0, :neighbors=>[(2, 3), (3, 5)]),
     Dict(:weight=>1000, :neighbors=>[(4, 1), (5, 2)]),
     Dict(:weight=>1000, :neighbors=>[(5, 1), (4, 2)]),
     Dict(:weight=>1000, :neighbors=>[(6, 1)]),
     Dict(:weight=>1000, :neighbors=>[(4, 3)]),
     Dict(:weight=>1000, :neighbors=>[])]
```

(*Visualisation coming up*)

**Register graph in Javis**
```julia
wg = GraphAnimation(g, false, 300, 300, O; 
                    node_attribute_fn=(g, node, attr) -> n(g, node, attr),
                    edge_attribute_fn=(g, node1, node2, attr) -> e(g, node1, node2))

function n(g, node, attr)
    if attr==:weight && g[node][attr]==1000
        return "inf"
    else
        return g[node][attr]
    end
end

function e(g, node1, node2)
    for j in g[node1][:neighbors]
        if j[1]==node2
            return j[2]
        end
    end
end
```

**Create nodes and edges**

Once the graph has been registered, we need to register nodes and edges to it. This can be skipped if the base graph representation was one of the known graph types listed in [example 2](example2.md). However, this way of doing it provides much more flexibility to customise the drawing function, frame management, etc.

```julia
nodes = [Object(@Frames(prev_start()+5, stop=100), GraphNode(i, drawNode; animate_on=:scale, property_style_map=Dict(:weight=>:weight), fill_color="white", border_color="black", text=string(i))) for i in range(1, 6; step=1)]

function drawNode(opts)
    sethue(opts[:fill_color])
    circle(opts[:position], 5, :fill)
    sethue(opts[:border_color])
    circle(opts[:position], 5, :stroke)
    text(opts[:text], opts[:position], valign = :middle, halign = :center)
    text(opts[:weight], opts[:position]+(0, 8), valign = :middle, halign = :center)
end

edges=[]
for (index, node) in enumerate(g)
    for j in node[:neighbors]
        push!(edges, Object(@Frames(prev_start()+5, stop=100), GraphEdge(index, j[1], drawEdge; animate_on=:scale, property_style_map=Dict(:weight=>:line_width, :weight=>:text), color="black")))
    end
end

# Need to provide custom drawEdge functions to account for self-loops, curved edges etc.
function drawEdge()
    sethue(opts[:color])
    setline(opts[:line_width])
    line(opts[:position1], opts[:position2], :stroke)
    # Now add the edge weight aligned to the edge line/curve 
    translate((opts[:position1]+opts[:position2])/2)
    rotate(slope(opts[:position1], opts[:position2]))
    translate(Point(0, 3))
    text(opts[:text], O, valign = :middle, halign = :center)
    return O
end
```
The value for property `:line_width` is tracked internally from the node property `:weight`. The extremas of the value of the property `:weight` is scaled and clipped between sensible line widths. Finding these extremum points are where the node and edge attribute functions are used for.

These limits get updated every time the utility function `updateGraph` gets called after changing the node properties.

**Visualise the algorithm**

To keep track of the neighboring node set, a `SortedDict` shall be used. To distinguish visited nodes, a `visited` data structure will be kept.
```julia
st=SortedDict([index=>first(w)[2] for (index, w) in enumerate(g)])
visited=[false for i in 1:6]
```

The states of the nodes are represented as `white` -> unmarked, `yellow highlighted` -> current & `green` -> marked. Currently all nodes are colored white by default.

```julia
# Make all edges translucent
changeEdgeProperty(wg, (node1, node2) -> true, :opacity, 0.5)
current=1
dst=6
while !isempty(st)
    current=first(st)
    if current[1]==dst
        highlightNode(wg, current[1], :border_color, "red")
        break
    end
    highlightNode(wg, current[1], :border_color, "yellow")
    visited[current[1]]=true
    delete!(st, current[1])
    changeNodeProperty!(wg, current[1], :fill_color, "green")
    for j in g[current[1]][:neighbors]
        if !visited[j[1]]
            highlightEdge(wg, current[1], j[1], :color, "yellow")
            st[j[1]]=min(st[j[1]], current[2]+j[2])
            changeNodeProperty!(wg, j[1], :weight, string(st[j[1]]))
        end
    end
end
```

**Weight update using `updateGraph`**

Changing the node weight drawn on the canvas can also be done in a different way. It is not very expressive for this example, but when updates to node properties like `:weight` in the graph has to be made in bulk, using `updateGraph` is simpler. 

Additionally, for known drawing properties like `:line_width` for edges easing transitions are provided between the 2 different states.

The changes to the above algorithm would be
```julia
            st[j[1]]=min(st[j[1]], current[2]+j[2])
            g[j[1]][:weight]=st[j[1]]
        end
        updateGraph!(wg, g)
    end
```

## Full Code

```julia
using Javis

function n(g, node, attr)
    if attr==:weight && g[node][attr]==1000
        return "inf"
    else
        return g[node][attr]
    end
end

function e(g, node1, node2)
    for j in g[node1][:neighbors]
        if j[1]==node2
            return j[2]
        end
    end
end

function drawEdge()
    sethue(opts[:color])
    setline(opts[:line_width])
    line(opts[:position1], opts[:position2], :stroke)
    # Now add the edge weight aligned to the edge line/curve 
    translate((opts[:position1]+opts[:position2])/2)
    rotate(slope(opts[:position1], opts[:position2]))
    translate(Point(0, 3))
    text(opts[:text], O, valign = :middle, halign = :center)
    return O
end

function drawNode(opts)
    sethue(opts[:fill_color])
    circle(opts[:position], 5, :fill)
    sethue(opts[:border_color])
    circle(opts[:position], 5, :stroke)
    text(opts[:text], opts[:position], valign = :middle, halign = :center)
    text(opts[:weight], opts[:position]+(0, 8), valign = :middle, halign = :center)
end

g = [Dict(:weight=>0, :neighbors=>[(2, 3), (3, 5)]),
     Dict(:weight=>1000, :neighbors=>[(4, 1), (5, 2)]),
     Dict(:weight=>1000, :neighbors=>[(5, 1), (4, 2)]),
     Dict(:weight=>1000, :neighbors=>[(6, 1)]),
     Dict(:weight=>1000, :neighbors=>[(4, 3)]),
     Dict(:weight=>1000, :neighbors=>[])]

video =Video(300, 300)
Background(1:100, ground)

wg = GraphAnimation(g, false, 300, 300, O; 
                    node_attribute_fn=(g, node, attr) -> n(g, node, attr),
                    edge_attribute_fn=(g, node1, node2, attr) -> e(g, node1, node2))

nodes = [Object(@Frames(prev_start()+5, stop=100), GraphNode(i, drawNode; animate_on=:scale, property_style_map=Dict(:weight=>:weight), fill_color="white", border_color="black", text=string(i))) for i in range(1, 6; step=1)]

edges=[]
for (index, node) in enumerate(g)
    for j in node[:neighbors]
        push!(edges, Object(@Frames(prev_start()+5, stop=100), GraphEdge(index, j[1], drawEdge; animate_on=:scale, property_style_map=Dict(:weight=>:line_width, :weight=>:text), color="black")))
    end
end

st=SortedDict([index=>first(w)[2] for (index, w) in enumerate(g)])
visited=[false for i in 1:6]

changeEdgeProperty(wg, (node1, node2) -> true, :opacity, 0.5)
current=1
dest=6
while !isempty(st)
    current=first(st)
    if current[1]==dest
        highlightNode(wg, current[1], :border_color, "red")
        break
    end
    highlightNode(wg, current[1], :border_color, "yellow")
    visited[current[1]]=true
    delete!(st, current[1])
    changeNodeProperty!(wg, current[1], :fill_color, "green")
    for j in g[current[1]][:neighbors]
        if !visited[j[1]]
            highlightEdge(wg, current[1], j[1], :color, "yellow")
            st[j[1]]=min(st[j[1]], current[2]+j[2])
            g[j[1]][:weight]=st[j[1]]
        end
        updateGraph!(wg, g)
    end
end

render(video; pathname="example3.md")
```
