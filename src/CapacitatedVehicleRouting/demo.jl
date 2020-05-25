module CapacitatedVehicleRouting
    using JuMP, BlockDecomposition, LightGraphs, MathOptInterface
    const MOI = MathOptInterface

    include("data.jl")
    include("model.jl")
end