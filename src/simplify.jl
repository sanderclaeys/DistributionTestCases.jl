
function simplify_feeder!(data_pmd;
    remove_transformers=true,
    loads_to_wye_pq=true
)
    if remove_transformers
        remove_transformers!(data_pmd)
    end
    if loads_to_wye_pq
        simplify_load_models!(data_pmd)
    end
end


function remove_transformers!(data_pmd)
    source = [bus for (_, bus) in data_pmd["bus"] if bus["bus_type"]==3][1]
    source_id = source["index"]
    vbase_new = source["base_kv"]

    # remove transformers
    for (trans_id, trans) in data_pmd["trans"]
        f_bus = trans["f_bus"]
        t_bus = trans["t_bus"]
        # do not remove the source bus
        bus_rm_id = (f_bus!=source_id) ? f_bus : t_bus
        bus_sub_id = (f_bus!=source_id) ? t_bus : f_bus
        delete!(data_pmd["bus"], string(bus_rm_id))
        delete!(data_pmd["trans"], trans_id)
        substitute_bus_reference!(data_pmd, bus_rm_id, bus_sub_id)
    end

    # update nominal voltage of loads
    for (_, load) in data_pmd["load"]
        vbase_old = data_pmd["bus"][string(load["load_bus"])]["base_kv"]
        #load["vnom_kv"] *= (vbase_new/vbase_old)
    end
end


function substitute_bus_reference!(data_pmd, bus_from_id, bus_to_id)
    for (_, load) in data_pmd["load"]
        if load["load_bus"]==bus_from_id
            load["load_bus"] = bus_to_id
        end
    end

    for (_, branch) in [data_pmd["branch"]..., data_pmd["trans"]...]
        if branch["f_bus"]==bus_from_id
            branch["f_bus"] = bus_to_id
        end
        if branch["t_bus"]==bus_from_id
            branch["t_bus"] = bus_to_id
        end
    end

    for (_, shunt) in data_pmd["shunt"]
        if shunt["shunt_bus"]==bus_from_id
            shunt["shunt_bus"] = bus_to_id
        end
    end

    for (_, gen) in data_pmd["gen"]
        if gen["gen_bus"]==bus_from_id
            gen["gen_bus"] = bus_to_id
        end
    end
end


function simplify_load_models!(data_pmd)
    for (_, load) in data_pmd["load"]
        # convert to constant power load
        load["model"] = "constant_power"
        # convert delta to wye load under balanced assumption
        if load["conn"]=="delta"
            load["conn"] = "wye"
            M = [1 -1 0; 0 1 -1; -1 0 1]
            Un = exp.(im.*[0, -2*pi/3, 2*pi/3])
            sd = load["pd"].values + im*load["qd"].values
            s_wye = Un.*(M'*(sd./(M*Un)))
            load["pd"] = PMs.MultiConductorVector(real.(s_wye))
            load["qd"] = PMs.MultiConductorVector(imag.(s_wye))
        end
        load["pd"] *= 1
        load["qd"] *= 1
    end
end
