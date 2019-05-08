to_string(x::Any) = string(x)
to_string(x::Int) = x
to_string(x::Real) = x
to_string(x::Float64) = x
to_string(x::PMs.MultiConductorVector{T}) where T <: Int = string(x)
to_string(x::PMs.MultiConductorVector{T}) where T <: Real = string(x)
to_string(x::PMs.MultiConductorVector{Bool}) = string(x)[5:end]
to_string(x::PMs.MultiConductorMatrix{T}) where T <: Int = string(x)
to_string(x::PMs.MultiConductorMatrix{T}) where T <: Real = string(x)
to_string(x::PMs.MultiConductorMatrix{Bool}) = string(x)[5:end]


function from_string(str::AbstractString)
    # matrix or vector
    if isempty(str)
        return str
    end
    if str[1]=='['
        if occursin(',', str)
            # this is a vector
            els = [strip(x) for x  in split(str[2:end-1], ',')]
            sample = els[1]
            constr = PMs.MultiConductorVector
        else
            rows = [strip(x) for x in split(str[2:end-1], ';')]
            els = vcat([reshape(v, 1, length(v)) for v in [split(row) for row in rows]]...)
            sample = els[1,1]
            constr = PMs.MultiConductorMatrix

        end
    else
        sample = str
        constr(x) = x
    end
    try
        if sample in ["true", "false"]
            return constr([x for x in parse.(Bool, els)])
        elseif !occursin('.', els[1])
            return constr(parse.(Int, els))
        else
            return constr(parse.(Float64, els))
        end
    catch
        return str
    end
end


function tppm_to_dict(d::Dict)
    out = Dict()
    for (k,v) in d
        if isa(v, Dict)
            out[k] = tppm_to_dict(v)
        else
            out[k] = to_string(v)
        end
    end
    return out
end


function dict_to_tppm(d::Dict)
    out = Dict()
    for (k,v) in d
        if isa(v, Dict)
            out[k] = dict_to_tppm(v)
        else
            if isa(v, AbstractString)
                out[k] = from_string(v)
            else
                out[k] = v
            end
        end
    end
    return out
end


function save_tppm(tppm, file_path)
    open(file_path,"w") do f
        JSON.print(f, tppm_to_dict(tppm))
    end
end


function load_tppm(file_path)
    dict = nothing
    open(file_path,"r") do f
        dict = JSON.parse(f)
    end
    return dict_to_tppm(dict)
end
