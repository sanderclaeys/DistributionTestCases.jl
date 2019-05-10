function direct_graph(gr::LG.AbstractGraph, v_source::Int)
   dgr = LG.DiGraph(LG.nv(gr))
   stack = [v_source]
   visited = []
   while length(stack)>0
      v = pop!(stack)
      children = [x for x in LG.neighbors(gr, v) if !(x in visited)]
      for child in children
         LG.add_edge!(dgr, v, child)
      end
      append!(visited, [v])
      append!(stack, children)
   end
   return dgr
end

function get_maxlen(gr, source)
   stack = [source]
   imp = Dict{Int, Int}()
   straight = Dict{Int, Bool}()
   while length(stack)>0
      v = pop!(stack)
      outn = LG.outneighbors(gr, v)
      if length(outn)==0
         straight[v] = true
         imp[v] = 0
      else
         unseen = [x for x in outn if !haskey(imp, x)]
         if length(unseen)==0
            imp[v] = 1+maximum([imp[x] for x in outn])
            if length(outn)==1 && straight[outn[1]]
               straight[v] = true
            else
               straight[v] = false
            end
         else
            stack = [stack..., v, unseen...]
         end
      end
   end
   return (imp, straight)
end


"""
This method assigns coordinates to all buses. This is done in such a way
that branches and transformers will never cross (for a radial feeder).

Buses are converted to vertices, and all arcs (transformers and branches)
are converted to edges. If the resulting graph is cyclic, the maximum spanning
tree is used instead. Next, a directed tree is obtained, directed away from the
source node.

When branching occurs, several rules apply.
If there is a single outneighbour, it is placed to the right.
If there are two outneighbours and one of them has a 'straight' path attached to
it, that one is placed right above going up, and the other outneighbour is
placed to the right.
For more than two outneighbours, more complex rules apply.
"""
function get_bus_coords(tppm::Dict)
   # make graph
   id2v = Dict([(bus["index"],v) for (v,bus) in enumerate(values(tppm["bus"]))])
   v2id = Dict([(v,id) for (id,v) in id2v])
   gr = LG.SimpleGraph(length(keys(id2v)))
   for (_,tr) in tppm["trans"]
      f_v = id2v[tr["f_bus"]]
      t_v = id2v[tr["t_bus"]]
      LG.add_edge!(gr, f_v, t_v)
   end
   for (_,br) in tppm["branch"]
      f_v = id2v[br["f_bus"]]
      t_v = id2v[br["t_bus"]]
      LG.add_edge!(gr, f_v, t_v)
   end

   # if cyclic, only keep min spanning tree
   # preferably max, but does not seem to  work
   # TODO test that this works!
   if LG.is_cyclic(gr)
      gr = LG.SimpleGraph(LG.kruskal_mst(gr))
   end

   # create directed graph
   id_source = [bus["index"] for (_,bus) in tppm["bus"] if bus["bus_type"]==3][1]
   v_source = id2v[id_source]
   dgr = direct_graph(gr, v_source)

   # calculate vertex weights and subtree straightness
   (w_v, straight) = get_maxlen(dgr, v_source)

   coords = Dict{Int, Any}()
   coords[v_source] = (0,0)
   stack = [v_source]
   height = 0
   while length(stack)>0
      v = pop!(stack)
      (v_x, v_y) = coords[v]
      outn = LG.outneighbors(dgr, v)
      imps  = [w_v[x] for x in outn]
      if length(outn)==0
         # nothing to do
      elseif length(outn)==2 && (straight[outn[1]] || straight[outn[2]])
         v_up     = straight[outn[1]] ? outn[1] : outn[2]
         v_right  = straight[outn[1]] ? outn[2] : outn[1]
         # branch going up
         v_up_x = v_x
         v_up_y = v_y + 1
         coords[v_up] = (v_up_x, v_up_y)
         while LG.outdegree(dgr, v_up)>0
            v_up = LG.outneighbors(dgr, v_up)[1]
            v_up_y += 1
            coords[v_up] = (v_up_x, v_up_y)
         end
         # branch going right
         coords[v_right] = (v_x+1, v_y)
         stack = [stack..., v_right]
      else
         unset = [x for x in outn if !haskey(coords, x)]
         imps  = [w_v[x] for x in unset]
         v_dest = unset[findmax(imps)[2]]
         if length(unset)==length(outn)
            coords[v_dest] = (v_x+1, v_y)
         else
            height = maximum([p[2] for p in values(coords) if p[1]>v_x])
            coords[v_dest] = (v_x+1, height+1)
         end
         if length(unset)>1
            #return here
            stack = [stack..., v, v_dest]
         else
            stack = [stack..., v_dest]
         end
      end
   end

   # convert coords keys from vertex to id
   out = Dict([(v2id[v], xy) for (v, xy) in coords])

   return out
end
