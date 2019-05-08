
# dump tppm leaf values to string
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

function guess_type(els::Union{AbstractString, Array{T} where T <: AbstractString})
    has_inf = false
    if !isa(els, Array)
        els = [els]
    end
    for el in els
        if el in ["Inf", "-Inf"]
            has_inf = true
            continue
        elseif occursin(r"^[1-9][0-9]*$", el)
            return Int
        elseif el in ["true", "false"]
            return Bool
        else
            try
                parse(Float64, el)
                return Float64
            catch

                return String
            end
        end
    end
    if has_inf
        return Float64
    end
end

# parse a string back to a leaf value
function from_string(str::AbstractString)
    # matrix or vector
    if isempty(str)
        return str
    end
    if str[1]=='['
        if occursin(',', str)
            # this is a vector
            els = [strip(x) for x  in split(str[2:end-1], ',')]
            constr = PMs.MultiConductorVector
        else
            rows = [strip(x) for x in split(str[2:end-1], ';')]
            els = vcat([reshape(v, 1, length(v)) for v in [split(row) for row in rows]]...)
            constr = PMs.MultiConductorMatrix

        end
    else
        els = str
        constr(x) = x
    end
    type = guess_type(els)
    if type <: AbstractString
        return constr(els)
    else
        # list comprehension needed to convert BitArray to Array{Bool}
        # has no effect on other Arrays
        return constr([x for x in parse.(type, els)])
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
    tppm = Dict{String, Any}()
    for (k,v) in d
        if isa(v, Dict)
            tppm[k] = dict_to_tppm(v)
        else
            if isa(v, AbstractString)
                tppm[k] = from_string(v)
            else
                tppm[k] = v
            end
        end
    end
    return tppm
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
    tppm = dict_to_tppm(dict)
    # OTHER FIXES
    # polarity should be a char and not a string
    # temporary fix; resolve this in TPPM later on
    for (_,trans) in tppm["trans"]
        for config in [trans["config_fr"], trans["config_to"]]
            config["polarity"] = config["polarity"][1]
        end
    end
    return tppm
end
