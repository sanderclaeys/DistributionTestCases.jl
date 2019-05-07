function get_IEEE13()
    dss = TPPMs.parse_dss(string(BASE_DIR, "data/IEEE13_TPPM.dss"))
    # remove reg 1 and reg 2
    dss["transformer"] = [tr for tr in dss["transformer"] if !(tr["name"] in ["reg2", "reg3"])]
    tppm = TPPMs.parse_opendss(dss)
    # find reg1 transformers
    reg1 = [tr for (_,tr) in tppm["trans"] if tr["source_id"]=="transformer.reg1"]
    reg1_w1 = [tr for tr in reg1 if split(tr["name"], "_")[2]=="w1"][1]
    reg1_w2 = [tr for tr in reg1 if split(tr["name"], "_")[2]=="w2"][1]
    # set correct tap settingsß
    reg1_w1["tm"] = PMs.MultiConductorVector([1.0, 1.0, 1.0])
    reg1_w2["tm"] = PMs.MultiConductorVector([1.0625, 1.0500, 1.06875])
    #reg1_w2["tapset"] = MultiConductorVector([1.0, 1.0, 1.0])
    # make per unit needed
    TPPMs.check_network_data(tppm)
    return tppm
end

function validate_IEEE13()


end
