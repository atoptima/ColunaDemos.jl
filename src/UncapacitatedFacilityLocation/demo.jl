module UncapacitatedFacilityLocation
    using JuMP, BlockDecomposition

    import Base.show, Base.print

    include("data.jl")
    include("model.jl")
end