function model(data::DataSmMiLs, optimizer)
    mils = BlockModel(optimizer, bridge_constraints = false)

    @axis(I, 1:data.nbitems)
    T = 1:data.nbperiods
    D = [sum(d(data, i, t) for t in T) for i in I]

    @variable(mils, x[i in 1:data.nbitems, t in T] >= 0)
    @variable(mils, y[i in I, t in T] >= 0)

    @constraint(mils, singlemode[t in T], sum(y[i, t] for i in I) <= 1)

    @constraint(mils, setup[i in I, t in T], x[i, t] - D[i] * y[i, t] <= 0)

    @constraint(mils, cov[i in I, t in T], 
        sum(x[i, τ] for τ in 1:t) >= sum(d(data, i, τ) for τ in 1:t)
    )

    @objective(mils, Min, 
        sum(c(data, i, t) * x[i, t] for i in I, t in T) +
        sum(f(data, i, t) * y[i, t] for i in I, t in T)
    )

    @benders_decomposition(mils, dec, I)

    return mils, dec, x, y
end