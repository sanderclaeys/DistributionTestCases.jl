function get_ieee34(; file_path="$(BASE_DIR)/src/data/ieee34/ieee34_pmd.dss")
    #dss = TPPMs.parse_dss(string(BASE_DIR, "data/IEEE34_TPPM.dss"))
    dss = PMD.parse_dss(file_path)
    # remove reg 1b, reg1c, reg2b and reg2c
    dss["transformer"] = [tr for tr in dss["transformer"] if !(tr["name"] in ["reg1b", "reg1c", "reg2b", "reg2c"])]
    for tr in dss["transformer"]
        if tr["name"]=="reg1a"
            tr["name"] = "reg1"
        elseif tr["name"]=="reg2a"
            tr["name"] = "reg2"
        end
    end
    tppm = PMD.parse_opendss(dss)
    # find reg1 and reg 2 transformers
    reg1 = [tr for (_,tr) in tppm["trans"] if occursin("transformer.reg1", tr["source_id"])]
    reg1_w1 = [tr for tr in reg1 if split(tr["name"], "_")[2]=="w1"][1]
    reg1_w2 = [tr for tr in reg1 if split(tr["name"], "_")[2]=="w2"][1]
    reg2 = [tr for (_,tr) in tppm["trans"] if occursin("transformer.reg2", tr["source_id"])]
    reg2_w1 = [tr for tr in reg2 if split(tr["name"], "_")[2]=="w1"][1]
    reg2_w2 = [tr for tr in reg2 if split(tr["name"], "_")[2]=="w2"][1]
    # set correct tap settings
    reg1_w1["tm"] = PMs.MultiConductorVector([1.0, 1.0, 1.0])
    reg1_w2["tm"] = PMs.MultiConductorVector([1.075, 1.03125, 1.03125])
    #reg1_w2["tm"] = PMs.MultiConductorVector([1.0, 1.0, 1.0])
    reg2_w1["tm"] = PMs.MultiConductorVector([1.0, 1.0, 1.0])
    reg2_w2["tm"] = PMs.MultiConductorVector([1.08125, 1.06875, 1.075])
    #reg2_w2["tm"] = PMs.MultiConductorVector([1.0, 1.0, 1.0])
    # make per unit needed
    PMD.correct_network_data!(tppm)
    return tppm
end
