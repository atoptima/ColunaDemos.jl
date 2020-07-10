mutable struct Data
    name::AbstractString # Instance name
    Q::Int # Bin capacity
    weight::Vector{Int} # Items weights
end

function data(filename::AbstractString)
    databpp = Data("", 0, Array{Int}(undef, 0))

    databpp.name = replace(replace(filename, r".*/" => ""), r"\..*" => "")

    raw = readdlm(filename, ' ', Int64)
    databpp.Q = raw[2] # Bin capacity
    databpp.weight = raw[3:end] # Items weights

    return databpp
end
