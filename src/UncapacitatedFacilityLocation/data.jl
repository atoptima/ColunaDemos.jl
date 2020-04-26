mutable struct Data
    facilities::UnitRange{Int}
    cities::UnitRange{Int}
    openingcost::Vector{Int}
    linkingcost::Matrix{Int}
end

function Data(nbf::Int, nbc::Int) 
    return Data(1:nbf, 1:nbc, zeros(Int, nbf), zeros(Int, nbf, nbc))
end

function data(filename::AbstractString)
    data = Int[]
    filepath = string(@__DIR__ , "/instances/" , filename)
    open(filepath) do file
        for line in eachline(file)
            match(r"^FILE", line) != nothing && continue #  jump file name
            for pieceofdata in split(line)
                push!(data, parse(Int, pieceofdata))
            end
        end
    end

    nbfacilites = data[1]
    nbcities = data[2]
    zero = data[3]

    dataufl = Data(data[1], data[2])

    offset = 3
    
    for f in data.facilities
        dataufl.openingcost[f] = data[offset + 1]
        dataufl.linkingcost[f, :] = data[offset + 2 : offset + 2 + nbcities]
        offset += 2 + nbcities
    end
    return dataufl
end

function show(io::IO, d::Data)
    println(io, "Uncapacitated Facility Location dataset.")
    println(io, "nb facilities = $(length(d.facilities)) and nb cities = $(length(d.cities))")
end
