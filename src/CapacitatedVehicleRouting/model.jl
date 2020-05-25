function model(data::Data, optimizer)
    cvrp = BlockModel(optimizer, bridge_constraints = false)

    @axis(VehicleTypes, [1])

    E = instance_edges(data)
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
            i2, _ = nodes_to_desc[i]
            j2, _ = nodes_to_desc[j]
            i2 == j2 && return Inf
            i2, j2 = i2 < j2 ? (i2, j2) : (j2, i2)
            ind = sum((dim + 1 - k) % dim for k = 1:i2) + j2 - i2
            return costs[ind]
        end
        costmx = fill(Inf, length(nodes_to_desc), length(nodes_to_desc))
        for e in edges(graph)
            costmx[e.src,e.dst] = curcost(e.src, e.dst)
        end
        pstate = dijkstra_shortest_paths(graph, source, costmx)

        prevvertex = target
        curvertex = pstate.parents[target]
        sol = Dict{Tuple{Int, Int}, Int}()
        prevloc = source
        curloc = 0
        while curvertex != 0
            curloc, _ = nodes_to_desc[curvertex]
            edge = prevloc < curloc ? (prevloc, curloc) : (curloc, prevloc)
            sol[edge] = get(sol, edge, 0) + 1
            prevvertex = curvertex
            prevloc = curloc
            curvertex = pstate.parents[curvertex]
        end
        # Create the solution (send only variables with non-zero values)
        solvars = JuMP.VariableRef[]
        solvals = Float64[]
        for (edge, val) in sol
            push!(solvars, x[spid, edge])
            push!(solvals, val)
        end

        # Submit the solution to the subproblem to Coluna
        MOI.submit(cvrp, BD.PricingSolution(cbdata), pstate.dists[target], solvars, solvals)
    end

    subproblems = getsubproblems(dec)
    # only one subproblem
    specify!(subproblems[1], lower_multiplicity = 0, upper_multiplicity = 20, solver = route_pricing_callback)

    return cvrp, x, dec
end