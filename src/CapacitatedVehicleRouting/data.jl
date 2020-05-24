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
            m = match(r"CAPACITY : (\d+)", line)
            if length(m.captures) == 1
                capacity = m.captures[1]
                continue
            end
            m = match(r"^(\d+) (\d+)", line)
            if length(m.captures) == 2
                push!(demands, m.captures[2])
                continue
            end
            m = match(r"^ (\d+) (\d+) (\d+)", line)
            if length(m.captures) == 3
                push!(coords, Pair{Int,Int}(m.captures[2], m.captures[3]))
                continue
            end
            println(line)
        end
    end
    return Data(coords, demands, capacity)
end