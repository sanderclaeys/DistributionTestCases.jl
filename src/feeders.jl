const CASE_PATH = Dict{String, Any}(
    "IEEE13"=>"$BASE_DIR/src/data/ieee13/ieee13_pmd.dss",
    "IEEE34"=>"$BASE_DIR/src/data/ieee34/ieee34_pmd.dss",
    "IEEE123"=>"$BASE_DIR/src/data/ieee123/ieee123_pmd.dss",
    "LVTestCase"=>Dict{Int, String}([
        (t, "$BASE_DIR/src/data/lvtestcase/snapshots/lvtestcase_pmd_t$t.dss")
        for t in 1:1440])
)
