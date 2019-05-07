"""
Parses an OpenDSS output text file of the type 'VLN_Node.Txt',
and extracts the voltage phasors of all buses.
When a node is missing from the data (for example, the third node in a segment
with two-phase cables), then the value will be 'missing' for that node.
"""
function parse_opendss_VLN_Node(file_path; nphs=3, va_offset=0)
    buses = Dict{String, Dict{Symbol, Any}}()
    open(file_path, "r") do file
        bus_name::Union{String, Nothing} = nothing
        for l in [l for l in eachline(file) if l!=""]
            parts = split(l)
            if !(parts[2] in ["and", "Node"])
                if parts[1]!="-"
                    bus_name = lowercase(parts[1])
                    buses[bus_name] = Dict{String, Any}()
                    buses[bus_name][:vm_kv] = Array{Union{Float64, Missing}, 1}(missing, nphs)
                    buses[bus_name][:va_rad] = Array{Union{Float64, Missing}, 1}(missing, nphs)
                end
                parts = [x for x in parts if !(x in ["."^x for x in 1:5])]
                node = parse(Int, parts[2])
                buses[bus_name][:vm_kv][node] = parse(Float64, parts[3])
                buses[bus_name][:va_rad][node] = deg2rad(parse(Float64, parts[5]))+va_offset
            end
        end
    end
    return buses
end


"""
Parses an OpenDSS output text file of the type 'Power_elem_kVA',
and extracts all load data from it (ignoring the neutral).
"""
function parse_opendss_Power_elem_kVA(file_path; nphs=3)
    loads = Dict{String, Any}()
    open(file_path, "r") do file
        bus_name::Union{String, Nothing} = nothing
        name = nothing
        data_mode = false
        for l in [l for l in eachline(file) if l!=""]
            parts = split(l)
            # if starts with TERMINAL, stop data mode
            if parts[1]=="TERMINAL"
                component = nothing
                name = nothing
                data_mode = false
            end
            if data_mode
                if !haskey(loads, name)
                    loads[name] = Dict{Symbol, Any}()
                    loads[name][:pd_kw] = Array{Union{Float64, Missing}, 1}(missing, nphs)
                    loads[name][:qd_kvar] = Array{Union{Float64, Missing}, 1}(missing, nphs)
                end
                node = parse(Int, parts[2])
                if node!=0
                    loads[name][:pd_kw][node] = parse(Float64, parts[3])
                    loads[name][:qd_kvar][node] = parse(Float64, parts[5])
                end
            end
            if parts[1]=="ELEMENT"
                el_str = parts[3][2:end-1]
                component = split(el_str, ".", limit=2)[1]
                if component=="Load"
                    name = lowercase(split(el_str, ".", limit=2)[2])
                    data_mode = true
                end
            end

        end
    end
    return loads
end


"Find the id (integer) of a component by its name."
function name2id(dict::Dict, name::String)
    for (k,v) in dict
        if haskey(v, "name") && v["name"]==name
            return v["index"]
        end
    end
    return nothing
end


"""
Replaces all load models that are not type 1 (constant PQ) and wye,
with an 'equivalent' type 1 wye model. To do this, the ACP solution is used.
"""
function convert_to_PQ(tppm::Dict)
    pm = PMs.build_generic_model(tppm, PMs.ACPPowerModel, TPPMs.post_tp_opf_lm, multiconductor=true)
    sol = PMs.solve_generic_model(pm, Ipopt.IpoptSolver(print_level=0))

    ret = deepcopy(tppm)

    for (load_id_str, load) in ret["load"]
        if load["model"]!="constant_power" || load["conn"]!="wye"
            load_id = load["index"]
            for c in 1:tppm["conductors"]
                load["pd"][c] = JuMP.getvalue(PMs.var(pm, pm.cnw, c, :pd, load_id))
                load["qd"][c] = JuMP.getvalue(PMs.var(pm, pm.cnw, c, :qd, load_id))
            end
            load["model"] = "constant_power"
            load["conn"] = "wye"
        end
    end

    return ret
end


"""
Check whether two solved pms have the same values for :pd, :pq, :vm and :va.
This therefore presumes an ACPPowerModel.
"""
function equal_solutions(pm1::PMs.GenericPowerModel{T}, pm2::PMs.GenericPowerModel{T};
                                pq_atol_kva=1E-2, vm_atol=1E-5, va_atol_rad=1E-4) where T <: PMs.AbstractACPForm
    @testset "equal load power" begin
        for load_id in PMs.ids(pm1, :load)
            for c in PMs.conductor_ids(pm1)
                sbase_kva_1 = PMs.ref(pm1, :baseMVA)*1E3
                sbase_kva_2 = PMs.ref(pm2, :baseMVA)*1E3
                pd1 = JuMP.getvalue(PMs.var(pm1, pm1.cnw, c, :pd, load_id))
                pd2 = JuMP.getvalue(PMs.var(pm2, pm2.cnw, c, :pd, load_id))
                qd1 = JuMP.getvalue(PMs.var(pm1, pm1.cnw, c, :qd, load_id))
                qd2 = JuMP.getvalue(PMs.var(pm2, pm2.cnw, c, :qd, load_id))
                @test abs(pd1*sbase_kva_1-pd2*sbase_kva_2)<= pq_atol_kva
                @test abs(qd1*sbase_kva_1-qd2*sbase_kva_2)<= pq_atol_kva
            end
        end
    end

    @testset "equal voltage" begin
        for bus_id in PMs.ids(pm1, :bus)
            for c in PMs.conductor_ids(pm1)
                vbase_kv_1 = PMs.ref(pm1, :bus, bus_id, "base_kv")
                vbase_kv_2 = PMs.ref(pm1, :bus, bus_id, "base_kv")
                vm1 = JuMP.getvalue(PMs.var(pm1, pm1.cnw, c, :vm, bus_id))
                vm2 = JuMP.getvalue(PMs.var(pm2, pm2.cnw, c, :vm, bus_id))
                va1 = JuMP.getvalue(PMs.var(pm1, pm1.cnw, c, :va, bus_id))
                va2 = JuMP.getvalue(PMs.var(pm2, pm2.cnw, c, :va, bus_id))
                @test vm1*vbase_kv_1/vbase_kv_2-vm2 <= vm_atol
                @test va1-va2 <= va_atol_rad
            end
        end
    end
end

# USAGE EXAMPLE
#buses_res = parse_opendss_VLN_Node("data/IEEE13NodecktAssets_VLN_Node.txt")
#loads_res = parse_opendss_Power_elem_kVA("data/IEEE13NodecktAssets_Power_elem_kVA.txt")
