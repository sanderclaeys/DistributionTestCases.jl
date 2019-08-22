function get_lvtestcase(; t=1000, file_path="$(BASE_DIR)/src/data/lvtestcase/snapshots/lvtestcase_pmd_t$t.dss")
    dss = PMD.parse_dss(file_path)
    data_pmd = PMD.parse_opendss(dss)
    PMD.correct_network_data!(data_pmd)

    return data_pmd
end
