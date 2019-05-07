TTF = TPPMTestFeeders
using Compat.Test

# Suppress warnings during testing.
Memento.setlevel!(Memento.getlogger(PowerModels), "error")

@testset "validate feeders" begin
    @testset "IEEE13" begin
        tppm = TTF.get_IEEE13()
        TTF.validate(tppm, "data/IEEE13NodecktAssets_VLN_Node.txt",  "data/IEEE13NodecktAssets_Power_elem_kVA.txt")
    end
end
