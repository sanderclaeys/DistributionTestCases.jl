import PowerModels
PMs = PowerModels
import ThreePhasePowerModels
TPPMs = ThreePhasePowerModels
TTF = TPPMTestFeeders

using Compat.Test
import Memento
import Ipopt

ipopt_solver = Ipopt.IpoptSolver(print_level=0)

# Suppress warnings during testing.
Memento.setlevel!(Memento.getlogger(PowerModels), "error")

@testset "TPPMTestFeeders" begin
    @testset "validate feeders" begin
        @testset "IEEE13" begin
            tppm = TTF.get_IEEE13()
            TTF.validate(tppm, "data/IEEE13NodecktAssets_VLN_Node.txt",  "data/IEEE13NodecktAssets_Power_elem_kVA.txt")
        end
    end

    @testset "convert PQ" begin
        # solve original
        tppm = TTF.get_IEEE13()
        pm = PMs.build_generic_model(tppm, PMs.ACPPowerModel, TPPMs.post_tp_opf_lm, multiconductor=true)
        sol = PMs.solve_generic_model(pm, ipopt_solver)

        #  create and solve PQ version
        tppm_pq = TTF.convert_to_PQ(tppm)
        pm_pq = PMs.build_generic_model(tppm_pq, PMs.ACPPowerModel, TPPMs.post_tp_opf_lm, multiconductor=true)
        sol_pq = PMs.solve_generic_model(pm_pq, ipopt_solver)

        # check they are equal
        TTF.equal_solutions(pm, pm_pq)
    end
end
