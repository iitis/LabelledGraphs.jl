module LabelledGraphs

    using LightGraphs
    using MetaGraphs
    export LabelledGraph, LabelledDiGraph, LabelledEdge


    struct LabelledGraph{S <: AbstractGraph{U} where U <: Integer, T} <: AbstractGraph{T}
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

    Base.:(==)(e1::LabelledEdge, e2::LabelledEdge) = src(e1) == src(e2) && dst(e1) == dst(e2)

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
        add_vertex!.(Ref(lg), vertices)
    end

    function MetaGraphs.set_prop!(
        lg::LabelledGraph{S, T}, v::T, prop::Symbol, val
    ) where {S <: AbstractMetaGraph, T}
        set_prop!(lg.inner_graph, lg.reverse_label_map[v], prop, val)
    end

    function MetaGraphs.set_prop!(
        lg::LabelledGraph{S, T}, s::T, d::T, prop::Symbol, val
    ) where {S <: AbstractMetaGraph, T}
        set_prop!(lg.inner_graph, lg.reverse_label_map[s], lg.reverse_label_map[d], prop, val)
    end

    function MetaGraphs.set_prop!(
        lg::LabelledGraph{S, T}, e::LabelledEdge, prop::Symbol, val
    ) where {S <: AbstractMetaGraph, T}
        set_prop!(lg, src(e), dst(e), prop, val)
    end

    function MetaGraphs.set_prop!(
        lg::LabelledGraph{S, T}, prop::Symbol, val
    ) where {S <: AbstractMetaGraph, T}
        set_prop!(lg.inner_graph, prop, val)
    end

    function MetaGraphs.get_prop(
        lg::LabelledGraph{S, T}, v::T, prop::Symbol
    ) where {S <: AbstractMetaGraph, T}
        get_prop(lg.inner_graph, lg.reverse_label_map[v], prop)
    end

    function MetaGraphs.get_prop(
        lg::LabelledGraph{S, T}, s::T, d::T, prop::Symbol
    ) where {S <: AbstractMetaGraph, T}
        get_prop(lg.inner_graph, lg.reverse_label_map[s], lg.reverse_label_map[d], prop)
    end

    function MetaGraphs.get_prop(
        lg::LabelledGraph{S, T}, e::LabelledEdge, prop::Symbol
    ) where {S <: AbstractMetaGraph, T}
        get_prop(lg, src(e), dst(e), prop)
    end

    function MetaGraphs.get_prop(
        lg::LabelledGraph{S, T}, prop::Symbol
    ) where {S <: AbstractMetaGraph, T}
        get_prop(lg.inner_graph, prop)
    end

    function MetaGraphs.set_props!(
        lg::LabelledGraph{S, T}, v::T, dict
    ) where {S <: AbstractMetaGraph, T}
        set_props!(lg.inner_graph, lg.reverse_label_map[v], dict)
    end

    function MetaGraphs.set_props!(
        lg::LabelledGraph{S, T}, s::T, d::T, dict
    ) where {S <: AbstractMetaGraph, T}
        set_props!(lg.inner_graph, lg.reverse_label_map[s], lg.reverse_label_map[d], dict)
    end

    function MetaGraphs.set_props!(
        lg::LabelledGraph{S, T}, e::LabelledEdge, dict
    ) where {S <: AbstractMetaGraph, T}
        set_props!(lg, src(e), dst(e), dict)
    end

    function MetaGraphs.set_props!(
        lg::LabelledGraph{S, T}, dict
    ) where {S <: AbstractMetaGraph, T}
        set_props!(lg.inner_graph, dict)
    end

    function MetaGraphs.props(
        lg::LabelledGraph{S, T}, v::T
    ) where {S <: AbstractMetaGraph, T}
        props(lg.inner_graph, lg.reverse_label_map[v])
    end

    function MetaGraphs.props(
        lg::LabelledGraph{S, T}, s::T, d::T
    ) where {S <: AbstractMetaGraph, T}
        props(lg.inner_graph, lg.reverse_label_map[s], lg.reverse_label_map[d])
    end

    function MetaGraphs.props(
        lg::LabelledGraph{S, T}, e::LabelledEdge
    ) where {S <: AbstractMetaGraph, T}
        props(lg, src(e), dst(e))
    end

    function MetaGraphs.props(lg::LabelledGraph{S, T})  where {S <: AbstractMetaGraph, T}
        props(lg.inner_graph)
    end

    function MetaGraphs.has_prop(
        lg::LabelledGraph{S, T}, v::T, prop::Symbol
    ) where {S <: AbstractMetaGraph, T}
        has_prop(lg.inner_graph, lg.reverse_label_map[v], prop)
    end

    function MetaGraphs.has_prop(
        lg::LabelledGraph{S, T}, s::T, d::T, prop::Symbol
    ) where {S <: AbstractMetaGraph, T}
        has_prop(lg.inner_graph, lg.reverse_label_map[s], lg.reverse_label_map[d], prop)
    end

    function MetaGraphs.has_prop(
        lg::LabelledGraph{S, T}, e::LabelledEdge, prop::Symbol
    ) where {S <: AbstractMetaGraph, T}
        has_prop(lg, src(e), dst(e), prop)
    end

    function MetaGraphs.has_prop(
        lg::LabelledGraph{S, T}, prop::Symbol
    ) where {S <: AbstractMetaGraph, T}
        has_prop(lg.inner_graph, prop)
    end

    function LightGraphs.induced_subgraph(
        lg::LabelledGraph{S, T}, vertices::Vector{T}
    ) where {S, T}
        sub_ig, _vmap = induced_subgraph(lg.inner_graph, [lg.reverse_label_map[v] for v in vertices])
        LabelledGraph(vertices, sub_ig), vertices
    end

    # --- Default-type aliases ---
    LabelledGraph(labels::Vector{T}) where T = LabelledGraph{SimpleGraph}(labels)
    LabelledDiGraph(labels::Vector{T}) where T = LabelledGraph{SimpleDiGraph}(labels)
end
