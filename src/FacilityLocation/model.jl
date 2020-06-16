function model(data::DataFl, optimizer)
    fl = BlockModel(optimizer)

    I = 1:data.nbcustomers
    J = 1:data.nbfacilities 

    @variable(fl, 0 <= x[i in I, j in J] <= 1)

    @variable(fl, y[j in J], Bin)

    @constraint(fl, cov[i in I],
                  sum( x[i, j] for j in J ) >= 1)

    @constraint(fl, knp[j in J],
                  sum( x[i, j] for i in I ) <= y[j] * data.capacities[j])

    @objective(fl, Min,
                  sum( data.costs[i,j] * x[i, j] for i in I, j in J)
                  + sum( data.fixedcosts[j] * y[j] for j in J) )

   @benders_decomposition(fl, dec, J)

    return fl, dec, x, y

end
