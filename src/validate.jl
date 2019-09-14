function compare_dss_to_pmd(sol_dss, sol_pmd, data_pmd;
        vm_rtol = 1E-6,
        verbose = true,
        buses_compare_ll=[]
    )
    name2id = Dict([(b["name"], k) for (k,b) in data_pmd["bus"] if haskey(b, "name") && b["name"]!=""])

    δ_max = 0
    for (name, sol_dss_bus) in sol_dss["bus"]
        id = name2id[name]
        vbase = data_pmd["bus"][id]["base_kv"]*1E3/sqrt(3)
        cs = sort(collect(keys(sol_dss_bus["vm"])))
        vm_pmd = sol_pmd["solution"]["bus"][id]["vm"]
        va_pmd = sol_pmd["solution"]["bus"][id]["va"]
        vm_dss = sol_dss_bus["vm"]
        va_dss = sol_dss_bus["va"]
        if name in buses_compare_ll
            @assert(length(cs)>1, "Bus $name only has one conductor, so it can not be compared in a line-to-line fashion.")
            for (i,c) in enumerate(cs)
                c_fr = c
                c_to = cs[mod(i+1,length(cs))+1]
                v_pmd_fr = vm_pmd[c_fr]*exp(im*va_pmd[c_fr])
                v_pmd_to = vm_pmd[c_to]*exp(im*va_pmd[c_to])
                v_dss_fr = vm_dss[c_fr]*exp(im*va_dss[c_fr])/vbase
                v_dss_to = vm_dss[c_to]*exp(im*va_dss[c_to])/vbase
                vm_pmd_frto = abs(v_pmd_fr-v_pmd_to)/sqrt(3)
                vm_dss_frto = abs(v_dss_fr-v_dss_to)/sqrt(3)
                δ = abs(vm_dss_frto-vm_pmd_frto)/abs(vm_dss_frto)
                δ_max = max(δ_max, δ)
                if δ >= vm_rtol && verbose
                    println("Deviation at bus $name.$c_fr->$c_to of $δ:")
                    println("\tdss: $vm_dss_frto")
                    println("\tpmd: $vm_pmd_frto")
                end
            end
        else
            for c in cs
                vm_pmd_c = vm_pmd[c]
                vm_dss_c = vm_dss[c]/vbase
                δ = abs(vm_pmd_c-vm_dss_c)/abs(vm_dss_c)
                δ_max = max(δ_max, δ)
                if δ > vm_rtol && verbose
                    println("Deviation at bus $name.$c of $δ:")
                    println("\tdss: $vm_dss_c")
                    println("\tpmd: $vm_pmd_c")
                end
            end
        end
    end
    return δ_max
end
