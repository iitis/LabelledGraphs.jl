using LightGraphs
using MetaGraphs
using Test

using LabelledGraphs


for graph_type ∈ [SimpleGraph, SimpleDiGraph]
@testset "Initializing LabelledGraph with another graph of type $graph_type" begin

    @testset "fails if number of labels is different than source graph's number of vertices" begin
        g = graph_type(5)
        labels = [1, 4, 5, 3]
        @test_throws ArgumentError LabelledGraph(labels, g)
    end

    @testset "fails if labels are not unique" begin
        g = path_digraph(4)
        labels = [1, 5, 10, 5]
        @test_throws ArgumentError LabelledGraph(labels, g)
    end


    @testset "gives a graph isomorphic to the source graph" begin
        g = graph_type(4)
        for (i, j) ∈ [(1, 2), (3, 2), (2, 4)] add_edge!(g, i, j) end
        labels = [20, 4, 5, 6]

        lg = LabelledGraph(labels, g)

        @testset "number of vertices in both graphs is the same" begin
            @test nv(lg) == nv(g)
        end

        @testset "sequence of vertices of LabelledGraph is equal to the labels used" begin
            @test collect(vertices(lg)) == labels
        end

        @testset "presence and absence of vertices is correctly reported" begin
            for v ∈ (20, 4, 5, 6)
                @test has_vertex(lg, v)
            end

            @test !has_vertex(lg, 1)
        end

        @testset "number of edges in both graph sis the same" begin
            @test ne(lg) == ne(g) == length(edges(lg))
        end

        # For non-directed LightGraphs, edges are reported lex-ordered, regardless of
        # the ordering of the original edge (i.e. edge (2, 1) is always reported as (1, 2)).
        # Since this ordering propagates to our LabelledGraphs, we need to define set of
        # expected edges accordingly.
        expected_edges = is_directed(g) ?
            [(i, j) for (i, j) ∈ [(20, 4), (5, 4), (4, 6)]] :
            [(i, j) for (i, j) ∈ [(20, 4), (4, 5), (4, 6)]]
        @testset "set of edges of LabelledGraph comprises source graph's edges with vertices mapped to labels" begin
            @test Set([(src(e), dst(e)) for e ∈ edges(lg)]) == Set(expected_edges)
        end

        @testset "presence and absence of edges is correctly reported" begin
            for (u, v) ∈ expected_edges
                @test has_edge(lg, LabelledEdge(u, v))
                @test has_edge(lg, u, v)
            end

            @test !has_edge(lg, 1, 2)
            @test !has_edge(lg, LabelledEdge(1, 2))
        end

        @testset "LabelledGraph is directed iff source graph is also directed" begin
            @test is_directed(lg) == is_directed(g)
        end
    end
end
end


for graph_type ∈ [SimpleGraph, SimpleDiGraph]
@testset "Initializing LabelledGraph{$graph_type} with only labels" begin
    lg = LabelledGraph{graph_type}([1, 7, 3, 5])

    @testset "gives graph with vertices corresponding to the labels" begin
        @test vertices(lg) == [1, 7, 3, 5]
    end

    @testset "and an empty set of edges" begin
        @test ne(lg) == length(edges(lg)) == 0
    end
end
end


@testset "Adding edge (s, d) to undirected LabelledGraph" begin
    lg = LabelledGraph{SimpleGraph}([4, 5, 0])

    add_edge!(lg, 4, 5)
    add_edge!(lg, LabelledEdge(4, 0))

    @testset "makes both (s, d) and (d, s) present in the graph begin" begin
        @test has_edge(lg, 4, 5) && has_edge(lg, 5, 4)
        @test has_edge(lg, 4, 0) && has_edge(lg, 0, 4)
    end

    @testset "does not add any other edge" begin
        @test ne(lg) == length(edges(lg)) == 2
    end

    @testset "makes s and d both ingoing and outgoing neighbors" begin
        @test 4 ∈ neighbors(lg, 5) && 4 ∈ outneighbors(lg, 5) && 4 ∈ inneighbors(lg, 5)
        @test 5 ∈ neighbors(lg, 4) && 5 ∈ outneighbors(lg, 4) && 5 ∈ inneighbors(lg, 4)

        @test 4 ∈ neighbors(lg, 0) && 4 ∈ outneighbors(lg, 0) && 4 ∈ inneighbors(lg, 0)
        @test 0 ∈ neighbors(lg, 4) && 0 ∈ outneighbors(lg, 4) && 0 ∈ inneighbors(lg, 4)
    end
end


@testset "Adding (s, d) edge to directed LabelledGraph" begin
    lg = LabelledGraph{SimpleDiGraph}(["a", "b", "c", "d"])

    add_edge!(lg, "a", "c")
    add_edge!(lg, "d", "a")

    @testset "does not add (d, s) edge" begin
        @test has_edge(lg, "a", "c") && !has_edge(lg, "c", "a")
        @test has_edge(lg, "d", "a") && !has_edge(lg, "a", "d")
    end

    @testset "does not add any other edge" begin
        @test ne(lg) == length(edges(lg)) == 2
    end

    @testset "makes s and d neighbors (as reported by all_neighbors)" begin
        @test "a" ∈ all_neighbors(lg, "c") && "c" ∈ all_neighbors(lg, "a")
        @test "d" ∈ all_neighbors(lg, "a") && "a" ∈ all_neighbors(lg, "d")
    end

    @testset "makes s an ingoing neighbor of d and d outgoing neighbor of s" begin
        @test "a" ∈ inneighbors(lg, "c") && "c" ∈ outneighbors(lg, "a")
        @test "d" ∈ inneighbors(lg, "a") && "a" ∈ outneighbors(lg, "d")
    end
end


for source_graph ∈ (path_digraph(5), path_graph(5))
@testset "Adding vertex to LabelledGraph{$source_graph}" begin

    lg = LabelledGraph(["a", "b", "c", "d", "e"], source_graph)

    @testset "is not possible if the label is duplicated" begin
        @test_throws ArgumentError add_vertex!(lg, "a")
    end

    add_vertex!(lg, "f")

    @testset "makes new vertex present in vertices list" begin
        @test "f" ∈ vertices(lg)
    end

    @testset "increases number of vertices by one" begin
        @test nv(lg) == length(vertices(lg)) == 6
    end

    @testset "makes it possible to connect new vertex to previously existing one" begin
        add_edge!(lg, "f", "b")
        @test has_edge(lg, "f", "b")
    end
end
end


for source_graph ∈ (path_digraph(5), path_graph(5))
@testset "Adding multiple vertices to LabelledGraph{$(typeof(source_graph))}" begin

    lg = LabelledGraph(["a", "b", "c", "d", "e"], source_graph)

    @testset "is not possible if any labels are duplicated, in which case no verts are added" begin
        @test_throws ArgumentError add_vertices!(lg, ["f", "g", "h", "a"])
        @test nv(lg) == 5
    end

    new_labels = ["u", "v", "w"]
    add_vertices!(lg, new_labels)

    @testset "makes new vertices present in vertices list" begin
        @test all(label ∈ vertices(lg) for label ∈ new_labels)
    end

    @testset "increases number of vertices by the number of added vertices" begin
        @test nv(lg) == length(vertices(lg)) == 8
    end

    @testset "makes it possible to connect any two of new vertices" begin
        add_edge!(lg, "u", "w")
        add_edge!(lg, "w", "v")
        @test has_edge(lg, "u", "w")
        @test has_edge(lg, "w", "v")
    end

    @testset "makes it possible to connet new vertex and previously existing one" begin
        add_edge!(lg, "w", "a")
        add_edge!(lg, "b", "u")
        @test has_edge(lg, "w", "a")
        @test has_edge(lg, "b", "u")
    end
end
end


@testset "LabelledGraph can be constructed using default-type aliases" begin
    lg = LabelledGraph(["a", "b", "c"])
    @test !is_directed(lg)
    @test nv(lg) == 3

    lg = LabelledDiGraph(["a", "b", "c"])
    @test is_directed(lg)
    @test nv(lg) == 3
end


for graph_type ∈ (MetaGraph, MetaDiGraph)
@testset "LabelledGraph backed up by $graph_type can store metainformation" begin
    lg = LabelledGraph{graph_type}([2, 5, 10])
    add_edge!(lg, 2, 5)
    set_prop!(lg, 2, :x, 10.0)
    set_prop!(lg, 2, 5, :y, "test")
    set_prop!(lg, LabelledEdge(2, 5), :z, [1, 2,3])
    set_prop!(lg, :name, "the ising model")

    @test get_prop(lg, 2, :x) == 10.0
    @test get_prop(lg, LabelledEdge(2, 5), :z) == [1, 2, 3]
    @test get_prop(lg, 2, 5, :y) == "test"
    @test get_prop(lg, :name) == "the ising model"
end
end


for graph_type ∈ (MetaGraph, MetaDiGraph)
@testset "LabelledGraph backed up by $graph_type can store multiple metainformation at once" begin
    lg = LabelledGraph{graph_type}([2, 5, 10])

    vertex_props = Dict(:x => 10.0, :y => -1.0)
    sd_props = Dict(:a => "test", :b => "Fortran")
    edge_props = Dict(:u => [1, 2, 3], :v => 0)
    graph_props = Dict(:name => "the", :title => "ising model")

    add_edge!(lg, 2, 5)
    set_props!(lg, 2, vertex_props)
    set_props!(lg, 2, 5, sd_props)
    set_props!(lg, LabelledEdge(2, 5), edge_props)
    set_props!(lg, graph_props)

    @test props(lg, 2) == vertex_props
    @test props(lg, LabelledEdge(2, 5)) == merge(sd_props, edge_props)
    @test props(lg, 2, 5) == merge(sd_props, edge_props)
    @test props(lg) == graph_props
end
end
