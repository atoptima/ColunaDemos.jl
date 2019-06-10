function model(data::DataSmMiLs, optimizer)
    mils = BlockModel(optimizer, bridge_constraints = false)

    @axis(S, 1:data.nbscenarios)

    I = 1:data.nbitems
    T = 1:data.nbperiods

    D = zeros(Int, data.nbitems, data.nbperiods, data.nbperiods, data.nbscenarios)
    for i in I
        for t in T
            for l in t:data.nbperiods
                for s in S
                    f = (l > t ? l-1 : t)
                    D[i,t,l,s] = D[i,t,f,s] + d(data, i, l, s)
                end
            end
        end
    end
    

    @variable(mils, x[i in I, t in T, l in T, s in S] >= 0)

    @show x
    
    @variable(mils, 0 <= y[i in I, t in T] <= 1)

    @show y

    @constraint(mils, singlemode[t in T],
                sum(y[i, t] for i in I) <= 1
                )

    @constraint(mils, setup[i in I, t in T, s in S],
                sum(x[i, t, l, s] for  l in t:data.nbperiods) -  y[i, t] <= 0
                )

    @constraint(mils, cov[i in I,  s in S], 
                sum(x[i, 1, t, s] for t in T) >= 1
                )

    last = data.nbperiods-1
    @constraint(mils, balance[i in I, t in 1:last, s in S],
                sum(x[i, t+1, τ, s] for τ in t+1:data.nbperiods) == sum(x[i, τ, t, s] for τ in 1:t)  
                )

    @constraint(mils, zero[i in I, t in 2:data.nbperiods, s in S],
                sum(x[i, t, τ, s] for τ in 1:t-1) <= 0 
                )

    @objective(mils, Min, 
               sum(c(data, i, t) * D[i, t, l, s] * x[i, t, l, s] for i in I, t in T, l in t:data.nbperiods, s in S) +
               sum(s(data, i, t) * y[i, t] for i in I, t in T)
               )

    @benders_decomposition(mils, dec, S)    

    return mils, dec, x, y
end
