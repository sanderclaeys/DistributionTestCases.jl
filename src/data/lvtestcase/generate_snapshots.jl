## read in profiles
global profs = Dict()
for i in 1:55
    open("profiles/load_profile_$i.txt") do f
        global profs["$i"] = [parse(Float64, x) for x in strip.(readlines(f))]
    end
end

# read in dss template
global dss
open("lvtestcase_pmd_template.dss") do f
    global dss = readlines(f)
end

ln_loads = [i for i in 1:length(dss) if length(dss[i])>=7 && dss[i][1:8]=="New Load"]
ts = length(profs["1"])
global dss_diff = Dict()
for i in ln_loads
    dss_diff[i] = Dict()
    line = deepcopy(dss[i])
    (nw, name, phases, bus, kv, kw, pf, yearly) = split(line, " ")
    id = yearly[14:end]
    line = join(split(line, " ")[1:end-1], " ")
    for t in 1:ts
        kw_val = parse(Float64, kw[4:end])*profs[id][t]
        global dss_diff[i][t] = "$nw $name $phases $bus $kv kW=$kw_val $pf vminpu=0.6 vmaxpu=1.4"
    end
end

for t in 1:ts
    open("snapshots/lvtestcase_pmd_t$t.dss", "w") do f
        for i in 1:length(dss)
            if i in ln_loads
                println(f, dss_diff[i][t])
            else
                println(f, dss[i])
            end
        end
    end
end
