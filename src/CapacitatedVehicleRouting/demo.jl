module CapacitatedVehicleRouting
    using JuMP, BlockDecomposition, LightGraphs, MathOptInterface, GLPK
    const MOI = MathOptInterface
    const BD = BlockDecomposition

    include("data.jl")
    include("model.jl")
end