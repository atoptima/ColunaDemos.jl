module SingleModeMultiItemsLotSizing
    using JuMP, BlockDecomposition

    include("data.jl")
    include("model.jl")
end