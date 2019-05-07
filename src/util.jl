"
Parses an OpenDSS output text file of the type 'VLN_Node.Txt',
and extracts the voltage phasors of all buses.
When a node is missing from the data (for example, the third node in a segment
with two-phase cables), then the value will be 'missing' for that node.
"
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


"
Parses an OpenDSS output text file of the type 'Power_elem_kVA',
and extracts all load data from it (ignoring the neutral).
"
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


# USAGE EXAMPLE
#buses_res = parse_opendss_VLN_Node("data/IEEE13NodecktAssets_VLN_Node.txt")
#loads_res = parse_opendss_Power_elem_kVA("data/IEEE13NodecktAssets_Power_elem_kVA.txt")
