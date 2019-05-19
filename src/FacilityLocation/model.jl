function model(data::DataFl, solver)
    fl = BlockModel(solver = solver)
  
    @variable(fl, 0 <= x[i in data.customers, j in data.factories] <= 1 )
    @variable(fl, y[j in data.factories], Bin)
  
    @constraint(fl, cov[i in data.customers],
                  sum( x[i, j] for j in data.factories ) >= 1)
  
    @constraint(fl, knp[j in data.factories],
                  sum( x[i, j] for i in data.customers ) <= y[j] * data.capacities[j])
  
    @objective(fl, Min,
                  sum( data.costs[i,j] * x[i, j] for j in data.factories, i in data.customers)
                  + sum( data.fixedcosts[j] * y[j] for j in data.factories) )
  
    function benders_fct(varname::Symbol, varid::Tuple)
      if varname == :x
        return (:B_SP, 0)
      else
        return (:B_MASTER, 0)
      end
    end
    add_Benders_decomposition(fl, benders_fct)
    return (fl, x, y)
end