function model(data::Data, optimizer)
    cvrp = BlockModel(optimizer, bridge_constraints = false)

    @axis(VehicleTypes, [1])

    E = edges(data)
    C = customers(data)
    dim = length(data.locations)

    @variable(cvrp, 0 <= x[v in VehicleTypes, e in E] <= 2, Int)
    @constraint(cvrp, cov[c in C],
        sum(x[v, e] for e in incidents(data, c), v in VehicleTypes) == 2
    )

    @objective(cvrp, Min, sum(dist(data, e) * x[v, e] for v in VehicleTypes, e in E))

    @dantzig_wolfe_decomposition(cvrp, dec, VehicleTypes)

    # Naive pricing problem to compute routes
    id(c, d) = 1000 * c + d
    nodes_to_desc = Tuple{Int, Int}[]
    desc_to_node = Dict{Int, Int}()
    push!(nodes_to_desc, (1, capacity(data)))
    for c in C, d in capacity(data):-1:demand(data, c)
        push!(nodes_to_desc, (c, d))
        desc_to_node[id(c, d)] = length(nodes_to_desc)
    end
    push!(nodes_to_desc, (1, capacity(data)))
    
    graph = SimpleDiGraph(length(nodes_to_desc))
    source = 1
    target = length(nodes_to_desc)
    for c in C, d in capacity(data):-1:demand(data, c)
        tail = desc_to_node[id(c, d)]
        if d == capacity(data)
            add_edge!(graph, source, tail)
        end
        for c2 in C
            d2 = d - demand(data, c)
            if c2 != c && d2 >= demand(data, c2)
                head = desc_to_node[id(c2, d2)]
                add_edge!(graph, tail, head)
            end
        end
        add_edge!(graph, tail, target)
    end

    function route_pricing_callback(cbdata)
        spid = BlockDecomposition.callback_spid(cbdata, cvrp)
        costs = [BlockDecomposition.callback_reduced_cost(cbdata, x[spid, e]) for e in E]

        function curcost(i, j)
            i == j && return Inf
            i2, _ = nodes_to_desc[i]
            j2, _ = nodes_to_desc[j]
            i2, j2 = i2 < j2 ? (i2, j2) : (j2, i2)
            @show dim, i, j, i2, j2
            ind = sum((dim + 2 - k) % (dim + 1) for k = 1:i2) + j2 - i2
            @show ind
            return costs[ind]
        end

        costmx = [curcost(i, j) for i in 1:length(nodes_to_desc), j in 1:length(nodes_to_desc)]
        pstate = dijkstra_shortest_path(graph, [source], distmx = costmx)
        @show pstate
        exit()
    end

    subproblems = getsubproblems(dec)
    specify!(subproblems[1], lower_multiplicity = 0, upper_multiplicity = 20, solver = route_pricing_callback)

    return cvrp, x, dec
end