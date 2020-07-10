function model(d::Data, optimizer)
    I = collect(1:length(d.weight))
    bpp = BlockModel(optimizer)

    @axis(BinsType, [1])

    @variable(bpp, x[k in BinsType, i in I], Bin)
    @variable(bpp, y[k in BinsType], Bin)

    @constraint(bpp, sp[i in I], sum(x[k, i] for k in BinsType) == 1)
    @constraint(bpp, ks[k in BinsType], sum(d.weight[i] * x[k, i] for i in I) - y[k] * d.Q <= 0)
    
    @objective(bpp, Min, sum(y[k] for k in BinsType))

    @dantzig_wolfe_decomposition(bpp, dec, BinsType)
    subproblems = BlockDecomposition.getsubproblems(dec)
    specify!.(subproblems, lower_multiplicity = 0, upper_multiplicity = length(I))

    return bpp, x, y, dec
end
