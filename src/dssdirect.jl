import PowerModelsDistribution
PMD = PowerModelsDistribution
import PowerModels
PMs = PowerModels
import OpenDSSDirect
ODD = OpenDSSDirect
import Ipopt
import JuMP


function get_soldss_opendssdirect(dss_path::AbstractString; tolerance=missing)
    dir = pwd()
    ODD.Basic.ClearAll()
    ODD.dss("compile $dss_path")

    if !ismissing(tolerance)
        ODD.Solution.Convergence(tolerance)
        ODD.Solution.Solve()
    end

    sol_dss = Dict{String, Any}()
    # buses
    sol_dss["bus"] = Dict{String, Any}()
    bnames = ODD.Circuit.AllBusNames()
    for bname in bnames
        ODD.Circuit.SetActiveBus(bname)
        sol_dss["bus"][bname] = Dict("vm"=>Dict{Int, Float64}(), "va"=>Dict{Int, Float64}())
        v = ODD.Bus.Voltages()
        for (i,c) in enumerate(ODD.Bus.Nodes())
            sol_dss["bus"][bname]["vm"][c] = abs(v[i])
            sol_dss["bus"][bname]["va"][c] = angle(v[i])
        end
    end
    # restore original directory
    cd(dir)
    return sol_dss
end
