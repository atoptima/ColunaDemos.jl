function model(data::Data, optimizer)
    ufl = BlockModel(optimizer)

    @axis(F, data.facilities)

    @variable(ufl, x[f in F, c in data.cities], Bin) # 1 if f supplies c
    @variable(ufl, y[f in F], Bin) # 1 if y open

    @constraint(ufl, cov[c in data.cities], sum(x[f,c] for f in F) == 1)

    @constraint(ufl, open[f in F, c in data.cities], x[f,c] <= y[f])

    @objective(ufl, Min,
        sum(data.linkingcost[f,c]*x[f,c] for f in F, c in data.cities) + sum(data.openingcost[f]*y[f] for f in F)
    )

    @benders_decomposition(ufl, dec, F)
    return ufl, x, y, dec
end