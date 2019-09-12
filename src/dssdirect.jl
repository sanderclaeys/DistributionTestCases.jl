import PowerModelsDistribution
PMD = PowerModelsDistribution
import PowerModels
PMs = PowerModels
import OpenDSSDirect
ODD = OpenDSSDirect
import Ipopt
import JuMP


function get_soldss_opendssdirect(dss_path::AbstractString)
    ODD.dss("compile $dss_path")
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
    return sol_dss
end


function validate_dssdirect(dss_path::AbstractString, data_pmd::Dict;
        ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-12),
        vm_atol = 1E-4,
        verbose = true
    )

    sol_pmd = PMD.run_tp_pf_lm(data_pmd, PMs.ACPPowerModel, ipopt_solver)["solution"]

    sol_dss = get_soldss_opendssdirect(dss_path)

    #
    name2id = Dict([(b["name"], k) for (k,b) in data_pmd["bus"] if haskey(b, "name") && b["name"]!=""])

    vm_diff_max = 0
    for (name, sol_dss_bus) in sol_dss["bus"]
        id = name2id[name]
        vbase = data_pmd["bus"][id]["base_kv"]*1E3/sqrt(3)
        bus_vm_diff_max = maximum(abs.([val/vbase-sol_pmd["bus"][id]["vm"][c]  for (c, val) in sol_dss_bus["vm"]]))
        vm_diff_max = max(bus_vm_diff_max, vm_diff_max)
        if verbose
            if isnan(bus_vm_diff_max) || bus_vm_diff_max > vm_atol
                println("Deviation at bus $name: $bus_vm_diff_max")
            end
        end
    end
    return vm_diff_max
    @test vm_diff_max<=vm_atol
end


function validate_dssdirect_sols(sol_pmd, sol_dss, data_pmd;
        ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-10),
        vm_atol = 1E-6,
        verbose = true,
        skip_bus_by_name=[]
    )
    name2id = Dict([(b["name"], k) for (k,b) in data_pmd["bus"] if haskey(b, "name") && b["name"]!=""])

    vm_diff_max = 0
    for (name, sol_dss_bus) in sol_dss["bus"]
        if !(name in skip_bus_by_name)
            id = name2id[name]
            vbase = data_pmd["bus"][id]["base_kv"]*1E3/sqrt(3)
            bus_vm_diff_max = maximum(abs.([val/vbase-sol_pmd["bus"][id]["vm"][c]  for (c, val) in sol_dss_bus["vm"]]))
            vm_diff_max = max(bus_vm_diff_max, vm_diff_max)
            if verbose
                if isnan(bus_vm_diff_max) || bus_vm_diff_max > vm_atol
                    println("Deviation at bus $name: $bus_vm_diff_max")
                end
            end
        end
    end
    return vm_diff_max
end
