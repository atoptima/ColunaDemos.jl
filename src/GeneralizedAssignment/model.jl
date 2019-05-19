function model(data::Data, optimizer)
    gap = BlockModel(optimizer)

    @axis(M, data.machines)

    @variable(gap, x[m in M, j in data.jobs], Bin)

    @constraint(gap, cov[j in data.jobs],
            sum(x[m,j] for m in M) >= 1)

    @constraint(gap, knp[m in M],
            sum(data.weight[j,m]*x[m,j] for j in data.jobs) <= data.capacity[m])

    @objective(gap, Min,
            sum(data.cost[j,m]*x[m,j] for m in M, j in data.jobs))

    @dantzig_wolfe_decomposition(gap, dec, M)

    return (gap, x)
end

