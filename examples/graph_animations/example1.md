## Graph traversal using BFS

### Points covered
1. Graph creation
2. Algorithm explanation through two different visualisations

### Graph Creation

The graph object can be created/initialized by the use of a LightGraph typed object or any arbitrary graph types. In the latter case, there is a need to specify some additional accessibility functions to make use of some advanced visualisation features. It is discussed in later examples. This one covers how to do it with the use of a simple adacency list. It is supposed to be the most simplest way one can use the API with almost a zero learning curve.

**Graph representation**
```julia
graph = [[2, 3, 4, 5],
         [6, 7],
         [8],
         [],
         [],
         [],
         [],
         []]
```
The input graph can be of any Julia data type. This does not impose any restriction on the type of graph but for advanced features it requires some extra work. An alternative to this is using `LightGraphs.jl` for which there are many convenience functions available. Its usage is covered in [Example 2](example2.md).

**Graph initialization**
```julia
# Parameters - Graph object | is directed? | width | height | starting position
ga = GraphAnimation(graph, true, 300, 300, O)
```

**Node registration**
```julia
nodes = [Object(@Frames(prev_start()+5, stop=100), GraphNode(i, drawNode; animate_on=:scale, fill_color="yellow", border_color="black", text=string(i), text_valign=:middle, text_halign=:center)) for i in range(1, 8; step=1)]

# TODO: Need to find the best way to map drawing arguments like text_align (specified before) into the drawing function. Using a dictionary, seems a good idea.
function drawNode(draw_opts)
    sethue(draw_opts[:fill_color])
    circle(draw_opts[:position], 5, :fill)
    sethue(draw_opts[:border_color])
    circle(draw_opts[:position], 5, :stroke)
    text(draw_opts[:text], draw_opts[:position], valign = draw_opts[:text_valign], halign = draw_opts[:text_halign])
end
```
The set of drawing options (like `border_color`) that can be supported depends solely on the user provided parameters and the drawing function used. The utility functions like `highlightNode` take as input one of these drawing parameters and a new value for it and perform highlighting operations on them.

In [Example 3](example3.md), I will demonstrate how to map these drawing options to node properties which are part of the input graph object. That will help animate changes in node properties simultaneously without any additional coding.

The additional option `animate_on` controls the appearance of the node on the canvas. The same option is used during removal of the nodes/edges.

The options available are:
* `:opacity` - both nodes and edges
* `:scale` - only for nodes
* `:line_width` - only for edges
* `:length` - only for edges

The result is eight balls drawn on the canvas at fixed locations unaltered by changes in the graph by addition/deletion of new nodes.

**Edge registration**

```julia
edges=[]
for (index, node) in enumerate(graph)
    for j in node
        push!(edges, Object(@Frames(prev_start()+5, stop=100), GraphEdge(index, j[1], drawEdge; animate_on=:length, color="black")))
    end
end

# Need to provide custom drawEdge functions to account for self-loops, curved edges etc.
function drawEdge(opts)
    sethue(opts[:color])
    line(opts[:position1], opts[:position2], :stroke)
end
```

### Graph visualisation

The nodes already visited need to be marked and a data structure like queue providing FIFO access is needed to store the order of traversal of nodes.
```julia
using DataStructures
# vis[x] indicates if a node is visited and Q is a queue data structure
vis=[false for i in 1:8]
Q=Queue{Int}()
```

The algorithm can be explained in two ways:

**Using simple coloring**
* Use a different fill color to convey the new nodes in the queue
* Change the color of visited nodes permanently

```julia
enqueue!(Q, 1)
# The frames argument is optional here.
changeNodeProperty!(ga, 1, :fill_color, "green")
while !isempty(Q)
    i=dequeue!(Q)
    vis[i]=true
    changeNodeProperty!(ga, i, :fill_color, "blue")
    for j in neighbors(i)
        if !vis[j]
            enqueue!(Q, j)
            changeNodeProperty!(ga, j, :fill_color, "green")
        end
    end
end
```

**Using node color or border color highlighting**
* Use a different fill or border color to convey the currently highlighted node
* Change the color of visited nodes permanently

```julia
# vis[x] indicates if a node is visited and Q is a queue data structure
highlightNode(ga, 1, :fill_color, "white") # Flicker between original yellow and white color for some default number of frames
vis[1]=true
changeNodeProperty!(ga, 1, :fill_color, "orange")
enqueue!(Q, 1)
while !Q.empty()
    i=dequeue!(Q)
    for j in neighbors(i)
        if !vis[j]
            highlightNode(ga, j, :fill_color, "white")
            vis[j]=true
            changeNodeProperty!(ga, j, :fill_color, "orange")
            enqueue!(Q, j)
        end
    end
end
```

## Full Code

```julia
using Javis, DataStructures

function ground(args...) 
    background("white")
    sethue("black")
end

function drawNode(draw_opts)
    sethue(draw_opts[:fill_color])
    circle(draw_opts[:position], 5, :fill)
    sethue(draw_opts[:border_color])
    circle(draw_opts[:position], 5, :stroke)
    text(draw_opts[:text], draw_opts[:position], valign = draw_opts[:text_valign], halign = draw_opts[:text_halign])
end

function drawEdge(opts)
    sethue(opts[:color])
    line(opts[:position1], opts[:position2], :stroke)
end

graph = [[2, 3, 4, 5],
         [6, 7],
         [8],
         [],
         [],
         [],
         [],
         []]

video=Video(300, 300)
Background(1:100, ground)

ga = GraphAnimation(graph, true, 300, 300, O)
nodes = [Object(@Frames(prev_start()+5, stop=100), GraphNode(i, drawNode; animate_on=:scale, fill_color="yellow", border_color="black", text=string(i), text_valign=:middle, text_halign=:center)) for i in range(1, 8; step=1)]

edges=[]
for (index, node) in enumerate(graph)
    for j in node
        push!(edges, Object(@Frames(prev_start()+5, stop=100), GraphEdge(index, j[1], drawEdge; animate_on=:length, color="black")))
    end
end

vis=[false for i in 1:8]
Q=Queue{Int}()
enqueue!(Q, 1)
changeNodeProperty!(ga, 1, :fill_color, "green")

while !isempty(Q)
    i=dequeue!(Q)
    vis[i]=true
    changeNodeProperty!(ga, i, :fill_color, "blue")
    for j in neighbors(i)
        if !vis[j]
            enqueue!(Q, j)
            changeNodeProperty!(ga, j, :fill_color, "green")
        end
    end
end

render(video; pathname="example1.gif")
```
