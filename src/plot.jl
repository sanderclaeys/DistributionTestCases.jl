function get_bus_coords(tppm; spacing_x=1, spacing_y=2)
    bus_source = [bus["index"] for (_,bus) in tppm["bus"] if bus["bus_type"]==3][1]
    coords = Dict{Int, Any}()
    coords[bus_source] = (0,0)

    br_arcs_fr = [(br["index"], br["f_bus"], br["t_bus"]) for (_,br) in tppm["branch"]]
    tr_arcs_fr = [(tr["index"], tr["f_bus"], tr["t_bus"]) for (_,tr) in tppm["trans"]]
    arcs_fr = [[(x..., "trans") for x in tr_arcs_fr]..., [(x..., "branch") for x in br_arcs_fr]...]
    arcs_new = ones(Bool, length(arcs_fr))
    stack = [bus_source]
    count = 0
    steps = 0
    bus_new = Dict{Int, Bool}()

    while length(stack)>0 && steps <= 200
        steps += 1
        bus = pop!(stack)
        bus_x = coords[bus][1]
        bus_y = coords[bus][2]
        if ismissing(bus_y)
            bus_y = count
        end
        if !haskey(bus_new, bus)
            bus_new[bus] = true
        end
        for (i,arc) in enumerate(arcs_fr)
            if arcs_new[i]
                if arc[2]==bus || arc[3]==bus
                    dest = (arc[2]==bus) ? arc[3] : arc[2]
                    arcs_new[i] = false
                    dest_x = bus_x + spacing_x
                    if !bus_new[bus]
                        count += spacing_y
                        dest_y = count
                    else
                        dest_y = count
                        bus_new[bus] = false
                    end
                    coords[dest] = (dest_x, dest_y)
                    stack = [stack..., bus, dest]
                    break
                end
            end
        end
    end
    return coords
end

function draw_topology(tppm, coords;
    bus_color="black", branch_color="black", trans_color="blue", oltc_color="purple",
    load_color="red", slack_color="green", straight=true)
    fig = Plots.plot(xaxis=false, yaxis=false, legend=false, grid=false)
    for (idstr,branch) in tppm["branch"]
        f_bus = branch["f_bus"]
        t_bus = branch["t_bus"]
        nph = length(branch["active_phases"])
        name = (haskey(branch, "name")) ? branch["name"] : ""
        if haskey(coords, f_bus) && haskey(coords, t_bus)
            f_x = coords[f_bus][1]
            f_y = coords[f_bus][2]
            t_x = coords[t_bus][1]
            t_y = coords[t_bus][2]
            Plots.plot!([f_x, f_x], [f_y, t_y], color=branch_color, width=nph)
            Plots.plot!([f_x, t_x], [t_y, t_y], color=branch_color, width=nph)
            Plots.scatter!([(f_x+t_x)/2], [t_y], color=branch_color,
                markershape=:square,
                markerstrokewidth=1,
                markercolor="white",
                markerstrokecolor=branch_color,
                markersize=3,
                hover="branch $idstr"
            )
        end
    end
    for (idstr,trans) in tppm["trans"]
        f_bus = trans["f_bus"]
        t_bus = trans["t_bus"]
        is_oltc = !all(trans["fixed"])
        lbl = is_oltc ? "oltc" : "trans"
        name = (haskey(trans, "name")) ? trans["name"] : ""
        if haskey(coords, f_bus) && haskey(coords, t_bus)
            f_x = coords[f_bus][1]
            f_y = coords[f_bus][2]
            t_x = coords[t_bus][1]
            t_y = coords[t_bus][2]
            tcol = (is_oltc) ? oltc_color : trans_color
            Plots.plot!([f_x, f_x], [f_y, t_y], color=tcol, width=3)
            Plots.plot!([f_x, t_x], [t_y, t_y], color=tcol, width=3)
            Plots.scatter!([(f_x+t_x)/2-0.1], [t_y], color="white",
                markerstrokewidth=1,
                markersize=7,
                markerstrokecolor=tcol
            )
            Plots.scatter!([(f_x+t_x)/2+0.1], [t_y], color="white",
                markerstrokewidth=1,
                markersize=7,
                markerstrokecolor=tcol,
                hover="$lbl $idstr"
            )
        end
    end
    for (idstr,bus) in tppm["bus"]
        id = bus["index"]
        loads = [load for (_,load) in tppm["load"] if load["load_bus"]==id]
        loads_labels = ["load $idstr" for (idstr,load) in tppm["load"] if load["load_bus"]==id]
        gens = [gen for (_,gen) in tppm["gen"] if gen["gen_bus"]==id]
        gens_labels = ["gen $idstr" for (idstr,gen) in tppm["gen"] if gen["gen_bus"]==id]
        name = (haskey(bus, "name")) ? bus["name"] : ""
        if haskey(coords, id)
            x = coords[id][1]
            y = coords[id][2]
            bcol = (bus["bus_type"]==3) ? slack_color : bus_color
            load_colors =  Array{String, 1}(undef, length(loads))
            for (i,load) in enumerate(loads)
                # fix once labels have settled
                if load["conn"]=="wye" && load["model"] in ["const_pq", "constant_power", "proportional_vm", "const_imp"]
                    load_colors[i] = "brown"
                else
                    load_colors[i] = "red"
                end
            end
            draw_topology_loads(length(loads), coords[id], loads_labels, load_color=load_colors)
            draw_topology_gens(length(gens), coords[id], gens_labels)
            Plots.scatter!([x], [y], color=bcol, hover="bus $idstr")
        end
    end
    return fig
end


function draw_topology_loads(nr_loads, bus_coords, labels; margin_deg=20, radius=0.8, load_color::Array{String, 1}=["red" for i in 1:nr_loads])
    if nr_loads==1
        spacing = [0.5]
    else
        spacing = [i/(nr_loads-1) for i in 0:nr_loads-1]
    end
    a_start = deg2rad(-margin_deg)
    a_end = deg2rad(-90+margin_deg)
    as = a_start.+(a_end-a_start).*spacing
    f_x = bus_coords[1]
    f_y = bus_coords[2]
    t_x = f_x .+ radius.*real.(exp.(im.*as))
    t_y = f_y .+ radius.*imag.(exp.(im.*as))
    for i in 1:nr_loads
        Plots.plot!([f_x, t_x[i]], [f_y, t_y[i]], color=load_color[i], width=1)
        Plots.scatter!([t_x[i]], [t_y[i]],
            color=load_color[i], markershape=:diamond, markerstrokewidth=0.5, markersize=3.5, hover=labels[i]
        )
    end
end

function draw_topology_gens(nr_gens, bus_coords, labels; margin_deg=20, radius=0.8, gen_color::Array{String, 1}=["green" for i in 1:nr_gens])
    if nr_gens==1
        spacing = [0.5]
    else
        spacing = [i/(nr_gens-1) for i in 0:nr_gens-1]
    end
    a_start = deg2rad(90+margin_deg)
    a_end = deg2rad(180-margin_deg)
    as = a_start.+(a_end-a_start).*spacing
    f_x = bus_coords[1]
    f_y = bus_coords[2]
    t_x = f_x .+ radius.*real.(exp.(im.*as))
    t_y = f_y .+ radius.*imag.(exp.(im.*as))
    for i in 1:nr_gens
        Plots.plot!([f_x, t_x[i]], [f_y, t_y[i]], color=gen_color[i], width=1)
        Plots.scatter!([t_x[i]], [t_y[i]],
            color=gen_color[i], markershape=:diamond, markerstrokewidth=0.5, markersize=3.5, hover=labels[i]
        )
    end
end
