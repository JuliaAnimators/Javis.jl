## Graph Animation Demos

The demo serves to list the features that I am going to implement for graph animation using Javis. The example links at the end will take you to use cases that I think are worth considering before implementing the API.

### List of features

* Graph type invariance - The user should have the flexibility in terms of the type of the graph. The default graph type supported would be from LightGraphs.jl
* Add/Remove edges or nodes - Upon such changes the layout should change automatically to take into account the new arrangement
* Utilities to update the graph
    1. `addNode!` - add a node on the canvas
    2. `addEdge!` - add an edge on the canvas
    3. `changeNodeProperty!` - Update drawing style of node(s) on canvas
    4. `changeEdgeProperty!` - Update drawing style of edge(s) on canvas
    5. `updateGraph!` - Takes in the updated input graph object and updates the drawing properties of nodes and edges correspondingly
* Animation tools on graph
    1. `animate_inneighbors` - Incoming neighbors (for a directed graph)
    2. `animate_outneighbors` - Outgoing neighbors (for a directed graph)
    3. `animate_neighbors` - All neighbors
    4. `highlightNode` - Highlight node(s) using flicker animation of a node property
    5. `highlightEdge` - Highlight edge(s) using flicker animation of an edge property
    6. `animatePath` - Animate a path on the graph
    7. `bfs` - Animate bfs at a node
    8. `dfs` - Animate dfs at a node

### Examples

1. [Graph Traversal](example1.md)
2. [Depth First Search](example2.md)
2. [Shortest Path](example3.md)
3. [Cycle Detection]()
4. [Minimum Spanning Tree]()
5. [Bipartite Matching]()
6. [Strongly connected components]()
7. [Graph Coloring]()
8. [Gradient backpropagation]()

### Reference implementation till now

The struct definitions of `GraphAnimation`, `GraphNode` & `GraphEdge` are provided in [Graphs.jl](../../src/structs/Graphs.jl)