function get_ieee13(; file_path="$(BASE_DIR)/src/data/ieee13/ieee13_pmd.dss")
    dss = PMD.parse_dss(file_path)
    # remove reg 1 and reg 2
    dss["transformer"] = [tr for tr in dss["transformer"] if !(tr["name"] in ["reg2", "reg3"])]
    tppm = PMD.parse_opendss(dss)
    # find reg1 transformers
    reg1 = [tr for (_,tr) in tppm["trans"] if occursin("transformer.reg1", tr["source_id"])]
    reg1_w1 = [tr for tr in reg1 if split(tr["name"], "_")[2]=="w1"][1]
    reg1_w2 = [tr for tr in reg1 if split(tr["name"], "_")[2]=="w2"][1]
    # set correct tap settingsß
    reg1_w1["tm"] = PMs.MultiConductorVector([1.0, 1.0, 1.0])
    reg1_w2["tm"] = PMs.MultiConductorVector([1.0625, 1.0500, 1.06875])
    #reg1_w2["tapset"] = MultiConductorVector([1.0, 1.0, 1.0])
    # make per unit needed
    PMD.correct_network_data!(tppm)
    return tppm
end
