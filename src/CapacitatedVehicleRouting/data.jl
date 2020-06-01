struct Data
    locations::Vector{Pair{Int, Int}} # first is depot
    demands::Vector{Int}
    capacity::Int
    totaldemand::Int
end

function data(filename::AbstractString)
    capacity = 0
    coords = Pair{Int,Int}[]
    demands = Int[]
    filepath = string(@__DIR__, "/instances/", filename)
    open(filepath) do file
        for line in eachline(file)
            m = match(r"CAPACITY : (\d+)", line)
            if m !== nothing && length(m.captures) == 1
                capacity = parse(Int, m.captures[1])
                continue
            end
            m = match(r"^(\d+) (\d+)", line)
            if m !== nothing && length(m.captures) == 2
                push!(demands, parse(Int, m.captures[2]))
                continue
            end
            m = match(r"^ (\d+) (\d+) (\d+)", line)
            if m !== nothing && length(m.captures) == 3
                x = parse(Int, m.captures[2])
                y = parse(Int, m.captures[3])
                push!(coords, Pair{Int,Int}(x, y))
                continue
            end
        end
    end
    totaldemand = sum(demands)
    return Data(coords, demands, capacity, totaldemand)
end

function instance_edges(data::Data)
    edges = Tuple{Int, Int}[]
    for i in 1:length(data.locations) - 1, j in i + 1:length(data.locations)
        push!(edges, (i, j))
    end
    return edges
end

function incidents(data::Data, c)
    edges = Tuple{Int, Int}[]
    for c2 in 1:length(data.locations)
        if c < c2
            push!(edges, (c, c2))
        elseif c > c2
            push!(edges, (c2, c))
        end
    end
    return edges
end

function dist(data, e)
    i, j = e
    x1 = data.locations[i].first
    x2 = data.locations[j].first
    y1 = data.locations[i].second
    y2 = data.locations[j].second
    return round(sqrt((x1 - x2)^2 + (y1 - y2)^2))
end

customers(data::Data) = 2:length(data.locations)
demand(data::Data, c) = data.demands[c]
capacity(data::Data) = data.capacity
totaldemand(data::Data) = data.totaldemand