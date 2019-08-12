function model(d::Data, optimizer)
    csp = BlockModel(optimizer, bridge_constraints = false)

    xub = [ min(d.orders[o].demand, floor(d.stocksheetswidth/d.orders[o].width))
            for o in 1:d.nborders ]

    @axis(Sheets, 1:100, Identical)

    @variable(csp, 0 <= x[s in Sheets, o in 1:d.nborders] <= xub[o], Int)
    @variable(csp, y[s in Sheets], Bin)

    @constraint(csp, cov[o in 1:d.nborders], sum(x[s, o] for s in Sheets) >= d.orders[o].demand)

    @constraint(csp, knp[s in Sheets],
                sum(x[s, o] * d.orders[o].width for o in 1:d.nborders)
                - y[s] * d.stocksheetswidth <= 0)

    @objective(csp, Min, y)

    # setting Dantzig Wolfe composition: one subproblem per machine
    @set_dantzig_wolfe_decompostion(csp, dec, Sheets)

    return (csp, x, y)
end