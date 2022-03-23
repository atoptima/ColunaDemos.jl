function model(data::Data, optimizer)
    cvrp = BlockModel(optimizer)

    @axis(VehicleTypes, [1])

    E = instance_edges(data)
    C = customers(data)
    Q = capacity(data)
    dim = length(data.locations)

    @variable(cvrp, 0 <= x[v in VehicleTypes, e in E] <= 2, Int)
    @constraint(cvrp, cov[c in C],
        sum(x[v, e] for e in incidents(data, c), v in VehicleTypes) == 2
    )
    @constraint(cvrp, lbveh, sum(x[1, (1, i)] for i in C) >= 2 * ceil(totaldemand(data) / Q))

    # routes = []
    # push!(routes, [21 31 19 17 13 7 26] .+ 1)
    # push!(routes, [12 1 16 30] .+ 1)
    # push!(routes, [27 24] .+ 1)
    # push!(routes, [29 18 8 9 22 15 10 25 5 20] .+ 1)
    # push!(routes, [14 28 11 4 23 3 2 6] .+ 1)
    # for r in routes
    #     for i in 2:length(r)
    #         e = (r[i-1] < r[i]) ? (r[i-1], r[i]) : (r[i], r[i-1])
    #         @constraint(cvrp, x[1, e] == 1.0)
    #     end
    # end

    @objective(cvrp, Min, sum(dist(data, e) * x[v, e] for v in VehicleTypes, e in E))

    @dantzig_wolfe_decomposition(cvrp, dec, VehicleTypes)

    ########################################################################################
    #  Pricing Callback                                                                    #
    ########################################################################################
    id(c, d) = 10000 * c + d
    nodes_to_desc = Tuple{Int, Int}[]
    desc_to_node = Dict{Int, Int}()
    push!(nodes_to_desc, (1, Q))
    for c in C, d in Q:-1:demand(data, c)
        push!(nodes_to_desc, (c, d))
        desc_to_node[id(c, d)] = length(nodes_to_desc)
    end
    push!(nodes_to_desc, (1, Q))
    
    graph = SimpleDiGraph(length(nodes_to_desc))
    source = 1
    target = length(nodes_to_desc)
    for c in C, d in Q:-1:demand(data, c)
        tail = desc_to_node[id(c, d)]
        if d == Q
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
        MOI.submit(cvrp, BD.PricingDualBound(cbdata), pstate.dists[target])
    end

    ########################################################################################
    #  Rounded Capacity Cuts                                                               #
    ########################################################################################
    nbnodes = length(C) + 1
    #sepgraph = complete_graph(nbnodes)

    sep = Model(HiGHS.Optimizer)
    @variable(sep, w[e in E] >= 0)
    @variable(sep, y[i in 1:nbnodes], Bin)
    @variable(sep, M >= 0, Int)
    @constraint(sep, cut1[e in E], w[e] >= y[e[1]] - y[e[2]])
    @constraint(sep, cut2[e in E], w[e] >= y[e[2]] - y[e[1]])
    @constraint(sep, dem, sum(demand(data,c) * y[c] for c in C) >= M * Q + 1)
    @constraint(sep, fix, y[1] == 0)

    function rounded_capacity_cuts(cbdata)
        distmx = zeros(Float64, nbnodes, nbnodes)
        for (i,j) in E
            val = callback_value(cbdata, x[1, (i,j)])
            distmx[i,j] = val
            distmx[j,i] = val
        end

        Mub = ceil(totaldemand(data)/Q) - 1
        @objective(sep, Min, sum(distmx[e...] * w[e] for e in E))
        for m in 1:Mub
            JuMP.fix(M, m, force = true)
            optimize!(sep)
            val = objective_value(sep)
            Ecut = Tuple{Int,Int}[]
            if val < 2*(m + 1) - 1e-6
                for e in E
                    if value(w[e]) ≈ 1.0
                        push!(Ecut, e)
                    end
                end
                rcc = @build_constraint(sum(x[1,e] for e in Ecut) >= 2*(m+1))
                MOI.submit(cvrp, MOI.UserCut(cbdata), rcc)
            end
        end
        return
    end
    MOI.set(cvrp, MOI.UserCutCallback(), rounded_capacity_cuts)
  
    ########################################################################################
    #  Subproblems multiplicity                                                            #
    ########################################################################################
    subproblems = getsubproblems(dec)
    # only one subproblem
    specify!(subproblems[1], lower_multiplicity = 0, upper_multiplicity = 20, solver = route_pricing_callback)

    return cvrp, x, dec
end