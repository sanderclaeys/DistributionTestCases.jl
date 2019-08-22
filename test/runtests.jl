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
