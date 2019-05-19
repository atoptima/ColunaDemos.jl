mutable struct Data
    machines::UnitRange{Int}
    jobs::UnitRange{Int}
    weight::Matrix{Int}
    cost::Matrix{Int}
    capacity::Vector{Int}
end

function Data(nbmachines::Int, nbjobs::Int) 
    return Data(1:nbmachines, 1:nbjobs, Matrix{Int}(undef, nbmachines,nbjobs),
                Matrix{Int}(undef, nbmachines, nbjobs), 
                Vector{Int}(undef, nbmachines))
end

function data(filename::AbstractString)
    data = Int[]
    filepath = string(@__DIR__ , "/instances/" , filename)
    open(filepath) do file
        for line in eachline(file)
            for pieceofdata in split(line)
                push!(data, parse(Int, pieceofdata))
            end
        end
    end

    datagap = Data(data[1], data[2])
    nbmachines = length(datagap.machines)
    nbjobs = length(datagap.jobs)

    offset = 2
    datagap.cost = reshape(data[offset+1 : offset+nbmachines*nbjobs], nbjobs, nbmachines)
    offset += nbmachines*nbjobs
    datagap.weight = reshape(data[offset+1 : offset+nbmachines*nbjobs], nbjobs, nbmachines)
    offset += nbmachines*nbjobs
    datagap.capacity = reshape(data[offset+1 : offset+nbmachines], nbmachines)
    return datagap
end

function show(io::IO, d::Data)
    println(io, "Generalized Assignment dataset.")
    println(io, "nb machines = $(length(d.machines)) and nb jobs = $(length(d.jobs))")
    println(io, "Capacities of machines : ")
    for m in d.machines
        println(io, "\t machine $m, capacity = $(d.capacity[m])")
    end

    println(io, "Ressource consumption of jobs : ")
    for j in d.jobs
        println(io, "\t job $j")
        for m in d.machines
            print(io, "\t\t on machines $m : consumption = $(d.weight[j,m])")
            println(io, " and cost = $(d.cost[j,m])")
        end
    end
end
