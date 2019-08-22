function get_ieee123(; file_path="$(BASE_DIR)/src/data/ieee123/ieee123_pmd.dss")
    #dss = TPPMs.parse_dss(string(BASE_DIR, "data/IEEE34_TPPM.dss"))
    dss = PMD.parse_dss(file_path)

    trs = Dict([(tr["name"], tr) for tr in dss["transformer"]])
    for tr_name in ["reg3c", "reg4b", "reg4c"]
        delete!(trs, tr_name)
    end
    for tr_name in ["reg2a", "reg3a", "reg4a"]
        tr = trs[tr_name]
        #remove phases suffix from the name; becomes three-phase
        tr["name"] = tr_name[1:end-1]
        tr["phases"] = "3"
        #only keep bus and not node specification
        # not strictly needed; the suffix is removed in the parser
        tr["buses"] = string("[", join([split(x, ".")[1] for x in split(tr["buses"][2:end-1], " ") if x!=""], " "), "]")
    end

    dss["transformer"] = collect(values(trs))

    data_pmd = PMD.parse_opendss(dss)

    # now, correct tap settings
    trs_pmd = Dict([(tr["source_id"], tr) for (_, tr) in data_pmd["trans"]])
    trs_pmd["transformer.reg1a_2"]["tm"] = PMs.MultiConductorVector(
        [PMD._parse_rpn("(0.00625 $x * 1 +)") for x in [7, 7, 7]]
    )
    trs_pmd["transformer.reg2_2"]["tm"] = PMs.MultiConductorVector(
        [PMD._parse_rpn("(0.00625 $x * 1 +)") for x in [-1, 0, 0]]
    )
    trs_pmd["transformer.reg3_2"]["tm"] = PMs.MultiConductorVector(
        [PMD._parse_rpn("(0.00625 $x * 1 +)") for x in [0, 0, -1]]
    )
    trs_pmd["transformer.reg4_2"]["tm"] = PMs.MultiConductorVector(
        [PMD._parse_rpn("(0.00625 $x * 1 +)") for x in [8, 1, 5]]
    )

    # make per unit needed
    PMD.correct_network_data!(data_pmd)

    return data_pmd
end
