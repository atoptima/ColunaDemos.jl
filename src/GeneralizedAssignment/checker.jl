function print_and_check_sol(data, gap, x)
    sol_is_ok = true
    assigned = Set{Int}()
    for m in data.machines
        w = 0.0
        for j in data.jobs
            if JuMP.value(x[m,j]) > 0.9999
                println("job $(j) attached to machine $(m)")
                push!(assigned, j)
                w += data.weight[j,m]
            end
        end
        println("Consumed ", w, " of machine ", m, ". Capacity is ",
                data.capacity[m], ".")
        if w > data.capacity[m]
            sol_is_ok = false
        end
    end
    if length(assigned) != length(data.jobs)
        println("Not all jobs were assigned.")
        sol_is_ok = false
    end
    if sol_is_ok
        println("Solution is feasible.")
    else
        println("Solution is not feasible. :(")
    end
    @show JuMP.objective_value(gap)
    return sol_is_ok
end
