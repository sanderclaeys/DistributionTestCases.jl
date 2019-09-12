function compare_dss_to_pmd(sol_dss, sol_pmd, data_pmd;
        vm_atol = 1E-6,
        verbose = true,
        skip_bus_by_name=[]
    )
    name2id = Dict([(b["name"], k) for (k,b) in data_pmd["bus"] if haskey(b, "name") && b["name"]!=""])

    vm_dev_max = 0
    for (name, sol_dss_bus) in sol_dss["bus"]
        id = name2id[name]
        vbase = data_pmd["bus"][id]["base_kv"]*1E3/sqrt(3)
        for c in keys(sol_dss_bus["vm"])
            vm_pmd = sol_pmd["solution"]["bus"][id]["vm"][c]
            vm_dss = sol_dss_bus["vm"][c]/vbase
            vm_dev = abs(vm_pmd-vm_dss)
            vm_dev_max = max(vm_dev_max, vm_dev)
            if vm_dev > vm_atol && verbose
                println("Deviation at bus $name.$c of $vm_dev:")
                println("\tdss: $vm_dss")
                println("\tpmd: $vm_pmd")
            end
        end
    end
    return vm_dev_max
end
