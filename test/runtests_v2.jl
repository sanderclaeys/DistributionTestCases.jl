import PowerModels
PMs = PowerModels
import PowerModelsDistribution
PMD = PowerModelsDistribution
import DistributionTestCases
DTC = DistributionTestCases

using Compat.Test
import Memento

import JuMP
import Ipopt
ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1E-10)
dss_tolerance = 1E-6
# Suppress warnings during testing.
Memento.setlevel!(Memento.getlogger(PowerModels), "error")

@testset "DistributionTestCases" begin

    @testset "validate test cases" begin

        forms = Dict(
            #"ACP"=>Dict(:type=>PMs.ACPPowerModel, :run_method=>PMD.run_mc_pf),
            "IVR"=>Dict(:type=>PMs.IVRPowerModel, :run_method=>PMD.run_mc_pf_iv),
        )

        for (name, form) in forms
            @testset "ieee13 - $name" begin
                path = DTC.CASE_PATH["IEEE13"]
                data_pmd = PMD.parse_file(path)

                sol_dss = DTC.get_soldss_opendssdirect(path, tolerance=dss_tolerance)
                sol_pmd = form[:run_method](data_pmd, form[:type], ipopt_solver)

                δ_max = DTC.compare_dss_to_pmd(sol_dss, sol_pmd, data_pmd, verbose=false)
                @test δ_max <= 2E-7
            end
            @testset "ieee34 - $name" begin
                path = DTC.CASE_PATH["IEEE34"]
                data_pmd = PMD.parse_file(path)

                sol_dss = DTC.get_soldss_opendssdirect(path, tolerance=dss_tolerance)
                sol_pmd = form[:run_method](data_pmd, form[:type], ipopt_solver)

                δ_max = DTC.compare_dss_to_pmd(sol_dss, sol_pmd, data_pmd, verbose=false)
                @test δ_max <= 2E-7
            end
            @testset "ieee123 - $name" begin
                path = DTC.CASE_PATH["IEEE123"]
                data_pmd = PMD.parse_file(path)

                sol_dss = DTC.get_soldss_opendssdirect(path, tolerance=dss_tolerance)
                sol_pmd = form[:run_method](data_pmd, form[:type], ipopt_solver)

                δ_max = DTC.compare_dss_to_pmd(sol_dss, sol_pmd, data_pmd,
                    buses_compare_ll=["610"], verbose=false)
                @test δ_max <= 5E-6
            end
            @testset "lvtestcase t=1000 - $name" begin
                path = DTC.CASE_PATH["LVTestCase"][1000]
                data_pmd = PMD.parse_file(path)

                sol_dss = DTC.get_soldss_opendssdirect(path, tolerance=dss_tolerance)
                sol_pmd = form[:run_method](data_pmd, form[:type], ipopt_solver)

                δ_max = DTC.compare_dss_to_pmd(sol_dss, sol_pmd, data_pmd, verbose=false)
                @test δ_max <= 2E-7
            end
        end
    end
end
