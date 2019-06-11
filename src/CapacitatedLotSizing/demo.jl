##############################################################################################################
# Coluna implementation for the Capacitated Lot-sizing Problem
#
# Compact formulation:
#
# \min \sum_{i=1}^{NI} \sum_{t=1}^{NT} pc_{i,t} x_{i,t} + sc_{i,t} y_{i,t} + hc_{i,t} s_{i,t}
# Subject to
# s_{i,0}, s_{i,T} = 0
# \sum_{i=1}^{NT} pt_{i,t} x_{i,t} + st_{i,t} y_{i,t} \leq cap_{t}, \forall t = 1, \dots, NT
# s_{i,t-1} + x_{i,t} = d_{i,t} + s_{i,t}, \forall i = 1, \dots, NI; t = 1, \dots, NT
# x_{i,t} \leq M y_{i,t}, \forall i = 1, \dots, NI; t = 1, \dots, NT
# y_{i,t} \in \{0, 1\}, \forall i = 1, \dots, NI; t = 1, \dots, NT
# x_{i,t}, s{i,t} \geq 0, \forall i = 1, \dots, NI; t = 1, \dots, NT
#
# PER ITEM DECOMPOSITION
#
# Master problem
#
# \min \sum_{i=1}^{NI} \sum_{k \in K_{i}} C_{k}^{i} \lambda_{k}^{i}
# Subject to
# \sum_{i=1}^{NI} \sum_{k \in K_{i}} coef_{k,t}^{i} \lambda_{k}^{i} \leq cap_{t}, \forall t = 1, \dots, NT
# \sum_{k \in K_{i}} \lambda_{k}^{i} \geq 1, \forall i = 1, \dots, NI [CONVEXITY CONSTRAINT]
# \lambda_{k \in K_{i}} \in \{0, 1\}, \forall i = 1, \dots, NI, k \in K_{i}
# ====>>>>> OBS.: coef_{k,t}^{i} comes from pricing
#
# Pricing subproblems (one for each item)
# [DEF: f(x_{i}, y_{i}, s_{i}) = \sum_{t=1}^{NT} pc_{i,t} x_{i,t} + sc_{i,t} y_{i,t} + hc_{i,t} s_{i,t}]
#
# \min f(x_{i}, y_{i}, s_{i}) - (\sum_{t=1}^{NT} pt_{i,t} x_{i,t} \mu_{t} - st_{i,t} y_{i,t} \mu_{t}) - \p_{i}
# Subject to
# s_{i,0}, s_{i,T} = 0
# s_{i,t-1} + x_{i,t} = d_{i,t} + s_{i,t}, \forall t = 1, \dots, NT
# x_{i,t} \leq M y_{i,t}, \forall t = 1, \dots, NT
# y_{i,t} \in \{0, 1\}, \forall t = 1, \dots, NT
# x_{i,t}, s{i,t} \geq 0, \forall t = 1, \dots, NT
##############################################################################################################
push!(LOAD_PATH, "modules/")

using JuMP
using BlockDecomposition
using Coluna
using Gurobi, GLPK, CPLEX

import Data
import Model

using Base.CoreLogging, Logging
# global_logger(ConsoleLogger(stderr, LogLevel(-3)))

appfolder = dirname(@__FILE__)

# Not working with CPLEX
coluna = JuMP.with_optimizer(Coluna.Optimizer,
                             default_optimizer = with_optimizer(GLPK.Optimizer))

inst = Data.readData("$appfolder/testSmall")

model, x, y, s, dec = Model.cg_clsp(inst, coluna)

print(model)

optimize!(model)
