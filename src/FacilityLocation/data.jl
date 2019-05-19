struct Data
    customers::UnitRange{Int}
    factories::UnitRange{Int}
    capacities::Vector{Int}
    fixedcosts::Vector{Int}
    costs::Matrix{Int}
end
  
function Data(path_file::AbstractString)
    scan = Scan(path_file)
    nbcustomers = next(scan, Int)
    nbfactories = next(scan, Int)
    return DataFl(1:nbcustomers,
                  1:nbfactories,
                  nextarray(scan, Int, nbfactories),
                  nextarray(scan, Int, nbfactories),
                  nextmatrix(scan, Int, nbcustomers, nbfactories))
end
  
  
  
  