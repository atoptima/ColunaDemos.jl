module SingleModeMultiItemsLotSizing
    using JuMP, BlockDecomposition

    include("data.jl")
    include("model.jl")
    include("model2.jl") # for Benders debug purpose
end