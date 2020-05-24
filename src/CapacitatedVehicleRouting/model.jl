function model(d::Data, optimizer)
    cvrp = BlockModel(optimizer, bridge_constraints = false)

    @axis(VehicleTypes, [1])

    E = edges(data)

    @variable(cvrp, 0 <= x[v in VehicleTypes, e in E] <= 2, Int)
    @constraint(cvrp, cov[c in C],
        sum(x[v, e] for e in incidents(d, c), v in VehicleTypes) == 2
    )

    @objective(cvrp, Min, sum(dist(data, e) * x[v, e] for v in VehicleTypes, e in E))

    @dantzig_wolfe_decomposition(cvrp, dec, VehicleTypes)
    subproblems = getsubproblems(dec)
    specify!(subproblems[1], lower_multiplicity = 0, upper_multiplicity = 20)
    return cvrp, x, dec
end