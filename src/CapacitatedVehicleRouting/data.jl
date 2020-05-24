struct Data
    locations::Vector{Pair{Int, Int}} # first is depot
    demands::Vector{Int}
    capacity::Int
end

function data(filename::AbstractString)
    capacity = 0
    coords = Pair{Int,Int}[]
    demands = Int[]
    filepath = string(@__DIR__, "/instances/", filename)
    open(filepath) do file
        for line in eachline(file)
            println(line)
        end
    end
    return Data(coords, demands, capacity)
end