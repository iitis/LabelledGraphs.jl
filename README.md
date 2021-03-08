# LabelledGraphs.jl

Graphs with vertices labelled with arbitrary objects.

## Motivation

Graphs from `LightGraphs` use vertices labelled with contiuous integer range starting from 1.
This poses a problem if one wants to handle graphs whose vertices are labelled either by more general integer ranges or other objects (e.g. strings).
`LabelledGraphs` extend `LightGraphs` by allowing more flexible labelling of verices.


## Usage

Labelled graph can be created by providing a sequence of labels, i.e.:

```julia
using LabelledGraphs

lg = LabelledGraph(["a", "b", "c"]) # Undirected graph with vertices a, b, c
ldg = LabelledDiGraph([4, 5, 10])   # Directed graph with vertices 4, 5, 10
```

One can also create labelled graph backed by a simple graph from `LightGraphs`.

```julia
using LabelledGraphs
using LightGraphs

g = path_graph(5)
lg = LabelledGraph(["a", "b", "c", "d", "e"], g)
```

Once the graph is created, it can be used mostly like other graphs rom `LightGraph`.
All method operate on labels given during graph's construction, for instance:

```julia
using LabelledGraphs
using LightGraphs

g = path_digraph(5)
lg = LabelledGraph(["a", "b", "c", "d", "e"], g)

println(vertices(lg))   # prints ["a", "b", "c", "d", "e"]
println(edges(lg))      # prints edges "a" -> "b", "b" -> "c" etc.
add_edge!(lg, "e", "b")
println(inneighbors(lg, "b")) # prints ["a", "e"]
```

Additionally, one can add new vertices to the `LabelledGraph`, either by using `add_vertex!` or `add_vertices!`.

```julia

add_vertex!(lg, "f")
add_vertices!(lg, ["u", "v", "w"])
```
