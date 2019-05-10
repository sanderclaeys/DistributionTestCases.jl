function _ray_endpoints(anchor, nr::Int; radius_max=0.8, margin_deg=25, levels=1)
    ang_start = deg2rad(-90+margin_deg)
    ang_end   = deg2rad(0-margin_deg)
    if nr==1
        vs = [(radius_max/levels)*exp(im*(ang_start+ang_end)/2)]
    else
        ang_step  = (ang_end-ang_start)/(nr-1)
        radius = [(mod(i-1,levels)+1) for i in 1:nr].*(radius_max/levels)
        ang = [ang_start+ang_step*i for i in 0:nr-1]
        vs = radius.*exp.(im.*ang)
    end
    endpoints = [(anchor[1]+real(v), anchor[2]+imag(v)) for v in vs]
end


function _get_label(comp_dict, comp_type)
    id = comp_dict["index"]
    if haskey(comp_dict, "name")
        name = comp_dict["name"]
        return string("$comp_type $id ($name)")
    else
        return string("$comp_type $id")
    end
end


function _draw_plobs(plobs)
    fig = Plots.plot(legend=false, xaxis=false, yaxis=false, grid=false)
    if haskey(plobs, :line)
        for line in plobs[:line]
            (p1x,p1y) = line[:p1]
            (p2x,p2y) = line[:p2]
            if p1x!=p2x && p1y!=p2y
                # insert a midpoint
                pmx = p1x
                pmy = p2y
                Plots.plot!([p1x, pmx, p2x], [p1y, pmy, p2y]; line[:kwargs_plot]...)
                if haskey(line, :kwargs_scatter)
                    Plots.scatter!([p1x/2+p2x/2], [p2y]; line[:kwargs_scatter]...)
                end
            else
                Plots.plot!([p1x, p2x], [p1y, p2y]; line[:kwargs_plot]...)
                if haskey(line, :kwargs_scatter)
                    Plots.scatter!([p1x/2+p2x/2], [p1y/2+p2y/2]; line[:kwargs_scatter]...)
                end
            end
        end
    end
    if haskey(plobs, :ray)
        for ray in plobs[:ray]
            (p1x,p1y) = ray[:anchor]
            items = ray[:items]
            nr = length(items)
            ps =_ray_endpoints(ray[:anchor], nr)
            for i in 1:nr
                item = items[i]
                (p2x,p2y) = ps[i]
                Plots.plot!([p1x, p2x], [p1y, p2y]; item[:kwargs_plot]...)
                Plots.scatter!([p2x], [p2y]; item[:kwargs_scatter]...)
            end
        end
    end
    if haskey(plobs, :connector)
        for conn in plobs[:connector]
            (px,py) = conn[:p]
            Plots.scatter!([px], [py]; conn[:kwargs_scatter]...)
        end
    end
    return fig
end


function draw_topology(tppm, coords)
    plobs = Dict(:connector=>[], :line=>[], :ray=>[])
    for (_,bus) in tppm["bus"]
        bus_id = bus["index"]
        # add the bus itself
        p = coords[bus_id]
        label =_get_label(bus, "bus")
        conn = Dict(:p=>p, :kwargs_scatter=>Dict(
            :markercolor=> bus["bus_type"]==3 ? :green : :black,
            :markersize=>2,
            :hover=>label,
        ))
        append!(plobs[:connector], [conn])
        # add a ray for its components
        ray = Dict(:anchor=>p, :items=>[])
        bus_shunts = [shunt for (_,shunt) in tppm["shunt"] if shunt["shunt_bus"]==bus_id]
        bus_loads = [load for (_,load) in tppm["load"] if load["load_bus"]==bus_id]
        bus_gens = [gen for (_,gen) in tppm["gen"] if gen["gen_bus"]==bus_id]
        # loads
        for load in bus_loads
            conn = haskey(load, "conn") ? load["conn"] : "wye"
            colmap = Dict("proportional_vm"=>:red, "proportional_vmsqr"=>:orange, "constant_power"=>:green)
            model = haskey(load, "model") ? load["model"] : "constant_power"
            lcol = haskey(colmap, model) ? colmap[model] : :black
            label =_get_label(load, "load")
            item = Dict(
                :kwargs_plot=>Dict(:linestyle=>:dash, :color=>lcol),
                :kwargs_scatter=>Dict(
                    :color=>lcol,
                    :markersize=>2,
                    :markershape=> conn=="delta" ? :utriangle : :rect,
                    :hover=>label,
                )
            )
            append!(ray[:items], [item])
        end
        # shunts
        for shunt in bus_shunts
            scol = :orange
            label =_get_label(shunt, "shunt")
            item = Dict(
                :kwargs_plot=>Dict(
                    :color=>scol, :linestyle=>:dash
                ),
                :kwargs_scatter=>Dict(
                    :color=>scol, :hover=>:label
                ),
            )
            append!(ray[:items], [item])
        end
        # gens
        for gen in bus_gens
            gcol = :green
            label =_get_label(gen, "gen")
            item = Dict(:kwargs_plot=>Dict(:color=>gcol),
                :kwargs_scatter=>Dict(:color=>gcol, :markershape=>:pentagon, :hover=>label)
            )
            append!(ray[:items], [item])
        end
        append!(plobs[:ray], [ray])
    end
    for (idstr,branch) in tppm["branch"]
        p1 = coords[branch["f_bus"]]
        p2 = coords[branch["t_bus"]]
        label =_get_label(branch, "branch")
        line = Dict(
            :p1=>p1, :p2=>p2,
            :kwargs_plot=>Dict(:color=>:black),
            :kwargs_scatter=>Dict(:color=>:white,
                :markershape=>:square, :markersize=>2, :hover=>label
            ),
        )
        append!(plobs[:line], [line])
    end
    for (idstr,trans) in tppm["trans"]
        (p1x,p1y) = coords[trans["f_bus"]]
        (p2x,p2y) = coords[trans["t_bus"]]
        label =_get_label(trans, "trans")
        tcol = :blue
        line = Dict(
            :p1=>(p1x,p1y), :p2=>(p2x,p2y),
            :kwargs_plot=>Dict(:color=>tcol),
            :kwargs_scatter=>Dict(:color=>tcol, :markershape=>:circle, :hover=>label)
        )
        append!(plobs[:line], [line])
    end
    return _draw_plobs(plobs)
end
