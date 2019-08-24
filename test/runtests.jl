import PowerModels
PMs = PowerModels
import PowerModelsDistribution
PMD = PowerModelsDistribution
import PMDTestFeeders
TF = PMDTestFeeders

using Compat.Test
import Memento

import JuMP
import Ipopt
ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, print_level=0, tol=1E-10)

# Suppress warnings during testing.
Memento.setlevel!(Memento.getlogger(PowerModels), "error")

@testset "PMDTestFeeders" begin
    @testset "validate test cases" begin
        @testset "ieee13" begin
            path = "$(TF.BASE_DIR)/src/data/ieee13/ieee13_pmd.dss"
            sol_dss = TF.get_soldss_opendssdirect(path)
            data_pmd = TF.get_ieee13()
            sol_pmd = PMD.run_ac_tp_pf_lm(data_pmd, ipopt_solver)["solution"]
            mismatch = TF.validate_dssdirect_sols(sol_pmd, sol_dss, data_pmd,verbose=false)
            @test mismatch <= 2E-6
        end
        @testset "ieee34" begin
            path = "$(TF.BASE_DIR)/src/data/ieee34/ieee34_pmd.dss"
            sol_dss = TF.get_soldss_opendssdirect(path)
            data_pmd = TF.get_ieee34()
            sol_pmd = PMD.run_ac_tp_pf_lm(data_pmd, ipopt_solver)["solution"]
            mismatch = TF.validate_dssdirect_sols(sol_pmd, sol_dss, data_pmd,verbose=false)
            @test mismatch <= 8.5E-7
        end
        @testset "ieee123" begin
            path = "$(TF.BASE_DIR)/src/data/ieee123/ieee123_pmd.dss"
            sol_dss = TF.get_soldss_opendssdirect(path)
            data_pmd = TF.get_ieee123()
            sol_pmd = PMD.run_ac_tp_pf_lm(data_pmd, ipopt_solver)["solution"]
            mismatch = TF.validate_dssdirect_sols(sol_pmd, sol_dss, data_pmd,verbose=false)
            @test mismatch <= 1E-4
        end
        @testset "lvtestcase t=1000" begin
            path = "$(TF.BASE_DIR)/src/data/lvtestcase/snapshots/lvtestcase_pmd_t1000.dss"
            sol_dss = TF.get_soldss_opendssdirect(path)
            data_pmd = TF.get_lvtestcase(t=1000)
            sol_pmd = PMD.run_ac_tp_pf_lm(data_pmd, ipopt_solver)["solution"]
            mismatch = TF.validate_dssdirect_sols(sol_pmd, sol_dss, data_pmd,verbose=false)
            @test mismatch <= 1E-7
        end
    end

    @testset "validate simplification" begin
        # validate simplification on IEEE13
        # set transformer tap to 1
        data_pmd = PMDTestFeeders.get_ieee13()
        for (_, trans) in data_pmd["trans"]
            trans["tm"] = PMs.MultiConductorVector(ones(3))
        end

        # first validate voltage drop
        #!############################
        data_pmd_v1 = deepcopy(data_pmd)
        PMDTF.simplify_feeder!(data_pmd_v1, loads_to_wye_pq=false)

        sol = PMD.run_ac_tp_pf_lm(data_pmd, ipopt_solver)
        sol_v1 = PMD.run_ac_tp_pf_lm(data_pmd_v1, ipopt_solver)
        vm_diff_max = maximum(vcat([abs.(sol["solution"]["bus"][id]["vm"].values-sol_v1["solution"]["bus"][id]["vm"].values) for (id, bus) in sol_v1["solution"]["bus"]]...))
        @test vm_diff_max<=1E-4

        # now validate load delta-wye conversion
        #!############################
        # remove voltage-dependency for original feeder for comparison
        for (_, load) in data_pmd["load"]
            load["model"] = "constant_power"
        end
        # set series impedance to zero to end up with balanced voltages everywhere
        for (_, branch) in data_pmd["branch"]
            branch["br_r"] *= 1E-10
            branch["br_x"] *= 1E-10
        end

        # create fully simplified feeder
        data_pmd_v2 = deepcopy(data_pmd)
        simplify_feeder!(data_pmd_v2)

        pm = PMs.build_model(data_pmd, PMs.ACPPowerModel, PMD.post_tp_pf_lm, ref_extensions=[PMD.ref_add_arcs_trans!], multiconductor=true)
        sol = PMs.optimize_model!(pm, ipopt_solver)
        pm_v2 = PMs.build_model(data_pmd_v2, PMs.ACPPowerModel, PMD.post_tp_pf_lm, ref_extensions=[PMD.ref_add_arcs_trans!], multiconductor=true)
        sol_v2 = PMs.optimize_model!(pm_v2, ipopt_solver)

        # check that loads draw same power under balanced conditions
        value(x) = isa(x, Number) ? x : JuMP.value(x)
        global err = 0
        for id in PMs.ids(pm, :load)
            ncnds = data_pmd["conductors"]
            pd = [value(PMs.var(pm, pm.cnw, c, :pd, id)) for c in 1:ncnds]
            qd = [value(PMs.var(pm, pm.cnw, c, :qd, id)) for c in 1:ncnds]
            pd_v2 = [value(PMs.var(pm_v2, pm_v2.cnw, c, :pd, id)) for c in 1:ncnds]
            qd_v2 = [value(PMs.var(pm_v2, pm_v2.cnw, c, :qd, id)) for c in 1:ncnds]
            global err = max(err, maximum(abs.(pd-pd_v2)))
            global err = max(err, maximum(abs.(qd-qd_v2)))
        end
        @test(err <= 1E-9)
    end
end
