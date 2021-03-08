module LabelledGraphs

    using LightGraphs
    export LabelledGraph, LabelledDiGraph, LabelledEdge

    abstract type AbstractLabelledGraph{T} <: AbstractGraph{T} end


    struct LabelledGraph{S <: AbstractGraph{U} where U <: Integer, T} <: AbstractLabelledGraph{T}
        labels::Vector{T}
        inner_graph::S
        reverse_label_map::Dict{T, Integer}

        function LabelledGraph(labels::Vector{T}, graph::S) where T where S <: AbstractGraph{U} where U <: Integer
            if length(labels) != nv(graph)
                throw(ArgumentError("Labels and inner graph's vertices have to be equinumerous."))
            elseif !allunique(labels)
                throw(ArgumentError("Labels have to be unique."))
            else
                new{S, T}(labels, graph, Dict(label => i for (label, i) ∈ zip(labels, vertices(graph))))
            end
        end
    end


    struct LabelledEdge{T} <: AbstractEdge{T}
        src::T
        dst::T
    end

    LightGraphs.src(e::LabelledEdge{T}) where T = e.src
    LightGraphs.dst(e::LabelledEdge{T}) where T = e.dst


    # --- External constructors ---
    LabelledGraph{S}(labels::Vector{T}) where T where S <: AbstractGraph =
        LabelledGraph(labels, S(length(labels)))


    # --- Querying vertices ---
    LightGraphs.nv(g::LabelledGraph) = length(g.labels)

    LightGraphs.vertices(g::LabelledGraph) = g.labels

    LightGraphs.has_vertex(g::LabelledGraph, v) = v in g.labels


    # --- Querying edges ---
    LightGraphs.ne(g::LabelledGraph) = ne(g.inner_graph)

    LightGraphs.edges(g::LabelledGraph) =
        map(e -> LabelledEdge(g.labels[src(e)], g.labels[dst(e)]), edges(g.inner_graph))

    LightGraphs.has_edge(g::LabelledGraph, s, d) =
        has_vertex(g, s) &&
        has_vertex(g, d) &&
        has_edge(g.inner_graph, g.reverse_label_map[s], g.reverse_label_map[d])

    LightGraphs.has_edge(g::LabelledGraph, e::LightGraphs.AbstractEdge) =
        has_edge(g, src(e), dst(e))


    # --- Querying neighborhoods ---
    LightGraphs.outneighbors(g::LabelledGraph{S, T}, v::T) where S where T =
        [g.labels[u] for u ∈ outneighbors(g.inner_graph, g.reverse_label_map[v])]

    LightGraphs.inneighbors(g::LabelledGraph{S, T}, v::T) where S where T =
        [g.labels[u] for u ∈ inneighbors(g.inner_graph, g.reverse_label_map[v])]

    LightGraphs.all_neighbors(g::LabelledGraph{S, T}, v::T) where S where T =
        collect(union(Set(inneighbors(g, v)), Set(outneighbors(g, v))))


    # --- Querying other graph properties ---
    LightGraphs.is_directed(::Type{LabelledGraph{S, T}}) where S where T = is_directed(S)


    # --- Mutations ---
    # Warning: this might need further adjustments if we incorporate support for static graphs,
    # as they are immutable.
    LightGraphs.add_edge!(lg::LabelledGraph{S, T}, s::T, d::T) where S where T =
        add_edge!(lg.inner_graph, lg.reverse_label_map[s], lg.reverse_label_map[d])

    LightGraphs.add_edge!(lg::LabelledGraph{S, T}, e::AbstractEdge{T}) where S where T =
        add_edge!(lg, src(e), dst(e))

    function LightGraphs.add_vertex!(lg::LabelledGraph{S, T}, v::T) where S where T
        if v ∈ lg.labels
            throw(ArgumentError("Duplicate labels are not allowed"))
        end
        add_vertex!(lg.inner_graph)
        push!(lg.labels, v)
        push!(lg.reverse_label_map, v => nv(lg.inner_graph))
    end

    function LightGraphs.add_vertices!(lg::LabelledGraph{S, T}, vertices::Vector{T}) where S where T
        if any(v ∈ lg.labels for v ∈ vertices)
            throw(ArgumentError("Duplicate labels are not allowed"))
        end
        foreach(label -> add_vertex!(lg, label), vertices)
    end


    # --- Default-type aliases ---
    LabelledGraph(labels::Vector{T}) where T = LabelledGraph{SimpleGraph}(labels)
    LabelledDiGraph(labels::Vector{T}) where T = LabelledGraph{SimpleDiGraph}(labels)


end
