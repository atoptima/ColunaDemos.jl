module CapacitatedVehicleRouting
    using JuMP, BlockDecomposition, LightGraphs

    include("data.jl")
    include("model.jl")
end