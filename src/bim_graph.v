module main

struct BimGraph {
mut:
	head []&BimNode
	node_count usize
}

struct BimNode {
mut:
	dest usize
	eid usize
	next &BimNode
}

struct BimEdge {
	src usize
	dest usize
	id usize
}

fn bim_graph_new(bim &Bim) BimGraph {
	mut edges := graph_create_edges(bim.transits,  bim.zones)

	graph := graph_create(edges, usize(bim.transits.len), usize(bim.zones.len))
	return graph
}

fn graph_create(edges []BimEdge, edge_count usize, node_count usize) BimGraph {
	mut src := usize(0)
	mut dest := usize(0)
	mut eid := usize(0)
	println("edges ${edges}")

	unsafe {
		// add edges to the directed graph one by one
		mut nodes := []&BimNode{len: int(edges.len)}

		for edge in edges {
			// get the source and destination vertex
			src = edge.src
			dest = edge.dest
			eid = edge.id

			// 1. allocate a new node of adjacency list from `src` to `dest`
			mut src_to_dest := &BimNode {
				dest: dest
				eid: eid
				next: nodes[src] // point new node to the current head
			}

			// point head pointer to the new node
			nodes[src] = src_to_dest

			// 2. allocate a new node of adjacency list from `dest` to `src`
			mut dest_to_src := &BimNode {
				dest: src
				eid: eid
				next: nodes[dest] // point new node to the current head
			}

			// change head pointer to point to the new node
			nodes[dest] = dest_to_src
		}

		graph := BimGraph {
			node_count: node_count
			head: nodes
		}

		return graph
	}
}

fn graph_create_edges(transits []BimTransit, zones []BimZone) []BimEdge
{
	mut edges := []BimEdge{}
	for i, transit in transits {
		mut ids := [usize(0), usize(zones.len)]!
		mut j := 0

		for k, zone in zones {
			if zone.outputs.any(it == transit.uuid) && j != 2 {
				ids[j] = usize(k)
				j++
			}
		}

		edges << BimEdge {
			id: usize(i)
			src: ids[0]
			dest: ids[1]
		}
	}
	return edges
}

fn arraylist_equal_callback(zone &BimZone, transit &BimTransit) bool {
	for output in zone.outputs {
		if output == transit.uuid {
			return true
		}
	}
	return false
}
