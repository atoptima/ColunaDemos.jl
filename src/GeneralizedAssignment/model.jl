function model(data::Data, optimizer, use_direct_model = true)
    gap = BlockModel(optimizer, direct_model = use_direct_model)

    @axis(M, data.machines)

    @variable(gap, x[m in M, j in data.jobs], Bin)

    @constraint(gap, cov[j in data.jobs],
            sum(x[m,j] for m in M) >= 1)

    @constraint(gap, knp[m in M],
            sum(data.weight[j,m]*x[m,j] for j in data.jobs) <= data.capacity[m])

    @objective(gap, Min,
            sum(data.cost[j,m]*x[m,j] for m in M, j in data.jobs))

    @dantzig_wolfe_decomposition(gap, dec, M)
    subproblems = BlockDecomposition.getsubproblems(dec)
    specify!.(subproblems, lower_multiplicity = 0)
    return gap, x, dec
end

function model_with_penalties(data::Data, optimizer, use_direct_model = true)
    gap = BlockModel(optimizer, direct_model = use_direct_model)

    penalties = Float64[sum(data.cost[j,m] for m in data.machines) * 0.7 for j in data.jobs]
    penalties ./= length(data.machines)

    capacities = Int[ceil(data.capacity[m] * 0.9) for m in data.machines]

    max_nb_jobs_not_covered = ceil(0.12 * length(data.jobs))

    @axis(M, data.machines)

    @variable(gap, x[m in M, j in data.jobs], Bin)
    @variable(gap, y[j in data.jobs], Bin) #equals one if job not assigned

    @constraint(gap, cov[j in data.jobs], sum(x[m,j] for m in M) + y[j] >= 1)
    @constraint(gap, limit_pen, sum(y[j] for j in data.jobs) <= max_nb_jobs_not_covered)

    @constraint(gap, knp[m in M],
        sum(data.weight[j,m]*x[m,j] for j in data.jobs) <= capacities[m])

    @objective(gap, Min,
        sum(data.cost[j,m]*x[m,j] for m in M, j in data.jobs) +
        sum(penalties[j]*y[j] for j in data.jobs))

    @dantzig_wolfe_decomposition(gap, dec, M)
    subproblems = BlockDecomposition.getsubproblems(dec)
    specify!.(subproblems, lower_multiplicity = 0)

    return gap, x, y, dec
end

function model_with_penalty(data::Data, optimizer, use_direct_model = true)
    gap = BlockModel(optimizer, direct_model = use_direct_model)

    penalty = 10000

    @axis(M, data.machines)

    @variable(gap, x[m in M, j in data.jobs], Bin)
    @variable(gap, y[j in data.jobs], Bin) #equals one if job not assigned

    @constraint(gap, cov[j in data.jobs], sum(x[m,j] for m in M) + y[j] >= 1)

    @constraint(gap, knp[m in M],
        sum(data.weight[j,m]*x[m,j] for j in data.jobs) <= data.capacity[m])

    @objective(gap, Min,
        sum(data.cost[j,m]*x[m,j] for m in M, j in data.jobs) +
        sum(penalty*y[j] for j in data.jobs))

    @dantzig_wolfe_decomposition(gap, dec, M)
    subproblems = BlockDecomposition.getsubproblems(dec)
    specify!.(subproblems, lower_multiplicity = 0)

    return gap, x, y, dec
end

function model_max(data::Data, optimizer, use_direct_model = true)
    gap = BlockModel(optimizer, direct_model = use_direct_model)

    rewards = data.cost
    capacities = data.capacity

    @axis(M, data.machines)

    @variable(gap, x[m in M, j in data.jobs], Bin)
    @constraint(gap, cov[j in data.jobs], sum(x[m,j] for m in M) <= 1)

    @constraint(gap, knp[m in M],
        sum(data.weight[j,m]*x[m,j] for j in data.jobs) <= capacities[m])

    @objective(gap, Max, sum(rewards[j,m]*x[m,j] for m in M, j in data.jobs))

    @dantzig_wolfe_decomposition(gap, dec, M)
    subproblems = BlockDecomposition.getsubproblems(dec)
    specify!.(subproblems, lower_multiplicity = 0)

    return gap, x, dec
end

function max_model_with_subcontracts(data::Data, optimizer, use_direct_model = true)
    gap = BlockModel(optimizer, direct_model = use_direct_model)

    rewards = data.cost
    sub_rewards = Float64[sum(rewards[j,m] for m in data.machines) * 0.5 for j in data.jobs]
    sub_rewards ./= length(data.machines)

    capacities = Int[ceil(data.capacity[m] * 0.5) for m in data.machines]

    max_nb_jobs_subcontracted = ceil(0.15 * length(data.jobs))

    @axis(M, data.machines)

    @variable(gap, x[m in M, j in data.jobs], Bin)
    @variable(gap, y[j in data.jobs], Bin) #equals one if job is subcontracted

    @constraint(gap, pack[j in data.jobs], sum(x[m,j] for m in M) + y[j] <= 1)
    @constraint(gap, limit_sub, sum(y[j] for j in data.jobs) <= max_nb_jobs_subcontracted)

    @constraint(gap, knp[m in M],
        sum(data.weight[j,m]*x[m,j] for j in data.jobs) <= capacities[m])

    @objective(gap, Max,
        sum(rewards[j,m]*x[m,j] for m in M, j in data.jobs) +
        sum(sub_rewards[j]*y[j] for j in data.jobs))

    @dantzig_wolfe_decomposition(gap, dec, M)
    subproblems = BlockDecomposition.getsubproblems(dec)
    specify!.(subproblems, lower_multiplicity = 0)

    return gap, x, y, dec
end


function model_without_knp_constraints(data::Data, optimizer, use_direct_model = true)
    gap = BlockModel(optimizer, direct_model = use_direct_model)

    @axis(M, data.machines)

    @variable(gap, x[m in M, j in data.jobs], Bin)

    @constraint(gap, cov[j in data.jobs],
            sum(x[m,j] for m in M) >= 1)

    @objective(gap, Min,
            sum(data.cost[j,m]*x[m,j] for m in M, j in data.jobs))

    @dantzig_wolfe_decomposition(gap, dec, M)

    return gap, x, dec
end
