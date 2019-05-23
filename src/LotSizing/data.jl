# item data :r =, f = setup cost, s =, h = inventory cost
mutable struct DataSmMiLs
    nbitems
    nbperiods
    data
end

function data(filename::AbstractString)
    data = Int[]
    filepath = string(@__DIR__ , "/instances/" , filename)
    # nbitems nbperiods
    # demand setupcost prodcost
    open(filepath) do file
        for line in eachline(file)
            for pieceofdata in split(line)
                push!(data, parse(Int, pieceofdata))
            end
        end
    end
    nbitems = data[1]
    nbperiods = data[2]
    reshaped = reshape(data[3:end], 3, nbitems * nbperiods)
    return DataSmMiLs(nbitems, nbperiods, reshaped)
end

function d(data::DataSmMiLs, item::Int, period::Int)
    return data.data[1, (period - 1) * data.nbitems + item]
end

function s(data::DataSmMiLs, item::Int, period::Int)
    return data.data[2, (period - 1) * data.nbitems + item]
end

function c(data::DataSmMiLs, item::Int, period::Int)
    return data.data[3, (period - 1) * data.nbitems + item]
end

function show(io::IO, data::DataSmMiLs)
    println(io, "nbperiods = ", data.nbperiods, "  nbitems = ", data.nbitems)
    for i in 1:data.nbitems
        println(io, "> item ", i)
        for p in 1:data.nbperiods
            println(io, "\t > period ", p, " : demand = ", d(data,i,p), "  setupcost = ", s(data,i,p), "  prodcost = ", p(data, i, p))
        end
    end
end
