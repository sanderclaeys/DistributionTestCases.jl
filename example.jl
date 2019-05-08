import PowerModels
PMs = PowerModels
import ThreePhasePowerModels
TPPMs = ThreePhasePowerModels
import TPPMTestFeeders
TTF = TPPMTestFeeders

import Ipopt

tppm = TTF.get_IEEE13()
tppm_pq = TTF.load_tppm("IEEE13_PQ.json")
(tppm_pq)

##

tppm = TTF.get_IEEE13()

# simulate with lm enabled TPPM
pm = PMs.build_generic_model(tppm, PMs.ACPPowerModel, TPPMs.post_tp_opf_lm, multiconductor=true)
sol = PMs.solve_generic_model(pm, Ipopt.IpoptSolver(print_level=0))

# convert to constant_power loads
tppm_pq_original = TTF.convert_to_PQ(tppm)

# now save to json file and load again
TTF.save_tppm(tppm_pq_original, "IEEE13_PQ.json")
tppm_pq = TTF.load_tppm("IEEE13_PQ.json")

# simulate with ordinary TPPM
pm_pq = PMs.build_generic_model(tppm_pq, PMs.ACPPowerModel, TPPMs.post_tp_opf, multiconductor=true)
sol_pq = PMs.solve_generic_model(pm_pq, Ipopt.IpoptSolver(print_level=0))

# compare results
# we can only compare the voltage, because pm_pq has no load variables
TTF.equal_solutions(pm, pm_pq, v_only=true)
