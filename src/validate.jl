"""
This function validates the data model by obtaining an ACP PF solution,
and comparing the bus voltage phasors and load power against the data contained
in the specified OpenDSS output files.
"""
function validate(tppm::Dict, dss_output_vmva_path, dss_output_pdqd_path;
                            vm_atol=1.5E-4, va_atol_deg=0.05, pq_atol_kva=0.1)
    res_buses = parse_opendss_VLN_Node(dss_output_vmva_path, va_offset=-deg2rad(30))
    res_loads = parse_opendss_Power_elem_kVA(dss_output_pdqd_path)

    validate(tppm, res_buses, res_loads,
            vm_atol=vm_atol, va_atol_deg=va_atol_deg, pq_atol_kva=pq_atol_kva)
end


"""
This function validates the data model by obtaining an ACP PF solution,
and comparing the bus voltage phasors and load power against the data contained
in the specified OpenDSS output files.
"""
function validate(tppm::Dict, res_buses::Dict, res_loads::Dict;
                    vm_atol=1.5E-4, va_atol_deg=0.05, pq_atol_kva=0.1)
    pm = PMs.build_generic_model(tppm, PMs.ACPPowerModel, TPPMs.post_tp_opf_lm, multiconductor=true)
    sol = PMs.solve_generic_model(pm, Ipopt.IpoptSolver(print_level=1))
    # check the load power
    @testset "load power" begin
        for (load_name, res_load) in res_loads
            load_id = name2id(tppm["load"], load_name)
            sbase_kva = tppm["baseMVA"]*1E3
            for c in 1:3
                pd_kw_dss = (ismissing(res_load[:pd_kw][c])) ? 0 : res_load[:pd_kw][c]
                pd_kw_tppm = JuMP.getvalue(PMs.var(pm, pm.cnw, c, :pd, load_id))*sbase_kva
                pd_kw_diff = pd_kw_dss-pd_kw_tppm
                @test abs(pd_kw_diff) <= pq_atol_kva

                qd_kvar_dss = (ismissing(res_load[:qd_kvar][c])) ? 0 : res_load[:qd_kvar][c]
                qd_kvar_tppm = JuMP.getvalue(PMs.var(pm, pm.cnw, c, :qd, load_id))*sbase_kva
                qd_kvar_diff = qd_kvar_dss-qd_kvar_tppm
                @test abs(qd_kvar_diff) <= pq_atol_kva
            end
        end
    end
    # check the voltage phasors
    @testset "bus voltage" begin
        for (bus_name, res_bus) in res_buses
            bus_id = name2id(tppm["bus"], bus_name)
            vbase_kv = tppm["bus"]["$bus_id"]["base_kv"]
            for c in 1:3
                if !ismissing(res_bus[:vm_kv][c])
                    vm_dss = res_bus[:vm_kv][c]/(vbase_kv/sqrt(3))
                    vm_tppm = sol["solution"]["bus"]["$bus_id"]["vm"][c]
                    vm_diff = vm_dss-vm_tppm
                    @test abs(vm_diff)<=vm_atol

                    va_dss = res_bus[:va_rad][c]
                    va_tppm = sol["solution"]["bus"]["$bus_id"]["va"][c]
                    va_diff_deg = rad2deg(va_dss-va_tppm)
                    @test abs(va_diff_deg)<=va_atol_deg
                end
            end
        end
    end
end
