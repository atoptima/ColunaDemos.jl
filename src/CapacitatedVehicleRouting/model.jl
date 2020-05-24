function model(d::Data, optimizer)
    cvrp = BlockModel(optimizer, bridge_constraints = false)

    @axis(VehicleTypes, [1])

    E = edges(data)
    C = customers(data)

    @variable(cvrp, 0 <= x[v in VehicleTypes, e in E] <= 2, Int)
    @constraint(cvrp, cov[c in C],
        sum(x[v, e] for e in incidents(d, c), v in VehicleTypes) == 2
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

    subproblems = getsubproblems(dec)
    specify!(subproblems[1], lower_multiplicity = 0, upper_multiplicity = 20)

    return cvrp, x, dec
end