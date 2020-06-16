function model(d::Data, optimizer)
    csp = BlockModel(optimizer)

    xub = [ min(d.orders[o].demand, floor(d.stocksheetswidth/d.orders[o].width))
            for o in 1:d.nborders ]

    @axis(SheetTypes, [1])

    @variable(csp, 0 <= x[s in SheetTypes, o in 1:d.nborders] <= xub[o], Int)
    @variable(csp, y[s in SheetTypes], Bin)

    @constraint(csp, cov[o in 1:d.nborders], 
        sum(x[s, o] for s in SheetTypes) >= d.orders[o].demand
    )
 
    @constraint(csp, knp[s in SheetTypes],
                sum(x[s, o] * d.orders[o].width for o in 1:d.nborders)
                - y[s] * d.stocksheetswidth <= 0)

    @objective(csp, Min, sum(y[s] for s in SheetTypes))

    # setting Dantzig Wolfe composition: one subproblem per machine
    @dantzig_wolfe_decomposition(csp, dec, SheetTypes)
    subproblems = BlockDecomposition.getsubproblems(dec)
    specify!.(subproblems, lower_multiplicity = 0, upper_multiplicity = 100)

    return csp, x, y, dec
end