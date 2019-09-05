struct Data
    nbcustomers::Int
    nbfacilities::Int
    capacities::Vector{Int}
    fixedcosts::Vector{Int}
    costs::Matrix{Int}
end
  
function data(path_file::AbstractString)
    scan = Scan(path_file)
    nbcustomers = next(scan, Int)
    nbfacilities = next(scan, Int)
    return Data(nbcustomers,
                  nbfacilities,
                  nextarray(scan, Int, nbfacilities),
                  nextarray(scan, Int, nbfacilities),
                  nextmatrix(scan, Int, nbcustomers, nbfacilities))
end
  
  
  
  
