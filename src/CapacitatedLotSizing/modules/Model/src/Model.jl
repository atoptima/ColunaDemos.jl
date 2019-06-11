module Model

using JuMP
using BlockDecomposition
using Coluna
using Gurobi
using Data

export cg_clsp

function cg_clsp(inst::InstanceData, optimizer)

    bigM = Array{Float64}(undef, inst.numItems, inst.numPer)

    bigM = compute_bigM_coeffs(inst)

    clsp = BlockModel(optimizer, bridge_constraints=false)

    @axis(I, 1:inst.numItems, false, lowerbound = 1)
    T = 1:inst.numPer
    TT = 2:inst.numPer

    # Create variables
    @variable(clsp, x[i in I,t in T] >= 0)	# Producao
    @variable(clsp, y[i in I,t in T], Bin)	# Setup
    @variable(clsp, s[i in I,t in T] >= 0)	# Estoque

    # Create objective function
    @objective(clsp, Min, sum(inst.pc * x[i,t] + inst.sc[i] * y[i,t] + inst.hc[i] * s[i,t] for i in I, t in T))

    # Create capacity constraints
    @constraint(clsp, capConstr[t in T], sum(inst.pt[i] * x[i,t] + inst.st[i] * y[i,t] for i in I) <= inst.cap)

    # Create inventory balance constraints
    @constraint(clsp, iniBalConstr[i in I,1], x[i,1] - s[i,1] == inst.dem[i,1])
    @constraint(clsp, balConstr[i in I,t in TT], s[i,t-1] + x[i,t] - s[i,t] == inst.dem[i,t])

    # Create setup constraints
    @constraint(clsp, setupConstr[i in I,t in T], x[i,t] - (bigM[i,t] * y[i,t]) <= 0)

    @dantzig_wolfe_decomposition(clsp, dec, I)

    return clsp, x, y, s, dec

end

end
